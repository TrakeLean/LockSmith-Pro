-- AutoResponse.lua
-- Auto-response system for insufficient skill

LockSmith = LockSmith or {}
LockSmith.AutoResponse = {}

-- Send low skill whisper
function LockSmith.AutoResponse:SendLowSkillWhisper(target, currentSkill, requiredSkill)
    if not LockSmithDB.lowSkillWhisper then
        return false
    end

    local message = LockSmithDB.lowSkillMessage
    message = string.gsub(message, "%%CURRENT%%", tostring(currentSkill))
    message = string.gsub(message, "%%REQUIRED%%", tostring(requiredSkill))

    return LockSmith.Utils:SendThrottledWhisper(target, message)
end

-- Handle a lockpick request that we can't fulfill
function LockSmith.AutoResponse:HandleInsufficientSkill(sender, boxData)
    local currentSkill = LockSmith.Skills:GetCachedSkill()
    local requiredSkill = boxData and boxData.skill or 1

    self:SendLowSkillWhisper(sender, currentSkill, requiredSkill)
end

-- Send thank-you whisper after a tip
function LockSmith.AutoResponse:SendThankYouWhisper(target, tipAmount)
    if not LockSmithDB or not LockSmithDB.thankYouWhisper then
        return false
    end
    if not target or target == "" then
        return false
    end

    local message = LockSmithDB.thankYouMessage
    if type(message) ~= "string" or message == "" then
        return false
    end

    local tipText = LockSmith.Utils:FormatGold(tipAmount or 0)
    message = string.gsub(message, "%%TIP%%", tipText)

    -- Send thank-you without throttling (trade just completed, important message)
    SendChatMessage(message, "WHISPER", nil, target)
    return true
end
