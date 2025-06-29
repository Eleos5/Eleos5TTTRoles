local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "observator"
ROLE.name = "Observator"
ROLE.nameplural = "Observators"
ROLE.nameext = "an Observator"
ROLE.nameshort = "obsvtr"

ROLE.desc = [[You can see each player's role, but you don't care who wins!]]

ROLE.team = ROLE_TEAM_JESTER

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

if not SERVER then
    
    hook.Add("TTTTargetIDPlayerText", "Observator_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
        
        if GetRoundState() < ROUND_ACTIVE then return end
        if not IsPlayer(ent) then return end
        if not cli:IsObservator() then return end
       
        local newText = text
        local newColor = col

        
        newColor = ROLE_COLORS_RADAR[ent:GetRole()]
        newText = string.upper(ROLE_STRINGS[ent:GetRole()])

        return newText, newColor, false
    end)

    hook.Add("TTTScoreboardPlayerRole", "Observator_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
        if GetRoundState() < ROUND_ACTIVE then return end
        
        if IsPlayer(ply) and cli:IsObservator() then
            local newColor = c
            local newRoleStr = roleStr
            newColor = ROLE_COLORS_SCOREBOARD[ply:GetRole()]
            newRoleStr = ROLE_STRINGS_SHORT[ply:GetRole()]

            return newColor, newRoleStr
        end
    end)

    hook.Add("TTTTargetIDPlayerRing", "Observator_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
        if GetRoundState() < ROUND_ACTIVE then return end
        if not IsPlayer(ent) then return end

        if cli:IsObservator() then
            local newRingVisible = ringVisible
            local newColor = false

            newColor = ROLE_COLORS_RADAR[ent:GetRole()]
            newRingVisible = true

            return newRingVisible, newColor
        end
    end)

    hook.Add("TTTTargetIDPlayerRoleIcon", "Informant_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
        if GetRoundState() < ROUND_ACTIVE then return end


        if cli:IsObservator() then
            return ply:GetRole(),true , ply:GetRole()
        end
    end)

elseif SERVER then
    AddCSLuaFile()
end