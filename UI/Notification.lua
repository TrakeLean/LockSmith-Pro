-- Notification.lua
-- Notification popup UI

LockSmith = LockSmith or {}
LockSmith.UI = LockSmith.UI or {}

local activeNotification = nil

-- Create notification popup
local function CreateNotificationPopup()
    -- Main frame
    local frame = CreateFrame("Frame", "LockSmithNotificationPopup", UIParent, "DialogBoxFrame")
    frame:SetSize(400, 200)
    frame:SetPoint("TOP", 0, -100)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    -- Make draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Title
    local titleBg = frame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetTexture(0, 0, 0, 0.8)
    titleBg:SetPoint("TOPLEFT", 5, -5)
    titleBg:SetPoint("TOPRIGHT", -5, -5)
    titleBg:SetHeight(30)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff00ff00Lockpick Request|r")
    frame.title = title

    -- Player name
    local playerName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerName:SetPoint("TOP", 0, -50)
    playerName:SetText("Player: Unknown")
    frame.playerName = playerName

    -- Box info
    local boxInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    boxInfo:SetPoint("TOP", 0, -70)
    boxInfo:SetText("Box: Unknown")
    frame.boxInfo = boxInfo

    -- Skill info
    local skillInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    skillInfo:SetPoint("TOP", 0, -90)
    skillInfo:SetText("Required Skill: 1")
    frame.skillInfo = skillInfo

    -- Your skill
    local yourSkill = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yourSkill:SetPoint("TOP", 0, -110)
    yourSkill:SetText("Your Skill: 1")
    frame.yourSkill = yourSkill

    -- Buttons
    local btnY = -150

    -- Invite button
    local inviteBtn = CreateFrame("Button", "LockSmithNotifyInviteBtn", frame, "GameMenuButtonTemplate")
    inviteBtn:SetSize(100, 25)
    inviteBtn:SetPoint("TOPLEFT", 30, btnY)
    inviteBtn:SetText("Invite")
    frame.inviteBtn = inviteBtn

    -- Whisper button
    local whisperBtn = CreateFrame("Button", "LockSmithNotifyWhisperBtn", frame, "GameMenuButtonTemplate")
    whisperBtn:SetSize(100, 25)
    whisperBtn:SetPoint("TOP", 0, btnY)
    whisperBtn:SetText("Whisper")
    frame.whisperBtn = whisperBtn

    -- Ignore button
    local ignoreBtn = CreateFrame("Button", "LockSmithNotifyIgnoreBtn", frame, "GameMenuButtonTemplate")
    ignoreBtn:SetSize(100, 25)
    ignoreBtn:SetPoint("TOPRIGHT", -30, btnY)
    ignoreBtn:SetText("Ignore")
    frame.ignoreBtn = ignoreBtn

    return frame
end

-- Show notification popup
function LockSmith.UI:ShowNotificationPopup(sender, boxData, channelName, requiredSkill)
    -- Create popup if it doesn't exist
    if not activeNotification then
        activeNotification = CreateNotificationPopup()
    end

    -- Update info
    activeNotification.playerName:SetText("|cffffffff Player:|r " .. sender)

    if boxData then
        activeNotification.boxInfo:SetText("|cffffffff Box:|r " .. boxData.name)
        activeNotification.skillInfo:SetText("|cffffffff Required Skill:|r " .. boxData.skill)
    else
        activeNotification.boxInfo:SetText("|cffffffff Box:|r Unknown (Generic Request)")
        activeNotification.skillInfo:SetText("|cffffffff Required Skill:|r Unknown")
    end

    local currentSkill, maxSkill = LockSmith.Skills:GetLockpickingSkill()
    activeNotification.yourSkill:SetText("|cff00ff00 Your Skill:|r " .. currentSkill .. "/" .. maxSkill)

    -- Setup button actions
    activeNotification.inviteBtn:SetScript("OnClick", function(self)
        InviteUnit(sender)
        print("|cff00ff00LockSmith:|r Invited " .. sender)
        activeNotification:Hide()
    end)

    activeNotification.whisperBtn:SetScript("OnClick", function(self)
        -- Open whisper window
        ChatFrame_SendTell(sender)
        activeNotification:Hide()
    end)

    activeNotification.ignoreBtn:SetScript("OnClick", function(self)
        activeNotification:Hide()
    end)

    -- Play sound
    PlaySound("TellMessage")

    -- Show popup
    activeNotification:Show()
end
