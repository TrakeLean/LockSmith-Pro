-- SlashCommands.lua
-- Slash command handlers

LockSmithPro = LockSmithPro or {}

-- Register slash commands
SLASH_LockSmithPro1 = "/LockSmithPro"
SLASH_LockSmithPro2 = "/ls"

SlashCmdList["LockSmithPro"] = function(msg)
    local cmd = string.lower(msg)

    if cmd == "start" then
        LockSmithPro:Start()

    elseif cmd == "stop" then
        LockSmithPro:Stop()

    elseif cmd == "toggle" then
        LockSmithPro:Toggle()

    elseif cmd == "ad" or cmd == "advertise" then
        LockSmithPro.Advertisement:SendAdvertisement()

    elseif cmd == "skill" then
        local skill, maxSkill = LockSmithPro.Skills:GetLockpickingSkill()
        print("|cff00ff00LockSmithPro:|r Lockpicking skill: " .. skill .. "/" .. maxSkill)

    elseif cmd == "stats" then
        print("|cff00ff00LockSmithPro Statistics:|r")
        print("Total Earned: " .. LockSmithPro.Utils:FormatGold(LockSmithProDB.stats.totalGold))
        print("Total Jobs: " .. LockSmithProDB.stats.totalJobs)
        print("Session Earned: " .. LockSmithPro.Utils:FormatGold(LockSmithPro.Statistics:GetSessionGold()))

        local avgTip = LockSmithPro.Statistics:GetAverageTip()
        if avgTip > 0 then
            print("Average Tip: " .. LockSmithPro.Utils:FormatGold(avgTip))
        end

    elseif cmd == "minimap" then
        LockSmithPro.Minimap:ToggleButton()
        if LockSmithProDB.minimapButtonHidden then
            print("|cff00ff00LockSmithPro:|r Minimap button hidden")
        else
            print("|cff00ff00LockSmithPro:|r Minimap button shown")
        end

    else
        -- Open dashboard
        if LockSmithPro.Dashboard then
            LockSmithPro.Dashboard:Show()
        else
            -- Fallback to old settings GUI if dashboard not loaded
            LockSmithPro.UI:OpenSettingsGUI()
        end
    end
end
