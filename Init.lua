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
    },

    -- Minimap button
    minimapPosition = 225,
    minimapButtonHidden = false,
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
        local loadedAddon = arg1
        if loadedAddon == addonName then
            InitializeSavedVariables()
            print("|cff00ff00LockSmith|r v" .. addonVersion .. " loaded! Type /locksmith for options")
        end

    elseif event == "PLAYER_LOGIN" then
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
