-- lua/autorun/hector_salamanca_role.lua
local hook, player, util, IsValid = hook, player, util, IsValid

local ROLE = {}
ROLE.nameraw        = "hectorsalamanca"
ROLE.name           = "Hector Salamanca"
ROLE.nameplural     = "Hectors Salamanca"
ROLE.nameext        = "Hector Salamanca"
ROLE.nameshort      = "hector"
ROLE.desc           = "You’re confined to a chair—others must push you (with E). Careful with that bell, you have been warned"
ROLE.team           = ROLE_TEAM_INNOCENT
ROLE.loadout        = { "weapon_hector_bell" }
ROLE.startinghealth = 100
ROLE.maxhealth      = 100

RegisterRole(ROLE)

if SERVER then
  -- Slow movement & reset push state
  hook.Add("PlayerSpawn", "Hector_SpawnSetup", function(ply)
    if ply:IsHectorSalamanca() then
      ply:SetWalkSpeed(50)
      ply:SetRunSpeed(50)
      ply:SetMaxSpeed(50)
      ply.hectorIsPushed = false
      ply.hectorPusher  = nil
    end
  end)

  -- Enforce slow when not pushed
  hook.Add("SetupMove", "Hector_EnforceSlow", function(ply, mv)
    if ply:IsHectorSalamanca() and not ply.hectorIsPushed then
      mv:SetMaxSpeed(50)
      mv:SetMaxClientSpeed(50)
    end
  end)

  -- Handle E to start/stop pushing, and jump to release
  hook.Add("KeyPress","Hector_HandleUseJump",function(ply,btn)
    if btn == IN_USE then
      local tr = ply:GetEyeTrace()
      local tgt = tr.Entity
      if IsValid(tgt) and tgt:IsPlayer() and tgt:IsHectorSalamanca() then
        tgt.hectorIsPushed = not tgt.hectorIsPushed
        tgt.hectorPusher  = tgt.hectorIsPushed and ply or nil
      end
    elseif btn == JUMP then
      for _,v in ipairs(player.GetAll()) do
        if v:IsHectorSalamanca() and v.hectorPusher == ply then
          v.hectorIsPushed = false
          v.hectorPusher  = nil
        end
      end
    end
  end)

  -- Move Hector along with pusher
  hook.Add("Tick","Hector_ApplyPush",function()
    for _,v in ipairs(player.GetAll()) do
      if v:IsHectorSalamanca() and v.hectorIsPushed and IsValid(v.hectorPusher) then
        local p   = v.hectorPusher
        local dir = p:GetForward()
        v:SetPos(p:GetPos() + dir * 50)
        v:SetEyeAngles(p:EyeAngles())
      end
    end
  end)

  -- Explosion on death
  hook.Add("PlayerDeath","Hector_ExplodeOnDeath",function(vic,inf,att)
    if vic:IsHectorSalamanca() then
      util.BlastDamage(vic, att, vic:GetPos(), 300, 200)
      local ed = EffectData()
      ed:SetOrigin(vic:GetPos())
      util.Effect("Explosion", ed)
    end
  end)

  AddCSLuaFile("weapons/weapon_hector_bell.lua")
end

if CLIENT then
-- force sit activity
  hook.Add("CalcMainActivity", "HectorSalamanca_Seated", function(ply, vel)
    if ply:IsHectorSalamanca() then
      return ACT_HL2MP_SIT, -1
    end
  end)

  -- lift the pelvis bone so the whole model sits higher
  hook.Add("Think", "HectorSalamanca_BoneOffset", function()
    for _, v in ipairs(player.GetAll()) do
      if not v:IsActiveHectorSalamanca() then continue end

      -- try pelvis first, fall back to a higher bone if needed
      local bone = v:LookupBone("ValveBiped.Bip01_Pelvis")
                 or v:LookupBone("ValveBiped.Bip01_Spine2")
      if bone then
        -- move that bone up 16 units; tweak the Z value to taste
        v:ManipulateBonePosition(bone, Vector(0, 0, 16))
      end
    end
  end)

end
