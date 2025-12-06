local ROLE = {}

ROLE.nameraw = "death"
ROLE.name = "Death"
ROLE.nameplural = "Deaths"
ROLE.nameext = "Death"
ROLE.nameshort = "dth"
ROLE.desc = [[You can't see but you have a lot of health and you one shot]]
ROLE.team = ROLE_TEAM_MONSTER
ROLE.shop = nil
ROLE.loadout = {}
ROLE.startingcredits = 0
ROLE.startinghealth = 1
ROLE.maxhealth = 1

RegisterRole(ROLE)

if SERVER then
   hook.Add("EntityTakeDamage", "DeathRoleDamageGiven", function(ent, dmginfo)
      if IsValid(ent) and ent:IsPlayer() then
         local attacker = dmginfo:GetAttacker()
         if not attacker then return end 
         if attacker.IsDeath and attacker:IsDeath() then
            dmginfo:SetDamage(999)
         end
      end
   end)


   local function DeathSetHealth(ply)
      local hp = 500 * #player.GetAll()
      ply:SetMaxHealth(hp)
      ply:SetHealth(hp)
   end

   hook.Add("PlayerCanPickupWeapon", "DeathNoPickup", function(ply, wep)
      if not string.find(wep:GetClass(), "crowbar") and ply:IsDeath() then
         return false
      end
   end)

   local function DropAllItems(ply)
      -- Check if player is valid and alive to prevent errors
      if not IsValid(ply) or not ply:Alive() then return end

      -- Loop through all weapons the player currently has
      for _, wep in ipairs(ply:GetWeapons()) do
         -- valid check ensures we don't try to drop a nil entity
         if IsValid(wep) then
               
               print(wep:GetClass())
               if string.find(wep:GetClass(), "weapon_zm_improvised") then
                  continue
               end

               -- Force the drop
               ply:DropWeapon(wep)
         end
      end
   end

   ROLE_ON_ROLE_ASSIGNED[ROLE_DEATH] = function (ply)
      DropAllItems(ply)
      timer.Simple(0.1, function ()
         DeathSetHealth(ply)
      end)
   end

end

if CLIENT then
   local function DeathFog()
      local ply = LocalPlayer()
      if not IsValid(ply) or not ply:IsActiveDeath() then return end
      render.FogMode(MATERIAL_FOG_LINEAR)
      render.FogStart(0)
      render.FogEnd(120)
      render.FogMaxDensity(1)
      return true
   end
   hook.Add("SetupWorldFog", "DeathFog", DeathFog)
   hook.Add("SetupSkyboxFog", "DeathFog", DeathFog)
end
