-- Settings.lua
-- Settings panel UI

LockSmith = LockSmith or {}
LockSmith.UI = LockSmith.UI or {}

local settingsCategory = nil
local settingsPanel = nil
local adMsgBox = nil
local lowSkillBox = nil
local thanksBox = nil
local boxStatLines = {}

local function GetDefaultMessage(key)
    local defaults = LockSmith.DefaultSettings
    if defaults and type(defaults[key]) == "string" then
        return defaults[key]
    end
    return ""
end

local function RefreshMessageFields()
    if not LockSmithDB then return end

    if adMsgBox then
        local msg = LockSmithDB.adMessage
        if type(msg) ~= "string" or msg == "" then
            msg = GetDefaultMessage("adMessage")
        end
        adMsgBox:SetText(msg)
        adMsgBox:SetCursorPosition(0)
        adMsgBox:HighlightText(0, 0)
    end

    if lowSkillBox then
        local msg = LockSmithDB.lowSkillMessage
        if type(msg) ~= "string" or msg == "" then
            msg = GetDefaultMessage("lowSkillMessage")
        end
        lowSkillBox:SetText(msg)
        lowSkillBox:SetCursorPosition(0)
        lowSkillBox:HighlightText(0, 0)
    end

    if thanksBox then
        local msg = LockSmithDB.thankYouMessage
        if type(msg) ~= "string" or msg == "" then
            msg = GetDefaultMessage("thankYouMessage")
        end
        thanksBox:SetText(msg)
        thanksBox:SetCursorPosition(0)
        thanksBox:HighlightText(0, 0)
    end
end

local function RefreshStats()
    if not LockSmithDB or not LockSmithDB.stats then return end

    -- Update main stat text elements
    if _G["LockSmithTotalGoldText"] then
        _G["LockSmithTotalGoldText"]:SetText("Total Gold Earned: " .. LockSmith.Utils:FormatGold(LockSmithDB.stats.totalGold))
    end
    if _G["LockSmithTotalJobsText"] then
        _G["LockSmithTotalJobsText"]:SetText("Total Jobs Completed: " .. LockSmithDB.stats.totalJobs)
    end
    if _G["LockSmithTotalBoxesText"] then
        _G["LockSmithTotalBoxesText"]:SetText("Total Boxes Opened: " .. (LockSmithDB.stats.totalBoxes or 0))
    end
    if _G["LockSmithAvgTipText"] then
        local avg = LockSmith.Statistics:GetAverageTip()
        _G["LockSmithAvgTipText"]:SetText("Average Tip: " .. LockSmith.Utils:FormatGold(avg))
    end
    if _G["LockSmithLastSessionText"] then
        _G["LockSmithLastSessionText"]:SetText("Last Session: " .. LockSmith.Utils:FormatGold(LockSmithDB.stats.lastSessionGold))
    end

    -- Update per-box stats (using boxStatLines from closure)
    local counts = LockSmithDB.stats.boxesOpened or {}
    if boxStatLines then
        for key, line in pairs(boxStatLines) do
            local data = LockSmith.BoxDatabase[key]
            local skill = data and data.skill or 0
            local label = (skill > 0 and (skill .. " - ") or "") .. (data and data.name or key)
            line:SetText(label .. ": " .. (counts[key] or 0))
        end
    end
end

local function CreateSettingsPanel()
    -- Main settings frame
    local panel = CreateFrame("Frame", "LockSmithSettingsPanel", UIParent)
    panel.name = "LockSmith"
    settingsPanel = panel
    panel:SetScript("OnShow", RefreshMessageFields)

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
    yOffset = yOffset - 25

    -- Sound effects checkbox
    local soundCheckbox = CreateFrame("CheckButton", "LockSmithSoundCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    soundCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[soundCheckbox:GetName() .. "Text"]:SetText("Play Sound Effects")
    soundCheckbox:SetChecked(LockSmithDB.playSoundEffects)
    soundCheckbox:SetScript("OnClick", function(self)
        LockSmithDB.playSoundEffects = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Auto-mark self with star checkbox
    local autoMarkSelfCheckbox = CreateFrame("CheckButton", "LockSmithAutoMarkSelfCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    autoMarkSelfCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[autoMarkSelfCheckbox:GetName() .. "Text"]:SetText("Auto-mark Self with Star (Party Leader)")
    autoMarkSelfCheckbox:SetChecked(LockSmithDB.autoMarkSelf)
    autoMarkSelfCheckbox:SetScript("OnClick", function(self)
        LockSmithDB.autoMarkSelf = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Auto-mark customers checkbox
    local autoMarkCustomersCheckbox = CreateFrame("CheckButton", "LockSmithAutoMarkCustomersCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    autoMarkCustomersCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[autoMarkCustomersCheckbox:GetName() .. "Text"]:SetText("Auto-mark Customers with Raid Icons")
    autoMarkCustomersCheckbox:SetChecked(LockSmithDB.autoMarkCustomers)
    autoMarkCustomersCheckbox:SetScript("OnClick", function(self)
        LockSmithDB.autoMarkCustomers = self:GetChecked()
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
    adMsgBox = CreateFrame("EditBox", "LockSmithAdMsgBox", scrollChild, "InputBoxTemplate")
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
    yOffset = yOffset - 35

    -- Icon helper text for ad message
    local adIconHelp = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    adIconHelp:SetPoint("TOPLEFT", 16, yOffset)
    adIconHelp:SetWidth(450)
    adIconHelp:SetJustifyH("LEFT")
    adIconHelp:SetText("|cff888888Available icons: {rt1} {rt2} {rt3} {rt4} {rt5} {rt6} {rt7} {rt8} {skull} {circle} {diamond} {triangle} {moon} {square} {cross} {star} ♥|r")
    yOffset = yOffset - 25

    -- Set default ad message
    local adDefaultBtn = CreateFrame("Button", "LockSmithAdDefaultBtn", scrollChild, "GameMenuButtonTemplate")
    adDefaultBtn:SetPoint("TOPLEFT", 16, yOffset)
    adDefaultBtn:SetSize(120, 25)
    adDefaultBtn:SetText("Set Default")
    adDefaultBtn:SetScript("OnClick", function()
        if not LockSmithDB then return end

        local defaultMsg = LockSmith.DefaultSettings and LockSmith.DefaultSettings.adMessage
        if type(defaultMsg) ~= "string" or defaultMsg == "" then
            return
        end

        LockSmithDB.adMessage = defaultMsg
        adMsgBox:SetText(defaultMsg)
        adMsgBox:ClearFocus()
    end)
    yOffset = yOffset - 35

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
    yOffset = yOffset - 25

    -- Yell ad channel checkbox
    local adYellCheck = CreateFrame("CheckButton", "LockSmithAdYellCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    adYellCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[adYellCheck:GetName() .. "Text"]:SetText("Yell")
    adYellCheck:SetChecked(LockSmithDB.adChannels.yell)
    adYellCheck:SetScript("OnClick", function(self)
        LockSmithDB.adChannels.yell = self:GetChecked()
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

    -- Auto-invite on whisper
    local autoInviteCheck = CreateFrame("CheckButton", "LockSmithAutoInviteCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    autoInviteCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[autoInviteCheck:GetName() .. "Text"]:SetText("Auto-invite whisper senders")
    autoInviteCheck:SetChecked(LockSmithDB.autoInviteWhisper)
    autoInviteCheck:SetScript("OnClick", function(self)
        LockSmithDB.autoInviteWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Popup on any whisper
    local popupWhisperCheck = CreateFrame("CheckButton", "LockSmithPopupWhisperCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    popupWhisperCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[popupWhisperCheck:GetName() .. "Text"]:SetText("Popup on any whisper (even without keywords)")
    popupWhisperCheck:SetChecked(LockSmithDB.popupOnAnyWhisper)
    popupWhisperCheck:SetScript("OnClick", function(self)
        LockSmithDB.popupOnAnyWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

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
    lowSkillBox = CreateFrame("EditBox", "LockSmithLowSkillBox", scrollChild, "InputBoxTemplate")
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
    yOffset = yOffset - 35

    -- Set default low skill message
    local lowSkillDefaultBtn = CreateFrame("Button", "LockSmithLowSkillDefaultBtn", scrollChild, "GameMenuButtonTemplate")
    lowSkillDefaultBtn:SetPoint("TOPLEFT", 16, yOffset)
    lowSkillDefaultBtn:SetSize(120, 25)
    lowSkillDefaultBtn:SetText("Set Default")
    lowSkillDefaultBtn:SetScript("OnClick", function()
        if not LockSmithDB then return end

        local defaultMsg = LockSmith.DefaultSettings and LockSmith.DefaultSettings.lowSkillMessage
        if type(defaultMsg) ~= "string" or defaultMsg == "" then
            return
        end

        LockSmithDB.lowSkillMessage = defaultMsg
        lowSkillBox:SetText(defaultMsg)
        lowSkillBox:ClearFocus()
    end)
    yOffset = yOffset - 35

    -- Thank-you whisper checkbox
    local thankYouCheck = CreateFrame("CheckButton", "LockSmithThankYouCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    thankYouCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[thankYouCheck:GetName() .. "Text"]:SetText("Whisper after receiving a tip")
    thankYouCheck:SetChecked(LockSmithDB.thankYouWhisper)
    thankYouCheck:SetScript("OnClick", function(self)
        LockSmithDB.thankYouWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Thank-you message label
    local thankYouLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    thankYouLabel:SetPoint("TOPLEFT", 16, yOffset)
    thankYouLabel:SetText("Thank-you Message (use %TIP%):")
    yOffset = yOffset - 20

    -- Thank-you message editbox
    thanksBox = CreateFrame("EditBox", "LockSmithThankYouBox", scrollChild, "InputBoxTemplate")
    thanksBox:SetPoint("TOPLEFT", 16, yOffset)
    thanksBox:SetSize(450, 30)
    thanksBox:SetText(LockSmithDB.thankYouMessage)
    thanksBox:SetAutoFocus(false)
    thanksBox:SetScript("OnTextChanged", function(self)
        LockSmithDB.thankYouMessage = self:GetText()
    end)
    thanksBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    yOffset = yOffset - 35

    -- Icon helper text for thank-you message
    local thankYouIconHelp = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    thankYouIconHelp:SetPoint("TOPLEFT", 16, yOffset)
    thankYouIconHelp:SetWidth(450)
    thankYouIconHelp:SetJustifyH("LEFT")
    thankYouIconHelp:SetText("|cff888888Available icons: {rt1} {rt2} {rt3} {rt4} {rt5} {rt6} {rt7} {rt8} {skull} {circle} {diamond} {triangle} {moon} {square} {cross} {star} ♥|r")
    yOffset = yOffset - 25

    -- Set default thank-you message
    local thankYouDefaultBtn = CreateFrame("Button", "LockSmithThankYouDefaultBtn", scrollChild, "GameMenuButtonTemplate")
    thankYouDefaultBtn:SetPoint("TOPLEFT", 16, yOffset)
    thankYouDefaultBtn:SetSize(120, 25)
    thankYouDefaultBtn:SetText("Set Default")
    thankYouDefaultBtn:SetScript("OnClick", function()
        if not LockSmithDB then return end

        local defaultMsg = LockSmith.DefaultSettings and LockSmith.DefaultSettings.thankYouMessage
        if type(defaultMsg) ~= "string" or defaultMsg == "" then
            return
        end

        LockSmithDB.thankYouMessage = defaultMsg
        thanksBox:SetText(defaultMsg)
        thanksBox:ClearFocus()
    end)
    yOffset = yOffset - 35

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

    -- Total boxes opened
    local totalBoxesText = scrollChild:CreateFontString("LockSmithTotalBoxesText", "ARTWORK", "GameFontNormal")
    totalBoxesText:SetPoint("TOPLEFT", 16, yOffset)
    totalBoxesText:SetText("Total Boxes Opened: " .. (LockSmithDB.stats.totalBoxes or 0))
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

    -- Per-box stats
    local boxStatsHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    boxStatsHeader:SetPoint("TOPLEFT", 16, yOffset)
    boxStatsHeader:SetText("|cff00ff00Boxes Opened (by type)|r")
    yOffset = yOffset - 18

    boxStatLines = {}  -- Reset the module-level table
    local boxKeys = {}
    for key, data in pairs(LockSmith.BoxDatabase) do
        table.insert(boxKeys, key)
    end
    table.sort(boxKeys, function(a, b)
        local dataA = LockSmith.BoxDatabase[a]
        local dataB = LockSmith.BoxDatabase[b]
        local skillA = dataA and dataA.skill or 0
        local skillB = dataB and dataB.skill or 0
        if skillA ~= skillB then
            return skillA > skillB
        end
        local nameA = dataA and dataA.name or a
        local nameB = dataB and dataB.name or b
        return nameA < nameB
    end)

    for _, key in ipairs(boxKeys) do
        local data = LockSmith.BoxDatabase[key]
        local line = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        line:SetPoint("TOPLEFT", 24, yOffset)
        local count = (LockSmithDB.stats.boxesOpened and LockSmithDB.stats.boxesOpened[key]) or 0
        local skill = data and data.skill or 0
        local label = (skill > 0 and (skill .. " - ") or "") .. (data and data.name or key)
        line:SetText(label .. ": " .. count)
        boxStatLines[key] = line
        yOffset = yOffset - 15
    end
    yOffset = yOffset - 12

    -- Reset stats button
    local resetStatsBtn = CreateFrame("Button", "LockSmithResetStatsBtn", scrollChild, "GameMenuButtonTemplate")
    resetStatsBtn:SetPoint("TOPLEFT", 16, yOffset)
    resetStatsBtn:SetSize(120, 25)
    resetStatsBtn:SetText("Reset Stats")
    resetStatsBtn:SetScript("OnClick", function(self)
        LockSmith.Statistics:ResetStats()

        _G["LockSmithTotalGoldText"]:SetText("Total Gold Earned: 0c")
        _G["LockSmithTotalJobsText"]:SetText("Total Jobs Completed: 0")
        _G["LockSmithTotalBoxesText"]:SetText("Total Boxes Opened: 0")
        _G["LockSmithAvgTipText"]:SetText("Average Tip: 0c")
        _G["LockSmithLastSessionText"]:SetText("Last Session: 0c")

        for key, line in pairs(boxStatLines) do
            local data = LockSmith.BoxDatabase[key]
            local name = data and data.name or key
            line:SetText(name .. ": 0")
        end

        print("|cff00ff00LockSmith:|r Statistics reset!")
    end)

    -- Register with interface options (compat for old/new APIs)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        if not settingsCategory then
            settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
            Settings.RegisterAddOnCategory(settingsCategory)
        end
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    RefreshMessageFields()

    return panel
end

-- Open settings GUI
function LockSmith.UI:OpenSettingsGUI()
    -- Create settings panel if it doesn't exist
    if not _G["LockSmithSettingsPanel"] then
        CreateSettingsPanel()
    end

    RefreshMessageFields()
    RefreshStats()  -- Auto-refresh statistics when panel opens

    -- Open interface options to our panel (call twice due to Blizzard bug on legacy UI)
    if Settings and Settings.OpenToCategory and settingsCategory then
        Settings.OpenToCategory(settingsCategory)
    elseif InterfaceOptionsFrame_OpenToCategory and settingsPanel then
        -- Call twice - Blizzard bug requires this to actually open to the addon
        InterfaceOptionsFrame_OpenToCategory(settingsPanel)
        InterfaceOptionsFrame_OpenToCategory(settingsPanel)
    end
end
