local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "beautifulbiomass"
ROLE.name = "Beautiful Biomass"
ROLE.nameplural = "Beautiful Bioasses"
ROLE.nameext = "a Beautiful Biomass"
ROLE.nameshort = "bbiomss"

ROLE.desc = [[Assimilate the bodies]]

ROLE.team = ROLE_TEAM_INDEPENDANT

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil

ROLE.startinghealth = 50
ROLE.maxhealth = 50

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil
ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

function AttachRagdollToPlayer(ply, ragdoll)
    if not (IsValid(ply) and IsValid(ragdoll)) then return end
    if ragdoll.biomass_assimilated then return end 

    local boneCount = ply:GetBoneCount()
    local boneIndex = 0
    if boneCount and boneCount > 1 then
        boneIndex = math.random(0, boneCount - 1)
    end

    hook.Add("Think", "BiomassFollow_" .. ragdoll:EntIndex(), function()
        if not (IsValid(ply) and IsValid(ragdoll)) then
            hook.Remove("Think", "BiomassFollow_" .. ragdoll:EntIndex())
            return
        end

        local bonePos, boneAng = ply:GetBonePosition(boneIndex)
        if bonePos then
            -- Move the entire ragdoll's root physics object
            local phys = ragdoll:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
                phys:SetPos(bonePos)
                phys:SetAngles(boneAng or Angle(0,0,0))
            end
            ragdoll:SetPos(bonePos) -- For completeness, but mostly cosmetic
            ragdoll:SetAngles(boneAng or Angle(0,0,0))
        end
    end)

    --constraint.Weld(ragdoll, ply, 0, boneIndex, 0, true, false)
    ragdoll.biomass_assimilated = true
end


if SERVER then

    hook.Add("Think", "BodyCollectorThink", function()
        for _, ply in PlayerIterator() do
            if ply:IsValid() and ply:Alive() and ply:IsBeautifulBiomass() then
                
                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 100)) do
                    
                    if IsRagdoll(ent) and not ent.biomass_assimilated then
                        print("Rag on em!")
                        AttachRagdollToPlayer(ply, ent)
                        
                        --break
                    end
                end
            end
        end
    end)

    AddCSLuaFile()
else
    
end