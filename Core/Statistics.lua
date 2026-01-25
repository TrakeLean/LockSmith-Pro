-- Statistics.lua
-- Gold tracking and statistics management

LockSmithPro = LockSmithPro or {}
LockSmithPro.Statistics = {}

local sessionStartTime = 0
local sessionGold = 0
local sessionJobs = 0
local sessionBoxes = 0
local pendingTradePartner = nil
local pendingTradeGold = 0
local pendingTradeBoxes = 0
local pendingTradeBoxCounts = nil
local tradeCompleted = false
local lastJobTimeByPartner = {}
local JOB_WINDOW_SECONDS = 600
local pickedLocksThisTrade = 0  -- Track Pick Lock casts during current trade

-- Pick Lock spell IDs across different WoW versions
-- We'll check against all of them since spell IDs can vary
local PICK_LOCK_SPELL_IDS = {
    1804,   -- Classic/Vanilla Pick Lock
    6460,   -- Pick Lock (Rank 2) - TBC+
}

-- Helper function to check if a spell ID is Pick Lock
local function IsPickLockSpell(spellID)
    for _, id in ipairs(PICK_LOCK_SPELL_IDS) do
        if spellID == id then
            return true
        end
    end
    return false
end

local function NormalizePartnerName(name)
    if type(name) ~= "string" then
        return ""
    end

    local base = name
    local dash = string.find(base, "-", 1, true)
    if dash then
        base = string.sub(base, 1, dash - 1)
    end

    return string.lower(base)
end

local function ShouldCountJob(partner)
    local key = NormalizePartnerName(partner)
    if key == "" then
        return true
    end

    local now = GetTime()
    local last = lastJobTimeByPartner[key]
    if not last or (now - last) > JOB_WINDOW_SECONDS then
        lastJobTimeByPartner[key] = now
        return true
    end

    return false
end

local function EnsureBoxStats()
    if not LockSmithProDB or not LockSmithProDB.stats then return end

    if type(LockSmithProDB.stats.boxesOpened) ~= "table" then
        LockSmithProDB.stats.boxesOpened = {}
    end
    if type(LockSmithProDB.stats.totalBoxes) ~= "number" then
        LockSmithProDB.stats.totalBoxes = 0
    end
end

local function CountTradeBoxes()
    local counts = {}
    local total = 0

    -- Check target's trade slots 1-6 ONLY (items being traded to us)
    -- Slot 7 ("Will Not Be Traded") is tracked separately via Pick Lock spell casts
    for slot = 1, 6 do
        local itemLink = GetTradeTargetItemLink(slot)
        if itemLink then
            local itemName, _, itemCount = GetTradeTargetItemInfo(slot)
            local boxData = LockSmithPro.GetBoxDataFromItemLink and LockSmithPro:GetBoxDataFromItemLink(itemLink, itemName)
            if boxData then
                local count = itemCount or 1
                total = total + count
                local key = boxData.key or boxData.name
                counts[key] = (counts[key] or 0) + count
            end
        end
    end

    if total == 0 then
        return 0, nil
    end

    return total, counts
end

-- Initialize session
function LockSmithPro.Statistics:InitSession()
    sessionStartTime = GetTime()
    sessionGold = 0
    sessionJobs = 0
    sessionBoxes = 0
end

-- Get session gold
function LockSmithPro.Statistics:GetSessionGold()
    return sessionGold
end

-- Get session jobs
function LockSmithPro.Statistics:GetSessionJobs()
    return sessionJobs
end

-- Get session boxes
function LockSmithPro.Statistics:GetSessionBoxes()
    return sessionBoxes
end

-- Get session average tip
function LockSmithPro.Statistics:GetSessionAverage()
    if sessionJobs > 0 then
        return math.floor(sessionGold / sessionJobs)
    end
    return 0
end

-- Track gold received
function LockSmithPro.Statistics:TrackGoldReceived(amount, source, boxCounts)
    local goldReceived = amount or 0
    local totalBoxes = 0

    if boxCounts then
        for _, count in pairs(boxCounts) do
            totalBoxes = totalBoxes + count
        end
    end

    if goldReceived <= 0 and totalBoxes <= 0 then
        return
    end

    if ShouldCountJob(source) then
        LockSmithProDB.stats.totalJobs = LockSmithProDB.stats.totalJobs + 1
        sessionJobs = sessionJobs + 1
        print("|cff00ff00LockSmithPro:|r Session jobs: " .. sessionJobs)
    end

    if goldReceived > 0 then
        sessionGold = sessionGold + goldReceived
        LockSmithProDB.stats.totalGold = LockSmithProDB.stats.totalGold + goldReceived
        print("|cff00ff00LockSmithPro:|r Session gold: " .. LockSmithPro.Utils:FormatGold(sessionGold))
    end

    if totalBoxes > 0 then
        sessionBoxes = sessionBoxes + totalBoxes
        EnsureBoxStats()
        LockSmithProDB.stats.totalBoxes = LockSmithProDB.stats.totalBoxes + totalBoxes
        for key, count in pairs(boxCounts) do
            LockSmithProDB.stats.boxesOpened[key] = (LockSmithProDB.stats.boxesOpened[key] or 0) + count
        end
        print("|cff00ff00LockSmithPro:|r Session boxes: " .. sessionBoxes)
    end

    if goldReceived > 0 then
        local boxNote = ""
        if totalBoxes > 0 then
            boxNote = " (" .. totalBoxes .. " box" .. (totalBoxes ~= 1 and "es" or "") .. ")"
        end
        print("|cff00ff00LockSmithPro:|r Received " .. LockSmithPro.Utils:FormatGold(goldReceived) .. " from " .. (source or "Unknown") .. boxNote)
    end
end

-- Get average tip
function LockSmithPro.Statistics:GetAverageTip()
    if LockSmithProDB.stats.totalJobs > 0 then
        return math.floor(LockSmithProDB.stats.totalGold / LockSmithProDB.stats.totalJobs)
    end
    return 0
end

-- Reset all statistics
function LockSmithPro.Statistics:ResetStats()
    LockSmithProDB.stats.totalGold = 0
    LockSmithProDB.stats.totalJobs = 0
    LockSmithProDB.stats.lastSessionGold = 0
    LockSmithProDB.stats.bestSessionGold = 0
    LockSmithProDB.stats.totalBoxes = 0
    LockSmithProDB.stats.boxesOpened = {}
    sessionGold = 0
    sessionJobs = 0
    sessionBoxes = 0
    lastJobTimeByPartner = {}
end

-- Save session stats
function LockSmithPro.Statistics:SaveSessionStats()
    LockSmithProDB.stats.lastSessionGold = sessionGold

    -- Update best session if current session is better
    if sessionGold > (LockSmithProDB.stats.bestSessionGold or 0) then
        LockSmithProDB.stats.bestSessionGold = sessionGold
    end
end

-- ================================
-- Trade Window Tracking
-- ================================

local tradeFrame = CreateFrame("Frame")
tradeFrame:RegisterEvent("TRADE_SHOW")
tradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
tradeFrame:RegisterEvent("TRADE_CLOSED")
tradeFrame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
tradeFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

tradeFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "TRADE_SHOW" then
        -- Reset trade data when trade window opens
        -- Try multiple methods to get partner name (handles no target case)
        pendingTradePartner = UnitName("NPC") or UnitName("target") or TradeFrameRecipientNameText:GetText() or "Unknown"
        pendingTradeGold = 0
        pendingTradeBoxes = 0
        pendingTradeBoxCounts = nil
        tradeCompleted = false
        pickedLocksThisTrade = 0  -- Reset lock pick counter
        print("|cff00ff00LockSmithPro:|r Trade opened with: " .. (pendingTradePartner or "Unknown"))

    elseif event == "TRADE_TARGET_ITEM_CHANGED" then
        -- Fires when customer changes items in trade window (including slot 7 "Will Not Be Traded")
        local slotIndex = ...
        if slotIndex == 7 then
            -- Customer put/removed item in "Will Not Be Traded" slot
            local itemLink = GetTradeTargetItemLink(7)
            if itemLink then
                print("|cff00ff00LockSmithPro:|r Item in 'Will Not Be Traded' slot: " .. itemLink)
            end
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Track Pick Lock spell casts during trade
        local unitTarget, castGUID, spellID = ...

        if unitTarget == "player" and IsPickLockSpell(spellID) then
            pickedLocksThisTrade = pickedLocksThisTrade + 1
            print("|cff00ff00LockSmithPro:|r Pick Lock cast #" .. pickedLocksThisTrade .. " (spell ID: " .. spellID .. ") during active trade")
        end

    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...

        -- ALWAYS capture trade data on EVERY accept update (handles all edge cases)
        -- This runs whenever ANYONE clicks accept (you or them, first time or re-accept)
        if not tradeCompleted then
            pendingTradeGold = GetTargetTradeMoney() or 0
            pendingTradeBoxes, pendingTradeBoxCounts = CountTradeBoxes()
            print("|cff00ff00LockSmithPro:|r Trade data captured - Gold: " .. pendingTradeGold .. ", Boxes: " .. (pendingTradeBoxes or 0) .. " (Player: " .. playerAccepted .. ", Target: " .. targetAccepted .. ")")
        end

        -- Process trade when both players accept
        if playerAccepted == 1 and targetAccepted == 1 and not tradeCompleted then
            tradeCompleted = true

            -- Use the data we captured
            local partner = pendingTradePartner
            local goldReceived = pendingTradeGold
            local totalBoxes = pendingTradeBoxes or 0
            local boxCounts = pendingTradeBoxCounts

            -- Add picked locks count to total (for in-window unlocking)
            if pickedLocksThisTrade > 0 then
                totalBoxes = totalBoxes + pickedLocksThisTrade
                print("|cff00ff00LockSmithPro:|r Added " .. pickedLocksThisTrade .. " in-window unlocks to box count")
            end

            print("|cff00ff00LockSmithPro:|r Processing trade - Gold: " .. goldReceived .. ", Boxes: " .. totalBoxes .. " (traded: " .. (pendingTradeBoxes or 0) .. ", picked: " .. pickedLocksThisTrade .. "), Partner: " .. (partner or "nil") .. ", Running: " .. tostring(LockSmithPro:IsRunning()))

            if LockSmithPro:IsRunning() and (goldReceived > 0 or totalBoxes > 0) then
                -- Track the stats immediately
                LockSmithPro.Statistics:TrackGoldReceived(goldReceived, partner, boxCounts)

                -- Track trade partner to prevent popup on "ty" whispers
                if LockSmithPro.ChatMonitor and LockSmithPro.ChatMonitor.TrackTradePartner and partner then
                    LockSmithPro.ChatMonitor:TrackTradePartner(partner)
                end

                -- Update dashboard stats
                if LockSmithPro.Dashboard then
                    LockSmithPro.Dashboard:UpdateJobBoardStatus()
                    -- Remove jobs from this trade partner
                    if partner then
                        LockSmithPro.Dashboard:RemoveJobsBySender(partner)
                    end
                end

                -- Send thank-you message after 2 second delay
                if goldReceived > 0 and LockSmithPro.AutoResponse and LockSmithProDB.thankYouWhisper then
                    local gold = goldReceived
                    if C_Timer and C_Timer.After then
                        C_Timer.After(2, function()
                            LockSmithPro.AutoResponse:SendThankYouWhisper(partner, gold)
                        end)
                    else
                        LockSmithPro.AutoResponse:SendThankYouWhisper(partner, gold)
                    end
                end
            else
                print("|cff00ff00LockSmithPro:|r Trade NOT tracked - IsRunning: " .. tostring(LockSmithPro:IsRunning()) .. ", Gold: " .. goldReceived .. ", Boxes: " .. totalBoxes)
            end
        end
    elseif event == "TRADE_CLOSED" then
        -- Reset all trade data
        print("|cff00ff00LockSmithPro:|r Trade window closed (Picked " .. pickedLocksThisTrade .. " locks this trade)")
        pendingTradePartner = nil
        pendingTradeGold = 0
        pendingTradeBoxes = 0
        pendingTradeBoxCounts = nil
        tradeCompleted = false
        pickedLocksThisTrade = 0
    end
end)

-- ================================
-- Mail Tracking
-- ================================

local mailFrame = CreateFrame("Frame")
mailFrame:RegisterEvent("MAIL_SHOW")
mailFrame:RegisterEvent("MAIL_INBOX_UPDATE")

local lastMailCheck = {}

mailFrame:SetScript("OnEvent", function(self, event)
    if not LockSmithPro:IsRunning() then return end

    if event == "MAIL_INBOX_UPDATE" then
        local numItems = GetInboxNumItems()

        for i = 1, numItems do
            local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead = GetInboxHeaderInfo(i)

            -- Only track new mail with gold
            if money and money > 0 and not wasRead then
                local mailKey = sender .. "_" .. i .. "_" .. money
                if not lastMailCheck[mailKey] then
                    lastMailCheck[mailKey] = true
                    -- Note: We can't automatically attribute mail gold to lockpicking
                    -- User would need to manually verify
                end
            end
        end
    end
end)
