-- Minimap.lua
-- Minimap button for LockSmithPro

LockSmithPro = LockSmithPro or {}
LockSmithPro.Minimap = {}

local minimapButton = nil
local isDragging = false

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
    GameTooltip:AddLine("Lockpicking: " .. skill .. "/" .. maxSkill, 1, 1, 1)

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

    -- Create the icon texture (using a lockpicking-themed icon)
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER", 0, 0)
    -- Using the Lockpicking skill icon
    icon:SetTexture("Interface\\Icons\\Spell_Nature_MoonKey")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Keep the icon inside the circular minimap frame
    if button.CreateMaskTexture and icon.AddMaskTexture then
        local mask = button:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetPoint("CENTER", icon, "CENTER", 0, 0)
        mask:SetSize(18, 18)
        icon:AddMaskTexture(mask)
        button.iconMask = mask
    end

    button.icon = icon

    -- Create border/background
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Create highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(18, 18)
    highlight:SetPoint("CENTER", 0, 0)
    highlight:SetTexture("Interface\\Icons\\Spell_Nature_MoonKey")
    highlight:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    highlight:SetBlendMode("ADD")

    if button.iconMask and highlight.AddMaskTexture then
        highlight:AddMaskTexture(button.iconMask)
    end

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
        self:LockHighlight()
        self:SetScript("OnUpdate", function() LockSmithPro.Minimap:UpdateButtonPosition() end)
    end)

    button:SetScript("OnDragStop", function(self)
        isDragging = false
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)

        -- Save position
        local position = LockSmithPro.Minimap:GetButtonAngle()
        LockSmithProDB.minimapPosition = position
    end)

    minimapButton = button
    return button
end

-- Update minimap button position while dragging
function LockSmithPro.Minimap:UpdateButtonPosition()
    if not minimapButton then return end

    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()

    px, py = px / scale, py / scale

    local angle = math.deg(math.atan2(py - my, px - mx))

    LockSmithProDB.minimapPosition = angle
    self:SetButtonPosition(angle)
end

-- Set minimap button position by angle
function LockSmithPro.Minimap:SetButtonPosition(angle)
    if not minimapButton then return end

    local radius = 80
    local rads = math.rad(angle)
    local x = math.cos(rads) * radius
    local y = math.sin(rads) * radius

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Get current minimap button angle
function LockSmithPro.Minimap:GetButtonAngle()
    if not minimapButton then return 0 end

    local mx, my = Minimap:GetCenter()
    local bx, by = minimapButton:GetCenter()

    if not bx or not by then return 0 end

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
