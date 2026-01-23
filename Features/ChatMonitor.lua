-- ChatMonitor.lua
-- Chat monitoring and message parsing

LockSmith = LockSmith or {}
LockSmith.ChatMonitor = {}

-- Process lockpick request from chat
function LockSmith.ChatMonitor:ProcessLockpickRequest(message, sender, channelName, channelNumber)
    if not LockSmith:IsRunning() then return end

    -- Don't process our own messages
    local playerName = UnitName("player")
    if sender == playerName then return end

    -- Check if message has lockpicking keywords
    if not LockSmith:HasLockpickKeyword(message) then return end

    -- Try to identify the box type
    local boxData = LockSmith:IdentifyBoxType(message)

    -- Get current skill
    local currentSkill, maxSkill = LockSmith.Skills:GetLockpickingSkill()

    -- Determine if we can handle this request
    local canHandle = true
    local requiredSkill = 1

    if boxData then
        requiredSkill = boxData.skill
        canHandle = currentSkill >= requiredSkill
    end

    if canHandle then
        -- Show notification popup
        LockSmith.UI:ShowNotificationPopup(sender, boxData, channelName, requiredSkill)
    else
        -- Send low skill whisper if enabled
        LockSmith.AutoResponse:HandleInsufficientSkill(sender, boxData)
    end
end

-- Chat event handler
local function OnChatMessage(event, ...)
    if not LockSmith:IsRunning() then return end

    local message, sender, languageName, channelString, target, flags, unknown, channelNumber, channelName

    if event == "CHAT_MSG_CHANNEL" then
        message = arg1
        sender = arg2
        channelString = arg4
        channelNumber = arg8
        channelName = arg9

        -- Check if we're monitoring this channel
        if channelName then
            local lowerChannel = string.lower(channelName)
            if string.find(lowerChannel, "trade") and not LockSmithDB.monitorTrade then
                return
            end
            if string.find(lowerChannel, "general") and not LockSmithDB.monitorGeneral then
                return
            end
            if string.find(lowerChannel, "lookingforgroup") and not LockSmithDB.monitorLFG then
                return
            end
        end

        LockSmith.ChatMonitor:ProcessLockpickRequest(message, sender, channelName, channelNumber)

    elseif event == "CHAT_MSG_WHISPER" then
        if not LockSmithDB.monitorWhisper then return end

        message = arg1
        sender = arg2

        LockSmith.ChatMonitor:ProcessLockpickRequest(message, sender, "WHISPER", nil)
    end
end

-- Register chat events
function LockSmith.ChatMonitor:RegisterEvents()
    local eventFrame = CreateFrame("Frame", "LockSmithChatMonitorFrame")
    eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    eventFrame:RegisterEvent("CHAT_MSG_WHISPER")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        OnChatMessage(event, ...)
    end)
end
