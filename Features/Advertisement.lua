-- Advertisement.lua
-- Advertisement system with timer

LockSmithPro = LockSmithPro or {}
LockSmithPro.Advertisement = {}

local adTimer = nil
LockSmithPro.Advertisement.adReady = false

-- Spell link constant
local SPELL_LINK_PICKLOCK = "|cff71d5ff|Hspell:1804|h[Pick Lock]|h|r"

-- Process ad message variables
function LockSmithPro.Advertisement:ProcessAdMessage(message)
    if type(message) ~= "string" then
        return ""
    end

    -- Replace %SPELL_LINK% with the Pick Lock spell link
    message = string.gsub(message, "%%SPELL_LINK%%", SPELL_LINK_PICKLOCK)

    return message
end

local function ReportSendFailure(reason, message)
    local explanation
    if reason == "too_long" then
        explanation = "Advertisement is " .. #message .. " bytes after inserting the spell link (maximum 255). Shorten it in Settings."
    elseif reason == "empty" then
        explanation = "Enter an advertisement message in Settings first."
    elseif reason == "unavailable" then
        explanation = "Chat sending is unavailable on this client."
    elseif reason == "rejected" or reason == "restricted" then
        explanation = "The client rejected the advertisement. Try sending it through the normal chat box."
    else
        explanation = "No selected chat channels are available. Join a channel or enable Yell in Settings."
    end
    print("|cffff0000LockSmithPro:|r " .. explanation)
end

function LockSmithPro.Advertisement:SendYellAdvertisement()
    local message = self:ProcessAdMessage(LockSmithProDB.adMessage)
    local sent, reason = LockSmithPro.Compat:SendChat(message, "YELL", nil, true)
    if sent then
        print("|cff00ff00LockSmithPro:|r Advertisement submitted to Yell")
    else
        ReportSendFailure(reason, message)
    end
    return sent
end

-- Send advertisement to configured channels
function LockSmithPro.Advertisement:SendAdvertisement()
    local message = self:ProcessAdMessage(LockSmithProDB.adMessage)
    local valid, reason = LockSmithPro.Compat:ValidateChatMessage(message)
    if not valid then ReportSendFailure(reason, message); return false end
    local sentCount, failureReason = 0, nil

    local function Send(channel, target)
        local sent, why = LockSmithPro.Compat:SendChat(message, channel, target, true)
        if sent then sentCount = sentCount + 1 else failureReason = why end
    end
    local channelNames = {trade = "Trade", general = "General", lfg = "LookingForGroup"}
    for key, name in pairs(channelNames) do
        if LockSmithProDB.adChannels[key] then
            local id = GetChannelName(name)
            if id and id > 0 then Send("CHANNEL", id) end
        end
    end
    if LockSmithProDB.adChannels.yell then Send("YELL") end

    if sentCount > 0 then
        print("|cff00ff00LockSmithPro:|r Advertisement submitted to " .. sentCount .. " channel(s)")

        -- Notify dashboard only on successful sends
        if LockSmithPro.Dashboard then
            LockSmithPro.Dashboard:OnAdSent()
        end

        self:ClearAdReady()

        -- Restart timer to sync button cooldown with adReady notification
        if LockSmithProDB.adTimerEnabled then
            self:RestartTimer()
        end
    else
        ReportSendFailure(failureReason, message)
    end
    return sentCount > 0
end

function LockSmithPro.Advertisement:NotifyAdReady()
    if self.adReady then return end

    self.adReady = true
    print("|cff00ff00LockSmithPro:|r Advertisement ready. Use the dashboard to send.")

    -- No longer show popup - dashboard handles this
end

function LockSmithPro.Advertisement:ClearAdReady()
    if not self.adReady then return end

    self.adReady = false
    -- No longer use popup - dashboard handles this
end

-- Start advertisement timer
function LockSmithPro.Advertisement:StartAdTimer()
    self:StopAdTimer() -- Clear any existing timer

    if not LockSmithProDB.adTimerEnabled then return end

    local interval = math.max(30, math.min(600, tonumber(LockSmithProDB.adTimerInterval) or 60))

    -- Create repeating timer
    adTimer = LockSmithPro.Utils:ScheduleRepeatingTimer(function()
        if LockSmithPro:IsRunning() and LockSmithProDB.adTimerEnabled then
            LockSmithPro.Advertisement:NotifyAdReady()
        end
    end, interval)

    print("|cff00ff00LockSmithPro:|r Ad timer started (every " .. interval .. " seconds)")
end

-- Stop advertisement timer
function LockSmithPro.Advertisement:StopAdTimer()
    if adTimer then
        LockSmithPro.Utils:CancelTimer(adTimer)
        adTimer = nil
    end

    self:ClearAdReady()
end

-- Restart timer with new interval
function LockSmithPro.Advertisement:RestartTimer()
    if LockSmithProDB.adTimerEnabled and LockSmithPro:IsRunning() then
        self:StartAdTimer()
    end
end
