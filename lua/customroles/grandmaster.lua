local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "grandmaster"
ROLE.name = "Grandmaster"
ROLE.nameplural = "Grandmasters"
ROLE.nameext = "a Grandmaster"
ROLE.nameshort = "gmas"

ROLE.desc = [[Let's settle this like gentlemen!]]

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil

ROLE.startinghealth = 99
ROLE.maxhealth = 99

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    hook.Add("EntityTakeDamage", "GrandmasterChessTrigger", function(target, dmginfo)
        if not IsValid(target) or not target:IsPlayer() then return end
        
        if terget.InChessGame then
            dmginfo:ScaleDamage(0.01)
        end

        local attacker = dmginfo:GetAttacker()
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        
        -- Check if Attacker is Grandmaster and using a Crowbar (or specific weapon)
        -- You might want to limit this to melee to prevent sniper-chess
        if attacker:IsGrandmaster() then
            
            -- Prevent spam: Check if either player is already in a game
            if attacker.InChessGame or target.InChessGame then return end

            -- 3. Negate Damage
            dmginfo:SetDamage(0)
            
            -- 4. Freeze Players (Optional but recommended)
            attacker:Freeze(true)
            target:Freeze(true)
            
            attacker.InChessGame = true
            target.InChessGame = true

            -- 5. Start the Chess Game
            -- The Grandmaster plays White (first move advantage)
            ChessSystem.StartGame(attacker, target)
            
            -- Send a message
            attacker:ChatPrint("You challenged " .. target:Nick() .. " to Chess!")
            target:ChatPrint("You have been challenged to Chess by the Grandmaster! Win or Die.")
            
            return true -- Block damage
        end
    end)

    hook.Add("ChessMatchEnded", "GrandmasterChessResult", function(winner, loser)
        
        -- Unfreeze
        if IsValid(winner) then 
            winner:Freeze(false) 
            winner.InChessGame = false
        end
        if IsValid(loser) then 
            loser:Freeze(false) 
            loser.InChessGame = false
        end

        -- Kill the Loser
        if IsValid(loser) and loser:Alive() then
            loser:Kill()
            -- Make it look like the winner killed them
            if IsValid(winner) then
                local dmg = DamageInfo()
                dmg:SetDamage(1000)
                dmg:SetAttacker(winner)
                dmg:SetInflictor(winner:GetActiveWeapon() or winner)
                dmg:SetDamageType(DMG_CRUSH)
                loser:TakeDamageInfo(dmg)
                
                winner:ChatPrint("Checkmate. Your opponent has fallen.")
            end
            loser:ChatPrint("Checkmate. You have been defeated.")
        end
    end)

    hook.Add("TTTScoringWinTitle", "GrandmasterRoundStart", function()
        for id, _ in pairs(ChessSystem.ActiveGames) do 
            ChessSystem.EndGame(id)
        end
    end)
else
    --tutorial text that says he's short
end