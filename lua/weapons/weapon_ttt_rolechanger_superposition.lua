if SERVER then
    AddCSLuaFile()
end

local COOLDOWN = 15.0

SWEP.AllowDrop = false
SWEP.PreventDrop = true

function SWEP:PreDrop()
    self.RemoveOnDrop = false
    return true
end

function SWEP:OnDrop()
    self:SetOwner(nil)
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:Initialize()
    self:SetHoldType("normal")

    if SERVER then
        self.NextUse = CurTime() + COOLDOWN
    end
end


SWEP.Base = "weapon_tttbase"
SWEP.PrintName = "Role Change Device"
SWEP.Author = "You"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.Kind = WEAPON_EQUIP
SWEP.AutoSpawnable = false
SWEP.DrawCrosshair = false

SWEP.ViewModel = "models/weapons/v_toolgun.mdl"
SWEP.WorldModel = "models/weapons/v_toolgun.mdl"

SWEP.Primary.Delay = 1
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"



-- All role groups you provided; the SWEP expects these to be defined globally
local ALL_GROUPS = {
    SHOP_ROLES,
    DELAYED_SHOP_ROLES,
    TRAITOR_ROLES,
    INNOCENT_ROLES,
    JESTER_ROLES,
    INDEPENDENT_ROLES,
    MONSTER_ROLES,
    DETECTIVE_ROLES,
    DETECTIVE_LIKE_ROLES
}

-- Build a deduped list of role indices from the groups
local function BuildRoleOptions()
    local roleOptions = {}
    local seen = {}

    for _, group in ipairs(ALL_GROUPS) do
        if istable(group) then
            for roleIndex, _ in pairs(group) do
                if roleIndex and not seen[roleIndex] then
                    seen[roleIndex] = true
                    table.insert(roleOptions, roleIndex)
                end
            end
        end
    end

    return roleOptions
end

-- Helper: try to get a human-readable name for the role index.
-- This attempts a few common global tables used by role systems; falls back to the index.
local function GetRoleNameSafe(roleIndex)
    -- Try common global role containers (best-effort; may not exist on all installs)
    if ROLES and istable(ROLES[roleIndex]) and ROLES[roleIndex].name then
        return ROLES[roleIndex].name
    end

    if ROLE_STRINGS and ROLE_STRINGS[roleIndex] then
        return ROLE_STRINGS[roleIndex]
    end

    if ROLE and istable(ROLE) and ROLE[roleIndex] and ROLE[roleIndex].name then
        return ROLE[roleIndex].name
    end

    -- If you have a different global with role metadata, add the lookup above.
    return "Role #" .. tostring(roleIndex)
end

-- Helper: check whether a role index is "enabled".
-- If role metadata is available, check an 'enabled' flag; otherwise assume enabled.
local function IsRoleEnabled(roleIndex)
    if ROLES and istable(ROLES[roleIndex]) and ROLES[roleIndex].enabled ~= nil then
        return ROLES[roleIndex].enabled ~= false
    end

    if ROLE and istable(ROLE[roleIndex]) and ROLE[roleIndex].enabled ~= nil then
        return ROLE[roleIndex].enabled ~= false
    end

    -- No metadata available — assume enabled.
    return true
end

-- Pick a random allowed role (excludes the T-J)
local function PickRandomAllowedRole(exclude_raw)
    local options = BuildRoleOptions()
    if #options == 0 then return nil end

    -- Filter out excluded and disabled ones
    local filtered = {}
    for _, roleIndex in ipairs(options) do
        -- print(roleIndex)
        -- Skip nil or non-number entries
        if roleIndex ~= nil then
            -- If there is metadata available, try to get its raw name to compare with exclude_raw
            local rawName = nil
            if ROLES and istable(ROLES[roleIndex]) and ROLES[roleIndex].nameraw then
                rawName = ROLES[roleIndex].nameraw
            elseif ROLE and istable(ROLE[roleIndex]) and ROLE[roleIndex].nameraw then
                rawName = ROLE[roleIndex].nameraw
            end

            -- If we can determine a raw name and it matches exclude_raw, skip it
            if rawName and rawName == exclude_raw then
                -- skip
            else
                -- Ensure role is enabled (best-effort)
                if IsRoleEnabled(roleIndex) then
                    table.insert(filtered, roleIndex)
                end
            end
        end
    end

    if #filtered == 0 then return nil end
    return table.Random(options)
end

-- PrimaryAttack: use the device to change role
function SWEP:PrimaryAttack()
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    if not ply:Alive() then return end

    local rd = nil
    if ply.GetRoleData then
        rd = ply:GetRoleData()
    end

    if self.NextUse and self.NextUse > CurTime() then
        ply:ChatPrint("Device recharging... " .. math.ceil(self.NextUse - CurTime()) .. "s")
        return
    end

    -- Pick a role index (numeric constant) — excludes Superposition
    local newRoleIndex = PickRandomAllowedRole("superposition")

    if not newRoleIndex then
        ply:ChatPrint("No eligible roles available to transform into.")
        self.NextUse = CurTime() + 1
        return
    end

    local roleName = GetRoleNameSafe(newRoleIndex)

    -- Announce and change role. Most CR4TTT installs accept ply:SetRole(index)
    ply:ChatPrint("You are becoming: " .. roleName)

    ply:SetRole(newRoleIndex)

    -- Sync state to clients (best-effort)
    if SendFullStateUpdate then
        SendFullStateUpdate()
    end

    -- Re-give the device after a small delay (SetRole may wipe inventory)
    local device_class = self:GetClass()
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end

        if ply:HasWeapon(device_class) then
            -- ply:StripWeapon(device_class)
        end
        hook.Run("PlayerLoadout", ply)
        local wep = ply:Give(device_class)
        if IsValid(wep) then
            wep.NextUse = CurTime() + COOLDOWN  -- preserve cooldown
            ply:SelectWeapon(device_class)
        end

    end)

    -- Cooldown and feedback
    self.NextUse = CurTime() + COOLDOWN
    ply:EmitSound("items/suitchargeok1.wav", 75, 100)
    ply:PrintMessage(HUD_PRINTCENTER, "Transformed into: " .. roleName .. "!")
end



