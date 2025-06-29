-- lua/weapons/weapon_hector_bell.lua
DEFINE_BASECLASS("weapon_tttbase")
local table, CurTime = table, CurTime

SWEP.PrintName      = "Hector's Bell"
SWEP.Spawnable      = false
SWEP.AutoSpawnable  = false
SWEP.Kind           = WEAPON_EQUIP2
SWEP.LimitedStock   = true
SWEP.EquipMenuData  = { type = "item_weapon", desc = "Ring carefully; 5 rings in 1.5s will kill you." }
SWEP.Icon           = "vgui/ttt/icon_bell"
SWEP.Primary.Delay  = 0.2
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"

function SWEP:Initialize()
  self:SetHoldType("normal")
  if SERVER then
    self.ringTimes = {}
  end
end

function SWEP:PrimaryAttack()
  if CLIENT then return end
  local ply = self:GetOwner()
  local now = CurTime()

  table.insert(self.ringTimes, now)
  for i = #self.ringTimes, 1, -1 do
    if now - self.ringTimes[i] > 1.5 then
      table.remove(self.ringTimes, i)
    end
  end

  ply:EmitSound("buttons/button14.wav")

  if #self.ringTimes >= 5 then
    ply:Kill()
    return
  end

  self:SetNextPrimaryFire(now + self.Primary.Delay)
end
