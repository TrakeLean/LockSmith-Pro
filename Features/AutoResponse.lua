-- AutoResponse.lua
-- Auto-response system for insufficient skill

LockSmithPro = LockSmithPro or {}
LockSmithPro.AutoResponse = {}

-- Send low skill whisper
function LockSmithPro.AutoResponse:SendLowSkillWhisper(target, currentSkill, requiredSkill)
    if not LockSmithProDB.lowSkillWhisper then
        return false
    end

    local message = LockSmithProDB.lowSkillMessage
    message = string.gsub(message, "%%CURRENT%%", tostring(currentSkill))
    message = string.gsub(message, "%%REQUIRED%%", tostring(requiredSkill))

    return LockSmithPro.Utils:SendThrottledWhisper(target, message)
end

-- Handle a lockpick request that we can't fulfill
function LockSmithPro.AutoResponse:HandleInsufficientSkill(sender, boxData)
    local currentSkill = LockSmithPro.Skills:GetCachedSkill()
    local requiredSkill = boxData and boxData.skill or 1

    self:SendLowSkillWhisper(sender, currentSkill, requiredSkill)
end

-- Send thank-you whisper after a tip
function LockSmithPro.AutoResponse:SendThankYouWhisper(target, tipAmount)
    if not LockSmithProDB or not LockSmithProDB.thankYouWhisper then
        return false
    end
    if not target or target == "" then
        return false
    end

    local message = LockSmithProDB.thankYouMessage
    if type(message) ~= "string" or message == "" then
        return false
    end

    local tipText = LockSmithPro.Utils:FormatGold(tipAmount or 0)
    message = string.gsub(message, "%%TIP%%", tipText)

    -- Send thank-you without throttling (trade just completed, important message)
    SendChatMessage(message, "WHISPER", nil, target)
    print("|cff00ff00LockSmithPro:|r Sent thank-you whisper to " .. target)
    return true
end
