-- Database.lua
-- Contains all junkbox/lockbox definitions and skill requirements

LockSmith = LockSmith or {}
LockSmith.BoxDatabase = {}

-- Junkbox and Lockbox database with skill requirements
LockSmith.BoxDatabase = {
    -- Junkboxes (pickpocketed items)
    ["battered"] = {
        name = "Battered Junkbox",
        skill = 1,
        itemID = 16882,
        type = "junkbox"
    },
    ["worn"] = {
        name = "Worn Junkbox",
        skill = 100,
        itemID = 16883,
        type = "junkbox"
    },
    ["sturdy"] = {
        name = "Sturdy Junkbox",
        skill = 175,
        itemID = 16884,
        type = "junkbox"
    },
    ["heavy"] = {
        name = "Heavy Junkbox",
        skill = 250,
        itemID = 16885,
        type = "junkbox",
        expansion = "classic"
    },
    ["strong junkbox"] = {
        name = "Strong Junkbox",
        skill = 300,
        itemID = 29569,
        type = "junkbox",
        expansion = "tbc"
    },

    -- World lockboxes
    ["strong iron"] = {
        name = "Strong Iron Lockbox",
        skill = 125,
        itemID = 4636,
        type = "lockbox"
    },
    ["steel"] = {
        name = "Steel Lockbox",
        skill = 175,
        itemID = 4637,
        type = "lockbox"
    },
    ["reinforced steel"] = {
        name = "Reinforced Steel Lockbox",
        skill = 225,
        itemID = 4638,
        type = "lockbox"
    },
    ["mithril"] = {
        name = "Mithril Lockbox",
        skill = 225,
        itemID = 5758,
        type = "lockbox"
    },
    ["thorium"] = {
        name = "Thorium Lockbox",
        skill = 225,
        itemID = 5759,
        type = "lockbox",
        expansion = "classic"
    },
    ["eternium"] = {
        name = "Eternium Lockbox",
        skill = 225,
        itemID = 5760,
        type = "lockbox",
        expansion = "classic"
    },
    ["khorium"] = {
        name = "Khorium Lockbox",
        skill = 325,
        itemID = 31952,
        type = "lockbox",
        expansion = "tbc"
    },
    ["ironbound"] = {
        name = "Ironbound Locked Chest",
        skill = 175,
        itemID = 13875,
        type = "chest",
        expansion = "classic"
    },
    ["reinforced locked"] = {
        name = "Reinforced Locked Chest",
        skill = 250,
        itemID = 13918,
        type = "chest",
        expansion = "classic"
    },

    -- Generic terms (match to lowest/most common)
    ["junkbox"] = {
        name = "Junkbox (Generic)",
        skill = 1,
        itemID = nil,
        type = "generic"
    },
    ["lockbox"] = {
        name = "Lockbox (Generic)",
        skill = 125,
        itemID = nil,
        type = "generic"
    },
    ["chest"] = {
        name = "Locked Chest (Generic)",
        skill = 175,
        itemID = nil,
        type = "generic"
    },
}

-- Fast lookups by item ID
LockSmith.BoxDatabaseById = {}
for key, data in pairs(LockSmith.BoxDatabase) do
    data.key = key
    if data.itemID then
        LockSmith.BoxDatabaseById[data.itemID] = key
    end
end

-- Detect WoW version
local function DetectWoWVersion()
    local version, build, date, tocversion = GetBuildInfo()

    -- Interface version ranges
    if tocversion >= 100000 then
        return "retail" -- Retail (Dragonflight+)
    elseif tocversion >= 30000 and tocversion < 40000 then
        return "wrath" -- Wrath of the Lich King
    elseif tocversion >= 20000 and tocversion < 30000 then
        return "tbc" -- The Burning Crusade
    elseif tocversion >= 11000 and tocversion < 20000 then
        return "classic" -- Classic/Vanilla
    else
        return "unknown"
    end
end

LockSmith.CurrentExpansion = DetectWoWVersion()

-- Get boxes relevant to current expansion
function LockSmith:GetRelevantBoxes()
    local relevant = {}
    local currentExp = self.CurrentExpansion

    for key, data in pairs(self.BoxDatabase) do
        -- Include if no expansion specified (generic) or matches current expansion or earlier
        if not data.expansion or data.expansion == "generic" then
            relevant[key] = data
        elseif currentExp == "tbc" and (data.expansion == "classic" or data.expansion == "tbc") then
            relevant[key] = data
        elseif currentExp == "wrath" and (data.expansion == "classic" or data.expansion == "tbc" or data.expansion == "wrath") then
            relevant[key] = data
        elseif currentExp == "classic" and data.expansion == "classic" then
            relevant[key] = data
        elseif currentExp == "retail" then
            relevant[key] = data -- Include all for retail
        end
    end

    return relevant
end

-- Keywords that indicate a lockpicking request
LockSmith.LockpickKeywords = {
    "lockpick",
    "lock pick",
    "pick lock",
    "lockbox",
    "lockboxes",
    "unlock",
    "open box",
    "open junk",
    "open chest",
    "pick my",
    "need pick",
    "need lockpick",
    "rogue pick",
    "rogue lockpick",
    "can someone pick",
    "anyone pick",
    "need a rogue",
}

-- Function to identify box type from message
function LockSmith:IdentifyBoxType(message)
    if type(message) ~= "string" then
        return nil
    end
    local lowerMsg = string.lower(message)

    -- Use only boxes relevant to current expansion
    local relevantBoxes = self:GetRelevantBoxes()

    -- Check for specific box types (longest matches first to avoid false positives)
    local sortedKeys = {}
    for keyword, _ in pairs(relevantBoxes) do
        table.insert(sortedKeys, keyword)
    end

    -- Sort by length (descending) to match longer phrases first
    table.sort(sortedKeys, function(a, b) return string.len(a) > string.len(b) end)

    for _, keyword in ipairs(sortedKeys) do
        if string.find(lowerMsg, keyword, 1, true) then
            return relevantBoxes[keyword]
        end
    end

    return nil
end

-- Resolve box data from an item link or name
function LockSmith:GetBoxDataFromItemLink(itemLink, itemName)
    if type(itemLink) == "string" then
        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
        if itemID and self.BoxDatabaseById and self.BoxDatabaseById[itemID] then
            local key = self.BoxDatabaseById[itemID]
            return self.BoxDatabase[key]
        end
    end

    if type(itemName) == "string" then
        return self:IdentifyBoxType(itemName)
    end

    return nil
end

-- Function to check if message contains lockpicking keywords
function LockSmith:HasLockpickKeyword(message)
    if type(message) ~= "string" then
        return false
    end
    local lowerMsg = string.lower(message)

    for _, keyword in ipairs(self.LockpickKeywords) do
        if string.find(lowerMsg, keyword, 1, true) then
            return true
        end
    end

    return false
end
