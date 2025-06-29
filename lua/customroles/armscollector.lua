local ROLE = {}

ROLE.nameraw        = "armscollector"
ROLE.name           = "Arms Collector"
ROLE.nameplural     = "Arms Collectors"
ROLE.nameext        = "an Arms Collector"
ROLE.nameshort      = "arm"

ROLE.desc           = [[You are {role}! You can pick up any number of weapons without dropping your old ones.]]
ROLE.shortdesc      = "Can pick up any weapon without replacing old ones."

ROLE.team           = ROLE_TEAM_TRAITOR

ROLE.shop           = nil
ROLE.loadout        = {}

ROLE.startingcredits = 0

ROLE.startinghealth = nil
ROLE.maxhealth      = nil

ROLE.isactive           = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars      = {}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    hook.Add("PlayerCanPickupWeapon", "ArmsCollector_InfinitePickup", function(ply, wep)
        if ply:IsArmsCollector() then
            return true
        end
    end)
end
