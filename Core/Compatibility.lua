-- Shared API and identity handling. Never shorten an address used for actions.
LockSmithPro = LockSmithPro or {}
LockSmithPro.Compat = {}
local Compat = LockSmithPro.Compat

function Compat:IsReadable(value)
    if issecretvalue and issecretvalue(value) then return false end
    return not canaccessvalue or canaccessvalue(value)
end

function Compat:IsString(value)
    return self:IsReadable(value) and type(value) == "string"
end

function Compat:IsNumber(value)
    return self:IsReadable(value) and type(value) == "number"
end

function Compat:IsForever()
    local interface = select(4, GetBuildInfo())
    return (WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)
        or (interface >= 16000 and interface < 20000)
end

function Compat:CanAutomate()
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return false end
    if C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted() then return false end
    return true
end

function Compat:UnitAddress(unit)
    if self:IsForever() then
        if NameUtil and NameUtil.GetUnmodifiedUnitFullName then
            local ok, full = pcall(NameUtil.GetUnmodifiedUnitFullName, unit)
            if ok and self:IsString(full) and full ~= "" then return full end
            return nil
        end
        local getName = UnitNameUnmodified or UnitName
        local first, surname = getName(unit)
        if not self:IsString(first) or first == "" then return nil end
        if not self:IsReadable(surname) then return nil end
        if self:IsString(surname) and surname ~= "" then
            local separators = Constants and Constants.CharacterNameSeparatorConsts
            return first .. (separators and separators.CHARACTERNAME_SURNAME_SEPARATOR or " ") .. surname
        end
        return first
    end
    local name, realm
    if UnitFullName then name, realm = UnitFullName(unit) else name, realm = UnitName(unit) end
    if not self:IsString(name) or name == "" or not self:IsReadable(realm) then return nil end
    if self:IsString(realm) and realm ~= "" and not name:find("-", 1, true) then
        return name .. "-" .. realm:gsub("%s", "")
    end
    return name
end

function Compat:ValidateChatMessage(message)
    if not self:IsString(message) or not message:find("%S") then return false, "empty" end
    if #message > 255 then return false, "too_long" end
    return true
end

-- Returns whether a send was dispatched, never a claim of server delivery.
-- Button/slash-command sends use the native API in the user's input event.
-- Its restrictions still apply; automation gates only preflight background sends.
function Compat:SendChat(message, channel, target, userInitiated)
    local valid, reason = self:ValidateChatMessage(message)
    if not valid then return false, reason end
    if not userInitiated and not self:CanAutomate() then return false, "restricted" end
    if not self:IsReadable(target) then return false, "restricted" end
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if not send then return false, "unavailable" end
    local ok, result = pcall(send, message, channel, nil, target)
    if not ok or result == false then return false, "rejected" end
    return true
end

function Compat:OpenWhisper(target)
    if not self:NameKey(target) then return false end
    local sendTell = ChatFrameUtil and ChatFrameUtil.SendTell or ChatFrame_SendTell
    if sendTell then return pcall(sendTell, target) end
    return false
end

function Compat:NameKey(name)
    if not self:IsString(name) or name == "" then return nil end
    -- Spaces are significant: Forever's first and second names stay together.
    -- On realm-based clients, bare names refer to our own realm.
    if not self:IsForever() then
        if not name:find("-", 1, true) then
            local realm = GetNormalizedRealmName and GetNormalizedRealmName()
            if self:IsString(realm) and realm ~= "" then name = name .. "-" .. realm end
        end
    end
    return string.lower(name)
end

function Compat:IsGroupMember(name)
    local key = self:NameKey(name)
    if not key then return false end
    if key == self:NameKey(self:UnitAddress("player")) then return true end
    local raid = IsInRaid and IsInRaid()
    local count = GetNumGroupMembers and GetNumGroupMembers() or 0
    for i = 1, count do
        local unit = (raid and "raid" or "party") .. i
        if key == self:NameKey(self:UnitAddress(unit)) then return true end
    end
    return false
end

-- Bounded, expiring timestamp stores. A burst of unique chat authors must not
-- retain an entire realm's names for the duration of a login.
function Compat:Remember(cache, key, ttl, limit)
    if not key then return false end
    local now = GetTime()
    local previous = cache[key]
    if previous and now - previous < ttl then return false end
    local count, oldestKey, oldest = 0, nil, math.huge
    for k, stamp in pairs(cache) do
        if now - stamp >= ttl then
            cache[k] = nil
        else
            count = count + 1
            if stamp < oldest then oldestKey, oldest = k, stamp end
        end
    end
    if count >= (limit or 512) and oldestKey then cache[oldestKey] = nil end
    cache[key] = now
    return true
end
