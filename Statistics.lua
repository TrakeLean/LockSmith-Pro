-- Statistics.lua
-- Gold tracking and statistics management

LockSmith = LockSmith or {}
LockSmith.Statistics = {}

local sessionStartTime = 0
local sessionGold = 0
local pendingTradePartner = nil

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
function LockSmith.Statistics:TrackGoldReceived(amount, source)
    sessionGold = sessionGold + amount
    LockSmithDB.stats.totalGold = LockSmithDB.stats.totalGold + amount
    LockSmithDB.stats.totalJobs = LockSmithDB.stats.totalJobs + 1

    print("|cff00ff00LockSmith:|r Received " .. LockSmith.Utils:FormatGold(amount) .. " from " .. (source or "Unknown"))
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
    sessionGold = 0
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

tradeFrame:SetScript("OnEvent", function(self, event)
    if event == "TRADE_SHOW" then
        pendingTradePartner = UnitName("NPC")

    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted = arg1
        local targetAccepted = arg2

        if playerAccepted == 1 and targetAccepted == 1 then
            -- Both accepted - trade will complete
            local goldReceived = GetTargetTradeMoney()
            if goldReceived > 0 and LockSmith:IsRunning() then
                LockSmith.Statistics:TrackGoldReceived(goldReceived, pendingTradePartner)
            end
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
