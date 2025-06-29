if SERVER then AddCSLuaFile() end

local ROLE = {}
ROLE.nameraw        = "wraith"
ROLE.name           = "Wraith"
ROLE.nameplural     = "Wraiths"
ROLE.nameext        = "a Wraith"
ROLE.nameshort      = "wraith"

ROLE.desc           = [[You are invisible to everyone else, but extremely fragile.]]
ROLE.team           = ROLE_TEAM_TRAITOR

ROLE.loadout        = {}
ROLE.startingcredits= 0
ROLE.startinghealth = 10
ROLE.maxhealth      = 10

RegisterRole(ROLE)

-- hide/show models when spawning or when the round resets
ROLE_ON_ROLE_ASSIGNED[ROLE_WRAITH] = function(ply)
    if ply:IsWraith() then
        ply:SetNoDraw(true)
        ply:DrawShadow(false)
    end
end

ROLE_ON_ROLE_ASSIGNED[ROLE_WRAITH] = function (ply)
    ply:SetNoDraw(true)
    ply:DrawShadow(false)
end

if CLIENT then
    local function HideLDMItems()
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsWraith() and ply ~= LocalPlayer() then
                for _, wep in ipairs(ply:GetWeapons()) do
                wep:SetNoDraw(true)
                end
            end
        end
    end
    hook.Add("PreDrawOpaqueRenderables", "WRAITH_HideWorldWeapons", HideLDMItems)

    hook.Add("PlayerEquip", "Wraith_HideWeaponsOnEquip", function(ply, weapon)
        if ply:IsWraith() then
            weapon:SetNoDraw(true)
        end
    end)


end
