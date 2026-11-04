-- Skills.lua
-- Lockpicking skill detection and management

LockSmithPro = LockSmithPro or {}
LockSmithPro.Skills = {}

local currentLockpickSkill = 0
local currentMaxSkill = 0
local skillKnown = false
local LOCKPICK_SKILL_LINE_ID = 633

local function TrimString(value)
    if not LockSmithPro.Compat:IsString(value) then
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

    if (C_Spell and C_Spell.GetSpellName) or GetSpellInfo then
        local pickLockName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(1804) or (GetSpellInfo and GetSpellInfo(1804)) -- Pick Lock spell (localized)
        if NormalizeName(pickLockName) == normalizedSkillName then
            return true
        end
    end

    return false
end

-- Get current lockpicking skill
function LockSmithPro.Skills:GetLockpickingSkill()
    if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
        local data = C_SkillInfo.GetSkillLineInfoByID(LOCKPICK_SKILL_LINE_ID)
        if data and LockSmithPro.Compat:IsNumber(data.rank) and LockSmithPro.Compat:IsNumber(data.maxRank) then
            currentLockpickSkill, currentMaxSkill, skillKnown = data.rank, data.maxRank, true
            return currentLockpickSkill, currentMaxSkill, skillKnown
        end
    end
    -- Newer clients: profession info provides locale-independent skillLine IDs
    if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
        local primary1, primary2, archaeology, fishing, cooking, firstAid = GetProfessions()
        for _, professionIndex in pairs({ primary1, primary2, archaeology, fishing, cooking, firstAid }) do
            if professionIndex then
                local skillName, icon, skillRank, skillMaxRank, numAbilities, spellOffset, skillLine = GetProfessionInfo(professionIndex)
                if skillLine == LOCKPICK_SKILL_LINE_ID or IsLockpickingName(skillName) then
                    currentLockpickSkill = skillRank or 0
                    currentMaxSkill = skillMaxRank or 0
                    skillKnown = true
                return currentLockpickSkill, currentMaxSkill, skillKnown
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
                skillKnown = true
                return currentLockpickSkill, currentMaxSkill, skillKnown
            end
        end
    end

    currentLockpickSkill = 0
    currentMaxSkill = 0
    skillKnown = false
    return 0, 0, false
end

-- Get cached skill values (faster, doesn't query game)
function LockSmithPro.Skills:GetCachedSkill()
    return currentLockpickSkill, currentMaxSkill, skillKnown
end

-- Check if player can pick a specific box
function LockSmithPro.Skills:CanPickBox(requiredSkill)
    return skillKnown and currentLockpickSkill >= requiredSkill
end

-- Update skill cache (call this when skill might have changed)
function LockSmithPro.Skills:UpdateCache()
    return self:GetLockpickingSkill()
end

function LockSmithPro.Skills:GetDisplayText()
    if not skillKnown then return "Unknown (check in game)" end
    return currentLockpickSkill .. "/" .. currentMaxSkill
end
local skillFrame = CreateFrame("Frame")
skillFrame:RegisterEvent("SKILL_LINES_CHANGED")
skillFrame:RegisterEvent("SPELLS_CHANGED")
skillFrame:RegisterEvent("PLAYER_LEVEL_UP")
skillFrame:SetScript("OnEvent", function() LockSmithPro.Skills:UpdateCache() end)
