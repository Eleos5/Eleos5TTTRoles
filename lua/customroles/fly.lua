local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "fly"
ROLE.name = "Fly"
ROLE.nameplural = "Flies"
ROLE.nameext = "a Fly"
ROLE.nameshort = "fly"

ROLE.desc = [[You win with anyone, but you are so annoying they will probably kill you anyway.]]

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

if SERVER then
    hook.Add("Initialize", "FlyInitialize", function()
        WIN_FLY = GenerateNewWinID(ROLE_FLY)
    end)
    resource.AddFile("sound/fly/FlyFly.mp3")

    buzzsound = "fly/FlyFly.mp3"
    function StartFlyBuzz(ply, oldbuzz)
        if not IsValid(ply) then return end
        --if ply.FlyBuzzSound then return end -- Already buzzing

        local buzz = oldbuzz or CreateSound(ply, buzzsound)
        if buzz then
            buzz:Play()
            buzz:ChangeVolume(0.5)
            ply.FlyBuzzSound = buzz
        end

        
        timer.Simple(27, function()
            if IsValid(ply) and ply:IsActiveFly() then
                StartFlyBuzz(ply, buzz)
            end
        end)
    end

    function StopFlyBuzz(ply)
        if ply.FlyBuzzSound then
            ply.FlyBuzzSound:Stop()
            ply.FlyBuzzSound = nil
        end
    end

    ROLE_ON_ROLE_ASSIGNED[ROLE_FLY] = function (ply)
        print("assigned on server!")

        StartFlyBuzz(ply)

        


        ply:SetFriction(0)
        ply:SetGravity(0)
        ply:SetModelScale(0.10, 0)
        timer.Simple(0, function()
            ply:SetViewOffset(Vector(0, 0, 5))
            ply:SetViewOffsetDucked(Vector(0, 0, 5))
        end)

        ply:SetMoveType(MOVETYPE_FLY)
    end

    hook.Add("TTTPlayerRoleChanged", "TTTFlyRemoved", function(ply)
        StopFlyBuzz(ply)

        ply:SetFriction(1)
        ply:SetGravity(1)
        ply:ResetPlayerScale()
        ply:SetMoveType(MOVETYPE_WALK)
    end)

    hook.Add("Think", "Flyer_Move", function()
        for _, ply in PlayerIterator() do 
           if ply:Alive() and ply:GetRole() == ROLE_FLY then
                -- Upwards with jump (IN_JUMP/SPACE)
                if ply:KeyDown(IN_JUMP) then
                    local vel = ply:GetVelocity()
                    ply:SetVelocity(Vector(0, 0, 5)) -- Adjust speed as needed
                end
                -- Downwards with crouch (IN_DUCK/CTRL)
                if ply:KeyDown(IN_DUCK) then
                    local vel = ply:GetVelocity()
                    ply:SetVelocity(Vector(0, 0, -5)) -- Adjust speed as needed
                end
                
            end
        end
    end)

    AddCSLuaFile()
else
    
end