sound.Add({
    name = "Peanut_NeckSnap",
    channel = CHAN_STATIC,
    volume = 1.5,
    level = 90,
    pitch = {95, 110},
    sound = {"peanut/NS1.ogg", "peanut/NS2.ogg", "peanut/NS3.ogg"}
})

if SERVER then AddCSLuaFile() end

SWEP.Base               = "weapon_tttbase"
SWEP.PrintName          = "Snap"
SWEP.Author             = "person person"
SWEP.Instructions       = "Left click to snap your foe's neck."
-- SWEP.Spawnable          = false
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
SWEP.Primary.Delay      = 0.1

function SWEP:DrawWorldModel() end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    
    if IsFirstTimePredicted() then
        if owner:GetNWFloat("Peanut_SpeedModifier", 0) ~= 0 then
            owner:LagCompensation(true)

            local trace = util.GetPlayerTrace(owner)
            trace.endpos = trace.start + (trace.endpos - trace.start):GetNormalized() * 150
            local tr = util.TraceLine(trace)
            local ent = tr.Entity
    
            if SERVER and ent and IsValid(ent) and ent:IsPlayer() and ent ~= owner and ent:Alive() then
                local dmg = DamageInfo()
                dmg:SetDamage(99999)
                dmg:SetAttacker(owner)
                dmg:SetInflictor(self)
                dmg:SetDamageType(DMG_CLUB)
                ent:TakeDamageInfo(dmg)

                owner:EmitSound("Peanut_NeckSnap")
            end
        
            owner:LagCompensation(false)
        end
    end
end
