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
local tradeWindowOpen = false  -- Track if trade window is currently open
local lastJobTimeByPartner = {}
local JOB_WINDOW_SECONDS = 600
local pickedLocksThisTrade = 0  -- Track Pick Lock casts during current trade
local pickedLockBoxCountsThisTrade = {}  -- Per-box counts for slot 7 Pick Lock casts
local pickedLocksUnattributedThisTrade = 0  -- Pick locks we couldn't map to a known box key
local currentSlot7BoxKey = nil
local tradeStateToken = 0
local ERR_TRADE_COMPLETE = _G.ERR_TRADE_COMPLETE

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

local function AddBoxCount(counts, key, amount)
    if type(counts) ~= "table" or type(key) ~= "string" or key == "" then
        return
    end

    local num = tonumber(amount) or 0
    if num <= 0 then
        return
    end

    counts[key] = (counts[key] or 0) + num
end

local function SumBoxCounts(counts)
    local total = 0
    if type(counts) ~= "table" then
        return 0
    end

    for _, count in pairs(counts) do
        total = total + (tonumber(count) or 0)
    end

    return total
end

local function ResetTradeTrackingState()
    pendingTradePartner = nil
    pendingTradeGold = 0
    pendingTradeBoxes = 0
    pendingTradeBoxCounts = nil
    tradeCompleted = false
    tradeWindowOpen = false
    pickedLocksThisTrade = 0
    pickedLockBoxCountsThisTrade = {}
    pickedLocksUnattributedThisTrade = 0
    currentSlot7BoxKey = nil
end

local function GetTradeTargetBoxData(slot)
    local itemLink = GetTradeTargetItemLink(slot)
    if not itemLink then
        return nil, nil
    end

    local itemName = GetTradeTargetItemInfo(slot)
    local boxData = LockSmithPro.GetBoxDataFromItemLink and LockSmithPro:GetBoxDataFromItemLink(itemLink, itemName)
    return boxData, itemLink
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
function LockSmithPro.Statistics:TrackGoldReceived(amount, source, boxCounts, extraBoxes)
    local goldReceived = amount or 0
    local totalBoxes = 0
    extraBoxes = tonumber(extraBoxes) or 0

    totalBoxes = totalBoxes + extraBoxes

    if type(boxCounts) == "table" then
        totalBoxes = totalBoxes + SumBoxCounts(boxCounts)
    else
        boxCounts = nil
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
        if boxCounts then
            for key, count in pairs(boxCounts) do
                LockSmithProDB.stats.boxesOpened[key] = (LockSmithProDB.stats.boxesOpened[key] or 0) + count
            end
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
-- Key insight from Gargul addon: Use UI_INFO_MESSAGE with ERR_TRADE_COMPLETE
-- instead of TRADE_ACCEPT_UPDATE for final trade processing.
-- This fires AFTER all spell casts and trade actions have completed on the server.

local tradeFrame = CreateFrame("Frame")
tradeFrame:RegisterEvent("TRADE_SHOW")
tradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
tradeFrame:RegisterEvent("TRADE_CLOSED")
tradeFrame:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
tradeFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
tradeFrame:RegisterEvent("UI_INFO_MESSAGE")  -- Used to detect successful trade completion

tradeFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "TRADE_SHOW" then
        -- Reset trade data when trade window opens
        -- Try multiple methods to get partner name (handles no target case)
        tradeStateToken = tradeStateToken + 1

        local partnerFromFrame = TradeFrameRecipientNameText and TradeFrameRecipientNameText:GetText() or nil
        pendingTradePartner = UnitName("NPC") or UnitName("target") or partnerFromFrame or "Unknown"
        pendingTradeGold = 0
        pendingTradeBoxes = 0
        pendingTradeBoxCounts = nil
        tradeCompleted = false
        tradeWindowOpen = true
        pickedLocksThisTrade = 0  -- Reset lock pick counter
        pickedLockBoxCountsThisTrade = {}
        pickedLocksUnattributedThisTrade = 0
        currentSlot7BoxKey = nil
        print("|cff00ff00LockSmithPro:|r Trade opened with: " .. (pendingTradePartner or "Unknown"))

    elseif event == "TRADE_TARGET_ITEM_CHANGED" then
        -- Fires when customer changes items in trade window (including slot 7 "Will Not Be Traded")
        local slotIndex = ...
        if slotIndex == 7 then
            -- Customer put/removed item in "Will Not Be Traded" slot
            local boxData, itemLink = GetTradeTargetBoxData(7)
            currentSlot7BoxKey = boxData and boxData.key or nil

            if itemLink then
                print("|cff00ff00LockSmithPro:|r Item in 'Will Not Be Traded' slot: " .. itemLink)
            end
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Track Pick Lock spell casts during trade (only while trade window is open)
        if not tradeWindowOpen then return end

        local unitTarget, castGUID, spellID = ...

        if unitTarget == "player" and IsPickLockSpell(spellID) then
            local boxKey = currentSlot7BoxKey
            if not boxKey then
                local slot7BoxData, slot7ItemLink = GetTradeTargetBoxData(7)
                if not slot7ItemLink then
                    return
                end

                boxKey = slot7BoxData and slot7BoxData.key or nil
                currentSlot7BoxKey = boxKey
            end

            pickedLocksThisTrade = pickedLocksThisTrade + 1

            if boxKey then
                AddBoxCount(pickedLockBoxCountsThisTrade, boxKey, 1)
            else
                pickedLocksUnattributedThisTrade = pickedLocksUnattributedThisTrade + 1
            end

            print("|cff00ff00LockSmithPro:|r Pick Lock cast #" .. pickedLocksThisTrade .. " (spell ID: " .. spellID .. ")")
        end

    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...

        -- Capture trade data on every accept update (handles tip changes, re-accepts, etc.)
        -- We DON'T process the trade here - we wait for UI_INFO_MESSAGE with ERR_TRADE_COMPLETE
        if not tradeCompleted then
            pendingTradeGold = GetTargetTradeMoney() or 0
            pendingTradeBoxes, pendingTradeBoxCounts = CountTradeBoxes()
            print("|cff00ff00LockSmithPro:|r Trade data captured - Gold: " .. pendingTradeGold .. ", Boxes: " .. (pendingTradeBoxes or 0) .. " (Player: " .. playerAccepted .. ", Target: " .. targetAccepted .. ")")
        end

    elseif event == "UI_INFO_MESSAGE" then
        -- This is the authoritative "trade completed" event
        -- ERR_TRADE_COMPLETE fires AFTER all spell casts and trade actions are done on the server
        local _, message = ...

        if message == ERR_TRADE_COMPLETE and not tradeCompleted then
            tradeCompleted = true

            -- Use the data we captured during TRADE_ACCEPT_UPDATE
            local partner = pendingTradePartner
            if not partner or partner == "" or partner == "Unknown" then
                local partnerFromFrame = TradeFrameRecipientNameText and TradeFrameRecipientNameText:GetText() or nil
                partner = UnitName("target") or partnerFromFrame or partner
            end
            local goldReceived = pendingTradeGold
            local tradedBoxes = pendingTradeBoxes or 0
            local boxCounts = {}
            local unattributedPickedLocks = pickedLocksUnattributedThisTrade or 0

            if type(pendingTradeBoxCounts) == "table" then
                for key, count in pairs(pendingTradeBoxCounts) do
                    AddBoxCount(boxCounts, key, count)
                end
            end

            -- Add picked locks count to total (for in-window unlocking in slot 7)
            if type(pickedLockBoxCountsThisTrade) == "table" then
                for key, count in pairs(pickedLockBoxCountsThisTrade) do
                    AddBoxCount(boxCounts, key, count)
                end
            end

            local totalBoxes = SumBoxCounts(boxCounts) + unattributedPickedLocks

            if pickedLocksThisTrade > 0 then
                print("|cff00ff00LockSmithPro:|r Added " .. pickedLocksThisTrade .. " in-window unlocks to box count")
            end

            print("|cff00ff00LockSmithPro:|r Trade completed - Gold: " .. goldReceived .. ", Boxes: " .. totalBoxes .. " (traded: " .. tradedBoxes .. ", picked: " .. pickedLocksThisTrade .. "), Partner: " .. (partner or "nil") .. ", Running: " .. tostring(LockSmithPro:IsRunning()))

            if LockSmithPro:IsRunning() and (goldReceived > 0 or totalBoxes > 0) then
                -- Track the stats
                LockSmithPro.Statistics:TrackGoldReceived(goldReceived, partner, boxCounts, unattributedPickedLocks)

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
        -- Trade window closed - DON'T reset state here if trade completed successfully
        -- The UI_INFO_MESSAGE event may fire AFTER TRADE_CLOSED
        -- Only reset if trade was cancelled (not completed)
        local closedToken = tradeStateToken
        tradeWindowOpen = false

        if not tradeCompleted then
            print("|cff00ff00LockSmithPro:|r Trade cancelled (Picked " .. pickedLocksThisTrade .. " locks)")
        end

        -- Reset state after a short delay to allow UI_INFO_MESSAGE to process
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, function()
                if tradeStateToken ~= closedToken then
                    return
                end

                ResetTradeTrackingState()
            end)
        else
            ResetTradeTrackingState()
        end
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
