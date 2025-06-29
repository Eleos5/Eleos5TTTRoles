local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "personperson"
ROLE.name = "Person Person"
ROLE.nameplural = "Many Persons"
ROLE.nameext = "Person"
ROLE.nameshort = "prson"

ROLE.desc = [[You can't communicate with anybody! But, you have 1 extra life!]]

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil

ROLE.startinghealth = 100
ROLE.maxhealth = 100

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then

        -- Clear the revive flag on new round
    hook.Add("TTTPrepareRound", "PersonPersonResetRevive", function()
        for _, ply in PlayerIterator() do
            ply.PersonPerson_Revived = nil
        end
    end)

    hook.Add("TTTBeginRound", "PersonPersonAnnouncement", function()
        for _, ply in PlayerIterator() do
            if not ply:IsActivePersonPerson() then continue  end
            chat.AddText(Color(255, 200, 50), "There is a mute among us")
            break
        end
    end)

   hook.Add("PlayerCanHearPlayersVoice", "PersonPersonMute", function (listener, talker)
        if talker:IsActivePersonPerson() then
            return false, true 
        end
   end)
    hook.Add("PlayerSay", "BlockChatForPlayer", function(ply, text, team)
        -- Replace with your logic for selecting the player(s)
        if ply:IsPersonPerson() then
            return "" -- Block their chat message
        end
    end)
    hook.Add("PlayerDeath", "PersonPersonDeathHandler", function(ply, inflictor, attacker)
        if not IsValid(ply) or not ply:IsPersonPerson() then return end
        if ply.PersonPerson_Revived then return end

        timer.Simple(1, function()
            --copied from vindicator

            local body = ply.server_ragdoll or ply:GetRagdollEntity()
            if IsValid(body) then
                body:Remove()
            end
            ply:SpawnForRound(true)
            ply:SetHealth(ROLE.startinghealth)

            local spawns = GetSpawnEnts(true, false)
            
            if IsValid(furthestSpawn) then
                local furthestPos = spawns[math.random(1, #spawns)]:GetPos()
                ply:SetPos(FindRespawnLocation(furthestPos) or furthestPos)
            end
            ply:PrintMessage(HUD_PRINTTALK, "You are now just a Person.")
                               
            
            ply.PersonPerson_Revived = true
        
        
        
        end)



        
    end)

    AddCSLuaFile()
else
    --tutorial text that says he's short
end