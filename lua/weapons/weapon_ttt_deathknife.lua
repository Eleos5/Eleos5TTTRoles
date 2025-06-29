if SERVER then AddCSLuaFile() end

SWEP.Base               = "weapon_tttbase"
SWEP.PrintName          = "Death Scythe"
SWEP.Author             = "Me"
SWEP.Instructions       = "Left click to slay your foe instantly."
SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false
SWEP.UseHands           = false
SWEP.DrawCrosshair      = false

SWEP.Kind               = WEAPON_MELEE
SWEP.Slot               = 0
SWEP.ViewModel          = ""
SWEP.WorldModel         = ""
SWEP.AutoSpawnable      = false
SWEP.LimitedStock       = true
SWEP.AllowDrop          = false

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Automatic  = true
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Delay      = 0.8
function SWEP:DrawWorldModel() end
--doesn't work for some reason, I'm just changing the attack damage

function SWEP:PrimaryAttack()
   self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
   if not IsFirstTimePredicted() then return end
   local owner = self:GetOwner()
   if not IsValid(owner) then return end
   owner:LagCompensation(true)
   local tr = owner:GetEyeTrace(MASK_SHOT)
   local ent = tr.Entity
   if IsValid(ent) and ent:IsPlayer() and ent ~= owner and ent:Alive() then
      local dmg = DamageInfo()
      dmg:SetDamage(9999)
      dmg:SetAttacker(owner)
      dmg:SetInflictor(self)
      dmg:SetDamageType(DMG_SLASH)
      ent:TakeDamageInfo(dmg)
   end
   owner:LagCompensation(false)
   self:SendWeaponAnim(ACT_VM_HITCENTER)
end
