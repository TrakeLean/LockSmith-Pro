-- Skills.lua
-- Lockpicking skill detection and management

LockSmithPro = LockSmithPro or {}
LockSmithPro.Skills = {}

local currentLockpickSkill = 0
local currentMaxSkill = 0
local LOCKPICK_SKILL_LINE_ID = 633

local function TrimString(value)
    if type(value) ~= "string" then
        return ""
    end

    if strtrim then
        return strtrim(value)
    end

    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NormalizeName(value)
    return string.lower(TrimString(value))
end

local function IsLockpickingName(skillName)
    local normalizedSkillName = NormalizeName(skillName)
    if normalizedSkillName == "" then
        return false
    end

    if normalizedSkillName == "lockpicking" then
        return true
    end

    if type(GetSpellInfo) == "function" then
        local pickLockName = GetSpellInfo(1804) -- Pick Lock spell (localized)
        if NormalizeName(pickLockName) == normalizedSkillName then
            return true
        end
    end

    return false
end

-- Get current lockpicking skill
function LockSmithPro.Skills:GetLockpickingSkill()
    -- Newer clients: profession info provides locale-independent skillLine IDs
    if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
        local primary1, primary2, archaeology, fishing, cooking, firstAid = GetProfessions()
        for _, professionIndex in ipairs({ primary1, primary2, archaeology, fishing, cooking, firstAid }) do
            if professionIndex then
                local skillName, icon, skillRank, skillMaxRank, numAbilities, spellOffset, skillLine = GetProfessionInfo(professionIndex)
                if skillLine == LOCKPICK_SKILL_LINE_ID or IsLockpickingName(skillName) then
                    currentLockpickSkill = skillRank or 0
                    currentMaxSkill = skillMaxRank or 0
                    return currentLockpickSkill, currentMaxSkill
                end
            end
        end
    end

    -- Older clients: fallback to skill-line scanning
    if type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
        local numSkills = GetNumSkillLines()
        for i = 1, numSkills do
            local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(i)
            if not isHeader and IsLockpickingName(skillName) then
                currentLockpickSkill = skillRank or 0
                currentMaxSkill = skillMaxRank or 0
                return currentLockpickSkill, currentMaxSkill
            end
        end
    end

    currentLockpickSkill = 0
    currentMaxSkill = 0
    return 0, 0
end

-- Get cached skill values (faster, doesn't query game)
function LockSmithPro.Skills:GetCachedSkill()
    return currentLockpickSkill, currentMaxSkill
end

-- Check if player can pick a specific box
function LockSmithPro.Skills:CanPickBox(requiredSkill)
    return currentLockpickSkill >= requiredSkill
end

-- Update skill cache (call this when skill might have changed)
function LockSmithPro.Skills:UpdateCache()
    return self:GetLockpickingSkill()
end
