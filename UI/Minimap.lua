-- Minimap.lua
-- Minimap button for LockSmith

LockSmith = LockSmith or {}
LockSmith.Minimap = {}

local minimapButton = nil
local isDragging = false

-- Create the minimap button
local function CreateMinimapButton()
    -- Create the button
    local button = CreateFrame("Button", "LockSmithMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Create the icon texture (using a lockpicking-themed icon)
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    -- Using the Lockpicking skill icon
    icon:SetTexture("Interface\\Icons\\Spell_Nature_MoonKey")
    button.icon = icon

    -- Create border/background
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Create highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(20, 20)
    highlight:SetPoint("CENTER", 0, 0)
    highlight:SetTexture("Interface\\Icons\\Spell_Nature_MoonKey")
    highlight:SetBlendMode("ADD")

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cff00ff00LockSmith|r", 1, 1, 1)

        if LockSmith:IsRunning() then
            local skill, maxSkill = LockSmith.Skills:GetLockpickingSkill()
            GameTooltip:AddLine("|cff00ff00Status: Running|r", 1, 1, 1)
            GameTooltip:AddLine("Lockpicking: " .. skill .. "/" .. maxSkill, 1, 1, 1)
        else
            GameTooltip:AddLine("|cffff0000Status: Stopped|r", 1, 1, 1)
        end

        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cffffffffLeft-Click:|r Toggle Dashboard", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cffffffffRight-Click:|r Start/Stop", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cffffffffShift+Click:|r Send Ad", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cffffffffDrag:|r Move Button", 0.7, 0.7, 0.7)

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Click handlers
    button:SetScript("OnClick", function(self, buttonPressed)
        if IsShiftKeyDown() then
            -- Shift+Click: Send advertisement
            LockSmith.Advertisement:SendAdvertisement()
        elseif buttonPressed == "LeftButton" then
            -- Left-click: Toggle dashboard
            if LockSmith.Dashboard then
                LockSmith.Dashboard:Toggle()
            end
        elseif buttonPressed == "RightButton" then
            -- Right-click: Toggle start/stop
            LockSmith:Toggle()
        end
    end)

    -- Dragging functionality
    button:SetScript("OnDragStart", function(self)
        isDragging = true
        self:LockHighlight()
        self:SetScript("OnUpdate", function() LockSmith.Minimap:UpdateButtonPosition() end)
    end)

    button:SetScript("OnDragStop", function(self)
        isDragging = false
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)

        -- Save position
        local position = LockSmith.Minimap:GetButtonAngle()
        LockSmithDB.minimapPosition = position
    end)

    minimapButton = button
    return button
end

-- Update minimap button position while dragging
function LockSmith.Minimap:UpdateButtonPosition()
    if not minimapButton then return end

    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()

    px, py = px / scale, py / scale

    local angle = math.deg(math.atan2(py - my, px - mx))

    LockSmithDB.minimapPosition = angle
    self:SetButtonPosition(angle)
end

-- Set minimap button position by angle
function LockSmith.Minimap:SetButtonPosition(angle)
    if not minimapButton then return end

    local radius = 80
    local rads = math.rad(angle)
    local x = math.cos(rads) * radius
    local y = math.sin(rads) * radius

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Get current minimap button angle
function LockSmith.Minimap:GetButtonAngle()
    if not minimapButton then return 0 end

    local mx, my = Minimap:GetCenter()
    local bx, by = minimapButton:GetCenter()

    if not bx or not by then return 0 end

    local angle = math.deg(math.atan2(by - my, bx - mx))
    return angle
end

-- Initialize minimap button
function LockSmith.Minimap:InitializeButton()
    if minimapButton then return end

    -- Create button
    CreateMinimapButton()

    -- Set initial position
    local angle = LockSmithDB.minimapPosition or 225
    self:SetButtonPosition(angle)

    -- Show/hide based on settings
    if LockSmithDB.minimapButtonHidden then
        minimapButton:Hide()
    else
        minimapButton:Show()
    end
end

-- Show/hide minimap button
function LockSmith.Minimap:ShowButton()
    if minimapButton then
        minimapButton:Show()
        LockSmithDB.minimapButtonHidden = false
    end
end

function LockSmith.Minimap:HideButton()
    if minimapButton then
        minimapButton:Hide()
        LockSmithDB.minimapButtonHidden = true
    end
end

function LockSmith.Minimap:ToggleButton()
    if LockSmithDB.minimapButtonHidden then
        self:ShowButton()
    else
        self:HideButton()
    end
end

-- Update minimap button icon based on status
function LockSmith.Minimap:UpdateButtonStatus()
    if not minimapButton then return end

    -- Could change icon color/appearance based on running status
    -- For now, tooltip will show the status
end
