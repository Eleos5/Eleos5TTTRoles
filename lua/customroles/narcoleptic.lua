local hook = hook
local IsValid = IsValid
local player = player
local timer = timer
local math = math
local convar = GetConVar

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "narcoleptic"
ROLE.name = "Narcoleptic"
ROLE.nameplural = "Narcoleptics"
ROLE.nameext = "a Narcoleptic"
ROLE.nameshort = "nclp"

ROLE.desc = [[You are an innocent, but you randomly fall asleep! While asleep, you heal over time.]]
ROLE.team = ROLE_TEAM_INNOCENT

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil
ROLE.startinghealth = 100
ROLE.maxhealth = 100

ROLE.translations = {}
ROLE.convars = {
    {
        cvar = "ttt_narcoleptic_regen_rate",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

RegisterRole(ROLE)

if SERVER then
    CreateConVar("ttt_narcoleptic_regen_rate", "5", {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Narcoleptic health regen per second while asleep")

    local function CreateTimeUntilSleep()
        return math.random(1,20)*(1/engine.TickInterval())
    end

    hook.Add("TTTPlayerAliveThink", "Narcoleptic_Think", function(ply, dead)
        if not ply:IsActiveNarcoleptic() then return end
        if not ply.narc_time_until_sleep then ply.narc_time_until_sleep = CreateTimeUntilSleep() end

        if not ply:IsRagdoll() then
            ply.narc_time_until_sleep = ply.narc_time_until_sleep - 1
        end
        
        if ply.narc_time_until_sleep <= 0 then
            local sleep_duration = math.random(5, 20)
            ply.narc_time_until_sleep = 99999 --disable healing
            ply:Ragdoll(sleep_duration, true)
            timer.Create("NarcolepticSleep" .. ply:EntIndex(), 1, sleep_duration, function()
                if not IsValid(ply) or not ply:IsActiveNarcoleptic() or not ply:IsRagdolled() then
                    timer.Remove("NarcolepticSleep" .. ply:EntIndex())
                    return
                end
                
                if ply:Health() < ply:GetMaxHealth() then
                    local regen_rate = GetConVar("ttt_narcoleptic_regen_rate"):GetInt()
                    ply:SetHealth(math.min(ply:Health() + regen_rate, ply:GetMaxHealth()))
                    ply.ragdoll_info.health = ply:Health()
                end
            end)

            timer.Simple(sleep_duration, function()
                ply.narc_time_until_sleep = CreateTimeUntilSleep() 
            end)


        end
    end)

elseif CLIENT then
    hook.Add("RenderScreenspaceEffects", "NarcolepticVisionEffect", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:IsActiveNarcoleptic() or not ply:IsRagdolled() then return end

        local grayout = {}
        grayout["$pp_colour_addr"] = 0
        grayout["$pp_colour_addg"] = 0
        grayout["$pp_colour_addb"] = 0
        grayout["$pp_colour_brightness"] = -0.3     -- Less dark
        grayout["$pp_colour_contrast"] = 0.8         -- Slightly muted contrast
        grayout["$pp_colour_colour"] = 0.5           -- Lower color saturation (grayer)
        grayout["$pp_colour_mulr"] = 0
        grayout["$pp_colour_mulg"] = 0
        grayout["$pp_colour_mulb"] = 0

        DrawColorModify(grayout)
    end)
end
