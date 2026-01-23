-- Core.lua
-- Main addon logic for LockSmith

LockSmith = LockSmith or {}

-- Local variables
local addonName = "LockSmith"
local addonVersion = "1.0.0"
local isRunning = false
local currentLockpickSkill = 0
local currentMaxSkill = 0
local lastMessageTime = {}
local MESSAGE_THROTTLE = 10 -- seconds between messages to same target
local adTimer = nil
local sessionStartTime = 0
local sessionGold = 0
local pendingTradePartner = nil

-- Default settings
local defaultSettings = {
    enabled = false,
    -- Channel monitoring
    monitorTrade = true,
    monitorGeneral = true,
    monitorLFG = true,
    monitorWhisper = true,

    -- Advertisement settings
    adMessage = "Locksmith, Let me open your Junkbox tips appreciated!",
    adChannels = {
        trade = true,
        general = true,
        lfg = false,
    },
    adTimerEnabled = false,
    adTimerInterval = 60, -- seconds (default 1 minute)

    -- Auto-response settings
    lowSkillWhisper = true,
    lowSkillMessage = "Sorry, my lockpicking skill (%CURRENT%) is too low for that box (requires %REQUIRED%)",

    -- Statistics
    stats = {
        totalGold = 0,
        totalJobs = 0,
        lastSessionGold = 0,
        lastSessionJobs = 0,
    }
}

-- Initialize saved variables
local function InitializeSavedVariables()
    if not LockSmithDB then
        LockSmithDB = {}
    end

    -- Merge defaults with saved settings
    for key, value in pairs(defaultSettings) do
        if LockSmithDB[key] == nil then
            if type(value) == "table" then
                LockSmithDB[key] = {}
                for k, v in pairs(value) do
                    LockSmithDB[key][k] = v
                end
            else
                LockSmithDB[key] = value
            end
        end
    end
end

-- Get current lockpicking skill
function LockSmith:GetLockpickingSkill()
    local numSkills = GetNumSkillLines()
    for i = 1, numSkills do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(i)
        if not isHeader and skillName == "Lockpicking" then
            currentLockpickSkill = skillRank or 0
            currentMaxSkill = skillMaxRank or 0
            return currentLockpickSkill, currentMaxSkill
        end
    end
    currentLockpickSkill = 0
    currentMaxSkill = 0
    return 0, 0
end

-- Check if we can send a message to avoid spam
local function CanSendMessage(target)
    local now = GetTime()
    if not lastMessageTime[target] or (now - lastMessageTime[target]) > MESSAGE_THROTTLE then
        lastMessageTime[target] = now
        return true
    end
    return false
end

-- Send whisper with throttle check
function LockSmith:SendThrottledWhisper(target, message)
    if CanSendMessage(target) then
        SendChatMessage(message, "WHISPER", nil, target)
        return true
    end
    return false
end

-- Process lockpick request
function LockSmith:ProcessLockpickRequest(message, sender, channelName, channelNumber)
    if not isRunning then return end

    -- Don't process our own messages
    local playerName = UnitName("player")
    if sender == playerName then return end

    -- Check if message has lockpicking keywords
    if not self:HasLockpickKeyword(message) then return end

    -- Try to identify the box type
    local boxData = self:IdentifyBoxType(message)

    -- Get current skill
    local currentSkill, maxSkill = self:GetLockpickingSkill()

    -- Determine if we can handle this request
    local canHandle = true
    local requiredSkill = 1

    if boxData then
        requiredSkill = boxData.skill
        canHandle = currentSkill >= requiredSkill
    end

    if canHandle then
        -- Show notification popup
        self:ShowNotificationPopup(sender, boxData, channelName, requiredSkill)
    else
        -- Send low skill whisper if enabled
        if LockSmithDB.lowSkillWhisper then
            local msg = LockSmithDB.lowSkillMessage
            msg = string.gsub(msg, "%%CURRENT%%", tostring(currentSkill))
            msg = string.gsub(msg, "%%REQUIRED%%", tostring(requiredSkill))
            self:SendThrottledWhisper(sender, msg)
        end
    end
end

-- Chat event handler
local function OnChatMessage(event, ...)
    if not isRunning then return end

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

        LockSmith:ProcessLockpickRequest(message, sender, channelName, channelNumber)

    elseif event == "CHAT_MSG_WHISPER" then
        if not LockSmithDB.monitorWhisper then return end

        message = arg1
        sender = arg2

        LockSmith:ProcessLockpickRequest(message, sender, "WHISPER", nil)
    end
end

-- Start/Stop functions
function LockSmith:Start()
    if isRunning then
        print("|cff00ff00LockSmith:|r Already running!")
        return
    end

    isRunning = true
    sessionStartTime = GetTime()
    sessionGold = 0

    -- Update skill
    self:GetLockpickingSkill()

    print("|cff00ff00LockSmith:|r Started! Lockpicking skill: " .. currentLockpickSkill .. "/" .. currentMaxSkill)

    -- Start ad timer if enabled
    if LockSmithDB.adTimerEnabled then
        self:StartAdTimer()
    end
end

function LockSmith:Stop()
    if not isRunning then
        print("|cff00ff00LockSmith:|r Already stopped!")
        return
    end

    isRunning = false

    -- Save session stats
    LockSmithDB.stats.lastSessionGold = sessionGold

    print("|cff00ff00LockSmith:|r Stopped! Session earnings: " .. self:FormatGold(sessionGold))

    -- Stop ad timer
    self:StopAdTimer()
end

function LockSmith:Toggle()
    if isRunning then
        self:Stop()
    else
        self:Start()
    end
end

function LockSmith:IsRunning()
    return isRunning
end

-- Advertisement functions
function LockSmith:SendAdvertisement()
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

function LockSmith:StartAdTimer()
    self:StopAdTimer() -- Clear any existing timer

    if not LockSmithDB.adTimerEnabled then return end

    local interval = LockSmithDB.adTimerInterval or 60

    -- Create repeating timer
    adTimer = self:ScheduleRepeatingTimer(function()
        if isRunning and LockSmithDB.adTimerEnabled then
            self:SendAdvertisement()
        end
    end, interval)

    print("|cff00ff00LockSmith:|r Ad timer started (every " .. interval .. " seconds)")
end

function LockSmith:StopAdTimer()
    if adTimer then
        self:CancelTimer(adTimer)
        adTimer = nil
    end
end

-- Simple timer functions (since we're not using Ace libraries)
local activeTimers = {}
local nextTimerID = 1

function LockSmith:ScheduleRepeatingTimer(callback, interval)
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

function LockSmith:CancelTimer(timerID)
    if activeTimers[timerID] then
        activeTimers[timerID]:SetScript("OnUpdate", nil)
        activeTimers[timerID] = nil
    end
end

-- Gold tracking
function LockSmith:TrackGoldReceived(amount, source)
    if not isRunning then return end

    sessionGold = sessionGold + amount
    LockSmithDB.stats.totalGold = LockSmithDB.stats.totalGold + amount
    LockSmithDB.stats.totalJobs = LockSmithDB.stats.totalJobs + 1

    print("|cff00ff00LockSmith:|r Received " .. self:FormatGold(amount) .. " from " .. (source or "Unknown"))
end

-- Format gold for display
function LockSmith:FormatGold(copper)
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

-- Trade tracking
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
            if goldReceived > 0 then
                LockSmith:TrackGoldReceived(goldReceived, pendingTradePartner)
            end
        end
    end
end)

-- Mail tracking
local mailFrame = CreateFrame("Frame")
mailFrame:RegisterEvent("MAIL_SHOW")
mailFrame:RegisterEvent("MAIL_INBOX_UPDATE")

local lastMailCheck = {}

mailFrame:SetScript("OnEvent", function(self, event)
    if not isRunning then return end

    if event == "MAIL_INBOX_UPDATE" then
        local numItems = GetInboxNumItems()

        for i = 1, numItems do
            local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead = GetInboxHeaderInfo(i)

            -- Only track new mail with gold
            if money and money > 0 and not wasRead then
                local mailKey = sender .. "_" .. i .. "_" .. money
                if not lastMailCheck[mailKey] then
                    lastMailCheck[mailKey] = true
                    -- We can't automatically know if it's a tip, so just track it
                    -- User will have to manually check
                end
            end
        end
    end
end)

-- Event registration frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = arg1
        if loadedAddon == addonName then
            InitializeSavedVariables()
            print("|cff00ff00LockSmith|r v" .. addonVersion .. " loaded! Type /locksmith for options")
        end

    elseif event == "PLAYER_LOGIN" then
        -- Update skill on login
        LockSmith:GetLockpickingSkill()

        -- Initialize minimap button
        LockSmith:InitializeMinimapButton()

        -- Auto-start if it was running before
        if LockSmithDB.enabled then
            LockSmith:Start()
        end

    elseif event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_WHISPER" then
        OnChatMessage(event, ...)
    end
end)

-- Slash commands
SLASH_LOCKSMITH1 = "/locksmith"
SLASH_LOCKSMITH2 = "/ls"

SlashCmdList["LOCKSMITH"] = function(msg)
    local cmd = string.lower(msg)

    if cmd == "start" then
        LockSmith:Start()
    elseif cmd == "stop" then
        LockSmith:Stop()
    elseif cmd == "toggle" then
        LockSmith:Toggle()
    elseif cmd == "ad" or cmd == "advertise" then
        LockSmith:SendAdvertisement()
    elseif cmd == "skill" then
        local skill, maxSkill = LockSmith:GetLockpickingSkill()
        print("|cff00ff00LockSmith:|r Lockpicking skill: " .. skill .. "/" .. maxSkill)
    elseif cmd == "stats" then
        print("|cff00ff00LockSmith Statistics:|r")
        print("Total Gold: " .. LockSmith:FormatGold(LockSmithDB.stats.totalGold))
        print("Total Jobs: " .. LockSmithDB.stats.totalJobs)
        print("Session Gold: " .. LockSmith:FormatGold(sessionGold))
        if LockSmithDB.stats.totalJobs > 0 then
            print("Average Tip: " .. LockSmith:FormatGold(math.floor(LockSmithDB.stats.totalGold / LockSmithDB.stats.totalJobs)))
        end
    elseif cmd == "minimap" then
        LockSmith:ToggleMinimapButton()
        if LockSmithDB.minimapButtonHidden then
            print("|cff00ff00LockSmith:|r Minimap button hidden")
        else
            print("|cff00ff00LockSmith:|r Minimap button shown")
        end
    else
        -- Open settings GUI
        LockSmith:OpenSettingsGUI()
    end
end
