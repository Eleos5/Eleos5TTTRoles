if SERVER then AddCSLuaFile() end

SWEP.Base          = "weapon_tttbase"
SWEP.PrintName     = "Stink Sprayer"
SWEP.Slot          = 7
SWEP.Kind          = WEAPON_EQUIP
SWEP.CanBuy        = { ROLE_SKUNK }
SWEP.InLoadoutFor  = { ROLE_SKUNK }
SWEP.AutoSpawnable = false
SWEP.LimitedStock  = true
SWEP.AllowDrop     = false
SWEP.NoSights      = true
SWEP.ViewModel     = ""
SWEP.WorldModel    = "models/weapons/w_bugbait.mdl"

SWEP.Primary.Automatic   = false
SWEP.Primary.Delay       = 1.5
SWEP.Primary.Ammo        = "none"
SWEP.Secondary           = SWEP.Primary

SWEP.SpraySound = Sound("weapons/bugbait/bugbait_squeeze1.wav")

local RANGE_SQR   = 200 * 200
local DOT         = CurTime

function SWEP:Initialize()
    if SERVER then util.PrecacheSound(self.SpraySound) end
end


function SWEP:PrimaryAttack()
    if not SERVER then return end
    local owner = self:GetOwner()
    print(owner)
    if not IsValid(owner) then return end
    self:SetNextPrimaryFire(DOT() + self.Primary.Delay)
    self:EmitSound(self.SpraySound)

    owner:SetAnimation(PLAYER_ATTACK1)

    for _, ply in player.Iterator() do
        print(math.sqrt(ply:GetPos():DistToSqr(owner:GetPos())))
        if ply ~= owner and ply:Alive() and ply:GetPos():DistToSqr(owner:GetPos()) <= RANGE_SQR and not ply:GetNWBool("skunk_stinked") and not ply:IsSkunk() then
            ply:SetNWBool("skunk_stinked", true)
        end
    end
end
