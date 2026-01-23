-- Statistics.lua
-- Gold tracking and statistics management

LockSmith = LockSmith or {}
LockSmith.Statistics = {}

local sessionStartTime = 0
local sessionGold = 0
local pendingTradePartner = nil
local tradeCompleted = false
local lastJobTimeByPartner = {}
local JOB_WINDOW_SECONDS = 600

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
    if not LockSmithDB or not LockSmithDB.stats then return end

    if type(LockSmithDB.stats.boxesOpened) ~= "table" then
        LockSmithDB.stats.boxesOpened = {}
    end
    if type(LockSmithDB.stats.totalBoxes) ~= "number" then
        LockSmithDB.stats.totalBoxes = 0
    end
end

local function CountTradeBoxes()
    local counts = {}
    local total = 0

    for slot = 1, 6 do
        local itemLink = GetTradePlayerItemLink(slot)
        if itemLink then
            local itemName, _, itemCount = GetTradePlayerItemInfo(slot)
            local boxData = LockSmith.GetBoxDataFromItemLink and LockSmith:GetBoxDataFromItemLink(itemLink, itemName)
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
function LockSmith.Statistics:InitSession()
    sessionStartTime = GetTime()
    sessionGold = 0
end

-- Get session gold
function LockSmith.Statistics:GetSessionGold()
    return sessionGold
end

-- Track gold received
function LockSmith.Statistics:TrackGoldReceived(amount, source, boxCounts)
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
        LockSmithDB.stats.totalJobs = LockSmithDB.stats.totalJobs + 1
    end

    if goldReceived > 0 then
        sessionGold = sessionGold + goldReceived
        LockSmithDB.stats.totalGold = LockSmithDB.stats.totalGold + goldReceived
    end

    if totalBoxes > 0 then
        EnsureBoxStats()
        LockSmithDB.stats.totalBoxes = LockSmithDB.stats.totalBoxes + totalBoxes
        for key, count in pairs(boxCounts) do
            LockSmithDB.stats.boxesOpened[key] = (LockSmithDB.stats.boxesOpened[key] or 0) + count
        end
    end

    if goldReceived > 0 then
        local boxNote = ""
        if totalBoxes > 0 then
            boxNote = " (" .. totalBoxes .. " box" .. (totalBoxes ~= 1 and "es" or "") .. ")"
        end
        print("|cff00ff00LockSmith:|r Received " .. LockSmith.Utils:FormatGold(goldReceived) .. " from " .. (source or "Unknown") .. boxNote)
    end
end

-- Get average tip
function LockSmith.Statistics:GetAverageTip()
    if LockSmithDB.stats.totalJobs > 0 then
        return math.floor(LockSmithDB.stats.totalGold / LockSmithDB.stats.totalJobs)
    end
    return 0
end

-- Reset all statistics
function LockSmith.Statistics:ResetStats()
    LockSmithDB.stats.totalGold = 0
    LockSmithDB.stats.totalJobs = 0
    LockSmithDB.stats.lastSessionGold = 0
    LockSmithDB.stats.totalBoxes = 0
    LockSmithDB.stats.boxesOpened = {}
    sessionGold = 0
    lastJobTimeByPartner = {}
end

-- Save session stats
function LockSmith.Statistics:SaveSessionStats()
    LockSmithDB.stats.lastSessionGold = sessionGold
end

-- ================================
-- Trade Window Tracking
-- ================================

local tradeFrame = CreateFrame("Frame")
tradeFrame:RegisterEvent("TRADE_SHOW")
tradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
tradeFrame:RegisterEvent("TRADE_CLOSED")

tradeFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "TRADE_SHOW" then
        pendingTradePartner = UnitName("NPC") or UnitName("target")
        tradeCompleted = false

    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...

        if playerAccepted == 1 and targetAccepted == 1 and not tradeCompleted then
            -- Both accepted - trade will complete
            local goldReceived = GetTargetTradeMoney() or 0
            local totalBoxes, boxCounts = CountTradeBoxes()

            if LockSmith:IsRunning() and (goldReceived > 0 or totalBoxes > 0) then
                LockSmith.Statistics:TrackGoldReceived(goldReceived, pendingTradePartner, boxCounts)
                if goldReceived > 0 and LockSmith.AutoResponse then
                    LockSmith.AutoResponse:SendThankYouWhisper(pendingTradePartner, goldReceived)
                end
            end
            tradeCompleted = true
        end
    elseif event == "TRADE_CLOSED" then
        pendingTradePartner = nil
        tradeCompleted = false
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
    if not LockSmith:IsRunning() then return end

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
