local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "bodybeetle"
ROLE.name = "Body Beetle"
ROLE.nameplural = "Body Beetles"
ROLE.nameext = "a Body Beetle"
ROLE.nameshort = "bbeetle"

ROLE.desc = [[You must bring all dead bodies together into a single pile before you can fight! While all bodies are together, you can attack and take only 10% damage.]]

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

    util.AddNetworkString("BodyBeetleNotify")

    local BODYPILE_RADIUS = 100 -- units
    local function GetAllCorpses()
        local ragdolls = {}
        for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
            if ent.player_ragdoll then
                table.insert(ragdolls, ent)
            end
        end
        return ragdolls
    end

    local function IsAllBodiesInPile()
        local ragdolls = GetAllCorpses()
        if #ragdolls <= 1 then return false end

        local base = ragdolls[1]:GetPos()
        for i = 2, #ragdolls do
            if base:DistToSqr(ragdolls[i]:GetPos()) > (BODYPILE_RADIUS * BODYPILE_RADIUS) then
                return false
            end
        end
        return true
    end

    local function IsBodyBeetle(ply)
        return ply.IsActiveBodyBeetle and ply:IsActiveBodyBeetle()
    end

    hook.Add("EntityTakeDamage", "BodyBeetle_DamageBlock", function(target, dmginfo)
        if not target:IsPlayer() then return end
        if not IsBodyBeetle(target) then return end

        if not target._bodybeetle_enabled then
            dmginfo:ScaleDamage(0.25)
        else
            dmginfo:ScaleDamage(0.01)
        end
    end)

    hook.Add("PlayerShouldTakeDamage", "BodyBeetle_BlockAttack", function(ply, attacker)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        if not IsBodyBeetle(attacker) then return end

        if not attacker._bodybeetle_enabled then
            return false
        end
    end)

    local function CheckBodyBeetleStatus()
        local all_in_pile = IsAllBodiesInPile()
        for _, ply in PlayerIterator() do
            if IsBodyBeetle(ply) then
                if all_in_pile and not ply._bodybeetle_enabled then
                    ply._bodybeetle_enabled = true
                    net.Start("BodyBeetleNotify")
                    net.WriteBool(true)
                    net.Send(ply)
                elseif not all_in_pile and ply._bodybeetle_enabled then
                    ply._bodybeetle_enabled = false
                    net.Start("BodyBeetleNotify")
                    net.WriteBool(false)
                    net.Send(ply)
                end
            end
        end
    end

    hook.Add("Think", "BodyBeetle_CorpseTracker", function()
        CheckBodyBeetleStatus()
    end)

    hook.Add("PlayerSpawn", "BodyBeetle_Reset", function(ply)
        if IsBodyBeetle(ply) then
            ply._bodybeetle_enabled = false
        end
    end)

end

if CLIENT then
    net.Receive("BodyBeetleNotify", function()
        local enabled = net.ReadBool()
        if enabled then
            chat.AddText(Color(180,180,0), "You have completed your pile! You may now attack and are resistant to damage.")
        else
            chat.AddText(Color(180,0,0), "You cannot attack until every corpse is in your pile.")
        end
    end)

 
    local BODYPILE_RADIUS = 100 -- match your server value

    hook.Add("PreDrawHalos", "BodyBeetle_HighlightCorpses", function()
        local ply = LocalPlayer()
        if not ply:IsActiveBodyBeetle() then return end

        local corpses = {}
        for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
            table.insert(corpses, ent)
        end

        if #corpses < 2 then
            -- Not enough bodies: all yellow
            if #corpses > 0 then
                halo.Add(corpses, Color(255, 255, 0), 3, 3, 2, true, true)
            end
        else
            -- Check pile
            local base = corpses[1]:GetPos()
            local green, red = {}, {}
            for i = 1, #corpses do
                local distSqr = base:DistToSqr(corpses[i]:GetPos())
                if distSqr <= (BODYPILE_RADIUS * BODYPILE_RADIUS) then
                    table.insert(green, corpses[i])
                else
                    table.insert(red, corpses[i])
                end
            end
            if #green > 0 then halo.Add(green, Color(0, 255, 0), 3, 3, 2, true, true) end
            if #red > 0 then halo.Add(red, Color(255, 0, 0), 3, 3, 2, true, true) end
        end
    end)


end
