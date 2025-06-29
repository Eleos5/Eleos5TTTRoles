-- lua/customroles/sleepingbeauty.lua
local ROLE = {}

-- Basic role information
ROLE.nameraw         = "sleepingbeauty"
ROLE.name            = "Sleeping Beauty"
ROLE.nameplural      = "Sleeping Beauties"
ROLE.nameext         = "a Sleeping Beauty"
ROLE.nameshort       = "sbt"

-- Descriptions
ROLE.desc = [[
You are {role}! You start the round asleep on the map.
Players can wake you up by using you. When awakened, you will join the team of the player who woke you and be given a random role from that team.
]]

ROLE.shortdesc = "Start the round asleep; gets woken up into the team and a random role of your awakener."

-- Initial team
ROLE.team = ROLE_TEAM_INDEPENDENT

-- No shop or loadout
ROLE.shop    = nil
ROLE.loadout = {}

-- Only useable on maps with a navmesh
ROLE.selectionpredicate = function()
    return navmesh.IsLoaded()
end

-- Register the role with CR for TTT
RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    ROLE_ON_ROLE_ASSIGNED[ROLE_SLEEPINGBEAUTY] = function(ply)
        if navmesh.IsLoaded() then
            local areas = navmesh.GetAllNavAreas()
            if #areas > 0 then
                local area = table.Random(areas)
                local pos = area:GetRandomPoint()  -- valid CNavArea method :contentReference[oaicite:0]{index=0}
                if pos then
                    --ply:SetPos(pos)
                end
            end
        end

        timer.Simple(0, function ()
            ply:Ragdoll()
        end)
    end

    -- Wake-up logic: when a player uses the ragdoll, wake SB up
    hook.Add("PlayerUse", "SB_PlayerUse", function(waker, ent)
        if ent:GetClass() ~= "prop_ragdoll" then return end

        local sb = ent.ragdolled_ply
        if not IsValid(sb) or not sb:IsSleepingBeauty() then return end

        -- Unragdoll and remove rag
        sb:UnRagdoll()

        -- Determine waker's team via the registered roles
        local team = waker:GetRoleTeam()
        
        -- Collect all roles matching that team (excluding Sleeping Beauty)
        local role_options = {}
        if team == ROLE_TEAM_TRAITOR then
            role_options = GetTeamRoles(TRAITOR_ROLES)
        elseif team == ROLE_TEAM_INNOCENT then
            role_options = GetTeamRoles(INNOCENT_ROLES)
        elseif team == ROLE_TEAM_JESTER then
            role_options = GetTeamRoles(JESTER_ROLES)
        elseif team == ROLE_TEAM_INDEPENDENT then
            role_options = GetTeamRoles(INDEPENDENT_ROLES)
        elseif team == ROLE_TEAM_MONSTER then
            role_options = GetTeamRoles(MONSTER_ROLES)
        elseif team == ROLE_TEAM_DETECTIVE then
            role_options = GetTeamRoles(DETECTIVE_ROLES)
        end
        
        -- Assign a random role from the waker's team
        if #role_options > 0 then
            sb:SetRole(table.Random(role_options))
        end
    end)
end

if CLIENT then
    -- Add a simple tutorial page entry
    hook.Add("TTTTutorialRoleText", "SleepingBeautyTutorial", function(role)
        if role ~= ROLE_SLEEPINGBEAUTY then return end
        return [[
            You are Sleeping Beauty! You begin the round asleep; others can wake you up.
            When awakened, you'll join their team and assume a random role from that team.
            ]]
    end)
end
