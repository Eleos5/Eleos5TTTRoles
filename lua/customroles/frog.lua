local hook = hook
local IsValid = IsValid
local player = player
local timer = timer

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "frog"
ROLE.name = "Frog"
ROLE.nameplural = "Frogs"
ROLE.nameext = "a Frog"
ROLE.nameshort = "frog"

ROLE.desc = [[Jump in the direction you're looking and ragdoll through the air. You take no fall damage!]]

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil

ROLE.startinghealth = 100
ROLE.maxhealth = nil

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

local ROLE = {}

ROLE.nameraw = "evilfrog"
ROLE.name = "Evil Frog"
ROLE.nameplural = "Evil Frogs"
ROLE.nameext = "an Evil Frog"
ROLE.nameshort = "evilfrog"

ROLE.desc = [[Jump in the direction you're looking and ragdoll through the air. You take no fall damage!]]

ROLE.team = ROLE_TEAM_TRAITOR

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil

ROLE.startinghealth = 100
ROLE.maxhealth = nil

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then
    hook.Add("KeyPress", "Frog_JumpLaunch", function(ply, key)
        if not ply:IsFrog() and not ply:IsEvilFrog() then return end
        if key ~= IN_JUMP then return end
        if ply:IsRagdolled() then return end
        if not ply:OnGround() then return end

        local dir = ply:GetAimVector()
        local vel = dir * 500 + Vector(0,0,300) -- Forward and upward

        ply:Ragdoll(1.5, true, true) -- Ragdoll for 1.5 seconds and take damage

        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            local rag = ply.ragdoll_ent
            if not IsValid(rag) then return end
            rag:GetPhysicsObject():SetVelocity(vel*100)
        end)

    end)

    hook.Add("EntityTakeDamage", "Frog_NoFallDamage", function(target, dmginfo)
        if not target:IsPlayer() then return end
        if not target:IsFrog() and not target:IsEvilFrog() then return end
        if dmginfo:IsFallDamage() then
            dmginfo:SetDamage(0)
            return true
        end
    end)
end