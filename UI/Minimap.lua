-- Minimap.lua
-- Minimap button for LockSmithPro

LockSmithPro = LockSmithPro or {}
LockSmithPro.Minimap = {}

local minimapButton = nil
local isDragging = false
local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Key_03"
local roundedQuadrants = {
    ROUND = {true, true, true, true},
    SQUARE = {false, false, false, false},
    ["CORNER-TOPLEFT"] = {false, false, false, true},
    ["CORNER-TOPRIGHT"] = {false, false, true, false},
    ["CORNER-BOTTOMLEFT"] = {false, true, false, false},
    ["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
    ["SIDE-LEFT"] = {false, true, false, true},
    ["SIDE-RIGHT"] = {true, false, true, false},
    ["SIDE-TOP"] = {false, false, true, true},
    ["SIDE-BOTTOM"] = {true, true, false, false},
    ["TRICORNER-TOPLEFT"] = {false, true, true, true},
    ["TRICORNER-TOPRIGHT"] = {true, false, true, true},
    ["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
    ["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
}

local function NormalizeAngle(angle)
    angle = tonumber(angle)
    if not angle or angle ~= angle or angle == math.huge or angle == -math.huge then return 225 end
    return angle % 360
end

local function RefreshMinimapTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("|cff00ff00LockSmithPro|r", 1, 1, 1)

    local skill, maxSkill = 0, 0
    if LockSmithPro.Skills and LockSmithPro.Skills.GetLockpickingSkill then
        skill, maxSkill = LockSmithPro.Skills:GetLockpickingSkill()
    end

    if LockSmithPro:IsRunning() then
        GameTooltip:AddLine("|cff00ff00Status: Running|r", 1, 1, 1)
    else
        GameTooltip:AddLine("|cffff0000Status: Stopped|r", 1, 1, 1)
    end
    GameTooltip:AddLine("Lockpicking: " .. LockSmithPro.Skills:GetDisplayText(), 1, 1, 1)

    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("|cffffffffLeft-Click:|r Toggle Dashboard", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cffffffffRight-Click:|r Start/Stop", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cffffffffShift+Click:|r Send Ad", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cffffffffDrag:|r Move Button", 0.7, 0.7, 0.7)

    GameTooltip:Show()
end

-- Create the minimap button
local function CreateMinimapButton()
    -- Create the button
    local button = CreateFrame("Button", "LockSmithProMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Align the artwork with the inset opening in the tracking border.
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", 7, -5)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)
    icon:SetTexture(ICON_TEXTURE)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Keep the icon inside the circular minimap frame
    if button.CreateMaskTexture and icon.AddMaskTexture then
        local mask = button:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetPoint("CENTER", icon, "CENTER", 0, 0)
        mask:SetSize(20, 20)
        icon:AddMaskTexture(mask)
        button.iconMask = mask
    end

    button.icon = icon

    -- Create border/background
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Use the native hover glow instead of brightening a second copy of the icon.
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        RefreshMinimapTooltip(self)
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Click handlers
    button:SetScript("OnClick", function(self, buttonPressed)
        if IsShiftKeyDown() then
            -- Shift+Click: Send advertisement
            LockSmithPro.Advertisement:SendAdvertisement()
        elseif buttonPressed == "LeftButton" then
            -- Left-click: Toggle dashboard
            if LockSmithPro.Dashboard then
                LockSmithPro.Dashboard:Toggle()
            end
        elseif buttonPressed == "RightButton" then
            -- Right-click: Toggle start/stop
            LockSmithPro:Toggle()
        end

        -- Refresh tooltip immediately if the mouse is still over the button
        if GameTooltip:IsOwned(self) then
            RefreshMinimapTooltip(self)
        end
    end)

    -- Dragging functionality
    button:SetScript("OnDragStart", function(self)
        isDragging = true
        GameTooltip:Hide()
        self:LockHighlight()
        self:SetScript("OnUpdate", function() LockSmithPro.Minimap:UpdateButtonPosition() end)
    end)

    button:SetScript("OnDragStop", function(self)
        isDragging = false
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)

        -- Save position
        LockSmithPro.Minimap:SetButtonPosition(LockSmithProDB.minimapPosition)
    end)

    button:SetScript("OnHide", function(self)
        isDragging = false
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    minimapButton = button
    local function Reposition()
        LockSmithPro.Minimap:SetButtonPosition(LockSmithProDB.minimapPosition)
    end
    Minimap:HookScript("OnSizeChanged", Reposition)
    Minimap:HookScript("OnShow", Reposition)
    return button
end

-- Update minimap button position while dragging
function LockSmithPro.Minimap:UpdateButtonPosition()
    if not minimapButton or not isDragging then return end

    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not mx or not my or not px or not py or not scale or scale <= 0 then return end

    px, py = px / scale, py / scale

    if px == mx and py == my then return end
    local angle = math.deg(math.atan2(py - my, px - mx))

    LockSmithProDB.minimapPosition = angle
    self:SetButtonPosition(angle)
end

-- Set minimap button position by angle
function LockSmithPro.Minimap:SetButtonPosition(angle)
    if not minimapButton then return end

    angle = NormalizeAngle(angle)
    LockSmithProDB.minimapPosition = angle
    local rads = math.rad(angle)
    local dx, dy = math.cos(rads), math.sin(rads)
    local radiusX = math.max(1, Minimap:GetWidth() / 2 + 10)
    local radiusY = math.max(1, Minimap:GetHeight() / 2 + 10)
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local quadrants = roundedQuadrants[shape] or roundedQuadrants.ROUND
    local quadrant = 1 + (dx < 0 and 1 or 0) + (dy > 0 and 2 or 0)
    local distance
    if quadrants[quadrant] then
        distance = 1 / math.sqrt((dx / radiusX)^2 + (dy / radiusY)^2)
    else
        distance = 1 / math.max(math.abs(dx) / radiusX, math.abs(dy) / radiusY)
    end
    local x, y = dx * distance, dy * distance

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Get current minimap button angle
function LockSmithPro.Minimap:GetButtonAngle()
    if not minimapButton then return 0 end

    local mx, my = Minimap:GetCenter()
    local bx, by = minimapButton:GetCenter()

    if not mx or not my or not bx or not by then return NormalizeAngle(LockSmithProDB.minimapPosition) end

    local angle = math.deg(math.atan2(by - my, bx - mx))
    return angle
end

-- Initialize minimap button
function LockSmithPro.Minimap:InitializeButton()
    if minimapButton then return end

    -- Create button
    CreateMinimapButton()

    -- Set initial position
    local angle = LockSmithProDB.minimapPosition or 225
    self:SetButtonPosition(angle)

    -- Show/hide based on settings
    if LockSmithProDB.minimapButtonHidden then
        minimapButton:Hide()
    else
        minimapButton:Show()
    end
end

-- Show/hide minimap button
function LockSmithPro.Minimap:ShowButton()
    if minimapButton then
        minimapButton:Show()
        LockSmithProDB.minimapButtonHidden = false
    end
end

function LockSmithPro.Minimap:HideButton()
    if minimapButton then
        minimapButton:Hide()
        LockSmithProDB.minimapButtonHidden = true
    end
end

function LockSmithPro.Minimap:ToggleButton()
    if LockSmithProDB.minimapButtonHidden then
        self:ShowButton()
    else
        self:HideButton()
    end
end

-- Update minimap button icon based on status
function LockSmithPro.Minimap:UpdateButtonStatus()
    if not minimapButton then return end

    -- Could change icon color/appearance based on running status
    -- For now, tooltip will show the status
end
