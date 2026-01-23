-- Notification.lua
-- Notification popup UI

LockSmith = LockSmith or {}
LockSmith.UI = LockSmith.UI or {}

local activeNotification = nil
local activeAdNotification = nil

local function HideDialogButtons(frame)
    if not frame then return end

    -- Hide template buttons by name
    if frame.GetName and frame:GetName() then
        local name = frame:GetName()
        for i = 1, 3 do
            local btn = _G[name .. "Button" .. i]
            if btn then
                btn:Hide()
                btn:SetAlpha(0)
                btn:EnableMouse(false)
                btn:SetScript("OnClick", nil)
            end
        end
    end

    -- Hide button references
    for i = 1, 3 do
        local btnName = "button" .. i
        if frame[btnName] then
            frame[btnName]:Hide()
            frame[btnName]:SetAlpha(0)
            frame[btnName]:EnableMouse(false)
            frame[btnName]:SetScript("OnClick", nil)
        end
    end

    -- Force hide all children that look like buttons
    if frame.GetChildren then
        for _, child in ipairs({frame:GetChildren()}) do
            if child.GetObjectType and child:GetObjectType() == "Button" then
                local name = child:GetName()
                if name and (string.find(name, "Button") or name == "button1" or name == "button2" or name == "button3") then
                    child:Hide()
                    child:SetAlpha(0)
                    child:EnableMouse(false)
                end
            end
        end
    end
end

local function PlayNotificationSound()
    if SOUNDKIT and SOUNDKIT.TELL_MESSAGE then
        PlaySound(SOUNDKIT.TELL_MESSAGE, "Master")
        return
    end

    if PlaySound then
        PlaySound("TellMessage")
    end
end

local function CreateAdReadyPopup()
    local frame = CreateFrame("Frame", "LockSmithAdReadyPopup", UIParent, "DialogBoxFrame")
    frame:SetSize(380, 170)
    frame:SetPoint("TOP", 0, -140)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    HideDialogButtons(frame)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff00ff00Advertisement Ready|r")
    frame.title = title

    local message = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message:SetPoint("TOP", 0, -45)
    message:SetWidth(320)
    message:SetJustifyH("CENTER")
    message:SetJustifyV("TOP")
    message:SetText("Click Send to post your ad.")
    frame.message = message

    -- Send button (left)
    local sendBtn = CreateFrame("Button", "LockSmithAdReadySendBtn", frame, "GameMenuButtonTemplate")
    sendBtn:SetSize(100, 25)
    sendBtn:SetPoint("BOTTOMLEFT", 25, 20)
    sendBtn:SetText("Send Now")
    frame.sendBtn = sendBtn

    -- Stop button (middle)
    local stopBtn = CreateFrame("Button", "LockSmithAdReadyStopBtn", frame, "GameMenuButtonTemplate")
    stopBtn:SetSize(100, 25)
    stopBtn:SetPoint("BOTTOM", 0, 20)
    stopBtn:SetText("Stop")
    frame.stopBtn = stopBtn

    -- Dismiss button (right)
    local dismissBtn = CreateFrame("Button", "LockSmithAdReadyDismissBtn", frame, "GameMenuButtonTemplate")
    dismissBtn:SetSize(100, 25)
    dismissBtn:SetPoint("BOTTOMRIGHT", -25, 20)
    dismissBtn:SetText("Dismiss")
    frame.dismissBtn = dismissBtn

    return frame
end

-- Create notification popup
local function CreateNotificationPopup()
    -- Main frame
    local frame = CreateFrame("Frame", "LockSmithNotificationPopup", UIParent, "DialogBoxFrame")
    frame:SetSize(400, 250)
    frame:SetPoint("TOP", 0, -100)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    -- Make draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    HideDialogButtons(frame)

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
    playerName:SetWidth(340)
    playerName:SetJustifyH("CENTER")
    playerName:SetJustifyV("TOP")
    playerName:SetText("Player: Unknown")
    frame.playerName = playerName

    -- Message text
    local requestText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    requestText:SetPoint("TOP", playerName, "BOTTOM", 0, -6)
    requestText:SetWidth(340)
    requestText:SetJustifyH("CENTER")
    requestText:SetJustifyV("TOP")
    if requestText.SetWordWrap then
        requestText:SetWordWrap(true)
    end
    requestText:SetText("Message: ")
    frame.requestText = requestText

    -- Box info
    local boxInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    boxInfo:SetPoint("TOP", requestText, "BOTTOM", 0, -8)
    boxInfo:SetWidth(340)
    boxInfo:SetJustifyH("CENTER")
    boxInfo:SetJustifyV("TOP")
    boxInfo:SetText("Box: Unknown")
    frame.boxInfo = boxInfo

    -- Skill info
    local skillInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    skillInfo:SetPoint("TOP", boxInfo, "BOTTOM", 0, -4)
    skillInfo:SetWidth(340)
    skillInfo:SetJustifyH("CENTER")
    skillInfo:SetJustifyV("TOP")
    skillInfo:SetText("Required Skill: 1")
    frame.skillInfo = skillInfo

    -- Your skill
    local yourSkill = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yourSkill:SetPoint("TOP", skillInfo, "BOTTOM", 0, -4)
    yourSkill:SetWidth(340)
    yourSkill:SetJustifyH("CENTER")
    yourSkill:SetJustifyV("TOP")
    yourSkill:SetText("Your Skill: 1")
    frame.yourSkill = yourSkill

    -- Buttons (4 buttons in 2 rows)
    local btnY1 = 45  -- Top row
    local btnY2 = 15  -- Bottom row

    -- Invite button (top left)
    local inviteBtn = CreateFrame("Button", "LockSmithNotifyInviteBtn", frame, "GameMenuButtonTemplate")
    inviteBtn:SetSize(90, 25)
    inviteBtn:SetPoint("BOTTOMLEFT", 25, btnY1)
    inviteBtn:SetText("Invite")
    frame.inviteBtn = inviteBtn

    -- Whisper button (top right)
    local whisperBtn = CreateFrame("Button", "LockSmithNotifyWhisperBtn", frame, "GameMenuButtonTemplate")
    whisperBtn:SetSize(90, 25)
    whisperBtn:SetPoint("BOTTOMRIGHT", -25, btnY1)
    whisperBtn:SetText("Whisper")
    frame.whisperBtn = whisperBtn

    -- Ignore Session button (bottom left)
    local ignoreSessionBtn = CreateFrame("Button", "LockSmithNotifyIgnoreSessionBtn", frame, "GameMenuButtonTemplate")
    ignoreSessionBtn:SetSize(90, 25)
    ignoreSessionBtn:SetPoint("BOTTOMLEFT", 25, btnY2)
    ignoreSessionBtn:SetText("Ignore Session")
    frame.ignoreSessionBtn = ignoreSessionBtn

    -- Dismiss button (bottom right)
    local ignoreBtn = CreateFrame("Button", "LockSmithNotifyIgnoreBtn", frame, "GameMenuButtonTemplate")
    ignoreBtn:SetSize(90, 25)
    ignoreBtn:SetPoint("BOTTOMRIGHT", -25, btnY2)
    ignoreBtn:SetText("Dismiss")
    frame.ignoreBtn = ignoreBtn

    return frame
end

-- Show notification popup
function LockSmith.UI:ShowNotificationPopup(sender, boxData, channelName, requiredSkill, message)
    -- Create popup if it doesn't exist
    if not activeNotification then
        activeNotification = CreateNotificationPopup()
    end

    -- Update info
    activeNotification.playerName:SetText("|cffffffff Player:|r " .. sender)
    if type(message) == "string" and message ~= "" then
        local trimmed = message
        if string.len(trimmed) > 200 then
            trimmed = string.sub(trimmed, 1, 197) .. "..."
        end
        activeNotification.requestText:SetText("|cffffffff Message:|r " .. trimmed)
    else
        activeNotification.requestText:SetText("|cffffffff Message:|r (none)")
    end

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
        if LockSmith.Utils and LockSmith.Utils.InvitePlayer and LockSmith.Utils:InvitePlayer(sender) then
            print("|cff00ff00LockSmith:|r Invited " .. sender)
        else
            print("|cffff0000LockSmith:|r Unable to invite " .. sender)
        end
        activeNotification:Hide()
    end)

    activeNotification.whisperBtn:SetScript("OnClick", function(self)
        -- Open whisper window
        ChatFrame_SendTell(sender)
        activeNotification:Hide()
    end)

    activeNotification.ignoreSessionBtn:SetScript("OnClick", function(self)
        LockSmith.ChatMonitor:AddToSessionIgnore(sender)
        activeNotification:Hide()
    end)

    activeNotification.ignoreBtn:SetScript("OnClick", function(self)
        activeNotification:Hide()
    end)

    -- Play sound
    PlayNotificationSound()

    -- Show popup
    activeNotification:Show()
end

function LockSmith.UI:ShowAdReadyPopup()
    if not activeAdNotification then
        activeAdNotification = CreateAdReadyPopup()
    end

    local msg = LockSmithDB and LockSmithDB.adMessage or ""
    if msg == "" then
        msg = "No advertisement message set."
    end
    activeAdNotification.message:SetText("|cffffffffMessage:|r " .. msg)

    activeAdNotification.sendBtn:SetScript("OnClick", function()
        LockSmith.Advertisement:SendAdvertisement()
    end)

    activeAdNotification.stopBtn:SetScript("OnClick", function()
        LockSmith:Stop()
        activeAdNotification:Hide()
    end)

    activeAdNotification.dismissBtn:SetScript("OnClick", function()
        if LockSmith.Advertisement and LockSmith.Advertisement.ClearAdReady then
            LockSmith.Advertisement:ClearAdReady()
        else
            activeAdNotification:Hide()
        end
    end)

    PlayNotificationSound()
    activeAdNotification:Show()
end

function LockSmith.UI:HideAdReadyPopup()
    if activeAdNotification then
        activeAdNotification:Hide()
    end
end
