local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "reflector"
ROLE.name = "Reflector"
ROLE.nameplural = "Reflectors"
ROLE.nameext = "a reflector"
ROLE.nameshort = "rflctr"

ROLE.desc = [[You barely deal damage, but you reflect all ranged damage back to any attacker! Win by surviving until any team wins]]

ROLE.team = ROLE_TEAM_INDEPENDANT

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
    hook.Add("EntityTakeDamage", "ReflectorDamageGivenAndTaken", function(ent, dmginfo)

        if IsValid(ent) and ent:IsPlayer() then
            local attacker = dmginfo:GetAttacker()
            if not attacker then return end 

            if ent:IsReflector() then
                local weapon = attacker:GetActiveWeapon()
                
                if string.find(weapon:GetClass(), "crowbar") or string.find(weapon:GetClass(), "improvised") then
                    return
                end
                attacker:TakeDamage(dmginfo:GetDamage())
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)
                return 
            elseif attacker:IsPlayer() and attacker:IsReflector() then
                dmginfo:ScaleDamage(0.01)
                return 
            end
                
           
            


        end
    end)
--    ROLE_ON_ROLE_ASSIGNED[ROLE_REFLECTOR] = function(ply)
       
--    end

    AddCSLuaFile()
else
    
    hook.Add("TTTTutorialRoleText", "REFLECTOR_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_REFLECTOR then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]
            local html = "The " .. ROLE_STRINGS[ROLE_REFLECTOR] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independant team</span> who wins with anyone. "
            html = html.."Unfortunately, I am too lazy to do all that so you just have to imagine it winning when it's alive while the round ends"

            return html
        end
    end)
end