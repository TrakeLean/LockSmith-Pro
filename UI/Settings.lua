-- Settings.lua
-- Settings panel UI

LockSmithPro = LockSmithPro or {}
LockSmithPro.UI = LockSmithPro.UI or {}

local settingsCategory = nil
local settingsPanel = nil
local adMsgBox = nil
local lowSkillBox = nil
local thanksBox = nil
local boxStatLines = {}

local function GetDefaultMessage(key)
    local defaults = LockSmithPro.DefaultSettings
    if defaults and type(defaults[key]) == "string" then
        return defaults[key]
    end
    return ""
end

local function RefreshMessageFields()
    if not LockSmithProDB then return end

    if adMsgBox then
        local msg = LockSmithProDB.adMessage
        if type(msg) ~= "string" or msg == "" then
            msg = GetDefaultMessage("adMessage")
        end
        adMsgBox:SetText(msg)
        adMsgBox:SetCursorPosition(0)
        adMsgBox:HighlightText(0, 0)
    end

    if lowSkillBox then
        local msg = LockSmithProDB.lowSkillMessage
        if type(msg) ~= "string" or msg == "" then
            msg = GetDefaultMessage("lowSkillMessage")
        end
        lowSkillBox:SetText(msg)
        lowSkillBox:SetCursorPosition(0)
        lowSkillBox:HighlightText(0, 0)
    end

    if thanksBox then
        local msg = LockSmithProDB.thankYouMessage
        if type(msg) ~= "string" or msg == "" then
            msg = GetDefaultMessage("thankYouMessage")
        end
        thanksBox:SetText(msg)
        thanksBox:SetCursorPosition(0)
        thanksBox:HighlightText(0, 0)
    end
end

local function RefreshStats()
    if not LockSmithProDB or not LockSmithProDB.stats then return end

    -- Update main stat text elements
    if _G["LockSmithProTotalGoldText"] then
        _G["LockSmithProTotalGoldText"]:SetText("Total Gold Earned: " .. LockSmithPro.Utils:FormatGold(LockSmithProDB.stats.totalGold))
    end
    if _G["LockSmithProTotalJobsText"] then
        _G["LockSmithProTotalJobsText"]:SetText("Total Jobs Completed: " .. LockSmithProDB.stats.totalJobs)
    end
    if _G["LockSmithProTotalBoxesText"] then
        _G["LockSmithProTotalBoxesText"]:SetText("Total Boxes Opened: " .. (LockSmithProDB.stats.totalBoxes or 0))
    end
    if _G["LockSmithProAvgTipText"] then
        local avg = LockSmithPro.Statistics:GetAverageTip()
        _G["LockSmithProAvgTipText"]:SetText("Average Tip: " .. LockSmithPro.Utils:FormatGold(avg))
    end
    if _G["LockSmithProLastSessionText"] then
        _G["LockSmithProLastSessionText"]:SetText("Last Session: " .. LockSmithPro.Utils:FormatGold(LockSmithProDB.stats.lastSessionGold))
    end

    -- Update per-box stats (using boxStatLines from closure)
    local counts = LockSmithProDB.stats.boxesOpened or {}
    if boxStatLines then
        for key, line in pairs(boxStatLines) do
            local data = LockSmithPro.BoxDatabase[key]
            local skill = data and data.skill or 0
            local label = (skill > 0 and (skill .. " - ") or "") .. (data and data.name or key)
            line:SetText(label .. ": " .. (counts[key] or 0))
        end
    end
end

local function CreateSettingsPanel()
    -- Main settings frame
    local panel = CreateFrame("Frame", "LockSmithProSettingsPanel", UIParent)
    panel.name = "LockSmithPro"
    settingsPanel = panel
    panel:SetScript("OnShow", RefreshMessageFields)

    -- Scroll frame for settings
    local scrollFrame = CreateFrame("ScrollFrame", "LockSmithProScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", "LockSmithProScrollChild", scrollFrame)
    scrollChild:SetSize(580, 1200)
    scrollFrame:SetScrollChild(scrollChild)

    local yOffset = -10

    -- Title
    local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, yOffset)
    title:SetText("LockSmithPro - Lockpicking Service Addon")
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
    local startStopBtn = CreateFrame("Button", "LockSmithProStartStopBtn", scrollChild, "GameMenuButtonTemplate")
    startStopBtn:SetPoint("TOPLEFT", 16, yOffset)
    startStopBtn:SetSize(120, 25)
    startStopBtn:SetText(LockSmithPro:IsRunning() and "Stop" or "Start")
    startStopBtn:SetScript("OnClick", function(self)
        LockSmithPro:Toggle()
        self:SetText(LockSmithPro:IsRunning() and "Stop" or "Start")

        -- Update status text
        local statusText = _G["LockSmithProStatusText"]
        if statusText then
            if LockSmithPro:IsRunning() then
                local skill, maxSkill = LockSmithPro.Skills:GetLockpickingSkill()
                statusText:SetText("|cff00ff00Status: Running|r (Skill: " .. skill .. "/" .. maxSkill .. ")")
            else
                statusText:SetText("|cffff0000Status: Stopped|r")
            end
        end
    end)
    yOffset = yOffset - 35

    -- Status text
    local statusText = scrollChild:CreateFontString("LockSmithProStatusText", "ARTWORK", "GameFontNormal")
    statusText:SetPoint("TOPLEFT", 16, yOffset)
    if LockSmithPro:IsRunning() then
        local skill, maxSkill = LockSmithPro.Skills:GetLockpickingSkill()
        statusText:SetText("|cff00ff00Status: Running|r (Skill: " .. skill .. "/" .. maxSkill .. ")")
    else
        statusText:SetText("|cffff0000Status: Stopped|r")
    end
    yOffset = yOffset - 25

    local statusNote = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    statusNote:SetPoint("TOPLEFT", 16, yOffset)
    statusNote:SetText("Note: You can use /LockSmithPro start or /LockSmithPro stop")
    yOffset = yOffset - 30

    -- ================================
    -- Channel Monitoring Section
    -- ================================

    local channelHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    channelHeader:SetPoint("TOPLEFT", 16, yOffset)
    channelHeader:SetText("|cff00ff00Channel Monitoring|r")
    yOffset = yOffset - 20

    -- Trade channel checkbox
    local tradeCheckbox = CreateFrame("CheckButton", "LockSmithProTradeCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    tradeCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[tradeCheckbox:GetName() .. "Text"]:SetText("Monitor Trade Channel")
    tradeCheckbox:SetChecked(LockSmithProDB.monitorTrade)
    tradeCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.monitorTrade = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- General channel checkbox
    local generalCheckbox = CreateFrame("CheckButton", "LockSmithProGeneralCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    generalCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[generalCheckbox:GetName() .. "Text"]:SetText("Monitor General Channel")
    generalCheckbox:SetChecked(LockSmithProDB.monitorGeneral)
    generalCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.monitorGeneral = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- LFG channel checkbox
    local lfgCheckbox = CreateFrame("CheckButton", "LockSmithProLFGCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    lfgCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[lfgCheckbox:GetName() .. "Text"]:SetText("Monitor LookingForGroup Channel")
    lfgCheckbox:SetChecked(LockSmithProDB.monitorLFG)
    lfgCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.monitorLFG = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Whisper channel checkbox
    local whisperCheckbox = CreateFrame("CheckButton", "LockSmithProWhisperCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    whisperCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[whisperCheckbox:GetName() .. "Text"]:SetText("Monitor Whispers")
    whisperCheckbox:SetChecked(LockSmithProDB.monitorWhisper)
    whisperCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.monitorWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Sound effects checkbox
    local soundCheckbox = CreateFrame("CheckButton", "LockSmithProSoundCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    soundCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[soundCheckbox:GetName() .. "Text"]:SetText("Play Sound Effects")
    soundCheckbox:SetChecked(LockSmithProDB.playSoundEffects)
    soundCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.playSoundEffects = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Debug chat checkbox
    local debugChatCheckbox = CreateFrame("CheckButton", "LockSmithProDebugChatCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    debugChatCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[debugChatCheckbox:GetName() .. "Text"]:SetText("Show Debug Logs in Chat")
    debugChatCheckbox:SetChecked(LockSmithProDB.debugChat == true)
    debugChatCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.debugChat = self:GetChecked() == true
    end)
    yOffset = yOffset - 25

    -- Auto-mark self with star checkbox
    local autoMarkSelfCheckbox = CreateFrame("CheckButton", "LockSmithProAutoMarkSelfCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    autoMarkSelfCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[autoMarkSelfCheckbox:GetName() .. "Text"]:SetText("Auto-mark Self with Star (Party Leader)")
    autoMarkSelfCheckbox:SetChecked(LockSmithProDB.autoMarkSelf)
    autoMarkSelfCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.autoMarkSelf = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Auto-mark customers checkbox
    local autoMarkCustomersCheckbox = CreateFrame("CheckButton", "LockSmithProAutoMarkCustomersCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    autoMarkCustomersCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[autoMarkCustomersCheckbox:GetName() .. "Text"]:SetText("Auto-mark Customers with Raid Icons")
    autoMarkCustomersCheckbox:SetChecked(LockSmithProDB.autoMarkCustomers)
    autoMarkCustomersCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.autoMarkCustomers = self:GetChecked()
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
    adMsgBox = CreateFrame("EditBox", "LockSmithProAdMsgBox", scrollChild, "InputBoxTemplate")
    adMsgBox:SetPoint("TOPLEFT", 16, yOffset)
    adMsgBox:SetSize(450, 30)
    adMsgBox:SetText(LockSmithProDB.adMessage)
    adMsgBox:SetAutoFocus(false)
    adMsgBox:SetScript("OnTextChanged", function(self)
        LockSmithProDB.adMessage = self:GetText()
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
    adIconHelp:SetText("|cff888888Available icons: {rt1} {rt2} {rt3} {rt4} {rt5} {rt6} {rt7} {rt8} {skull} {circle} {diamond} {triangle} {moon} {square} {cross} {star} <3|r")
    yOffset = yOffset - 25

    -- Set default ad message
    local adDefaultBtn = CreateFrame("Button", "LockSmithProAdDefaultBtn", scrollChild, "GameMenuButtonTemplate")
    adDefaultBtn:SetPoint("TOPLEFT", 16, yOffset)
    adDefaultBtn:SetSize(120, 25)
    adDefaultBtn:SetText("Set Default")
    adDefaultBtn:SetScript("OnClick", function()
        if not LockSmithProDB then return end

        local defaultMsg = LockSmithPro.DefaultSettings and LockSmithPro.DefaultSettings.adMessage
        if type(defaultMsg) ~= "string" or defaultMsg == "" then
            return
        end

        LockSmithProDB.adMessage = defaultMsg
        adMsgBox:SetText(defaultMsg)
        adMsgBox:ClearFocus()
    end)
    yOffset = yOffset - 35

    -- Manual send button
    local sendAdBtn = CreateFrame("Button", "LockSmithProSendAdBtn", scrollChild, "GameMenuButtonTemplate")
    sendAdBtn:SetPoint("TOPLEFT", 16, yOffset)
    sendAdBtn:SetSize(150, 25)
    sendAdBtn:SetText("Send Advertisement")
    sendAdBtn:SetScript("OnClick", function(self)
        LockSmithPro.Advertisement:SendAdvertisement()
    end)
    yOffset = yOffset - 35

    -- Ad channels label
    local adChannelLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    adChannelLabel:SetPoint("TOPLEFT", 16, yOffset)
    adChannelLabel:SetText("Send Advertisements To:")
    yOffset = yOffset - 20

    -- Trade ad channel checkbox
    local adTradeCheck = CreateFrame("CheckButton", "LockSmithProAdTradeCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    adTradeCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[adTradeCheck:GetName() .. "Text"]:SetText("Trade Channel")
    adTradeCheck:SetChecked(LockSmithProDB.adChannels.trade)
    adTradeCheck:SetScript("OnClick", function(self)
        LockSmithProDB.adChannels.trade = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- General ad channel checkbox
    local adGeneralCheck = CreateFrame("CheckButton", "LockSmithProAdGeneralCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    adGeneralCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[adGeneralCheck:GetName() .. "Text"]:SetText("General Channel")
    adGeneralCheck:SetChecked(LockSmithProDB.adChannels.general)
    adGeneralCheck:SetScript("OnClick", function(self)
        LockSmithProDB.adChannels.general = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- LFG ad channel checkbox
    local adLFGCheck = CreateFrame("CheckButton", "LockSmithProAdLFGCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    adLFGCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[adLFGCheck:GetName() .. "Text"]:SetText("LookingForGroup Channel")
    adLFGCheck:SetChecked(LockSmithProDB.adChannels.lfg)
    adLFGCheck:SetScript("OnClick", function(self)
        LockSmithProDB.adChannels.lfg = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Yell ad channel checkbox
    local adYellCheck = CreateFrame("CheckButton", "LockSmithProAdYellCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    adYellCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[adYellCheck:GetName() .. "Text"]:SetText("Yell")
    adYellCheck:SetChecked(LockSmithProDB.adChannels.yell)
    adYellCheck:SetScript("OnClick", function(self)
        LockSmithProDB.adChannels.yell = self:GetChecked()
    end)
    yOffset = yOffset - 35

    -- Timer enabled checkbox
    local timerCheckbox = CreateFrame("CheckButton", "LockSmithProTimerCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    timerCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    _G[timerCheckbox:GetName() .. "Text"]:SetText("Enable Auto-Advertisement Timer")
    timerCheckbox:SetChecked(LockSmithProDB.adTimerEnabled)
    timerCheckbox:SetScript("OnClick", function(self)
        LockSmithProDB.adTimerEnabled = self:GetChecked()
        if self:GetChecked() and LockSmithPro:IsRunning() then
            LockSmithPro.Advertisement:StartAdTimer()
        else
            LockSmithPro.Advertisement:StopAdTimer()
        end
    end)
    yOffset = yOffset - 30

    -- Timer interval slider
    local timerSlider = CreateFrame("Slider", "LockSmithProTimerSlider", scrollChild, "OptionsSliderTemplate")
    timerSlider:SetPoint("TOPLEFT", 16, yOffset)
    timerSlider:SetMinMaxValues(30, 600)
    timerSlider:SetValue(LockSmithProDB.adTimerInterval or 60)
    timerSlider:SetValueStep(30)
    timerSlider:SetObeyStepOnDrag(true)
    _G[timerSlider:GetName() .. "Low"]:SetText("30s")
    _G[timerSlider:GetName() .. "High"]:SetText("10m")
    _G[timerSlider:GetName() .. "Text"]:SetText("Timer Interval: " .. (LockSmithProDB.adTimerInterval or 60) .. "s")
    timerSlider:SetScript("OnValueChanged", function(self, value)
        LockSmithProDB.adTimerInterval = value
        _G[self:GetName() .. "Text"]:SetText("Timer Interval: " .. value .. "s")
        if LockSmithProDB.adTimerEnabled and LockSmithPro:IsRunning() then
            LockSmithPro.Advertisement:StartAdTimer()
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
    local autoInviteCheck = CreateFrame("CheckButton", "LockSmithProAutoInviteCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    autoInviteCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[autoInviteCheck:GetName() .. "Text"]:SetText("Auto-invite whisper senders")
    autoInviteCheck:SetChecked(LockSmithProDB.autoInviteWhisper)
    autoInviteCheck:SetScript("OnClick", function(self)
        LockSmithProDB.autoInviteWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Popup on any whisper
    local popupWhisperCheck = CreateFrame("CheckButton", "LockSmithProPopupWhisperCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    popupWhisperCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[popupWhisperCheck:GetName() .. "Text"]:SetText("Popup on any whisper (even without keywords)")
    popupWhisperCheck:SetChecked(LockSmithProDB.popupOnAnyWhisper)
    popupWhisperCheck:SetScript("OnClick", function(self)
        LockSmithProDB.popupOnAnyWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Low skill whisper checkbox
    local lowSkillCheck = CreateFrame("CheckButton", "LockSmithProLowSkillCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    lowSkillCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[lowSkillCheck:GetName() .. "Text"]:SetText("Whisper when skill is too low")
    lowSkillCheck:SetChecked(LockSmithProDB.lowSkillWhisper)
    lowSkillCheck:SetScript("OnClick", function(self)
        LockSmithProDB.lowSkillWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Low skill message label
    local lowSkillLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lowSkillLabel:SetPoint("TOPLEFT", 16, yOffset)
    lowSkillLabel:SetText("Low Skill Message (use %CURRENT% and %REQUIRED%):")
    yOffset = yOffset - 20

    -- Low skill message editbox
    lowSkillBox = CreateFrame("EditBox", "LockSmithProLowSkillBox", scrollChild, "InputBoxTemplate")
    lowSkillBox:SetPoint("TOPLEFT", 16, yOffset)
    lowSkillBox:SetSize(450, 30)
    lowSkillBox:SetText(LockSmithProDB.lowSkillMessage)
    lowSkillBox:SetAutoFocus(false)
    lowSkillBox:SetScript("OnTextChanged", function(self)
        LockSmithProDB.lowSkillMessage = self:GetText()
    end)
    lowSkillBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    yOffset = yOffset - 35

    -- Set default low skill message
    local lowSkillDefaultBtn = CreateFrame("Button", "LockSmithProLowSkillDefaultBtn", scrollChild, "GameMenuButtonTemplate")
    lowSkillDefaultBtn:SetPoint("TOPLEFT", 16, yOffset)
    lowSkillDefaultBtn:SetSize(120, 25)
    lowSkillDefaultBtn:SetText("Set Default")
    lowSkillDefaultBtn:SetScript("OnClick", function()
        if not LockSmithProDB then return end

        local defaultMsg = LockSmithPro.DefaultSettings and LockSmithPro.DefaultSettings.lowSkillMessage
        if type(defaultMsg) ~= "string" or defaultMsg == "" then
            return
        end

        LockSmithProDB.lowSkillMessage = defaultMsg
        lowSkillBox:SetText(defaultMsg)
        lowSkillBox:ClearFocus()
    end)
    yOffset = yOffset - 35

    -- Thank-you whisper checkbox
    local thankYouCheck = CreateFrame("CheckButton", "LockSmithProThankYouCheck", scrollChild, "ChatConfigCheckButtonTemplate")
    thankYouCheck:SetPoint("TOPLEFT", 16, yOffset)
    _G[thankYouCheck:GetName() .. "Text"]:SetText("Whisper after receiving a tip")
    thankYouCheck:SetChecked(LockSmithProDB.thankYouWhisper)
    thankYouCheck:SetScript("OnClick", function(self)
        LockSmithProDB.thankYouWhisper = self:GetChecked()
    end)
    yOffset = yOffset - 25

    -- Thank-you message label
    local thankYouLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    thankYouLabel:SetPoint("TOPLEFT", 16, yOffset)
    thankYouLabel:SetText("Thank-you Message (use %TIP%):")
    yOffset = yOffset - 20

    -- Thank-you message editbox
    thanksBox = CreateFrame("EditBox", "LockSmithProThankYouBox", scrollChild, "InputBoxTemplate")
    thanksBox:SetPoint("TOPLEFT", 16, yOffset)
    thanksBox:SetSize(450, 30)
    thanksBox:SetText(LockSmithProDB.thankYouMessage)
    thanksBox:SetAutoFocus(false)
    thanksBox:SetScript("OnTextChanged", function(self)
        LockSmithProDB.thankYouMessage = self:GetText()
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
    thankYouIconHelp:SetText("|cff888888Available icons: {rt1} {rt2} {rt3} {rt4} {rt5} {rt6} {rt7} {rt8} {skull} {circle} {diamond} {triangle} {moon} {square} {cross} {star} <3|r")
    yOffset = yOffset - 25

    -- Set default thank-you message
    local thankYouDefaultBtn = CreateFrame("Button", "LockSmithProThankYouDefaultBtn", scrollChild, "GameMenuButtonTemplate")
    thankYouDefaultBtn:SetPoint("TOPLEFT", 16, yOffset)
    thankYouDefaultBtn:SetSize(120, 25)
    thankYouDefaultBtn:SetText("Set Default")
    thankYouDefaultBtn:SetScript("OnClick", function()
        if not LockSmithProDB then return end

        local defaultMsg = LockSmithPro.DefaultSettings and LockSmithPro.DefaultSettings.thankYouMessage
        if type(defaultMsg) ~= "string" or defaultMsg == "" then
            return
        end

        LockSmithProDB.thankYouMessage = defaultMsg
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
    local totalGoldText = scrollChild:CreateFontString("LockSmithProTotalGoldText", "ARTWORK", "GameFontNormal")
    totalGoldText:SetPoint("TOPLEFT", 16, yOffset)
    totalGoldText:SetText("Total Gold Earned: " .. LockSmithPro.Utils:FormatGold(LockSmithProDB.stats.totalGold))
    yOffset = yOffset - 20

    -- Total jobs
    local totalJobsText = scrollChild:CreateFontString("LockSmithProTotalJobsText", "ARTWORK", "GameFontNormal")
    totalJobsText:SetPoint("TOPLEFT", 16, yOffset)
    totalJobsText:SetText("Total Jobs Completed: " .. LockSmithProDB.stats.totalJobs)
    yOffset = yOffset - 20

    -- Total boxes opened
    local totalBoxesText = scrollChild:CreateFontString("LockSmithProTotalBoxesText", "ARTWORK", "GameFontNormal")
    totalBoxesText:SetPoint("TOPLEFT", 16, yOffset)
    totalBoxesText:SetText("Total Boxes Opened: " .. (LockSmithProDB.stats.totalBoxes or 0))
    yOffset = yOffset - 20

    -- Average tip
    local avgTip = LockSmithPro.Statistics:GetAverageTip()
    local avgTipText = scrollChild:CreateFontString("LockSmithProAvgTipText", "ARTWORK", "GameFontNormal")
    avgTipText:SetPoint("TOPLEFT", 16, yOffset)
    avgTipText:SetText("Average Tip: " .. LockSmithPro.Utils:FormatGold(avgTip))
    yOffset = yOffset - 20

    -- Last session gold
    local lastSessionText = scrollChild:CreateFontString("LockSmithProLastSessionText", "ARTWORK", "GameFontNormal")
    lastSessionText:SetPoint("TOPLEFT", 16, yOffset)
    lastSessionText:SetText("Last Session: " .. LockSmithPro.Utils:FormatGold(LockSmithProDB.stats.lastSessionGold))
    yOffset = yOffset - 30

    -- Per-box stats
    local boxStatsHeader = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    boxStatsHeader:SetPoint("TOPLEFT", 16, yOffset)
    boxStatsHeader:SetText("|cff00ff00Boxes Opened (by type)|r")
    yOffset = yOffset - 18

    boxStatLines = {}  -- Reset the module-level table
    local boxKeys = {}
    for key, data in pairs(LockSmithPro.BoxDatabase) do
        table.insert(boxKeys, key)
    end
    table.sort(boxKeys, function(a, b)
        local dataA = LockSmithPro.BoxDatabase[a]
        local dataB = LockSmithPro.BoxDatabase[b]
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
        local data = LockSmithPro.BoxDatabase[key]
        local line = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        line:SetPoint("TOPLEFT", 24, yOffset)
        local count = (LockSmithProDB.stats.boxesOpened and LockSmithProDB.stats.boxesOpened[key]) or 0
        local skill = data and data.skill or 0
        local label = (skill > 0 and (skill .. " - ") or "") .. (data and data.name or key)
        line:SetText(label .. ": " .. count)
        boxStatLines[key] = line
        yOffset = yOffset - 15
    end
    yOffset = yOffset - 12

    -- Reset stats button
    local resetStatsBtn = CreateFrame("Button", "LockSmithProResetStatsBtn", scrollChild, "GameMenuButtonTemplate")
    resetStatsBtn:SetPoint("TOPLEFT", 16, yOffset)
    resetStatsBtn:SetSize(120, 25)
    resetStatsBtn:SetText("Reset Stats")
    resetStatsBtn:SetScript("OnClick", function(self)
        LockSmithPro.Statistics:ResetStats()

        _G["LockSmithProTotalGoldText"]:SetText("Total Gold Earned: 0c")
        _G["LockSmithProTotalJobsText"]:SetText("Total Jobs Completed: 0")
        _G["LockSmithProTotalBoxesText"]:SetText("Total Boxes Opened: 0")
        _G["LockSmithProAvgTipText"]:SetText("Average Tip: 0c")
        _G["LockSmithProLastSessionText"]:SetText("Last Session: 0c")

        for key, line in pairs(boxStatLines) do
            local data = LockSmithPro.BoxDatabase[key]
            local name = data and data.name or key
            line:SetText(name .. ": 0")
        end

        print("|cff00ff00LockSmithPro:|r Statistics reset!")
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
function LockSmithPro.UI:OpenSettingsGUI()
    -- Create settings panel if it doesn't exist
    if not _G["LockSmithProSettingsPanel"] then
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

-- Ensure Blizzard Settings/AddOns registration exists on login
function LockSmithPro.UI:EnsureSettingsPanelRegistered()
    if not _G["LockSmithProSettingsPanel"] then
        CreateSettingsPanel()
    end
end
