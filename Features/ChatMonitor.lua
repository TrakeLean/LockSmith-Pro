-- ChatMonitor.lua
-- Chat monitoring and message parsing

LockSmith = LockSmith or {}
LockSmith.ChatMonitor = {}

local sessionIgnoreList = {}
local lastInviteTime = {}
local INVITE_THROTTLE = 30

local function NormalizeSenderName(name)
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

local function CanInvite(sender)
    local now = GetTime()
    local last = lastInviteTime[sender]
    if not last or (now - last) > INVITE_THROTTLE then
        lastInviteTime[sender] = now
        return true
    end
    return false
end

local function IsGroupMember(name)
    local target = NormalizeSenderName(name)
    if target == "" then
        return false
    end

    -- Check if player is in a raid
    local inRaid = UnitInRaid("player")
    if inRaid then
        -- Use GetNumGroupMembers for newer clients, GetNumRaidMembers for classic
        local count = GetNumGroupMembers and GetNumGroupMembers() or (GetNumRaidMembers and GetNumRaidMembers() or 0)
        for i = 1, count do
            local member = UnitName("raid" .. i)
            if member and NormalizeSenderName(member) == target then
                return true
            end
        end
    else
        -- Use GetNumSubgroupMembers for newer clients, GetNumPartyMembers for classic
        local count = GetNumSubgroupMembers and GetNumSubgroupMembers() or (GetNumPartyMembers and GetNumPartyMembers() or 0)
        for i = 1, count do
            local member = UnitName("party" .. i)
            if member and NormalizeSenderName(member) == target then
                return true
            end
        end
    end

    return false
end

function LockSmith.ChatMonitor:IsSelfSender(sender)
    local playerName = UnitName("player")
    if not playerName then
        return false
    end

    local senderBase = NormalizeSenderName(sender)
    local playerBase = NormalizeSenderName(playerName)
    return senderBase ~= "" and senderBase == playerBase
end

-- Session ignore list management
function LockSmith.ChatMonitor:AddToSessionIgnore(sender)
    local normalized = NormalizeSenderName(sender)
    if normalized ~= "" then
        sessionIgnoreList[normalized] = true
        print("|cff00ff00LockSmith:|r Ignoring " .. sender .. " for this session")
    end
end

function LockSmith.ChatMonitor:ClearSessionIgnore()
    sessionIgnoreList = {}
end

function LockSmith.ChatMonitor:IsSessionIgnored(sender)
    local normalized = NormalizeSenderName(sender)
    return sessionIgnoreList[normalized] == true
end

-- Process lockpick request from chat
function LockSmith.ChatMonitor:ProcessLockpickRequest(message, sender, channelName, channelNumber, allowNonKeyword)
    if not LockSmith:IsRunning() then return end

    -- Don't process our own messages
    if self:IsSelfSender(sender) then return end

    -- Check if sender is ignored for this session
    if self:IsSessionIgnored(sender) then return end

    -- Check if message has lockpicking keywords
    local hasKeyword = LockSmith:HasLockpickKeyword(message)
    if not hasKeyword and not allowNonKeyword then return end

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

    if hasKeyword and not canHandle then
        -- Send low skill whisper if enabled
        LockSmith.AutoResponse:HandleInsufficientSkill(sender, boxData)
    else
        -- Show notification popup
        LockSmith.UI:ShowNotificationPopup(sender, boxData, channelName, requiredSkill, message)
    end
end

-- Chat event handler
local function OnChatMessage(event, ...)
    if not LockSmith:IsRunning() then return end

    local message, sender, channelNumber, channelName

    if event == "CHAT_MSG_CHANNEL" then
        message, sender, _, _, _, _, _, channelNumber, channelName = ...
        if type(message) ~= "string" then return end

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

        LockSmith.ChatMonitor:ProcessLockpickRequest(message, sender, channelName, channelNumber, false)

    elseif event == "CHAT_MSG_WHISPER" then
        message, sender = ...
        if type(message) ~= "string" then return end
        if LockSmith.ChatMonitor:IsSelfSender(sender) then return end

        -- Auto-invite if enabled (and skip popup since we're auto-inviting)
        if LockSmithDB.autoInviteWhisper and CanInvite(sender) and not IsGroupMember(sender) then
            if LockSmith.Utils and LockSmith.Utils.InvitePlayer then
                LockSmith.Utils:InvitePlayer(sender)
            end
            return  -- Skip popup when auto-inviting
        end

        local allowNonKeyword = LockSmithDB.popupOnAnyWhisper
        if not LockSmithDB.monitorWhisper and not allowNonKeyword then return end

        LockSmith.ChatMonitor:ProcessLockpickRequest(message, sender, "WHISPER", nil, allowNonKeyword)
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
