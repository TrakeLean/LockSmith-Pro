-- Init.lua
-- Initialization and addon lifecycle management

LockSmith = LockSmith or {}

-- Addon metadata
local addonName = "LockSmith"
local addonVersion = "1.0.0"

-- Runtime state
local isRunning = false

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

    -- Raid marker settings
    autoMarkSelf = true,
    autoMarkCustomers = true,

    -- Statistics
    stats = {
        totalGold = 0,
        totalJobs = 0,
        lastSessionGold = 0,
        totalBoxes = 0,
        boxesOpened = {},
    },

    -- Minimap button
    minimapPosition = 225,
    minimapButtonHidden = false,
}

LockSmith.DefaultSettings = defaultSettings

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
                    if type(v) == "table" then
                        LockSmithDB[key][k] = {}
                        for k2, v2 in pairs(v) do
                            LockSmithDB[key][k][k2] = v2
                        end
                    else
                        LockSmithDB[key][k] = v
                    end
                end
            else
                LockSmithDB[key] = value
            end
        end
    end

    -- Ensure key strings always have defaults (avoid nil/empty errors)
    if type(LockSmithDB.adMessage) ~= "string" or LockSmithDB.adMessage == "" then
        LockSmithDB.adMessage = defaultSettings.adMessage
    end
    if type(LockSmithDB.lowSkillMessage) ~= "string" or LockSmithDB.lowSkillMessage == "" then
        LockSmithDB.lowSkillMessage = defaultSettings.lowSkillMessage
    end
    if type(LockSmithDB.thankYouMessage) ~= "string" or LockSmithDB.thankYouMessage == "" then
        LockSmithDB.thankYouMessage = defaultSettings.thankYouMessage
    end
    if LockSmithDB.thankYouWhisper == nil then
        LockSmithDB.thankYouWhisper = defaultSettings.thankYouWhisper
    end
    if LockSmithDB.autoInviteWhisper == nil then
        LockSmithDB.autoInviteWhisper = defaultSettings.autoInviteWhisper
    end
    if LockSmithDB.popupOnAnyWhisper == nil then
        LockSmithDB.popupOnAnyWhisper = defaultSettings.popupOnAnyWhisper
    end
    if LockSmithDB.playSoundEffects == nil then
        LockSmithDB.playSoundEffects = defaultSettings.playSoundEffects
    end
    if LockSmithDB.autoMarkSelf == nil then
        LockSmithDB.autoMarkSelf = defaultSettings.autoMarkSelf
    end
    if LockSmithDB.autoMarkCustomers == nil then
        LockSmithDB.autoMarkCustomers = defaultSettings.autoMarkCustomers
    end

    if type(LockSmithDB.stats) ~= "table" then
        LockSmithDB.stats = {}
    end
    if type(LockSmithDB.stats.totalGold) ~= "number" then
        LockSmithDB.stats.totalGold = 0
    end
    if type(LockSmithDB.stats.totalJobs) ~= "number" then
        LockSmithDB.stats.totalJobs = 0
    end
    if type(LockSmithDB.stats.lastSessionGold) ~= "number" then
        LockSmithDB.stats.lastSessionGold = 0
    end
    if type(LockSmithDB.stats.totalBoxes) ~= "number" then
        LockSmithDB.stats.totalBoxes = 0
    end
    if type(LockSmithDB.stats.boxesOpened) ~= "table" then
        LockSmithDB.stats.boxesOpened = {}
    end

    if type(LockSmithDB.adChannels) ~= "table" then
        LockSmithDB.adChannels = {}
    end
    if LockSmithDB.adChannels.trade == nil then
        LockSmithDB.adChannels.trade = defaultSettings.adChannels.trade
    end
    if LockSmithDB.adChannels.general == nil then
        LockSmithDB.adChannels.general = defaultSettings.adChannels.general
    end
    if LockSmithDB.adChannels.lfg == nil then
        LockSmithDB.adChannels.lfg = defaultSettings.adChannels.lfg
    end
    if LockSmithDB.adChannels.yell == nil then
        LockSmithDB.adChannels.yell = defaultSettings.adChannels.yell
    end
end

-- ================================
-- Core Addon Functions
-- ================================

-- Start the addon
function LockSmith:Start()
    if isRunning then
        print("|cff00ff00LockSmith:|r Already running!")
        return
    end

    isRunning = true
    LockSmith.Statistics:InitSession()

    -- Update skill cache
    LockSmith.Skills:GetLockpickingSkill()
    local skill, maxSkill = LockSmith.Skills:GetCachedSkill()

    print("|cff00ff00LockSmith:|r Started! Lockpicking skill: " .. skill .. "/" .. maxSkill)

    -- Start ad timer if enabled
    if LockSmithDB.adTimerEnabled then
        LockSmith.Advertisement:StartAdTimer()
    end

    -- Update dashboard if open
    if LockSmith.Dashboard then
        LockSmith.Dashboard:UpdateJobBoardStatus()
    end
end

-- Stop the addon
function LockSmith:Stop()
    if not isRunning then
        print("|cff00ff00LockSmith:|r Already stopped!")
        return
    end

    isRunning = false

    -- Save session stats
    LockSmith.Statistics:SaveSessionStats()

    local sessionGold = LockSmith.Statistics:GetSessionGold()
    print("|cff00ff00LockSmith:|r Stopped! Session earnings: " .. LockSmith.Utils:FormatGold(sessionGold))

    -- Stop ad timer
    LockSmith.Advertisement:StopAdTimer()

    -- Clear session ignore list
    LockSmith.ChatMonitor:ClearSessionIgnore()

    -- Update dashboard if open
    if LockSmith.Dashboard then
        LockSmith.Dashboard:UpdateJobBoardStatus()
    end
end

-- Toggle addon on/off
function LockSmith:Toggle()
    if isRunning then
        self:Stop()
    else
        self:Start()
    end
end

-- Check if addon is running
function LockSmith:IsRunning()
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
            print("|cff00ff00LockSmith|r v" .. addonVersion .. " loaded! Type /locksmith for options")
        end

    elseif event == "PLAYER_LOGIN" then
        -- Initialize dashboard
        if LockSmith.Dashboard then
            LockSmith.Dashboard:Initialize()
        end

        -- Update skill on login
        LockSmith.Skills:GetLockpickingSkill()

        -- Initialize minimap button
        LockSmith.Minimap:InitializeButton()

        -- Register chat monitoring events
        LockSmith.ChatMonitor:RegisterEvents()

        -- Auto-start if it was running before
        if LockSmithDB.enabled then
            LockSmith:Start()
        end
    end
end)
