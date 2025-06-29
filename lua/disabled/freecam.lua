local ROLE = {}
ROLE.nameraw    = "freecam"
ROLE.name       = "Freecam"
ROLE.nameplural = "Freecams"
ROLE.nameext    = "a Freecam"
ROLE.nameshort  = "fcam"

ROLE.team       = ROLE_TEAM_INNOCENT
ROLE.loadout    = { "weapon_freecam" }

-- optional: control how often this role can appear
ROLE.radar      = false
ROLE.preventwin = false
ROLE.fallback   = ROLE_TEAM_INNOCENT

-- colors for HUD
ROLE.color      = Color(100, 150, 250, 255)
ROLE.abbr       = "FCAM"

-- no shop, no special credits
ROLE.shop       = nil
ROLE.startingcredits = nil

-- register it
RegisterRole(ROLE)
