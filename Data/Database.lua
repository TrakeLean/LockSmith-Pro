-- Database.lua
-- Contains all junkbox/lockbox definitions and skill requirements

LockSmithPro = LockSmithPro or {}
LockSmithPro.BoxDatabase = {}

-- Junkbox and Lockbox database with skill requirements
LockSmithPro.BoxDatabase = {
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
    ["reinforced junkbox"] = {
        name = "Reinforced Junkbox",
        skill = 350,
        itemID = 43575,
        type = "junkbox",
        expansion = "wrath"
    },
    ["flame-scarred"] = {
        name = "Flame-Scarred Junkbox",
        skill = 400,
        itemID = 63349,
        type = "junkbox",
        expansion = "cata"
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
    ["froststeel"] = {
        name = "Froststeel Lockbox",
        skill = 375,
        itemID = 43622,
        type = "lockbox",
        expansion = "wrath"
    },
    ["titanium"] = {
        name = "Titanium Lockbox",
        skill = 400,
        itemID = 43624,
        type = "lockbox",
        expansion = "wrath"
    },
    ["elementium"] = {
        name = "Elementium Lockbox",
        skill = 425,
        itemID = 68729,
        type = "lockbox",
        expansion = "cata"
    },
    ["ghost iron"] = {
        name = "Ghost Iron Lockbox",
        skill = 450,
        itemID = 88567,
        type = "lockbox",
        expansion = "mop"
    },
    ["true steel"] = {
        name = "True Steel Lockbox",
        skill = 500,
        itemID = 116920,
        type = "lockbox",
        expansion = "wod"
    },
    ["leystone"] = {
        name = "Leystone Lockbox",
        skill = 550,
        itemID = 121331,
        type = "lockbox",
        expansion = "legion"
    },
    ["barnacled"] = {
        name = "Barnacled Lockbox",
        skill = 600,
        itemID = 169475,
        type = "lockbox",
        expansion = "bfa"
    },
    ["synvir"] = {
        name = "Synvir Lockbox",
        skill = 1,
        itemID = 179311,
        type = "lockbox",
        expansion = "shadowlands"
    },
    ["oxxein"] = {
        name = "Oxxein Lockbox",
        skill = 1,
        itemID = 180532,
        type = "lockbox",
        expansion = "shadowlands"
    },
    ["bismuth"] = {
        name = "Bismuth Lockbox",
        skill = 80,
        itemID = 220376,
        type = "lockbox",
        expansion = "tww"
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
LockSmithPro.BoxDatabaseById = {}
for key, data in pairs(LockSmithPro.BoxDatabase) do
    data.key = key
    if data.itemID then
        LockSmithPro.BoxDatabaseById[data.itemID] = key
    end
end

-- Detect WoW version
local function DetectWoWVersion()
    local version, build, date, tocversion = GetBuildInfo()

    -- Interface version ranges
    if tocversion >= 100000 then
        return "retail" -- Retail (Dragonflight+)
    elseif tocversion >= 40000 and tocversion < 100000 then
        return "cata" -- Cataclysm
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

LockSmithPro.CurrentExpansion = DetectWoWVersion()

-- Get boxes relevant to current expansion
function LockSmithPro:GetRelevantBoxes()
    local relevant = {}
    local currentExp = self.CurrentExpansion

    for key, data in pairs(self.BoxDatabase) do
        -- Include if no expansion specified (generic) or matches current expansion or earlier
        if not data.expansion or data.expansion == "generic" then
            relevant[key] = data
        elseif currentExp == "classic" and data.expansion == "classic" then
            relevant[key] = data
        elseif currentExp == "tbc" and (data.expansion == "classic" or data.expansion == "tbc") then
            relevant[key] = data
        elseif currentExp == "wrath" and (data.expansion == "classic" or data.expansion == "tbc" or data.expansion == "wrath") then
            relevant[key] = data
        elseif currentExp == "cata" and (data.expansion == "classic" or data.expansion == "tbc" or data.expansion == "wrath" or data.expansion == "cata") then
            relevant[key] = data
        elseif currentExp == "retail" then
            relevant[key] = data -- Include all for retail
        end
    end

    return relevant
end

-- Keywords that indicate a lockpicking request
-- Note: Lockpicking keywords are now configurable via the includeKeywords filter in settings
-- This allows users to customize or disable keyword detection entirely

-- Function to identify box type from message
-- ONLY identifies boxes from item links, not from text matching
function LockSmithPro:IdentifyBoxType(message)
    if type(message) ~= "string" then
        return nil
    end

    -- ONLY check for item links (works for all languages!)
    -- Item links look like: |cffffffff|Hitem:16882:0:0:0:0:0:0:0|h[Battered Junkbox]|h|r
    local itemID = tonumber(string.match(message, "|Hitem:(%d+)"))
    if itemID and self.BoxDatabaseById and self.BoxDatabaseById[itemID] then
        local key = self.BoxDatabaseById[itemID]
        return self.BoxDatabase[key]
    end

    -- No item link found - don't try to identify from text
    return nil
end

-- Resolve box data from an item link or name
function LockSmithPro:GetBoxDataFromItemLink(itemLink, itemName)
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

-- Note: HasLockpickKeyword function removed - keyword filtering now handled by includeKeywords setting
