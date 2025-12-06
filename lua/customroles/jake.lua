local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "jake"
ROLE.name = "Jake"
ROLE.nameplural = "Jakes"
ROLE.nameext = "a Jake"
ROLE.nameshort = "jake"

ROLE.desc = [[Very Short! Previously the backstabber role]]

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.shop = nil
ROLE.loadout = {"weapon_roulette"}

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
    resource.AddFile("sound/jake/NoMoreRoblox.mp3")
    resource.AddFile("sound/jake/AnyoneRunLibrary.mp3")

    ROLE_ON_ROLE_ASSIGNED[ROLE_JAKE] = function (plr)
        plr:SetModelScale(0.75, 0.1)
    end

    ROLE_MOVE_ROLE_STATE[ROLE_JAKE] = function (ply, _, _)
        plr:SetModelScale(1, 0.1)
    end

    hook.Add("TTTSprintStateChange", "JakeRunLibrary",function (ply, sprinting, wasSprinting)
        if ply:IsJake() and not wasSprinting then
            if math.random(1,10) == 1 then
                ply:EmitSound("jake/AnyoneRunLibrary.mp3")
            end
        end
    end)

    hook.Add("TTTWinCheckComplete", "OnWincheckJake", function (wintype)
        for _, p in PlayerIterator() do 
            if p:IsJake() then
                p:EmitSound("jake/NoMoreRoblox.mp3")
            end
        end
    end)


    AddCSLuaFile()
else
    --tutorial text that says he's short
end