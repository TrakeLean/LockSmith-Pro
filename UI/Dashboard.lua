-- Dashboard.lua
-- Main persistent UI window for LockSmith

LockSmith = LockSmith or {}
LockSmith.Dashboard = {}

local mainFrame = nil
local currentTab = "jobboard"

-- Default window settings
local DEFAULT_WIDTH = 400
local DEFAULT_HEIGHT = 600
local MIN_WIDTH = 350
local MIN_HEIGHT = 400

-- ================================
-- Helper Functions
-- ================================

local function SaveWindowPosition()
    if not mainFrame then return end

    local point, _, relativePoint, xOfs, yOfs = mainFrame:GetPoint()
    LockSmithDB.dashboard = LockSmithDB.dashboard or {}
    LockSmithDB.dashboard.point = point
    LockSmithDB.dashboard.relativePoint = relativePoint
    LockSmithDB.dashboard.x = xOfs
    LockSmithDB.dashboard.y = yOfs
    LockSmithDB.dashboard.width = mainFrame:GetWidth()
    LockSmithDB.dashboard.height = mainFrame:GetHeight()
end

local function LoadWindowPosition()
    if not mainFrame or not LockSmithDB.dashboard then return end

    local db = LockSmithDB.dashboard
    if db.point and db.x and db.y then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x, db.y)
    end

    if db.width and db.height then
        mainFrame:SetSize(db.width, db.height)
    end
end

-- ================================
-- Tab System
-- ================================

local tabs = {}

local function SwitchTab(tabName, forceRefresh)
    if currentTab == tabName and not forceRefresh then return end

    currentTab = tabName

    -- Hide all tab content
    for name, data in pairs(tabs) do
        if data.content then
            data.content:Hide()
        end
        if data.button then
            -- Unhighlight button
            data.button.selectedTexture:Hide()
        end
    end

    -- Show selected tab content
    if tabs[tabName] and tabs[tabName].content then
        tabs[tabName].content:Show()
    end

    -- Highlight selected button
    if tabs[tabName] and tabs[tabName].button then
        tabs[tabName].button.selectedTexture:Show()
    end

    -- Call tab-specific update function if exists
    if tabs[tabName] and tabs[tabName].onShow then
        tabs[tabName].onShow()
    end
end

local tabButtons = {} -- Track buttons for positioning
local numTabs = 3

-- Function to update tab button widths based on container width
local function UpdateTabButtonWidths(containerWidth)
    if not containerWidth or containerWidth <= 0 then return end

    -- Calculate available width: container width - left margin (10) - right margin (10 + scroll bar ~17) - gaps between buttons (4px * 2)
    -- We need to account for the scroll bar on the right side
    local availableWidth = containerWidth - 15 - 30 - (4 * (numTabs - 1))
    local buttonWidth = math.floor(availableWidth / numTabs)

    -- Update each button's width
    for _, button in ipairs(tabButtons) do
        if button then
            button:SetWidth(buttonWidth)
        end
    end
end

local function CreateTabButton(parent, tabName, displayName, index)
    local button = CreateFrame("Button", "LockSmithTab" .. tabName, parent)
    button:SetHeight(30)
    button:SetWidth(120) -- Initial width, will be updated

    -- Position buttons horizontally
    if index == 1 then
        button:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 10, -2)
    else
        button:SetPoint("LEFT", tabButtons[index - 1], "RIGHT", 4, 0)
    end

    tabButtons[index] = button

    -- Background (unselected state)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.2, 0.1, 0.1, 0.8) -- Dark reddish brown

    -- Selected state
    button.selectedTexture = button:CreateTexture(nil, "BACKGROUND")
    button.selectedTexture:SetAllPoints()
    button.selectedTexture:SetColorTexture(0.6, 0.2, 0.2, 1.0) -- Rogue red
    button.selectedTexture:SetDrawLayer("BACKGROUND", 1)
    button.selectedTexture:Hide()

    -- Hover state
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(0.4, 0.15, 0.15, 0.5)

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER")
    button.text:SetText(displayName)

    -- Click handler
    button:SetScript("OnClick", function()
        SwitchTab(tabName)
    end)

    return button
end

local function CreateTabContent(parent, tabName)
    local content = CreateFrame("Frame", "LockSmithTabContent" .. tabName, parent)
    content:SetAllPoints(parent)
    content:Hide()

    return content
end

-- ================================
-- Main Frame Creation
-- ================================

local function CreateDashboardFrame()
    if mainFrame then return mainFrame end

    -- Main frame
    mainFrame = CreateFrame("Frame", "LockSmithDashboard", UIParent, "BackdropTemplate")
    mainFrame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(10)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:SetResizable(true)
    mainFrame:SetClampedToScreen(true)

    -- Backdrop
    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    mainFrame:SetBackdropColor(0.1, 0.05, 0.05, 0.95) -- Dark reddish
    mainFrame:SetBackdropBorderColor(0.6, 0.2, 0.2, 1) -- Rogue red border

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, mainFrame)
    titleBar:SetHeight(30)
    titleBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 12, -12)
    titleBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -12, -12)

    -- Title background
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.3, 0.1, 0.1, 0.9)

    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    title:SetText("|cff990000LockSmith Dashboard|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -5, 0)
    closeBtn:SetSize(20, 20)
    closeBtn:SetScript("OnClick", function()
        LockSmith.Dashboard:Hide()
    end)

    -- Make draggable via title bar
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function()
        mainFrame:StartMoving()
    end)
    titleBar:SetScript("OnMouseUp", function()
        mainFrame:StopMovingOrSizing()
        SaveWindowPosition()
    end)

    -- Resize grip (bottom-right corner)
    local resizeGrip = CreateFrame("Button", nil, mainFrame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:EnableMouse(true)

    local resizeTexture = resizeGrip:CreateTexture(nil, "OVERLAY")
    resizeTexture:SetAllPoints()
    resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    resizeGrip:SetScript("OnMouseDown", function()
        mainFrame:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        mainFrame:StopMovingOrSizing()
        SaveWindowPosition()
    end)

    -- Min/max size constraints (TBC compatibility)
    if mainFrame.SetResizeBounds then
        mainFrame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, 800, 1000)
    elseif mainFrame.SetMinResize then
        mainFrame:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
        mainFrame:SetMaxResize(800, 1000)
    end

    -- Tab container (holds all tab content)
    local tabContainer = CreateFrame("Frame", "LockSmithTabContainer", mainFrame)
    tabContainer:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -40) -- Space for tab buttons
    tabContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -15, 15)
    mainFrame.tabContainer = tabContainer

    -- Handle window resize
    mainFrame:SetScript("OnSizeChanged", function(_, width, height)
        SaveWindowPosition()
        LockSmith.Dashboard:OnWindowResize(width, height)
    end)

    -- Create tabs
    tabs.jobboard = {
        button = CreateTabButton(tabContainer, "jobboard", "Job Board", 1),
        content = CreateTabContent(tabContainer, "jobboard")
    }

    tabs.stats = {
        button = CreateTabButton(tabContainer, "stats", "Stats", 2),
        content = CreateTabContent(tabContainer, "stats")
    }

    tabs.settings = {
        button = CreateTabButton(tabContainer, "settings", "Settings", 3),
        content = CreateTabContent(tabContainer, "settings")
    }

    -- Initialize tab contents (will be filled by other modules)
    LockSmith.Dashboard:InitializeJobBoard(tabs.jobboard.content)
    LockSmith.Dashboard:InitializeStats(tabs.stats.content)
    LockSmith.Dashboard:InitializeSettings(tabs.settings.content)

    -- Load saved position/size
    LoadWindowPosition()

    -- Set initial tab button widths
    UpdateTabButtonWidths(mainFrame:GetWidth())

    -- Default to Job Board tab (force refresh to ensure it shows)
    SwitchTab("jobboard", true)

    mainFrame:Hide() -- Start hidden

    return mainFrame
end

-- ================================
-- Public API
-- ================================

function LockSmith.Dashboard:Initialize()
    CreateDashboardFrame()
end

function LockSmith.Dashboard:Show()
    if not mainFrame then
        CreateDashboardFrame()
    end
    mainFrame:Show()
end

function LockSmith.Dashboard:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

function LockSmith.Dashboard:Toggle()
    if not mainFrame then
        CreateDashboardFrame()
    end

    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

function LockSmith.Dashboard:IsShown()
    return mainFrame and mainFrame:IsShown()
end

-- Handle window resize for responsive layout
function LockSmith.Dashboard:OnWindowResize(width, height)
    if not mainFrame then return end

    -- Update tab button widths to fill the row
    UpdateTabButtonWidths(width)

    -- Rebuild job list to adjust card widths
    if currentTab == "jobboard" then
        -- Update scroll frame content width
        if tabs.jobboard and tabs.jobboard.jobScrollFrame and tabs.jobboard.jobContentFrame then
            tabs.jobboard.jobContentFrame:SetWidth(tabs.jobboard.jobScrollFrame:GetWidth())
        end
        LockSmith.Dashboard:RebuildJobList()
    end

    -- Update stats tab layout
    if currentTab == "stats" and tabs.stats and tabs.stats.content then
        LockSmith.Dashboard:UpdateStatsLayout(width, height)
    end
end

-- ================================
-- Job Board Tab
-- ================================

local jobList = {} -- Active job requests
local jobFrames = {} -- UI frames for each job
local jobScrollFrame = nil
local jobContentFrame = nil
local lastAdSendTime = 0 -- Track last ad send time

function LockSmith.Dashboard:InitializeJobBoard(content)
    -- Status bar at top
    local statusBar = CreateFrame("Frame", nil, content, "BackdropTemplate")
    statusBar:SetHeight(40)
    statusBar:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    statusBar:SetPoint("TOPRIGHT", content, "TOPRIGHT", -5, -5)
    statusBar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    statusBar:SetBackdropColor(0.15, 0.05, 0.05, 1)
    statusBar:SetBackdropBorderColor(0.4, 0.15, 0.15, 1)

    -- Status text
    local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("LEFT", statusBar, "LEFT", 10, 0)
    statusText:SetText("|cffff0000Stopped|r")
    content.statusText = statusText

    -- Skill text
    local skillText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    skillText:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
    skillText:SetText("Skill: --/--")
    content.skillText = skillText

    -- Start/Stop button
    local startStopBtn = CreateFrame("Button", nil, statusBar, "GameMenuButtonTemplate")
    startStopBtn:SetSize(80, 25)
    startStopBtn:SetPoint("RIGHT", statusBar, "RIGHT", -10, 0)
    startStopBtn:SetText("Start")
    startStopBtn:SetScript("OnClick", function()
        LockSmith:Toggle()
        LockSmith.Dashboard:UpdateJobBoardStatus()
    end)
    content.startStopBtn = startStopBtn

    -- Scrollable job list
    jobScrollFrame = CreateFrame("ScrollFrame", "LockSmithJobScrollFrame", content, "UIPanelScrollFrameTemplate")
    jobScrollFrame:SetPoint("TOPLEFT", statusBar, "BOTTOMLEFT", 0, -10)
    jobScrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 120)

    jobContentFrame = CreateFrame("Frame", nil, jobScrollFrame)
    jobContentFrame:SetSize(jobScrollFrame:GetWidth(), 1) -- Height will grow dynamically
    jobScrollFrame:SetScrollChild(jobContentFrame)

    -- Store references for resize handling
    tabs.jobboard.jobScrollFrame = jobScrollFrame
    tabs.jobboard.jobContentFrame = jobContentFrame

    -- Session stats footer
    local statsFooter = CreateFrame("Frame", nil, content, "BackdropTemplate")
    statsFooter:SetHeight(50)
    statsFooter:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 5, 65)
    statsFooter:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 65)
    statsFooter:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    statsFooter:SetBackdropColor(0.15, 0.05, 0.05, 1)
    statsFooter:SetBackdropBorderColor(0.4, 0.15, 0.15, 1)

    local statsTitle = statsFooter:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statsTitle:SetPoint("TOP", statsFooter, "TOP", 0, -5)
    statsTitle:SetText("|cffffcc00SESSION STATS|r")

    -- Individual stat labels spread evenly across the width, centered vertically
    local goldText = statsFooter:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldText:SetPoint("LEFT", statsFooter, "LEFT", 10, 0)
    goldText:SetPoint("RIGHT", statsFooter, "LEFT", (statsFooter:GetWidth() or 400) * 0.25, 0)
    goldText:SetJustifyH("CENTER")
    goldText:SetText("Gold: 0g")
    content.goldText = goldText

    local jobsText = statsFooter:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    jobsText:SetPoint("LEFT", statsFooter, "LEFT", (statsFooter:GetWidth() or 400) * 0.25, 0)
    jobsText:SetPoint("RIGHT", statsFooter, "CENTER", 0, 0)
    jobsText:SetJustifyH("CENTER")
    jobsText:SetText("Jobs: 0")
    content.jobsText = jobsText

    local boxesText = statsFooter:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    boxesText:SetPoint("LEFT", statsFooter, "CENTER", 0, 0)
    boxesText:SetPoint("RIGHT", statsFooter, "RIGHT", -(statsFooter:GetWidth() or 400) * 0.25, 0)
    boxesText:SetJustifyH("CENTER")
    boxesText:SetText("Boxes: 0")
    content.boxesText = boxesText

    local avgText = statsFooter:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    avgText:SetPoint("LEFT", statsFooter, "RIGHT", -(statsFooter:GetWidth() or 400) * 0.25, 0)
    avgText:SetPoint("RIGHT", statsFooter, "RIGHT", -10, 0)
    avgText:SetJustifyH("CENTER")
    avgText:SetText("Avg: 0g")
    content.avgText = avgText

    -- Ad buttons
    local adButtonFrame = CreateFrame("Frame", nil, content)
    adButtonFrame:SetHeight(55)
    adButtonFrame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 5, 5)
    adButtonFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)

    -- Send Ad button (with countdown) - use anchors for responsive sizing
    local sendAdBtn = CreateFrame("Button", nil, adButtonFrame, "GameMenuButtonTemplate")
    sendAdBtn:SetHeight(30)
    sendAdBtn:SetPoint("LEFT", adButtonFrame, "LEFT", 5, 0)
    sendAdBtn:SetPoint("RIGHT", adButtonFrame, "CENTER", -2, 0)
    sendAdBtn:SetText("Send Ad")
    sendAdBtn:SetScript("OnClick", function()
        if LockSmith.Advertisement then
            LockSmith.Advertisement:SendAdvertisement()
            LockSmith.Dashboard:UpdateAdButton()
        end
    end)
    content.sendAdBtn = sendAdBtn

    -- Start ticker for ad countdown
    if not tabs.jobboard.adTicker then
        tabs.jobboard.adTicker = C_Timer.NewTicker(1, function()
            if currentTab == "jobboard" then
                LockSmith.Dashboard:UpdateAdButton()
            end
        end)
    end

    -- Yell Ad button - use anchors for responsive sizing
    local yellAdBtn = CreateFrame("Button", nil, adButtonFrame, "GameMenuButtonTemplate")
    yellAdBtn:SetHeight(30)
    yellAdBtn:SetPoint("LEFT", adButtonFrame, "CENTER", 2, 0)
    yellAdBtn:SetPoint("RIGHT", adButtonFrame, "RIGHT", -5, 0)
    yellAdBtn:SetText("Yell Ad")
    yellAdBtn:SetScript("OnClick", function()
        if LockSmith.Advertisement and LockSmithDB.adMessage then
            SendChatMessage(LockSmithDB.adMessage, "YELL")
            print("|cff00ff00LockSmith:|r Ad sent to Yell")
        end
    end)

    -- Update status initially
    LockSmith.Dashboard:UpdateJobBoardStatus()
end

-- Update ad button with countdown
function LockSmith.Dashboard:UpdateAdButton()
    if not tabs.jobboard or not tabs.jobboard.content then return end

    local sendAdBtn = tabs.jobboard.content.sendAdBtn
    if not sendAdBtn then return end

    local now = GetTime()
    local interval = LockSmithDB.adTimerInterval or 60
    local timeSinceLastAd = now - lastAdSendTime
    local timeRemaining = math.max(0, interval - timeSinceLastAd)

    if timeRemaining > 0 then
        local seconds = math.ceil(timeRemaining)
        sendAdBtn:SetText("Send Ad (" .. seconds .. "s)")
    else
        sendAdBtn:SetText("Send Ad")
    end
end

-- Track ad send
function LockSmith.Dashboard:OnAdSent()
    lastAdSendTime = GetTime()
    LockSmith.Dashboard:UpdateAdButton()
end

-- Update status bar
function LockSmith.Dashboard:UpdateJobBoardStatus()
    if not tabs.jobboard or not tabs.jobboard.content then return end

    local content = tabs.jobboard.content
    local isRunning = LockSmith:IsRunning()

    -- Status text
    if content.statusText then
        if isRunning then
            content.statusText:SetText("|cff00ff00Running|r")
        else
            content.statusText:SetText("|cffff0000Stopped|r")
        end
    end

    -- Skill text
    if content.skillText then
        local skill, maxSkill = LockSmith.Skills:GetCachedSkill()
        content.skillText:SetText("Skill: " .. skill .. "/" .. maxSkill)
    end

    -- Start/Stop button
    if content.startStopBtn then
        content.startStopBtn:SetText(isRunning and "Stop" or "Start")
    end

    -- Session stats (update individual text elements)
    if content.goldText then
        local sessionGold = LockSmith.Statistics:GetSessionGold()
        local sessionJobs = LockSmith.Statistics:GetSessionJobs()
        local sessionBoxes = LockSmith.Statistics:GetSessionBoxes()
        local sessionAvg = LockSmith.Statistics:GetSessionAverage()

        content.goldText:SetText("Gold: " .. LockSmith.Utils:FormatGold(sessionGold))
        content.jobsText:SetText("Jobs: " .. sessionJobs)
        content.boxesText:SetText("Boxes: " .. sessionBoxes)
        content.avgText:SetText("Avg: " .. LockSmith.Utils:FormatGold(sessionAvg))
    end
end

-- Add a job to the board
function LockSmith.Dashboard:AddJob(sender, message, boxData, channelName, requiredSkill)
    -- Create job data
    local job = {
        sender = sender,
        message = message,
        boxData = boxData,
        channelName = channelName,
        requiredSkill = requiredSkill,
        timestamp = GetTime()
    }

    -- Add to list (newest first)
    table.insert(jobList, 1, job)

    -- Rebuild job list UI
    LockSmith.Dashboard:RebuildJobList()

    -- Play sound and visual alert
    if LockSmithDB.playSoundEffects then
        PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or "TellMessage", "Master")
    end
end

-- Clear all jobs
function LockSmith.Dashboard:ClearAllJobs()
    jobList = {}
    LockSmith.Dashboard:RebuildJobList()
end

-- Remove a specific job
function LockSmith.Dashboard:RemoveJob(index)
    table.remove(jobList, index)
    LockSmith.Dashboard:RebuildJobList()
end

-- Rebuild the job list UI
function LockSmith.Dashboard:RebuildJobList()
    -- Clear existing job frames
    for _, frame in ipairs(jobFrames) do
        frame:Hide()
        frame:SetParent(nil)
    end
    jobFrames = {}

    if not jobContentFrame then return end

    local yOffset = -5
    local cardSpacing = 10

    for i, job in ipairs(jobList) do
        local card = LockSmith.Dashboard:CreateJobCard(job, i)
        card:SetPoint("TOPLEFT", jobContentFrame, "TOPLEFT", 5, yOffset)
        card:SetPoint("TOPRIGHT", jobContentFrame, "TOPRIGHT", -5, yOffset)

        -- Highlight if new (within 2 seconds)
        if GetTime() - job.timestamp < 2 then
            LockSmith.Dashboard:AnimateNewJob(card)
        end

        table.insert(jobFrames, card)
        -- Use the card's actual height (which is now dynamic)
        yOffset = yOffset - card:GetHeight() - cardSpacing
    end

    -- Update content height for scrolling
    local totalHeight = math.abs(yOffset) + 10
    jobContentFrame:SetHeight(totalHeight)
end

-- Create a job card
function LockSmith.Dashboard:CreateJobCard(job, index)
    local card = CreateFrame("Frame", nil, jobContentFrame, "BackdropTemplate")
    card:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    card:SetBackdropColor(0.2, 0.1, 0.1, 0.95)
    card:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)

    -- Close button (X) in top-right corner
    local closeBtn = CreateFrame("Button", nil, card)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -4, -4)

    local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeBtnText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeBtnText:SetText("|cffaaaaaa×|r")

    closeBtn:SetScript("OnEnter", function(self)
        closeBtnText:SetText("|cffff0000×|r")
    end)
    closeBtn:SetScript("OnLeave", function(self)
        closeBtnText:SetText("|cffaaaaaa×|r")
    end)
    closeBtn:SetScript("OnClick", function()
        LockSmith.Dashboard:RemoveJob(index)
    end)

    -- Player name (smaller font)
    local playerName = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerName:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
    playerName:SetText("|cff" .. (job.channelName == "WHISPER" and "ff69b4" or "ffcc00") .. job.sender .. "|r")

    -- Channel (smaller font)
    local channel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    channel:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -4, -6)
    channel:SetText(job.channelName or "Unknown")

    -- Message (smaller font, with word wrapping)
    local msg = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetPoint("TOPLEFT", playerName, "BOTTOMLEFT", 0, -4)
    msg:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -20)
    msg:SetJustifyH("LEFT")
    msg:SetJustifyV("TOP")
    msg:SetWordWrap(true)
    msg:SetMaxLines(0) -- No limit on lines
    msg:SetNonSpaceWrap(false)

    local msgText = job.message or ""
    msg:SetText("\"" .. msgText .. "\"")

    -- Let the text calculate its height
    local msgHeight = msg:GetStringHeight()

    -- Box info (smaller font)
    local boxInfo = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    boxInfo:SetPoint("TOPLEFT", msg, "BOTTOMLEFT", 0, -4)
    if job.boxData then
        boxInfo:SetText("|cff00ff00Box:|r " .. job.boxData.name .. " (|cffffcc00" .. job.requiredSkill .. " skill|r)")
    else
        boxInfo:SetText("|cffccccccBox: Unknown|r")
    end

    -- Buttons (responsive width - use anchors to distribute evenly)
    -- Each button gets equal width by anchoring both left and right edges
    local inviteBtn = CreateFrame("Button", nil, card, "GameMenuButtonTemplate")
    inviteBtn:SetHeight(22)
    inviteBtn:SetText("Invite")
    inviteBtn:SetScript("OnClick", function()
        if LockSmith.Utils then
            LockSmith.Utils:InvitePlayer(job.sender)
        end
    end)

    local whisperBtn = CreateFrame("Button", nil, card, "GameMenuButtonTemplate")
    whisperBtn:SetHeight(22)
    whisperBtn:SetText("Whisper")
    whisperBtn:SetScript("OnClick", function()
        ChatFrame_SendTell(job.sender)
    end)

    local ignoreBtn = CreateFrame("Button", nil, card, "GameMenuButtonTemplate")
    ignoreBtn:SetHeight(22)
    ignoreBtn:SetText("Ignore")
    ignoreBtn:SetScript("OnClick", function()
        if LockSmith.ChatMonitor and LockSmith.ChatMonitor.AddToSessionIgnore then
            LockSmith.ChatMonitor:AddToSessionIgnore(job.sender)
        end
        LockSmith.Dashboard:RemoveJob(index)
    end)

    -- Calculate total card height dynamically FIRST
    -- Top padding (8) + playerName height (~14) + spacing (4) + message height + spacing (4) + boxInfo height (~14) + spacing (6) + button height (22) + bottom padding (6)
    local totalHeight = 8 + 14 + 4 + msgHeight + 4 + 14 + 6 + 22 + 6
    card:SetHeight(math.max(95, totalHeight)) -- Minimum 95 to match original

    -- Get card width from parent (jobContentFrame width - the 10px margins from anchoring)
    local cardWidth = (jobContentFrame and jobContentFrame:GetWidth() or 400) - 10

    -- Calculate button widths: (cardWidth - left margin - right margin - 2 gaps) / 3
    local leftMargin = 10
    local rightMargin = 10
    local gapSize = 4
    local availableWidth = cardWidth - leftMargin - rightMargin - (gapSize * 2)
    local buttonWidth = math.floor(availableWidth / 3)

    -- Set all button widths
    inviteBtn:SetWidth(buttonWidth)
    whisperBtn:SetWidth(buttonWidth)
    ignoreBtn:SetWidth(buttonWidth)

    -- Position buttons at the bottom in a row
    inviteBtn:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", leftMargin, 6)
    whisperBtn:SetPoint("LEFT", inviteBtn, "RIGHT", gapSize, 0)
    ignoreBtn:SetPoint("LEFT", whisperBtn, "RIGHT", gapSize, 0)

    return card
end

-- Animate new job card
function LockSmith.Dashboard:AnimateNewJob(card)
    -- Flash border
    local flashCount = 0
    local flashFrame = CreateFrame("Frame")
    flashFrame:SetScript("OnUpdate", function(self, elapsed)
        flashCount = flashCount + elapsed * 4 -- 4 flashes per second

        if flashCount < 4 then -- Flash for 1 second
            local alpha = (math.sin(flashCount * math.pi) + 1) / 2
            card:SetBackdropBorderColor(1, 0.5 + alpha * 0.5, 0, 1)
        else
            card:SetBackdropBorderColor(0.5, 0.2, 0.2, 1) -- Reset to normal
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- ================================
-- Stats Tab
-- ================================

function LockSmith.Dashboard:InitializeStats(content)
    -- Create a scroll frame for ALL stats content
    local statsScrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    statsScrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    statsScrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 50)
    content.statsScrollFrame = statsScrollFrame

    -- Scroll child that will hold all stats content
    local scrollChild = CreateFrame("Frame", nil, statsScrollFrame)
    scrollChild:SetWidth(statsScrollFrame:GetWidth())
    statsScrollFrame:SetScrollChild(scrollChild)
    content.statsScrollChild = scrollChild

    -- Main stats cards (now parented to scrollChild)
    local card1 = LockSmith.Dashboard:CreateStatCard(scrollChild, "Total Gold", "totalGold")
    card1:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    card1:SetSize(180, 70)
    content.statCard1 = card1

    local card2 = LockSmith.Dashboard:CreateStatCard(scrollChild, "Total Jobs", "totalJobs")
    card2:SetPoint("LEFT", card1, "RIGHT", 10, 0)
    card2:SetSize(180, 70)
    content.statCard2 = card2

    local card3 = LockSmith.Dashboard:CreateStatCard(scrollChild, "Total Boxes", "totalBoxes")
    card3:SetPoint("TOPLEFT", card1, "BOTTOMLEFT", 0, -10)
    card3:SetSize(180, 70)
    content.statCard3 = card3

    local card4 = LockSmith.Dashboard:CreateStatCard(scrollChild, "Average Tip", "avgTip")
    card4:SetPoint("LEFT", card3, "RIGHT", 10, 0)
    card4:SetSize(180, 70)
    content.statCard4 = card4

    local card5 = LockSmith.Dashboard:CreateStatCard(scrollChild, "Last Session", "lastSession")
    card5:SetPoint("TOPLEFT", card3, "BOTTOMLEFT", 0, -10)
    card5:SetSize(180, 70)
    content.statCard5 = card5

    local card6 = LockSmith.Dashboard:CreateStatCard(scrollChild, "Best Session", "bestSession")
    card6:SetPoint("LEFT", card5, "RIGHT", 10, 0)
    card6:SetSize(180, 70)
    content.statCard6 = card6

    -- Per-box breakdown header
    local boxHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    boxHeader:SetPoint("TOPLEFT", card5, "BOTTOMLEFT", 0, -25)
    boxHeader:SetText("|cffffcc00Boxes Opened|r")
    content.boxHeader = boxHeader

    -- Box list container (simple frame, no nested scroll)
    local boxListFrame = CreateFrame("Frame", nil, scrollChild)
    boxListFrame:SetPoint("TOPLEFT", boxHeader, "BOTTOMLEFT", 0, -10)
    boxListFrame:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, -280)
    boxListFrame:SetHeight(1) -- Will grow dynamically
    content.boxListFrame = boxListFrame

    -- Reset button at bottom of scroll content
    local resetBtn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    resetBtn:SetSize(150, 30)
    resetBtn:SetPoint("BOTTOM", content, "BOTTOM", 0, 10)
    resetBtn:SetText("Reset Stats")
    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["LOCKSMITH_RESET_STATS"] = {
            text = "Are you sure you want to reset all statistics? This cannot be undone!",
            button1 = "Yes, Reset",
            button2 = "Cancel",
            OnAccept = function()
                LockSmith.Statistics:ResetStats()
                LockSmith.Dashboard:UpdateStatsTab()
                print("|cff00ff00LockSmith:|r Statistics reset!")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("LOCKSMITH_RESET_STATS")
    end)

    -- Initial update
    LockSmith.Dashboard:UpdateStatsTab()

    -- Set up update ticker for skill level (every 5 seconds when tab visible)
    tabs.stats.onShow = function()
        -- Update layout based on current window width
        if mainFrame then
            LockSmith.Dashboard:UpdateStatsLayout(mainFrame:GetWidth(), mainFrame:GetHeight())
        end

        -- Update stat values
        LockSmith.Dashboard:UpdateStatsTab()

        if not tabs.stats.ticker then
            tabs.stats.ticker = C_Timer.NewTicker(5, function()
                if currentTab == "stats" then
                    -- Update skill level in stat cards
                    LockSmith.Dashboard:UpdateStatsTab()
                end
            end)
        end
    end
end

-- Create a stat card
function LockSmith.Dashboard:CreateStatCard(parent, title, statType)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    card:SetBackdropColor(0.15, 0.05, 0.05, 1)
    card:SetBackdropBorderColor(0.6, 0.2, 0.2, 1)

    -- Title
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("TOP", card, "TOP", 0, -8)
    titleText:SetText("|cffcccccc" .. title .. "|r")

    -- Value
    local valueText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    valueText:SetPoint("CENTER", card, "CENTER", 0, -5)
    valueText:SetText("0")
    card.valueText = valueText
    card.statType = statType

    return card
end

-- Update stats tab
function LockSmith.Dashboard:UpdateStatsTab()
    if not tabs.stats or not tabs.stats.content then return end

    local content = tabs.stats.content

    -- Update stat cards
    for i = 1, 6 do
        local card = content["statCard" .. i]
        if card and card.valueText and card.statType then
            local value = ""
            local statType = card.statType

            if statType == "totalGold" then
                value = LockSmith.Utils:FormatGold(LockSmithDB.stats.totalGold or 0)
            elseif statType == "totalJobs" then
                value = tostring(LockSmithDB.stats.totalJobs or 0)
            elseif statType == "totalBoxes" then
                value = tostring(LockSmithDB.stats.totalBoxes or 0)
            elseif statType == "avgTip" then
                value = LockSmith.Utils:FormatGold(LockSmith.Statistics:GetAverageTip())
            elseif statType == "lastSession" then
                value = LockSmith.Utils:FormatGold(LockSmithDB.stats.lastSessionGold or 0)
            elseif statType == "bestSession" then
                value = LockSmith.Utils:FormatGold(LockSmithDB.stats.bestSessionGold or 0)
            end

            card.valueText:SetText(value)
        end
    end

    -- Update per-box stats
    LockSmith.Dashboard:UpdateBoxStats()
end

-- Update box stats list
function LockSmith.Dashboard:UpdateBoxStats()
    if not tabs.stats or not tabs.stats.content then return end

    local boxListFrame = tabs.stats.content.boxListFrame
    local scrollChild = tabs.stats.content.statsScrollChild
    if not boxListFrame or not scrollChild then return end

    -- Clear existing
    for _, child in ipairs({boxListFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = -5
    local lineHeight = 20
    local counts = LockSmithDB.stats.boxesOpened or {}

    -- Get sorted box list
    local boxList = {}
    for key, count in pairs(counts) do
        if count > 0 then
            table.insert(boxList, {key = key, count = count})
        end
    end

    -- Sort by count descending
    table.sort(boxList, function(a, b) return a.count > b.count end)

    -- Create text lines
    for _, boxData in ipairs(boxList) do
        local data = LockSmith.BoxDatabase[boxData.key]
        local skill = data and data.skill or 0
        local name = data and data.name or boxData.key
        local label = (skill > 0 and ("|cffffcc00" .. skill .. "|r - ") or "") .. name

        local line = boxListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        line:SetPoint("TOPLEFT", boxListFrame, "TOPLEFT", 10, yOffset)
        line:SetText(label .. ": |cff00ff00" .. boxData.count .. "|r")

        yOffset = yOffset - lineHeight
    end

    -- Update box list frame height
    local boxListHeight = math.max(1, #boxList * lineHeight + 10)
    boxListFrame:SetHeight(boxListHeight)

    -- Update total scroll child height: stat cards (3 rows * 80) + box header (40) + box list + padding
    local totalHeight = 240 + 40 + boxListHeight + 50
    scrollChild:SetHeight(totalHeight)
end

-- Update stats tab layout for responsive design
function LockSmith.Dashboard:UpdateStatsLayout(width, _)
    if not tabs.stats or not tabs.stats.content then return end

    local content = tabs.stats.content
    local scrollChild = content.statsScrollChild
    local boxHeader = content.boxHeader

    if not scrollChild then return end

    -- Update scroll child width to match scroll frame
    if content.statsScrollFrame then
        scrollChild:SetWidth(content.statsScrollFrame:GetWidth())
    end

    -- Calculate how many columns can fit based on width
    -- We need to work with the scroll child's actual width (which accounts for scrollbar)
    local scrollChildWidth = scrollChild:GetWidth() or (width - 30)
    local minCardWidth = 150
    local cardSpacing = 10
    local leftMargin = 10
    local rightMargin = 10
    local availableWidth = scrollChildWidth - leftMargin - rightMargin

    local numColumns = 1
    if availableWidth >= (minCardWidth * 3 + cardSpacing * 2) then
        numColumns = 3
    elseif availableWidth >= (minCardWidth * 2 + cardSpacing) then
        numColumns = 2
    end

    -- Calculate actual card width to fill available space
    local cardWidth = math.floor((availableWidth - (cardSpacing * (numColumns - 1))) / numColumns)

    -- Arrange cards in grid
    local numCards = 6
    local numRows = math.ceil(numCards / numColumns)

    for i = 1, numCards do
        local card = content["statCard" .. i]
        if card then
            card:ClearAllPoints()

            -- Calculate row and column for this card (0-indexed for easier math)
            local row = math.floor((i - 1) / numColumns)
            local col = (i - 1) % numColumns

            if col == 0 then
                -- First card in row
                if row == 0 then
                    card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
                else
                    local prevRowFirstCard = content["statCard" .. (row * numColumns + 1 - numColumns)]
                    card:SetPoint("TOPLEFT", prevRowFirstCard, "BOTTOMLEFT", 0, -10)
                end
            else
                -- Not first card in row - anchor to left neighbor
                local leftNeighbor = content["statCard" .. (i - 1)]
                card:SetPoint("LEFT", leftNeighbor, "RIGHT", cardSpacing, 0)
            end

            -- Set width (or use anchors for single column mode)
            if numColumns == 1 then
                card:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -rightMargin, row == 0 and -10 or 0)
            else
                card:SetWidth(cardWidth)
            end
        end
    end

    -- Position box header below the last row of cards
    local lastRowFirstCardIndex = (numRows - 1) * numColumns + 1
    local lastRowFirstCard = content["statCard" .. lastRowFirstCardIndex]

    if boxHeader and lastRowFirstCard then
        boxHeader:ClearAllPoints()
        boxHeader:SetPoint("TOPLEFT", lastRowFirstCard, "BOTTOMLEFT", 0, -25)
    end

    -- Update box list frame positioning
    if content.boxListFrame then
        local headerYOffset = -(numRows * 80 + (numRows - 1) * 10 + 10 + 25)
        content.boxListFrame:ClearAllPoints()
        content.boxListFrame:SetPoint("TOPLEFT", boxHeader, "BOTTOMLEFT", 0, -10)
        content.boxListFrame:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, headerYOffset - 10)
    end

    -- Refresh box stats to recalculate scroll child height
    LockSmith.Dashboard:UpdateBoxStats()
end

-- ================================
-- Settings Tab
-- ================================

function LockSmith.Dashboard:InitializeSettings(content)
    -- Scroll frame for settings
    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 5)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(350) -- Set width explicitly
    scrollFrame:SetScrollChild(scrollChild)

    -- Ensure visibility
    scrollChild:Show()

    local yOffset = -10

    -- Helper function to create header
    local function CreateHeader(text)
        local header = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        header:SetText("|cffffcc00" .. text .. "|r")
        yOffset = yOffset - 25
        return header
    end

    -- Helper function to create checkbox
    local function CreateCheckbox(label, dbKey, nestedTable, nestedKey)
        local checkbox = CreateFrame("CheckButton", "LockSmithSettingsCB" .. math.random(1000000), scrollChild, "ChatConfigCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)

        -- Set text (checkbox template creates a Text fontstring)
        local textWidget = _G[checkbox:GetName() .. "Text"]
        if textWidget then
            textWidget:SetText(label)
        end

        if nestedTable and nestedKey then
            -- Nested table value (e.g., LockSmithDB.adChannels.trade)
            checkbox:SetChecked(LockSmithDB[nestedTable] and LockSmithDB[nestedTable][nestedKey])
            checkbox:SetScript("OnClick", function(self)
                if not LockSmithDB[nestedTable] then
                    LockSmithDB[nestedTable] = {}
                end
                LockSmithDB[nestedTable][nestedKey] = self:GetChecked()
            end)
        else
            -- Simple value (e.g., LockSmithDB.monitorTrade)
            checkbox:SetChecked(LockSmithDB[dbKey])
            checkbox:SetScript("OnClick", function(self)
                LockSmithDB[dbKey] = self:GetChecked()
            end)
        end

        yOffset = yOffset - 25
        return checkbox
    end

    -- Channel Monitoring
    CreateHeader("Channel Monitoring")
    CreateCheckbox("Monitor Trade Channel", "monitorTrade")
    CreateCheckbox("Monitor General Channel", "monitorGeneral")
    CreateCheckbox("Monitor LFG Channel", "monitorLFG")
    CreateCheckbox("Monitor Whispers", "monitorWhisper")
    CreateCheckbox("Play Sound Effects", "playSoundEffects")
    CreateCheckbox("Auto-mark Self with Star (Party Leader)", "autoMarkSelf")
    CreateCheckbox("Auto-mark Customers with Raid Icons", "autoMarkCustomers")
    yOffset = yOffset - 10

    -- Advertisement Settings
    CreateHeader("Advertisement")

    local adLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    adLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    adLabel:SetText("Advertisement Message:")
    yOffset = yOffset - 20

    local adMsgBox = CreateFrame("EditBox", "LockSmithAdMsgBox", scrollChild, "InputBoxTemplate")
    adMsgBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    adMsgBox:SetSize(340, 30)
    adMsgBox:SetText(LockSmithDB.adMessage or "")
    adMsgBox:SetAutoFocus(false)
    adMsgBox:SetScript("OnTextChanged", function(self)
        LockSmithDB.adMessage = self:GetText()
    end)
    adMsgBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    yOffset = yOffset - 40

    local setDefaultBtn = CreateFrame("Button", nil, scrollChild, "GameMenuButtonTemplate")
    setDefaultBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    setDefaultBtn:SetSize(120, 25)
    setDefaultBtn:SetText("Set Default")
    setDefaultBtn:SetScript("OnClick", function()
        local default = "LockSmith - Rogue lockpicking service available! Free picks, tips appreciated {rt1}"
        LockSmithDB.adMessage = default
        adMsgBox:SetText(default)
    end)
    yOffset = yOffset - 35

    local adChannelLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    adChannelLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    adChannelLabel:SetText("Send Advertisement To:")
    yOffset = yOffset - 20

    CreateCheckbox("Trade", nil, "adChannels", "trade")
    CreateCheckbox("General", nil, "adChannels", "general")
    CreateCheckbox("LFG", nil, "adChannels", "lfg")
    CreateCheckbox("Yell", nil, "adChannels", "yell")
    yOffset = yOffset - 5

    local timerCheckbox = CreateCheckbox("Enable Auto-Advertisement Timer", "adTimerEnabled")
    yOffset = yOffset - 10

    -- Timer interval - show current value and +/- buttons
    local timerContainer = CreateFrame("Frame", nil, scrollChild)
    timerContainer:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    timerContainer:SetSize(300, 30)

    local timerLabel = timerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerLabel:SetPoint("LEFT", timerContainer, "LEFT", 0, 0)
    timerLabel:SetText("Timer Interval:")

    local timerValue = timerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timerValue:SetPoint("CENTER", timerContainer, "CENTER", 0, 0)
    timerValue:SetText("|cff00ff00" .. (LockSmithDB.adTimerInterval or 60) .. "s|r")

    local decreaseBtn = CreateFrame("Button", nil, timerContainer, "GameMenuButtonTemplate")
    decreaseBtn:SetSize(30, 25)
    decreaseBtn:SetPoint("RIGHT", timerValue, "LEFT", -10, 0)
    decreaseBtn:SetText("-")
    decreaseBtn:SetScript("OnClick", function()
        local current = LockSmithDB.adTimerInterval or 60
        local new = math.max(30, current - 10)
        LockSmithDB.adTimerInterval = new
        timerValue:SetText("|cff00ff00" .. new .. "s|r")
    end)

    local increaseBtn = CreateFrame("Button", nil, timerContainer, "GameMenuButtonTemplate")
    increaseBtn:SetSize(30, 25)
    increaseBtn:SetPoint("LEFT", timerValue, "RIGHT", 10, 0)
    increaseBtn:SetText("+")
    increaseBtn:SetScript("OnClick", function()
        local current = LockSmithDB.adTimerInterval or 60
        local new = math.min(600, current + 10)
        LockSmithDB.adTimerInterval = new
        timerValue:SetText("|cff00ff00" .. new .. "s|r")
    end)

    yOffset = yOffset - 40

    -- Auto-Response Settings
    CreateHeader("Auto-Response")
    CreateCheckbox("Auto-invite on Whisper", "autoInviteWhisper")
    CreateCheckbox("Show Popup on Any Whisper", "popupOnAnyWhisper")
    CreateCheckbox("Low Skill Whisper", "lowSkillWhisper")
    yOffset = yOffset - 5

    local lowSkillLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lowSkillLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    lowSkillLabel:SetText("Low Skill Message:")
    yOffset = yOffset - 20

    local lowSkillBox = CreateFrame("EditBox", "LockSmithLowSkillBox", scrollChild, "InputBoxTemplate")
    lowSkillBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    lowSkillBox:SetSize(340, 30)
    lowSkillBox:SetText(LockSmithDB.lowSkillMessage or "")
    lowSkillBox:SetAutoFocus(false)
    lowSkillBox:SetScript("OnTextChanged", function(self)
        LockSmithDB.lowSkillMessage = self:GetText()
    end)
    lowSkillBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    yOffset = yOffset - 40

    CreateCheckbox("Thank-You Whisper (after tip)", "thankYouWhisper")
    yOffset = yOffset - 5

    local thankYouLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    thankYouLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    thankYouLabel:SetText("Thank-You Message:")
    yOffset = yOffset - 20

    local thankYouBox = CreateFrame("EditBox", "LockSmithThankYouBox", scrollChild, "InputBoxTemplate")
    thankYouBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    thankYouBox:SetSize(340, 30)
    thankYouBox:SetText(LockSmithDB.thankYouMessage or "")
    thankYouBox:SetAutoFocus(false)
    thankYouBox:SetScript("OnTextChanged", function(self)
        LockSmithDB.thankYouMessage = self:GetText()
    end)
    thankYouBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    yOffset = yOffset - 40

    local helpText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    helpText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    helpText:SetText("|cffccccccVariables: %CURRENT%, %REQUIRED%, %TIP%|r")
    yOffset = yOffset - 30

    -- Update scroll child height
    scrollChild:SetHeight(math.abs(yOffset) + 20)
end
