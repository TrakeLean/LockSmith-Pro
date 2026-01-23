-- Skills.lua
-- Lockpicking skill detection and management

LockSmith = LockSmith or {}
LockSmith.Skills = {}

local currentLockpickSkill = 0
local currentMaxSkill = 0

-- Get current lockpicking skill
function LockSmith.Skills:GetLockpickingSkill()
    local numSkills = GetNumSkillLines()
    for i = 1, numSkills do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(i)
        if not isHeader and skillName == "Lockpicking" then
            currentLockpickSkill = skillRank or 0
            currentMaxSkill = skillMaxRank or 0
            return currentLockpickSkill, currentMaxSkill
        end
    end
    currentLockpickSkill = 0
    currentMaxSkill = 0
    return 0, 0
end

-- Get cached skill values (faster, doesn't query game)
function LockSmith.Skills:GetCachedSkill()
    return currentLockpickSkill, currentMaxSkill
end

-- Check if player can pick a specific box
function LockSmith.Skills:CanPickBox(requiredSkill)
    return currentLockpickSkill >= requiredSkill
end

-- Update skill cache (call this when skill might have changed)
function LockSmith.Skills:UpdateCache()
    return self:GetLockpickingSkill()
end
