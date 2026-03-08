-- Init.lua
-- Initialization and addon lifecycle management

LockSmithPro = LockSmithPro or {}

-- Addon metadata
local addonName = "LockSmithPro"
local addonVersion = "1.0.1"

-- Runtime state
local isRunning = false

-- Default settings
local defaultSettings = {
    enabled = false,
    -- Channel monitoring
    monitorTrade = true,
    monitorGeneral = true,
    monitorLFG = true,
    monitorSay = true,
    monitorWhisper = true,

    -- Advertisement settings
    adMessage = "%SPELL_LINK% service available! Let me open your Junkboxes - tips appreciated!",
    adChannels = {
        trade = true,
        general = true,
        lfg = false,
        yell = false,
    },
    adTimerEnabled = false,
    adTimerInterval = 60, -- seconds (default 1 minute)

    -- Auto-response settings
    lowSkillWhisper = true,
    lowSkillMessage = "Sorry, my lockpicking skill (%CURRENT%) is too low for that box (requires %REQUIRED%)",
    thankYouWhisper = true,
    thankYouMessage = "Thank you for the %TIP% tip! ♥",
    autoInviteWhisper = false,
    popupOnAnyWhisper = false,

    -- Sound settings
    playSoundEffects = true,
    debugChat = false,

    -- Raid marker settings
    autoMarkSelf = true,
    autoMarkCustomers = true,

    -- Job board filters
    includeKeywords = "lockpick, lock pick, lockbox, unlock, rogue, rouge", -- Comma-separated keywords that MUST be in message
    excludeKeywords = "wts, lfg, premade, wsg, ab, av", -- Comma-separated keywords that must NOT be in message

    -- Statistics
    stats = {
        totalGold = 0,
        totalJobs = 0,
        lastSessionGold = 0,
        bestSessionGold = 0,
        totalBoxes = 0,
        boxesOpened = {},
    },

    -- Minimap button
    minimapPosition = 225,
    minimapButtonHidden = false,
}

LockSmithPro.DefaultSettings = defaultSettings

-- Initialize saved variables
local function InitializeSavedVariables()
    if not LockSmithProDB then
        LockSmithProDB = {}
    end

    -- Merge defaults with saved settings
    for key, value in pairs(defaultSettings) do
        if LockSmithProDB[key] == nil then
            if type(value) == "table" then
                LockSmithProDB[key] = {}
                for k, v in pairs(value) do
                    if type(v) == "table" then
                        LockSmithProDB[key][k] = {}
                        for k2, v2 in pairs(v) do
                            LockSmithProDB[key][k][k2] = v2
                        end
                    else
                        LockSmithProDB[key][k] = v
                    end
                end
            else
                LockSmithProDB[key] = value
            end
        end
    end

    -- Ensure key strings always have defaults (avoid nil/empty errors)
    if type(LockSmithProDB.adMessage) ~= "string" or LockSmithProDB.adMessage == "" then
        LockSmithProDB.adMessage = defaultSettings.adMessage
    end
    if type(LockSmithProDB.lowSkillMessage) ~= "string" or LockSmithProDB.lowSkillMessage == "" then
        LockSmithProDB.lowSkillMessage = defaultSettings.lowSkillMessage
    end
    if type(LockSmithProDB.thankYouMessage) ~= "string" or LockSmithProDB.thankYouMessage == "" then
        LockSmithProDB.thankYouMessage = defaultSettings.thankYouMessage
    end
    if LockSmithProDB.thankYouWhisper == nil then
        LockSmithProDB.thankYouWhisper = defaultSettings.thankYouWhisper
    end
    if LockSmithProDB.autoInviteWhisper == nil then
        LockSmithProDB.autoInviteWhisper = defaultSettings.autoInviteWhisper
    end
    if LockSmithProDB.popupOnAnyWhisper == nil then
        LockSmithProDB.popupOnAnyWhisper = defaultSettings.popupOnAnyWhisper
    end
    if LockSmithProDB.playSoundEffects == nil then
        LockSmithProDB.playSoundEffects = defaultSettings.playSoundEffects
    end
    if LockSmithProDB.debugChat == nil then
        LockSmithProDB.debugChat = defaultSettings.debugChat
    end
    if LockSmithProDB.autoMarkSelf == nil then
        LockSmithProDB.autoMarkSelf = defaultSettings.autoMarkSelf
    end
    if LockSmithProDB.autoMarkCustomers == nil then
        LockSmithProDB.autoMarkCustomers = defaultSettings.autoMarkCustomers
    end
    if type(LockSmithProDB.includeKeywords) ~= "string" then
        LockSmithProDB.includeKeywords = defaultSettings.includeKeywords
    end
    if type(LockSmithProDB.excludeKeywords) ~= "string" then
        LockSmithProDB.excludeKeywords = defaultSettings.excludeKeywords
    end

    if type(LockSmithProDB.stats) ~= "table" then
        LockSmithProDB.stats = {}
    end
    if type(LockSmithProDB.stats.totalGold) ~= "number" then
        LockSmithProDB.stats.totalGold = 0
    end
    if type(LockSmithProDB.stats.totalJobs) ~= "number" then
        LockSmithProDB.stats.totalJobs = 0
    end
    if type(LockSmithProDB.stats.lastSessionGold) ~= "number" then
        LockSmithProDB.stats.lastSessionGold = 0
    end
    if type(LockSmithProDB.stats.bestSessionGold) ~= "number" then
        LockSmithProDB.stats.bestSessionGold = 0
    end
    if type(LockSmithProDB.stats.totalBoxes) ~= "number" then
        LockSmithProDB.stats.totalBoxes = 0
    end
    if type(LockSmithProDB.stats.boxesOpened) ~= "table" then
        LockSmithProDB.stats.boxesOpened = {}
    end

    if type(LockSmithProDB.adChannels) ~= "table" then
        LockSmithProDB.adChannels = {}
    end
    if LockSmithProDB.adChannels.trade == nil then
        LockSmithProDB.adChannels.trade = defaultSettings.adChannels.trade
    end
    if LockSmithProDB.adChannels.general == nil then
        LockSmithProDB.adChannels.general = defaultSettings.adChannels.general
    end
    if LockSmithProDB.adChannels.lfg == nil then
        LockSmithProDB.adChannels.lfg = defaultSettings.adChannels.lfg
    end
    if LockSmithProDB.adChannels.yell == nil then
        LockSmithProDB.adChannels.yell = defaultSettings.adChannels.yell
    end
end

-- ================================
-- Core Addon Functions
-- ================================

-- Start the addon
function LockSmithPro:Start()
    if isRunning then
        print("|cff00ff00LockSmithPro:|r Already running!")
        return
    end

    isRunning = true
    LockSmithProDB.enabled = true
    LockSmithPro.Statistics:InitSession()

    -- Update skill cache
    LockSmithPro.Skills:GetLockpickingSkill()
    local skill, maxSkill = LockSmithPro.Skills:GetCachedSkill()

    print("|cff00ff00LockSmithPro:|r Started! Lockpicking skill: " .. skill .. "/" .. maxSkill)

    -- Start ad timer if enabled
    if LockSmithProDB.adTimerEnabled then
        LockSmithPro.Advertisement:StartAdTimer()
    end

    -- Update dashboard if open
    if LockSmithPro.Dashboard then
        LockSmithPro.Dashboard:UpdateJobBoardStatus()
    end
end

-- Stop the addon
function LockSmithPro:Stop()
    if not isRunning then
        print("|cff00ff00LockSmithPro:|r Already stopped!")
        return
    end

    isRunning = false
    LockSmithProDB.enabled = false

    -- Save session stats
    LockSmithPro.Statistics:SaveSessionStats()

    local sessionGold = LockSmithPro.Statistics:GetSessionGold()
    print("|cff00ff00LockSmithPro:|r Stopped! Session earnings: " .. LockSmithPro.Utils:FormatGold(sessionGold))

    -- Stop ad timer
    LockSmithPro.Advertisement:StopAdTimer()

    -- Clear session ignore list
    LockSmithPro.ChatMonitor:ClearSessionIgnore()

    -- Update dashboard if open
    if LockSmithPro.Dashboard then
        LockSmithPro.Dashboard:UpdateJobBoardStatus()
    end
end

-- Toggle addon on/off
function LockSmithPro:Toggle()
    if isRunning then
        self:Stop()
    else
        self:Start()
    end
end

-- Check if addon is running
function LockSmithPro:IsRunning()
    return isRunning
end

-- ================================
-- Event Handlers
-- ================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            InitializeSavedVariables()
            print("|cff00ff00LockSmithPro|r v" .. addonVersion .. " loaded! Type /LockSmithPro for options")
        end

    elseif event == "PLAYER_LOGIN" then
        -- Register Blizzard Settings/AddOns panel so it appears in the AddOns list
        if LockSmithPro.UI and LockSmithPro.UI.EnsureSettingsPanelRegistered then
            LockSmithPro.UI:EnsureSettingsPanelRegistered()
        end

        -- Initialize dashboard
        if LockSmithPro.Dashboard then
            LockSmithPro.Dashboard:Initialize()
        end

        -- Update skill on login
        LockSmithPro.Skills:GetLockpickingSkill()

        -- Initialize minimap button
        LockSmithPro.Minimap:InitializeButton()

        -- Register chat monitoring events
        LockSmithPro.ChatMonitor:RegisterEvents()

        -- Auto-start if it was running before
        if LockSmithProDB.enabled then
            LockSmithPro:Start()
        end
    end
end)
