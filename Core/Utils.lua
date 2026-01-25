-- Utils.lua
-- Utility functions for LockSmithPro

LockSmithPro = LockSmithPro or {}
LockSmithPro.Utils = {}

-- ================================
-- Timer System
-- ================================

local activeTimers = {}
local nextTimerID = 1

function LockSmithPro.Utils:ScheduleRepeatingTimer(callback, interval)
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

function LockSmithPro.Utils:CancelTimer(timerID)
    if activeTimers[timerID] then
        activeTimers[timerID]:SetScript("OnUpdate", nil)
        activeTimers[timerID] = nil
    end
end

-- ================================
-- Gold Formatting
-- ================================

function LockSmithPro.Utils:FormatGold(copper)
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

function LockSmithPro.Utils:CanSendMessage(target)
    local now = GetTime()
    if not lastMessageTime[target] or (now - lastMessageTime[target]) > MESSAGE_THROTTLE then
        lastMessageTime[target] = now
        return true
    end
    return false
end

function LockSmithPro.Utils:SendThrottledWhisper(target, message)
    if self:CanSendMessage(target) then
        SendChatMessage(message, "WHISPER", nil, target)
        return true
    end
    return false
end

-- ================================
-- Channel Helpers
-- ================================

function LockSmithPro.Utils:GetChannelID(channelName)
    local id = GetChannelName(channelName)
    if id and id > 0 then
        return id
    end
    return nil
end

function LockSmithPro.Utils:SendToChannel(message, channelName)
    local channelID = self:GetChannelID(channelName)
    if channelID then
        SendChatMessage(message, "CHANNEL", nil, channelID)
        return true
    end
    return false
end

-- Invite helper with API fallbacks
function LockSmithPro.Utils:InvitePlayer(target)
    if not target or target == "" then
        return false
    end

    -- Notify ChatMonitor that we're sending an invite
    if LockSmithPro.ChatMonitor and LockSmithPro.ChatMonitor.OnInviteSent then
        LockSmithPro.ChatMonitor:OnInviteSent(target)
    end

    if C_PartyInfo and C_PartyInfo.InviteUnit then
        C_PartyInfo.InviteUnit(target)
        return true
    end

    if InviteUnit then
        InviteUnit(target)
        return true
    end

    if InviteByName then
        InviteByName(target)
        return true
    end

    return false
end

-- ================================
-- Auto Raid Marker
-- ================================

local hasSetMarker = false
local markedPlayers = {}  -- Track which players have been marked
local customerMarkerIcons = {3, 7, 4, 5, 6, 2, 8}  -- Diamond, Cross, Triangle, Moon, Square, Circle, Skull
local nextCustomerIconIndex = 1

local markerFrame = CreateFrame("Frame")

-- Set raid marker on player
local function SetPlayerRaidMarker()
    -- SetRaidTarget: 1=Star, 2=Circle, 3=Diamond, 4=Triangle, 5=Moon, 6=Square, 7=Cross, 8=Skull
    if SetRaidTarget and LockSmithProDB and LockSmithProDB.autoMarkSelf then
        SetRaidTarget("player", 1)  -- 1 = Star
    end
end

-- Get normalized player name
local function NormalizePlayerName(name)
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

-- Set raid marker on a customer
local function SetCustomerRaidMarker(unitID, playerName)
    if not SetRaidTarget then return end
    if not LockSmithProDB or not LockSmithProDB.autoMarkCustomers then return end

    local normalized = NormalizePlayerName(playerName)
    if normalized == "" then return end

    -- Don't mark if already marked
    if markedPlayers[normalized] then return end

    -- Get the next available icon
    local iconIndex = customerMarkerIcons[nextCustomerIconIndex]
    if not iconIndex then return end  -- All icons used

    -- Set the marker
    SetRaidTarget(unitID, iconIndex)
    markedPlayers[normalized] = iconIndex

    -- Move to next icon for next customer
    nextCustomerIconIndex = nextCustomerIconIndex + 1
end

-- Mark all current party/raid members
local function MarkAllCustomers()
    if not LockSmithProDB or not LockSmithProDB.autoMarkCustomers then return end

    local playerName = UnitName("player")
    local playerNormalized = NormalizePlayerName(playerName)

    -- Check if in raid
    local inRaid = UnitInRaid("player")
    if inRaid then
        local count = GetNumGroupMembers and GetNumGroupMembers() or (GetNumRaidMembers and GetNumRaidMembers() or 0)
        for i = 1, count do
            local member = UnitName("raid" .. i)
            if member then
                local normalized = NormalizePlayerName(member)
                if normalized ~= playerNormalized and normalized ~= "" then
                    SetCustomerRaidMarker("raid" .. i, member)
                end
            end
        end
    else
        local count = GetNumSubgroupMembers and GetNumSubgroupMembers() or (GetNumPartyMembers and GetNumPartyMembers() or 0)
        for i = 1, count do
            local member = UnitName("party" .. i)
            if member then
                local normalized = NormalizePlayerName(member)
                if normalized ~= playerNormalized and normalized ~= "" then
                    SetCustomerRaidMarker("party" .. i, member)
                end
            end
        end
    end
end

-- Check if we should set the marker
local function CheckAndSetMarker()
    -- Only set marker once per group
    if hasSetMarker then
        -- Check for new customers to mark
        MarkAllCustomers()
        return
    end

    -- Check if we're in a party and are the leader
    local isLeader = UnitIsGroupLeader and UnitIsGroupLeader("player")
    if not isLeader then
        -- For Classic/TBC compatibility
        isLeader = (GetNumGroupMembers and GetNumGroupMembers() > 0) or (GetNumPartyMembers and GetNumPartyMembers() > 0)
    end

    if isLeader then
        -- Small delay to ensure group is formed
        local delayFrame = CreateFrame("Frame")
        local elapsed = 0
        delayFrame:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            if elapsed >= 0.5 then
                SetPlayerRaidMarker()
                MarkAllCustomers()
                hasSetMarker = true
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- Reset marker flag when leaving group
markerFrame:RegisterEvent("GROUP_LEFT")
markerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

markerFrame:SetScript("OnEvent", function(self, event)
    if event == "GROUP_LEFT" then
        hasSetMarker = false
        markedPlayers = {}
        nextCustomerIconIndex = 1
    elseif event == "GROUP_ROSTER_UPDATE" then
        if LockSmithPro:IsRunning() then
            CheckAndSetMarker()
        end
    end
end)
