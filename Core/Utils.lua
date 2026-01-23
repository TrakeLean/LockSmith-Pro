-- Utils.lua
-- Utility functions for LockSmith

LockSmith = LockSmith or {}
LockSmith.Utils = {}

-- ================================
-- Timer System
-- ================================

local activeTimers = {}
local nextTimerID = 1

function LockSmith.Utils:ScheduleRepeatingTimer(callback, interval)
    local timerID = nextTimerID
    nextTimerID = nextTimerID + 1

    local frame = CreateFrame("Frame")
    local elapsed = 0

    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= interval then
            elapsed = 0
            callback()
        end
    end)

    activeTimers[timerID] = frame
    return timerID
end

function LockSmith.Utils:CancelTimer(timerID)
    if activeTimers[timerID] then
        activeTimers[timerID]:SetScript("OnUpdate", nil)
        activeTimers[timerID] = nil
    end
end

-- ================================
-- Gold Formatting
-- ================================

function LockSmith.Utils:FormatGold(copper)
    if copper == 0 then return "0c" end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperRemainder = copper % 100

    local result = ""
    if gold > 0 then
        result = gold .. "g"
    end
    if silver > 0 then
        if result ~= "" then result = result .. " " end
        result = result .. silver .. "s"
    end
    if copperRemainder > 0 or result == "" then
        if result ~= "" then result = result .. " " end
        result = result .. copperRemainder .. "c"
    end

    return result
end

-- ================================
-- Message Throttling
-- ================================

local lastMessageTime = {}
local MESSAGE_THROTTLE = 10 -- seconds between messages to same target

function LockSmith.Utils:CanSendMessage(target)
    local now = GetTime()
    if not lastMessageTime[target] or (now - lastMessageTime[target]) > MESSAGE_THROTTLE then
        lastMessageTime[target] = now
        return true
    end
    return false
end

function LockSmith.Utils:SendThrottledWhisper(target, message)
    if self:CanSendMessage(target) then
        SendChatMessage(message, "WHISPER", nil, target)
        return true
    end
    return false
end

-- ================================
-- Channel Helpers
-- ================================

function LockSmith.Utils:GetChannelID(channelName)
    local id = GetChannelName(channelName)
    if id and id > 0 then
        return id
    end
    return nil
end

function LockSmith.Utils:SendToChannel(message, channelName)
    local channelID = self:GetChannelID(channelName)
    if channelID then
        SendChatMessage(message, "CHANNEL", nil, channelID)
        return true
    end
    return false
end
