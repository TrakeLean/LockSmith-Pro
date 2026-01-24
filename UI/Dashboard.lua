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

local function SwitchTab(tabName)
    if currentTab == tabName then return end

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

local function CreateTabButton(parent, tabName, displayName, index)
    local button = CreateFrame("Button", "LockSmithTab" .. tabName, parent)
    button:SetSize(120, 30)

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

    -- Min/max size constraints
    mainFrame:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
    mainFrame:SetMaxResize(800, 1000)

    -- Tab container (holds all tab content)
    local tabContainer = CreateFrame("Frame", "LockSmithTabContainer", mainFrame)
    tabContainer:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -40) -- Space for tab buttons
    tabContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -15, 15)

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

    -- Default to Job Board tab
    SwitchTab("jobboard")

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

-- ================================
-- Job Board Tab
-- ================================

local jobList = {} -- Active job requests
local jobFrames = {} -- UI frames for each job
local jobScrollFrame = nil
local jobContentFrame = nil

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
    statsTitle:SetPoint("TOPLEFT", statsFooter, "TOPLEFT", 10, -5)
    statsTitle:SetText("|cffffcc00SESSION STATS|r")

    local statsText = statsFooter:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsText:SetPoint("LEFT", statsFooter, "LEFT", 10, -10)
    statsText:SetText("Gold: 0g | Jobs: 0 | Avg: 0g")
    content.statsText = statsText

    -- Ad buttons
    local adButtonFrame = CreateFrame("Frame", nil, content)
    adButtonFrame:SetHeight(55)
    adButtonFrame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 5, 5)
    adButtonFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)

    -- Send Ad button (with countdown)
    local sendAdBtn = CreateFrame("Button", nil, adButtonFrame, "GameMenuButtonTemplate")
    sendAdBtn:SetSize(180, 30)
    sendAdBtn:SetPoint("LEFT", adButtonFrame, "LEFT", 5, 0)
    sendAdBtn:SetText("Send Ad")
    sendAdBtn:SetScript("OnClick", function()
        if LockSmith.Advertisement then
            LockSmith.Advertisement:SendAdvertisement()
        end
    end)
    content.sendAdBtn = sendAdBtn

    -- Yell Ad button
    local yellAdBtn = CreateFrame("Button", nil, adButtonFrame, "GameMenuButtonTemplate")
    yellAdBtn:SetSize(180, 30)
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

    -- Session stats
    if content.statsText then
        local sessionGold = LockSmith.Statistics:GetSessionGold()
        local totalJobs = LockSmithDB.stats.totalJobs or 0
        local avgTip = LockSmith.Statistics:GetAverageTip()

        content.statsText:SetText(
            "Gold: " .. LockSmith.Utils:FormatGold(sessionGold) ..
            " | Jobs: " .. totalJobs ..
            " | Avg: " .. LockSmith.Utils:FormatGold(avgTip)
        )
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
    local cardHeight = 95
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
        yOffset = yOffset - cardHeight - cardSpacing
    end

    -- Update content height for scrolling
    local totalHeight = math.max(1, #jobList * (cardHeight + cardSpacing) + 10)
    jobContentFrame:SetHeight(totalHeight)
end

-- Create a job card
function LockSmith.Dashboard:CreateJobCard(job, index)
    local card = CreateFrame("Frame", nil, jobContentFrame, "BackdropTemplate")
    card:SetHeight(95)
    card:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    card:SetBackdropColor(0.2, 0.1, 0.1, 0.95)
    card:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)

    -- Player name
    local playerName = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    playerName:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
    playerName:SetText("|cff" .. (job.channelName == "WHISPER" and "ff69b4" or "ffcc00") .. job.sender .. "|r")

    -- Channel
    local channel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    channel:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -8)
    channel:SetText(job.channelName or "Unknown")

    -- Message
    local msg = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msg:SetPoint("TOPLEFT", playerName, "BOTTOMLEFT", 0, -5)
    msg:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -25)
    msg:SetHeight(20)
    msg:SetJustifyH("LEFT")
    msg:SetWordWrap(false)
    msg:SetText("\"" .. (job.message or "") .. "\"")

    -- Box info
    local boxInfo = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    boxInfo:SetPoint("TOPLEFT", msg, "BOTTOMLEFT", 0, -5)
    if job.boxData then
        boxInfo:SetText("|cff00ff00Box:|r " .. job.boxData.name .. " (|cffffcc00" .. job.requiredSkill .. " skill|r)")
    else
        boxInfo:SetText("|cffccccccBox: Unknown|r")
    end

    -- Buttons
    local inviteBtn = CreateFrame("Button", nil, card, "GameMenuButtonTemplate")
    inviteBtn:SetSize(90, 25)
    inviteBtn:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 8)
    inviteBtn:SetText("Invite")
    inviteBtn:SetScript("OnClick", function()
        if LockSmith.Utils then
            LockSmith.Utils:InvitePlayer(job.sender)
        end
    end)

    local whisperBtn = CreateFrame("Button", nil, card, "GameMenuButtonTemplate")
    whisperBtn:SetSize(90, 25)
    whisperBtn:SetPoint("LEFT", inviteBtn, "RIGHT", 5, 0)
    whisperBtn:SetText("Whisper")
    whisperBtn:SetScript("OnClick", function()
        ChatFrame_SendTell(job.sender)
    end)

    local ignoreBtn = CreateFrame("Button", nil, card, "GameMenuButtonTemplate")
    ignoreBtn:SetSize(90, 25)
    ignoreBtn:SetPoint("LEFT", whisperBtn, "RIGHT", 5, 0)
    ignoreBtn:SetText("Ignore")
    ignoreBtn:SetScript("OnClick", function()
        if LockSmith.ChatMonitor then
            LockSmith.ChatMonitor:AddSessionIgnore(job.sender)
        end
        LockSmith.Dashboard:RemoveJob(index)
    end)

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
    -- Main stats cards
    local card1 = LockSmith.Dashboard:CreateStatCard(content, "Total Gold", "totalGold")
    card1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    card1:SetSize(180, 70)
    content.statCard1 = card1

    local card2 = LockSmith.Dashboard:CreateStatCard(content, "Total Jobs", "totalJobs")
    card2:SetPoint("LEFT", card1, "RIGHT", 10, 0)
    card2:SetSize(180, 70)
    content.statCard2 = card2

    local card3 = LockSmith.Dashboard:CreateStatCard(content, "Total Boxes", "totalBoxes")
    card3:SetPoint("TOPLEFT", card1, "BOTTOMLEFT", 0, -10)
    card3:SetSize(180, 70)
    content.statCard3 = card3

    local card4 = LockSmith.Dashboard:CreateStatCard(content, "Average Tip", "avgTip")
    card4:SetPoint("LEFT", card3, "RIGHT", 10, 0)
    card4:SetSize(180, 70)
    content.statCard4 = card4

    local card5 = LockSmith.Dashboard:CreateStatCard(content, "Last Session", "lastSession")
    card5:SetPoint("TOPLEFT", card3, "BOTTOMLEFT", 0, -10)
    card5:SetSize(180, 70)
    content.statCard5 = card5

    -- Per-box breakdown
    local boxHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    boxHeader:SetPoint("TOPLEFT", card3, "BOTTOMLEFT", 0, -90)
    boxHeader:SetText("|cffffcc00Boxes Opened|r")

    -- Scrollable box list
    local boxScrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    boxScrollFrame:SetPoint("TOPLEFT", boxHeader, "BOTTOMLEFT", 0, -10)
    boxScrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 50)

    local boxContentFrame = CreateFrame("Frame", nil, boxScrollFrame)
    boxContentFrame:SetSize(boxScrollFrame:GetWidth(), 1)
    boxScrollFrame:SetScrollChild(boxContentFrame)
    content.boxContentFrame = boxContentFrame

    -- Reset button
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
    for i = 1, 5 do
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

    local boxContentFrame = tabs.stats.content.boxContentFrame
    if not boxContentFrame then return end

    -- Clear existing
    for _, child in ipairs({boxContentFrame:GetChildren()}) do
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

        local line = boxContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        line:SetPoint("TOPLEFT", boxContentFrame, "TOPLEFT", 10, yOffset)
        line:SetText(label .. ": |cff00ff00" .. boxData.count .. "|r")

        yOffset = yOffset - lineHeight
    end

    -- Update content height
    local totalHeight = math.max(1, #boxList * lineHeight + 10)
    boxContentFrame:SetHeight(totalHeight)
end

function LockSmith.Dashboard:InitializeSettings(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("Settings - Coming Soon")
end
