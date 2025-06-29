local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "unstableshuffler"
ROLE.name = "Unstable Shuffler"
ROLE.nameplural = "Unstable Shufflers"
ROLE.nameext = "an Unstable Shuffler"
ROLE.nameshort = "unstbshflr"

ROLE.desc = [[Whenever you get hit, everybody swaps positions]]

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

    local function SpawnSmokeEffect(pos)
        local effect = EffectData()
        effect:SetOrigin(pos)
        util.Effect("VortDispel", effect, true, true)
         sound.Play("npc/combine_gunship/gunship_ping_search.wav", pos, 75, 100, 1)
        --physics/metal/soda_can_impact_soft3.wav
    end

    function ShufflePlayers()
        local playerpositions = {}
        for _, player in PlayerIterator() do
            if not player:Alive() then continue end
            table.insert(playerpositions, player:GetPos())
        end
        for _, player in PlayerIterator() do
            if not player:Alive() then continue end
            local index = math.random(1,#playerpositions)
            player:SetPos(playerpositions[index])
            
            SpawnSmokeEffect(playerpositions[index])
            table.remove(playerpositions, index)
        end
    end

    hook.Add("EntityTakeDamage", "UnstableShufflerDamageTaken", function(ent, dmginfo)

        if IsValid(ent) and ent:IsPlayer() then
            local attacker = dmginfo:GetAttacker()
            if not attacker then return end 

            if ent:IsUnstableShuffler() then
                ShufflePlayers()
            end
    
        end
    end)

    hook.Add("TTTPlayerAliveThink", "UnstableShufflerRandomSwap", function(ply)
        if not ply:IsUnstableShuffler() then return end
        if math.random(2000) ~= 1 then return end

        -- Get all other alive, non-spec players
        local candidates = {}
        for _, other in ipairs(player.GetAll()) do
            if other ~= ply and other:Alive() and not other:IsSpec() then
                table.insert(candidates, other)
            end
        end
        if #candidates == 0 then return end

        -- Pick a random target
        local target = candidates[math.random(#candidates)]
        if not IsValid(target) then return end

        -- Swap positions
        local pos1 = ply:GetPos()
        local pos2 = target:GetPos()

        ply:SetPos(pos2)
        target:SetPos(pos1)

        SpawnSmokeEffect(pos1)
        SpawnSmokeEffect(pos12)
        -- Optionally: Effect or notification here
    end)

    AddCSLuaFile()
else
    
    hook.Add("TTTTutorialRoleText", "Shuffler_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_REFLECTOR then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]
            local html = "The " .. ROLE_STRINGS[ROLE_REFLECTOR] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who wins with anyone."
            html = html.."Upon taking damage from a player, they shuffle everybody's position!"
            return html
        end
    end)
end