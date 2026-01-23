-- Settings.lua
-- Settings panel UI

LockSmith = LockSmith or {}
LockSmith.UI = LockSmith.UI or {}

local function CreateSettingsPanel()
    -- Main settings frame
    local panel = CreateFrame("Frame", "LockSmithSettingsPanel", UIParent)
    panel.name = "LockSmith"

    -- Scroll frame for settings
    local scrollFrame = CreateFrame("ScrollFrame", "LockSmithScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", "LockSmithScrollChild", scrollFrame)
    scrollChild:SetSize(580, 1200)
    scrollFrame:SetScrollChild(scrollChild)

    local yOffset = -10

    -- Title
    local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, yOffset)
    title:SetText("LockSmith - Lockpicking Service Addon")
    yOffset = yOffset - 30

    -- Version
    local version = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", 16, yOffset)
    version:SetText("Version 1.0.0")
    yOffset = yOffset - 30

    -- ================================
    -- Start/Stop Section
    -- ================================

    local startStopHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    startStopHeader:SetPoint("TOPLEFT", 16, yOffset)
    startStopHeader:SetText("|cff00ff00Addon Control|r")
    yOffset = yOffset - 20

    -- Start/Stop button
    local startStopBtn = CreateFrame("Button", "LockSmithStartStopBtn", scrollChild, "GameMenuButtonTemplate")
    startStopBtn:SetPoint("TOPLEFT", 16, yOffset)
    startStopBtn:SetSize(120, 25)
    startStopBtn:SetText(LockSmith:IsRunning() and "Stop" or "Start")
    startStopBtn:SetScript("OnClick", function(self)
        LockSmith:Toggle()
        self:SetText(LockSmith:IsRunning() and "Stop" or "Start")

        -- Update status text
        local statusText = _G["LockSmithStatusText"]
        if statusText then
            if LockSmith:IsRunning() then
                local skill, maxSkill = LockSmith.Skills:GetLockpickingSkill()
                statusText:SetText("|cff00ff00Status: Running|r (Skill: " .. skill .. "/" .. maxSkill .. ")")
            else
                statusText:SetText("|cffff0000Status: Stopped|r")
            end
        end
    end)
    yOffset = yOffset - 35

    -- Status text
    local statusText = scrollChild:CreateFontString("LockSmithStatusText", "ARTWORK", "GameFontNormal")
    statusText:SetPoint("TOPLEFT", 16, yOffset)
    if LockSmith:IsRunning() then
        local skill, maxSkill = LockSmith.Skills:GetLockpickingSkill()
        statusText:SetText("|cff00ff00Status: Running|r (Skill: " .. skill .. "/" .. maxSkill .. ")")
    else
        statusText:SetText("|cffff0000Status: Stopped|r")
    end
    yOffset = yOffset - 25

    local statusNote = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    statusNote:SetPoint("TOPLEFT", 16, yOffset)
    statusNote:SetText("Note: You can use /locksmith start or /locksmith stop")
    yOffset = yOffset - 30

    -- ================================
    -- Channel Monitoring Section
    -- ================================

    local channelHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    channelHeader:SetPoint("TOPLEFT", 16, yOffset)
    channelHeader:SetText("|cff00ff00Channel Monitoring|r")
    yOffset = yOffset - 20

    -- Trade channel checkbox
    local tradeCheckbox = CreateFrame("CheckButton", "LockSmithTradeCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    tradeCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[tradeCheckbox:GetName() .. "Text"]:SetText("Monitor Trade Channel")
    tradeCheckbox:SetChecked(LockSmithDB.monitorTrade)
    tradeCheckbox:SetScript("OnClick", function(self)
        LockSmithDB.monitorTrade = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- General channel checkbox
    local generalCheckbox = CreateFrame("CheckButton", "LockSmithGeneralCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    generalCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[generalCheckbox:GetName() .. "Text"]:SetText("Monitor General Channel")
    generalCheckbox:SetChecked(LockSmithDB.monitorGeneral)
    generalCheckbox:SetScript("OnClick", function(self)
        LockSmithDB.monitorGeneral = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- LFG channel checkbox
    local lfgCheckbox = CreateFrame("CheckButton", "LockSmithLFGCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    lfgCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[lfgCheckbox:GetName() .. "Text"]:SetText("Monitor LookingForGroup Channel")
    lfgCheckbox:SetChecked(LockSmithDB.monitorLFG)
    lfgCheckbox:SetScript("OnClick", function(self)
        LockSmithDB.monitorLFG = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Whisper channel checkbox
    local whisperCheckbox = CreateFrame("CheckButton", "LockSmithWhisperCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    whisperCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[whisperCheckbox:GetName() .. "Text"]:SetText("Monitor Whispers")
    whisperCheckbox:SetChecked(LockSmithDB.monitorWhisper)
    whisperCheckbox:SetScript("OnClick", function(self)
        LockSmithDB.monitorWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 35

    -- ================================
    -- Advertisement Section
    -- ================================

    local adHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    adHeader:SetPoint("TOPLEFT", 16, yOffset)
    adHeader:SetText("|cff00ff00Advertisement Settings|r")
    yOffset = yOffset - 20

    -- Ad message label
    local adMsgLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    adMsgLabel:SetPoint("TOPLEFT", 16, yOffset)
    adMsgLabel:SetText("Advertisement Message:")
    yOffset = yOffset - 20

    -- Ad message editbox
    local adMsgBox = CreateFrame("EditBox", "LockSmithAdMsgBox", scrollChild, "InputBoxTemplate")
    adMsgBox:SetPoint("TOPLEFT", 16, yOffset)
    adMsgBox:SetSize(450, 30)
    adMsgBox:SetText(LockSmithDB.adMessage)
    adMsgBox:SetAutoFocus(false)
    adMsgBox:SetScript("OnTextChanged", function(self)
        LockSmithDB.adMessage = self:GetText()
    end)
    adMsgBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    yOffset = yOffset - 40

    -- Manual send button
    local sendAdBtn = CreateFrame("Button", "LockSmithSendAdBtn", scrollChild, "GameMenuButtonTemplate")
    sendAdBtn:SetPoint("TOPLEFT", 16, yOffset)
    sendAdBtn:SetSize(150, 25)
    sendAdBtn:SetText("Send Advertisement")
    sendAdBtn:SetScript("OnClick", function(self)
        LockSmith.Advertisement:SendAdvertisement()
    end)
    yOffset = yOffset - 35

    -- Ad channels label
    local adChannelLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    adChannelLabel:SetPoint("TOPLEFT", 16, yOffset)
    adChannelLabel:SetText("Send Advertisements To:")
    yOffset = yOffset - 20

    -- Trade ad channel checkbox
    local adTradeCheck = CreateFrame("CheckButton", "LockSmithAdTradeCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    adTradeCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[adTradeCheck:GetName() .. "Text"]:SetText("Trade Channel")
    adTradeCheck:SetChecked(LockSmithDB.adChannels.trade)
    adTradeCheck:SetScript("OnClick", function(self)
        LockSmithDB.adChannels.trade = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- General ad channel checkbox
    local adGeneralCheck = CreateFrame("CheckButton", "LockSmithAdGeneralCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    adGeneralCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[adGeneralCheck:GetName() .. "Text"]:SetText("General Channel")
    adGeneralCheck:SetChecked(LockSmithDB.adChannels.general)
    adGeneralCheck:SetScript("OnClick", function(self)
        LockSmithDB.adChannels.general = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- LFG ad channel checkbox
    local adLFGCheck = CreateFrame("CheckButton", "LockSmithAdLFGCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    adLFGCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[adLFGCheck:GetName() .. "Text"]:SetText("LookingForGroup Channel")
    adLFGCheck:SetChecked(LockSmithDB.adChannels.lfg)
    adLFGCheck:SetScript("OnClick", function(self)
        LockSmithDB.adChannels.lfg = self:GetChecked()
    end)
    yOffset = yOffset - 35

    -- Timer enabled checkbox
    local timerCheckbox = CreateFrame("CheckButton", "LockSmithTimerCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    timerCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[timerCheckbox:GetName() .. "Text"]:SetText("Enable Auto-Advertisement Timer")
    timerCheckbox:SetChecked(LockSmithDB.adTimerEnabled)
    timerCheckbox:SetScript("OnClick", function(self)
        LockSmithDB.adTimerEnabled = self:GetChecked()
        if self:GetChecked() and LockSmith:IsRunning() then
            LockSmith.Advertisement:StartAdTimer()
        else
            LockSmith.Advertisement:StopAdTimer()
        end
    end)
    yOffset = yOffset - 30

    -- Timer interval slider
    local timerSlider = CreateFrame("Slider", "LockSmithTimerSlider", scrollChild, "OptionsSliderTemplate")
    timerSlider:SetPoint("TOPLEFT", 16, yOffset)
    timerSlider:SetMinMaxValues(30, 600)
    timerSlider:SetValue(LockSmithDB.adTimerInterval or 60)
    timerSlider:SetValueStep(30)
    timerSlider:SetObeyStepOnDrag(true)
    _G[timerSlider:GetName() .. "Low"]:SetText("30s")
    _G[timerSlider:GetName() .. "High"]:SetText("10m")
    _G[timerSlider:GetName() .. "Text"]:SetText("Timer Interval: " .. (LockSmithDB.adTimerInterval or 60) .. "s")
    timerSlider:SetScript("OnValueChanged", function(self, value)
        LockSmithDB.adTimerInterval = value
        _G[self:GetName() .. "Text"]:SetText("Timer Interval: " .. value .. "s")
        if LockSmithDB.adTimerEnabled and LockSmith:IsRunning() then
            LockSmith.Advertisement:StartAdTimer()
        end
    end)
    yOffset = yOffset - 50

    -- ================================
    -- Auto-Response Section
    -- ================================

    local responseHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    responseHeader:SetPoint("TOPLEFT", 16, yOffset)
    responseHeader:SetText("|cff00ff00Auto-Response Settings|r")
    yOffset = yOffset - 20

    -- Low skill whisper checkbox
    local lowSkillCheck = CreateFrame("CheckButton", "LockSmithLowSkillCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    lowSkillCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[lowSkillCheck:GetName() .. "Text"]:SetText("Whisper when skill is too low")
    lowSkillCheck:SetChecked(LockSmithDB.lowSkillWhisper)
    lowSkillCheck:SetScript("OnClick", function(self)
        LockSmithDB.lowSkillWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Low skill message label
    local lowSkillLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lowSkillLabel:SetPoint("TOPLEFT", 16, yOffset)
    lowSkillLabel:SetText("Low Skill Message (use %CURRENT% and %REQUIRED%):")
    yOffset = yOffset - 20

    -- Low skill message editbox
    local lowSkillBox = CreateFrame("EditBox", "LockSmithLowSkillBox", scrollChild, "InputBoxTemplate")
    lowSkillBox:SetPoint("TOPLEFT", 16, yOffset)
    lowSkillBox:SetSize(450, 30)
    lowSkillBox:SetText(LockSmithDB.lowSkillMessage)
    lowSkillBox:SetAutoFocus(false)
    lowSkillBox:SetScript("OnTextChanged", function(self)
        LockSmithDB.lowSkillMessage = self:GetText()
    end)
    lowSkillBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    yOffset = yOffset - 50

    -- ================================
    -- Statistics Section
    -- ================================

    local statsHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    statsHeader:SetPoint("TOPLEFT", 16, yOffset)
    statsHeader:SetText("|cff00ff00Statistics|r")
    yOffset = yOffset - 20

    -- Total gold
    local totalGoldText = scrollChild:CreateFontString("LockSmithTotalGoldText", "ARTWORK", "GameFontNormal")
    totalGoldText:SetPoint("TOPLEFT", 16, yOffset)
    totalGoldText:SetText("Total Gold Earned: " .. LockSmith.Utils:FormatGold(LockSmithDB.stats.totalGold))
    yOffset = yOffset - 20

    -- Total jobs
    local totalJobsText = scrollChild:CreateFontString("LockSmithTotalJobsText", "ARTWORK", "GameFontNormal")
    totalJobsText:SetPoint("TOPLEFT", 16, yOffset)
    totalJobsText:SetText("Total Jobs Completed: " .. LockSmithDB.stats.totalJobs)
    yOffset = yOffset - 20

    -- Average tip
    local avgTip = LockSmith.Statistics:GetAverageTip()
    local avgTipText = scrollChild:CreateFontString("LockSmithAvgTipText", "ARTWORK", "GameFontNormal")
    avgTipText:SetPoint("TOPLEFT", 16, yOffset)
    avgTipText:SetText("Average Tip: " .. LockSmith.Utils:FormatGold(avgTip))
    yOffset = yOffset - 20

    -- Last session gold
    local lastSessionText = scrollChild:CreateFontString("LockSmithLastSessionText", "ARTWORK", "GameFontNormal")
    lastSessionText:SetPoint("TOPLEFT", 16, yOffset)
    lastSessionText:SetText("Last Session: " .. LockSmith.Utils:FormatGold(LockSmithDB.stats.lastSessionGold))
    yOffset = yOffset - 30

    -- Refresh stats button
    local refreshStatsBtn = CreateFrame("Button", "LockSmithRefreshStatsBtn", scrollChild, "GameMenuButtonTemplate")
    refreshStatsBtn:SetPoint("TOPLEFT", 16, yOffset)
    refreshStatsBtn:SetSize(120, 25)
    refreshStatsBtn:SetText("Refresh Stats")
    refreshStatsBtn:SetScript("OnClick", function(self)
        _G["LockSmithTotalGoldText"]:SetText("Total Gold Earned: " .. LockSmith.Utils:FormatGold(LockSmithDB.stats.totalGold))
        _G["LockSmithTotalJobsText"]:SetText("Total Jobs Completed: " .. LockSmithDB.stats.totalJobs)

        local avg = LockSmith.Statistics:GetAverageTip()
        _G["LockSmithAvgTipText"]:SetText("Average Tip: " .. LockSmith.Utils:FormatGold(avg))
        _G["LockSmithLastSessionText"]:SetText("Last Session: " .. LockSmith.Utils:FormatGold(LockSmithDB.stats.lastSessionGold))
    end)
    yOffset = yOffset - 40

    -- Reset stats button
    local resetStatsBtn = CreateFrame("Button", "LockSmithResetStatsBtn", scrollChild, "GameMenuButtonTemplate")
    resetStatsBtn:SetPoint("TOPLEFT", 16, yOffset)
    resetStatsBtn:SetSize(120, 25)
    resetStatsBtn:SetText("Reset Stats")
    resetStatsBtn:SetScript("OnClick", function(self)
        LockSmith.Statistics:ResetStats()

        _G["LockSmithTotalGoldText"]:SetText("Total Gold Earned: 0c")
        _G["LockSmithTotalJobsText"]:SetText("Total Jobs Completed: 0")
        _G["LockSmithAvgTipText"]:SetText("Average Tip: 0c")
        _G["LockSmithLastSessionText"]:SetText("Last Session: 0c")

        print("|cff00ff00LockSmith:|r Statistics reset!")
    end)

    -- Register with interface options
    InterfaceOptions_AddCategory(panel)

    return panel
end

-- Open settings GUI
function LockSmith.UI:OpenSettingsGUI()
    -- Create settings panel if it doesn't exist
    if not _G["LockSmithSettingsPanel"] then
        CreateSettingsPanel()
    end

    -- Open interface options to our panel (call twice due to Blizzard bug)
    InterfaceOptionsFrame_OpenToCategory("LockSmith")
    InterfaceOptionsFrame_OpenToCategory("LockSmith")
end
