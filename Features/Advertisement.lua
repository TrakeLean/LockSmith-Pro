-- Advertisement.lua
-- Advertisement system with timer

LockSmith = LockSmith or {}
LockSmith.Advertisement = {}

local adTimer = nil

-- Send advertisement to configured channels
function LockSmith.Advertisement:SendAdvertisement()
    local message = LockSmithDB.adMessage
    local sentCount = 0

    -- Send to Trade
    if LockSmithDB.adChannels.trade then
        local tradeID = GetChannelName("Trade - City")
        if not tradeID or tradeID == 0 then
            tradeID = GetChannelName("Trade")
        end
        if tradeID and tradeID > 0 then
            SendChatMessage(message, "CHANNEL", nil, tradeID)
            sentCount = sentCount + 1
        end
    end

    -- Send to General
    if LockSmithDB.adChannels.general then
        local generalID = GetChannelName("General")
        if generalID and generalID > 0 then
            SendChatMessage(message, "CHANNEL", nil, generalID)
            sentCount = sentCount + 1
        end
    end

    -- Send to LFG
    if LockSmithDB.adChannels.lfg then
        local lfgID = GetChannelName("LookingForGroup")
        if lfgID and lfgID > 0 then
            SendChatMessage(message, "CHANNEL", nil, lfgID)
            sentCount = sentCount + 1
        end
    end

    if sentCount > 0 then
        print("|cff00ff00LockSmith:|r Advertisement sent to " .. sentCount .. " channel(s)")
    else
        print("|cffff0000LockSmith:|r No channels available for advertisement")
    end
end

-- Start advertisement timer
function LockSmith.Advertisement:StartAdTimer()
    self:StopAdTimer() -- Clear any existing timer

    if not LockSmithDB.adTimerEnabled then return end

    local interval = LockSmithDB.adTimerInterval or 60

    -- Create repeating timer
    adTimer = LockSmith.Utils:ScheduleRepeatingTimer(function()
        if LockSmith:IsRunning() and LockSmithDB.adTimerEnabled then
            LockSmith.Advertisement:SendAdvertisement()
        end
    end, interval)

    print("|cff00ff00LockSmith:|r Ad timer started (every " .. interval .. " seconds)")
end

-- Stop advertisement timer
function LockSmith.Advertisement:StopAdTimer()
    if adTimer then
        LockSmith.Utils:CancelTimer(adTimer)
        adTimer = nil
    end
end

-- Restart timer with new interval
function LockSmith.Advertisement:RestartTimer()
    if LockSmithDB.adTimerEnabled and LockSmith:IsRunning() then
        self:StartAdTimer()
    end
end
