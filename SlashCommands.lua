-- SlashCommands.lua
-- Slash command handlers

LockSmith = LockSmith or {}

-- Register slash commands
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
        LockSmith.Advertisement:SendAdvertisement()

    elseif cmd == "skill" then
        local skill, maxSkill = LockSmith.Skills:GetLockpickingSkill()
        print("|cff00ff00LockSmith:|r Lockpicking skill: " .. skill .. "/" .. maxSkill)

    elseif cmd == "stats" then
        print("|cff00ff00LockSmith Statistics:|r")
        print("Total Gold: " .. LockSmith.Utils:FormatGold(LockSmithDB.stats.totalGold))
        print("Total Jobs: " .. LockSmithDB.stats.totalJobs)
        print("Session Gold: " .. LockSmith.Utils:FormatGold(LockSmith.Statistics:GetSessionGold()))

        local avgTip = LockSmith.Statistics:GetAverageTip()
        if avgTip > 0 then
            print("Average Tip: " .. LockSmith.Utils:FormatGold(avgTip))
        end

    elseif cmd == "minimap" then
        LockSmith.Minimap:ToggleButton()
        if LockSmithDB.minimapButtonHidden then
            print("|cff00ff00LockSmith:|r Minimap button hidden")
        else
            print("|cff00ff00LockSmith:|r Minimap button shown")
        end

    else
        -- Open settings GUI
        LockSmith.UI:OpenSettingsGUI()
    end
end
