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

-- Placeholder functions (will be implemented next)
function LockSmith.Dashboard:InitializeJobBoard(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("Job Board - Coming Soon")
end

function LockSmith.Dashboard:InitializeStats(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("Stats - Coming Soon")
end

function LockSmith.Dashboard:InitializeSettings(content)
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText("Settings - Coming Soon")
end
