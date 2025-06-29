local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "propmaster"
ROLE.name = "Prop Master"
ROLE.nameplural = "Prop Masters"
ROLE.nameext = "a Prop Master"
ROLE.nameshort = "prpmstr"

ROLE.desc = [[All damage that you take gets reflected to any nearby objects]]

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


if SERVER then

local function SpawnSparksEffect(pos)
    local effect = EffectData()
    effect:SetOrigin(pos)
    util.Effect("ManhackSparks", effect, true, true)
end

function GetBreakables(entlist)
    local breakables = {}
    for _, ent in ipairs(entlist) do
        if IsValid(ent) then
            local class = ent:GetClass()
            if class == "func_breakable" or class == "func_breakable_surf" then
                table.insert(breakables, ent)
            elseif ent:IsNPC() or ent:IsPlayer() then
                -- skip living things
            elseif ent:GetMaxHealth() and ent:GetMaxHealth() > 0 then
                if ent:Health() <= 0 then
                    continue
                end
                table.insert(breakables, ent)
            end
        end
    end
    return breakables
end

function MoveBreakablesTowardsPlayer(propMaster, radius, speed)
    if not navmesh.IsLoaded() then
        print("No navmesh loaded on this map.")
        return
    end

    local breakables = GetBreakables(ents.FindInSphere(propMaster:GetPos(), radius))

    local targetArea = navmesh.GetNearestNavArea(propMaster:GetPos())
    if not IsValid(targetArea) then
        print("No nav area near Prop Master.")
        return
    end

    for _, prop in ipairs(breakables) do
        if not IsValid(prop) then continue end
        local propPos = prop:GetPos()
        local propArea = navmesh.GetNearestNavArea(propPos)
        if not IsValid(propArea) then continue end

        local nextArea = nil
        local minDist = math.huge

        for _, adjArea in ipairs(propArea:GetAdjacentAreas()) do
            local dist = adjArea:GetCenter():DistToSqr(targetArea:GetCenter())
            if dist < minDist then
                minDist = dist
                nextArea = adjArea
            end
        end

        local moveTarget
        if nextArea and nextArea ~= targetArea then
            moveTarget = nextArea:GetCenter()
        else
            moveTarget = targetArea:GetCenter()
        end

        local phys = prop:GetPhysicsObject()
        if IsValid(phys) then
            local dir = (moveTarget - propPos):GetNormalized() + Vector(0,0.25,0)
            phys:SetVelocity(dir * speed)
        end
    end
end


function ReflectDamageToNearbyBreakable(pos, radius, dmg)
    local breakables = GetBreakables(ents.FindInSphere(pos, radius)) 

    if #breakables > 0 then
        local target = breakables[math.random(#breakables)]
        local dmginfo = DamageInfo()
        dmginfo:SetDamage(dmg)
        dmginfo:SetDamageType(DMG_GENERIC)
        dmginfo:SetAttacker(game.GetWorld())
        dmginfo:SetInflictor(game.GetWorld())
        dmginfo:SetDamageForce(Vector(0,0,1))
        target:TakeDamageInfo(dmginfo)
        SpawnSparksEffect(target:GetPos())
        SpawnSparksEffect(pos)
        return target
    end
end

hook.Add("TTTBeginRound", "PropMaster_RoleFeatures_TTTBeginRound", function()
    timer.Create("propmaster_think", 1, 0, function ()
        for _, ply in PlayerIterator() do 
            if ply:IsPropMaster() then
                MoveBreakablesTowardsPlayer(ply, 2000, 200)
            end
        end
    end)
end)

hook.Add("EntityTakeDamage", "PropMasterDamageTaken", function(ent, dmginfo)

    if IsValid(ent) and ent:IsPlayer() then
        

        if ent:IsPropMaster() and ReflectDamageToNearbyBreakable(ent:GetPos(), 200, dmginfo:GetDamage()) then
            dmginfo:SetDamage(0)
            return 
        end
        
    end
end)



    AddCSLuaFile()
else

end