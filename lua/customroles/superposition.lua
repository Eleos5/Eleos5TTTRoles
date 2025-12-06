local ROLE = {}

-- REQUIRED NAMES
ROLE.nameraw = "superposition"
ROLE.name = "Superposition"
ROLE.nameplural = "Superpositions"
ROLE.nameext = "a Superposition"
ROLE.nameshort = "Sppos"

ROLE.desc = [[The Superposition starts as an Innocent but can transform into a random custom role using their device.]]

ROLE.shortdesc = "Starts innocent, but can transform into another custom role."

-- Superposition IS AN INNOCENT-TEAM ROLE
ROLE.team = ROLE_TEAM_INNOCENT

-- NO SHOP (you give the device via loadout)
ROLE.shop = nil

-- GIVE THE DEVICE ON SPAWN
ROLE.loadout = {
    "weapon_ttt_rolechanger_superposition"
}

-- NO CREDITS
ROLE.startingcredits = 0

-- Health unchanged, so leave nil
ROLE.startinghealth = nil
ROLE.maxhealth = nil

-- ACTIVE ROLE
ROLE.isactive = true  -- Role is actually used in-round

-- No special selection rules needed
ROLE.selectionpredicate = nil

-- Superposition does NOT act like a jester (change to true if you want that!)
ROLE.shouldactlikejester = false

-- No language translations
ROLE.translations = {}

-- CONVARS (optional example)
ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()
end

