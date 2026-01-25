-- ChatMonitor.lua
-- Chat monitoring and message parsing

LockSmithPro = LockSmithPro or {}
LockSmithPro.ChatMonitor = {}

local sessionIgnoreList = {}
local lastInviteTime = {}
local declinedInvites = {}  -- Track people who declined invites this session
local INVITE_THROTTLE = 30
local recentTradePartners = {}  -- Cache of last 5 people we traded with
local MAX_RECENT_TRADES = 5

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
    local normalized = NormalizeSenderName(sender)

    -- Don't re-invite if they declined this session
    if declinedInvites[normalized] then
        return false
    end

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

-- Add a player to the recent trade partners cache
local function AddToRecentTradePartners(name)
    local normalized = NormalizeSenderName(name)
    if normalized == "" then return end

    -- Remove if already exists (to move to front)
    for i = #recentTradePartners, 1, -1 do
        if recentTradePartners[i] == normalized then
            table.remove(recentTradePartners, i)
        end
    end

    -- Add to front
    table.insert(recentTradePartners, 1, normalized)

    -- Keep only last 5
    while #recentTradePartners > MAX_RECENT_TRADES do
        table.remove(recentTradePartners)
    end
end

-- Check if player was a recent trade partner
local function WasRecentTradePartner(name)
    local normalized = NormalizeSenderName(name)
    if normalized == "" then return false end

    for _, recentName in ipairs(recentTradePartners) do
        if recentName == normalized then
            return true
        end
    end
    return false
end

function LockSmithPro.ChatMonitor:IsSelfSender(sender)
    local playerName = UnitName("player")
    if not playerName then
        return false
    end

    local senderBase = NormalizeSenderName(sender)
    local playerBase = NormalizeSenderName(playerName)
    return senderBase ~= "" and senderBase == playerBase
end

-- Session ignore list management
function LockSmithPro.ChatMonitor:AddToSessionIgnore(sender)
    local normalized = NormalizeSenderName(sender)
    if normalized ~= "" then
        sessionIgnoreList[normalized] = true
        print("|cff00ff00LockSmithPro:|r Ignoring " .. sender .. " for this session")
    end
end

function LockSmithPro.ChatMonitor:ClearSessionIgnore()
    sessionIgnoreList = {}
    declinedInvites = {}
end

function LockSmithPro.ChatMonitor:IsSessionIgnored(sender)
    local normalized = NormalizeSenderName(sender)
    return sessionIgnoreList[normalized] == true
end

-- Track a completed trade partner (called from Statistics module)
function LockSmithPro.ChatMonitor:TrackTradePartner(partnerName)
    AddToRecentTradePartners(partnerName)
end

-- Process lockpick request from chat
function LockSmithPro.ChatMonitor:ProcessLockpickRequest(message, sender, channelName, channelNumber, allowNonKeyword)
    if not LockSmithPro:IsRunning() then return end

    -- Don't process our own messages
    if self:IsSelfSender(sender) then return end

    -- Don't process if sender is already in our group
    if IsGroupMember(sender) then return end

    -- Check if sender is ignored for this session
    if self:IsSessionIgnored(sender) then return end

    -- Check if sender was a recent trade partner (skip popup if they just traded with us)
    if WasRecentTradePartner(sender) then return end

    -- Apply custom include/exclude filters
    local lowerMsg = string.lower(message)

    -- Check exclude keywords first (if any exist, message must NOT contain them)
    if LockSmithProDB.excludeKeywords and LockSmithProDB.excludeKeywords ~= "" then
        local excludeList = {}
        for keyword in string.gmatch(LockSmithProDB.excludeKeywords, "[^,]+") do
            local trimmed = string.match(keyword, "^%s*(.-)%s*$") -- Trim whitespace
            if trimmed ~= "" then
                table.insert(excludeList, string.lower(trimmed))
            end
        end

        for _, excludeWord in ipairs(excludeList) do
            if string.find(lowerMsg, excludeWord, 1, true) then
                return -- Message contains excluded keyword, ignore it
            end
        end
    end

    -- Check include keywords (message must contain at least one)
    -- If includeKeywords is empty and allowNonKeyword is false, reject the message
    if LockSmithProDB.includeKeywords and LockSmithProDB.includeKeywords ~= "" then
        local includeList = {}
        for keyword in string.gmatch(LockSmithProDB.includeKeywords, "[^,]+") do
            local trimmed = string.match(keyword, "^%s*(.-)%s*$") -- Trim whitespace
            if trimmed ~= "" then
                table.insert(includeList, string.lower(trimmed))
            end
        end

        if #includeList > 0 then
            local foundInclude = false
            for _, includeWord in ipairs(includeList) do
                if string.find(lowerMsg, includeWord, 1, true) then
                    foundInclude = true
                    break
                end
            end

            if not foundInclude then
                return -- Message doesn't contain any required include keywords
            end
        end
    elseif not allowNonKeyword then
        -- No include keywords defined and not allowing non-keyword messages
        return
    end

    -- Try to identify the box type
    local boxData = LockSmithPro:IdentifyBoxType(message)

    -- Get current skill
    local currentSkill, maxSkill = LockSmithPro.Skills:GetLockpickingSkill()

    -- Determine if we can handle this request
    local canHandle = true
    local requiredSkill = 1

    if boxData then
        requiredSkill = boxData.skill
        canHandle = currentSkill >= requiredSkill
    end

    if not canHandle then
        -- Send low skill whisper if enabled
        LockSmithPro.AutoResponse:HandleInsufficientSkill(sender, boxData)
    else
        -- Add to dashboard job board
        if LockSmithPro.Dashboard then
            LockSmithPro.Dashboard:AddJob(sender, message, boxData, channelName, requiredSkill)
        else
            -- Fallback to popup if dashboard not available
            LockSmithPro.UI:ShowNotificationPopup(sender, boxData, channelName, requiredSkill, message)
        end
    end
end

-- Chat event handler
local function OnChatMessage(event, ...)
    if not LockSmithPro:IsRunning() then return end

    local message, sender, channelNumber, channelName

    if event == "CHAT_MSG_CHANNEL" then
        message, sender, _, _, _, _, _, channelNumber, channelName = ...
        if type(message) ~= "string" then return end

        -- Check if we're monitoring this channel
        if channelName then
            local lowerChannel = string.lower(channelName)
            if string.find(lowerChannel, "trade") and not LockSmithProDB.monitorTrade then
                return
            end
            if string.find(lowerChannel, "general") and not LockSmithProDB.monitorGeneral then
                return
            end
            if string.find(lowerChannel, "lookingforgroup") and not LockSmithProDB.monitorLFG then
                return
            end
        end

        LockSmithPro.ChatMonitor:ProcessLockpickRequest(message, sender, channelName, channelNumber, false)

    elseif event == "CHAT_MSG_WHISPER" then
        message, sender = ...
        if type(message) ~= "string" then return end
        if LockSmithPro.ChatMonitor:IsSelfSender(sender) then return end

        -- Skip if they were a recent trade partner (they're just saying "ty")
        if WasRecentTradePartner(sender) then return end

        -- Auto-invite if enabled (and skip popup since we're auto-inviting)
        if LockSmithProDB.autoInviteWhisper and CanInvite(sender) and not IsGroupMember(sender) then
            if LockSmithPro.Utils and LockSmithPro.Utils.InvitePlayer then
                LockSmithPro.Utils:InvitePlayer(sender)
            end
            return  -- Skip popup when auto-inviting
        end

        local allowNonKeyword = LockSmithProDB.popupOnAnyWhisper
        if not LockSmithProDB.monitorWhisper and not allowNonKeyword then return end

        LockSmithPro.ChatMonitor:ProcessLockpickRequest(message, sender, "WHISPER", nil, allowNonKeyword)

    elseif event == "CHAT_MSG_SAY" then
        message, sender = ...
        if type(message) ~= "string" then return end
        if LockSmithPro.ChatMonitor:IsSelfSender(sender) then return end
        if not LockSmithProDB.monitorSay then return end

        -- Skip if they were a recent trade partner
        if WasRecentTradePartner(sender) then return end

        LockSmithPro.ChatMonitor:ProcessLockpickRequest(message, sender, "SAY", nil, false)
    end
end

-- Track when we send an invite
local pendingInvites = {}  -- Map of normalized names to timestamp when we invited them

function LockSmithPro.ChatMonitor:OnInviteSent(playerName)
    local normalized = NormalizeSenderName(playerName)
    if normalized ~= "" then
        pendingInvites[normalized] = GetTime()
    end
end

-- Register chat events
function LockSmithPro.ChatMonitor:RegisterEvents()
    local eventFrame = CreateFrame("Frame", "LockSmithProChatMonitorFrame")
    eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    eventFrame:RegisterEvent("CHAT_MSG_SAY")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_SAY" then
            OnChatMessage(event, ...)
        elseif event == "GROUP_ROSTER_UPDATE" then
            -- Check all pending invites to see if they joined or declined
            for normalized, inviteTime in pairs(pendingInvites) do
                local isInGroup = IsGroupMember(normalized)
                if isInGroup then
                    -- They joined! Remove them from pending
                    pendingInvites[normalized] = nil

                    -- Remove their jobs from the dashboard
                    if LockSmithPro.Dashboard then
                        LockSmithPro.Dashboard:RemoveJobsBySender(normalized)
                    end
                elseif GetTime() - inviteTime > 60 then
                    -- After 60 seconds, assume they declined or ignored it
                    declinedInvites[normalized] = true
                    pendingInvites[normalized] = nil
                end
            end
        end
    end)
end
