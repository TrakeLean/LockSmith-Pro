-- Utils.lua
-- Utility functions for LockSmithPro

LockSmithPro = LockSmithPro or {}
LockSmithPro.Utils = {}

-- ================================
-- Chat Logging
-- ================================

function LockSmithPro:IsDebugChatEnabled()
    return LockSmithProDB and LockSmithProDB.debugChat == true
end

function LockSmithPro:DebugPrint(message)
    if not self:IsDebugChatEnabled() then
        return
    end

    if message == nil then
        return
    end

    print("|cff66ccffLockSmithPro Debug:|r " .. tostring(message))
end

-- ================================
-- Timer System
-- ================================

function LockSmithPro.Utils:ScheduleRepeatingTimer(callback, interval)
    return C_Timer.NewTicker(math.max(1, tonumber(interval) or 60), callback)
end

function LockSmithPro.Utils:CancelTimer(timer)
    if timer then timer:Cancel() end
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

local lastWhisperTime = -math.huge
function LockSmithPro.Utils:CanSendMessage(target)
    return LockSmithPro.Compat:Remember(lastMessageTime, LockSmithPro.Compat:NameKey(target), MESSAGE_THROTTLE)
end

function LockSmithPro.Utils:SendThrottledWhisper(target, message)
    if not LockSmithPro.Compat:CanAutomate() then return false end
    if not LockSmithPro.Compat:IsString(message) or message == "" or #message > 255 then return false end
    if GetTime() - lastWhisperTime < 2 then return false end
    if self:CanSendMessage(target) then
        lastWhisperTime = GetTime()
        return LockSmithPro.Compat:SendChat(message, "WHISPER", target)
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
        return LockSmithPro.Compat:SendChat(message, "CHANNEL", channelID)
    end
    return false
end

-- All invite entry points share cooldowns and group checks.
local inviteTimes = {}
local lastInviteTime = -math.huge
function LockSmithPro.Utils:InvitePlayer(target, automatic)
    local compat = LockSmithPro.Compat
    local key = compat:NameKey(target)
    if not key or (InCombatLockdown and InCombatLockdown()) then return false end
    if automatic and not compat:CanAutomate() then return false end
    if compat:IsGroupMember(target) then return false end
    if C_PartyInfo and C_PartyInfo.CanInvite and not C_PartyInfo.CanInvite() then return false end
    if IsInGroup and IsInGroup() then
        if not (UnitIsGroupLeader("player") or (UnitIsGroupAssistant and UnitIsGroupAssistant("player"))) then return false end
        local capacity = IsInRaid and IsInRaid() and 40 or 5
        if GetNumGroupMembers() >= capacity then return false end
    end
    if GetTime() - lastInviteTime < 2 then return false end
    if not compat:Remember(inviteTimes, key, 30) then return false end
    local invite = C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit or InviteByName
    if not invite then return false end
    lastInviteTime = GetTime()
    local ok = pcall(invite, target)
    if ok and LockSmithPro.ChatMonitor then LockSmithPro.ChatMonitor:OnInviteSent(target) end
    return ok
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
        pcall(SetRaidTarget, "player", 1)  -- 1 = Star
    end
end

-- Get normalized player name
local function NormalizePlayerName(name)
    return LockSmithPro.Compat:NameKey(name) or ""
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
    if not pcall(SetRaidTarget, unitID, iconIndex) then return end
    markedPlayers[normalized] = iconIndex

    -- Move to next icon for next customer
    nextCustomerIconIndex = nextCustomerIconIndex + 1
end

-- Mark all current party/raid members
local function MarkAllCustomers()
    if not LockSmithProDB or not LockSmithProDB.autoMarkCustomers then return end

    local playerName = LockSmithPro.Compat:UnitAddress("player")
    local playerNormalized = NormalizePlayerName(playerName)

    -- Check if in raid
    local inRaid = UnitInRaid("player")
    if inRaid then
        local count = GetNumGroupMembers and GetNumGroupMembers() or (GetNumRaidMembers and GetNumRaidMembers() or 0)
        for i = 1, count do
            local member = LockSmithPro.Compat:UnitAddress("raid" .. i)
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
            local member = LockSmithPro.Compat:UnitAddress("party" .. i)
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
    if not LockSmithPro.Compat:CanAutomate() or (InCombatLockdown and InCombatLockdown()) then return end
    if not UnitIsGroupLeader or not UnitIsGroupLeader("player") then return end
    if not hasSetMarker then
        SetPlayerRaidMarker()
        hasSetMarker = true
    end
    MarkAllCustomers()
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
