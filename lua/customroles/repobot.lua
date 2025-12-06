local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "repobot"
ROLE.name = "Repobot"
ROLE.nameplural = "Repobots"
ROLE.nameext = "a Repo Bot"
ROLE.nameshort = "rpobt"

ROLE.desc = [[You can pick up people with your Magneto Stick!]]

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil

ROLE.startinghealth = 200
ROLE.maxhealth = nil

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

local EVILROLE = {}

EVILROLE.nameraw = "evilrepobot"
EVILROLE.name = "EvilRepobot"
EVILROLE.nameplural = "Evil Repobots"
EVILROLE.nameext = "an Evil Repo Bot"
EVILROLE.nameshort = "evlrpobt"

EVILROLE.desc = [[You can pick up people with your Magneto Stick!]]

EVILROLE.team = ROLE_TEAM_TRAITOR

EVILROLE.shop = nil
EVILROLE.loadout = {}

EVILROLE.startingcredits = nil

EVILROLE.startinghealth = 200
EVILROLE.maxhealth = nil

EVILROLE.isactive = nil
EVILROLE.selectionpredicate = nil
EVILROLE.shouldactlikejester = nil

EVILROLE.translations = {}

EVILROLE.convars = {}

RegisterRole(EVILROLE)

if SERVER then
    local carriedPlayers = {}  -- [carrier:EntIndex()] = carried_ply
    
    function IsRepobot(ply)
        return ply:IsRepobot() or ply:IsEvilRepobot()
    end

    function GetTargetPos(carrier)
        local offset = carrier:GetAimVector() * 90 + Vector(0,0,-20)
        local targetPos = carrier:GetShootPos() + offset
        return targetPos
    end

    -- Helper to start carry
    function StartCarryingPlayer(carrier, target)
        local id = carrier:EntIndex()
        carriedPlayers[id] = target
        target:SetMoveType(MOVETYPE_NONE)  -- "Freeze" target for physics safety
    end

    -- Helper to stop carry
    function StopCarryingPlayer(carrier)
        local id = carrier:EntIndex()
        local carried = carriedPlayers[id]
        if IsValid(carried) then
            carried:SetMoveType(MOVETYPE_WALK)
            timer.Simple(0, function ()
                 carried:SetVelocity((GetTargetPos(carrier)-carried:GetPos())*5)
            end)
        end
        carriedPlayers[id] = nil
    end

    hook.Add("TTTEndRound", "ResetCarriedRepoBot", function ()
        carriedPlayers = {}
    end)

    hook.Add("EntityTakeDamage", "RepobotRagdollOnDamage", function(ply, dmginfo)
        if not IsValid(ply) then return end
        if not ply:IsPlayer() then return end
        if not (ply:IsActiveRepobot() or ply:IsEvilRepobot()) then return end
        if ply:IsRagdolled() then return end
        if dmginfo:GetDamageType() ~= DMG_BLAST and not dmginfo:GetAttacker() then return end
    
        -- Calculate fling direction: opposite of the damage force or attacker direction
        -- Can't be in a timer because dmginfo gets cleaned up after the hook
        local force = dmginfo:GetDamageForce()
        if force:IsZero() then
            -- If no force, use from attacker or random
            local att = dmginfo:GetAttacker()
            if IsValid(att) and att:IsPlayer() then
                force = (ply:GetPos() - att:GetPos()):GetNormalized() * 2000
            else
                force = VectorRand() * 2000
            end
        else
            force = force:GetNormalized() * 3000
        end

        -- Small delay so ragdoll entity exists
        timer.Simple(0, function()
            ply:Ragdoll(2, true)
        end)

        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            local rag = ply.ragdoll_ent
            if not IsValid(rag) then return end
            rag:GetPhysicsObject():SetVelocity(force)
        end)

        -- Optional: Unragdoll after a bit (e.g. 2 seconds)
        -- timer.Simple(2, function()
        --     if IsValid(ply) and ply:IsRagdolled() then
        --         ply:UnRagdoll()
        --     end
        -- end)
    end)


    -- Think: update position of all carried players
    hook.Add("Think", "PersistentPlayerCarry", function()
        for id, ply in pairs(carriedPlayers) do
            local carrier = Entity(id)
            if not IsValid(carrier) or not IsValid(ply) or not carrier:Alive() or not ply:Alive() then
                StopCarryingPlayer(carrier)
            else
                local weapon = carrier:GetActiveWeapon()
                if not IsValid(weapon) or weapon:GetClass() ~= "weapon_zm_carry" then
                    StopCarryingPlayer(carrier)
                else
                    -- Carry point (front of carrier, eye-level)
                   
                    local targetPos = GetTargetPos(carrier)

                    -- Set up a hull trace (same as player bounding box)
                    local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
                    local tr = util.TraceHull({
                        start = ply:GetPos(),
                        endpos = targetPos,
                        mins = mins,
                        maxs = maxs,
                        filter = function(ent)
                        if ent == ply or ent == carrier then return false end
                        if ent:IsPlayer() then return false end
                        if ent:IsWorld() then return true end
                        if ent:IsSolid() and ent:GetCollisionGroup() == COLLISION_GROUP_NONE then
                            return true
                        end
                        return false
                    end
                    })

                    if tr.Hit then
                        -- Place as close as possible without clipping
                        ply:SetPos(tr.HitPos)
                    else
                        ply:SetPos(targetPos)
                    end

                    
                   -- ply:SetPos(carrier:GetShootPos() + offset)
                    -- Optional: face same way as carrier
                    --ply:SetEyeAngles(carrier:EyeAngles())
                end
            end
        end
    end)

    hook.Add("Think", "RepobotShrinkOnCrouch", function()
        for _, ply in PlayerIterator() do
            if IsRepobot(ply) then
                if ply:Crouching() then
                    if ply:GetModelScale() ~= 0.5 then
                        ply:SetModelScale(0.50, 0.1)  -- shrink to half-size over 0.1s
                        timer.Simple(0.1, function()
                            if not ply:Crouching() then return end
                               ply:SetCurrentViewOffset(Vector(0, 0, 64 * 0.25))
                        end)
                    end
                else
                    if ply:GetModelScale() ~= 1 then
                        ply:SetModelScale(1, 0.1)   -- restore to normal over 0.1s
                        timer.Simple(0.1, function()
                            if ply:Crouching() then return end
                            ply:SetCurrentViewOffset(Vector(0, 0, 64))
                        end)
                    
                    
                    end
                end
            end
        end
    end)

    -- Hook for your pickup trigger (e.g. secondary attack)
    hook.Add("KeyPress", "TryPlayerCarry", function(ply, key)
        if key == IN_ATTACK2 then  -- Right-click
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep:GetClass() == "weapon_zm_carry" and IsRepobot(ply) then
                if carriedPlayers[ply:EntIndex()] then
                    StopCarryingPlayer(ply)
                    return 
                end


                -- Trace in front to find a player
                local tr = util.TraceLine({
                    start = ply:GetShootPos(),
                    endpos = ply:GetShootPos() + ply:GetAimVector() * 90,
                    filter = ply
                })
                if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
                    StartCarryingPlayer(ply, tr.Entity)
                end
            end
        end
    end)

    -- Hook for drop: drop on reload, switch weapon, or drop weapon
    hook.Add("KeyPress", "DropCarriedPlayerOnReload", function(ply, key)
        if key == IN_RELOAD then
            StopCarryingPlayer(ply)
        end
    end)

    hook.Add("PlayerDroppedWeapon", "DropCarriedPlayerOnWeaponDrop", function(ply, wep)
        if wep:GetClass() == "weapon_zm_carry" then
            StopCarryingPlayer(ply)
        end
    end)

    hook.Add("PlayerDeath", "DropCarriedPlayerOnDeath", function(victim)
        StopCarryingPlayer(victim)
        -- Also stop if victim *is* being carried
        for id, ply in pairs(carriedPlayers) do
            if ply == victim then
                StopCarryingPlayer(Entity(id))
            end
        end
    end)

    hook.Add("PlayerDeath", "RepobotExplodeOnDeath", function(victim, inflictor, attacker)
        
        if IsRepobot(victim) then
          
            -- Wait a short moment so the ragdoll spawns
            timer.Simple(3, function()
                if not IsValid(victim) then return end
                
                -- Find their ragdoll (TTT/GM usually attaches ragdoll entity to player)
                local rag = victim:GetRagdollEntity()
                local pos = (IsValid(rag) and rag:GetPos()) or victim:GetPos()
                print(rag)
                -- Effect: explosion
                local effect = EffectData()
                effect:SetOrigin(pos)
                util.Effect("Explosion", effect, true, true)

                -- Sound: built-in GMod explosion
                sound.Play("ambient/explosions/explode_4.wav", pos, 100, 100, 1)

                util.BlastDamage(victim or attacker, victim or attacker, pos, 128, 80)

                -- Remove ragdoll after (optional)
                timer.Simple(0.2, function()
                    if IsValid(rag) then
                        rag:Remove()
                    end
                end)
            end)
        end
    end)



    -- ROLE_ON_ROLE_ASSIGNED[ROLE_REPOBOT] = function(ply)
    --     local stick = ply:GetWeapon("weapon_zm_carry")
    --     if stick then
    --         if IsValid(stick) then
                
    --             -- hook.Add("Think", "MagnetoStick_PlayerCarry_" .. ply:EntIndex(), function()
    --             --     if not IsValid(stick) or not IsValid(ply) then
    --             --         hook.Remove("Think", "MagnetoStick_PlayerCarry_" .. ply:EntIndex())
    --             --         return
    --             --     end
    --             --     local held = stick.repo_held_player = ent
    --             --     if not held then
    --             --         return
    --             --     end
    --             --     print(held)
    --             --     if IsValid(held) and held:IsPlayer() then
    --             --         --held:SetVelocity((held:GetPos()-stick.CarryHack:GetPos())*1)
    --             --         stick.EntHolding:SetPos(stick.CarryHack:GetPos())
    --             --     end
    --             -- end)




    --             -- Store the original function if we haven't already
    --             if not stick._OriginalAllowPickup then
    --                 stick._OriginalAllowPickup = stick.AllowPickup
    --             end

    --             -- Override with our custom function
    --             stick.AllowPickup = function(self, ent)
    --                 if IsValid(ent) and ent:IsPlayer() then
    --                     stick.repo_held_player = ent
    --                     return false
    --                 end
    --                 -- Fallback to original logic
    --                 return self._OriginalAllowPickup and self:_OriginalAllowPickup(ent, phys)
    --             end
    --         end
    --     end
    -- end
end