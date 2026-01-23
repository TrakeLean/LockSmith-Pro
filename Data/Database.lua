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
        type = "junkbox"
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
        type = "lockbox"
    },
    ["ironbound"] = {
        name = "Ironbound Locked Chest",
        skill = 175,
        itemID = 13875,
        type = "chest"
    },
    ["reinforced locked"] = {
        name = "Reinforced Locked Chest",
        skill = 250,
        itemID = 13918,
        type = "chest"
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

-- Keywords that indicate a lockpicking request
LockSmith.LockpickKeywords = {
    "lockpick",
    "lock pick",
    "pick lock",
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
    local lowerMsg = string.lower(message)

    -- Check for specific box types (longest matches first to avoid false positives)
    local sortedKeys = {}
    for keyword, _ in pairs(self.BoxDatabase) do
        table.insert(sortedKeys, keyword)
    end

    -- Sort by length (descending) to match longer phrases first
    table.sort(sortedKeys, function(a, b) return string.len(a) > string.len(b) end)

    for _, keyword in ipairs(sortedKeys) do
        if string.find(lowerMsg, keyword, 1, true) then
            return self.BoxDatabase[keyword]
        end
    end

    return nil
end

-- Function to check if message contains lockpicking keywords
function LockSmith:HasLockpickKeyword(message)
    local lowerMsg = string.lower(message)

    for _, keyword in ipairs(self.LockpickKeywords) do
        if string.find(lowerMsg, keyword, 1, true) then
            return true
        end
    end

    return false
end
