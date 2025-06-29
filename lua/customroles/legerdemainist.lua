local hook    = hook
local player  = player
local ipairs  = ipairs

local ROLE = {}
ROLE.nameraw    = "legerdemainist"
ROLE.name       = "Legerdemainist"
ROLE.nameplural = "Legerdemainists"
ROLE.nameext    = "a Legerdemainist"
ROLE.nameshort  = "ldm"

ROLE.desc       = [[Other players see you empty-handed and in your idle stance.]]
ROLE.team       = ROLE_TEAM_INNOCENT

ROLE.loadout        = {}
ROLE.startingcredits = 0
ROLE.convars        = {}

RegisterRole(ROLE)

if CLIENT then
  -- 1) Hide all world-models of weapons/items carried by Legerdemainists
  local function HideLDMItems()
    for _, ply in ipairs(player.GetAll()) do
      if ply:IsLegerdemainist() and ply ~= LocalPlayer() then
        for _, wep in ipairs(ply:GetWeapons()) do
          wep:SetNoDraw(true)
          wep:SetHoldType("passive")
        end
      end
    end
  end
  hook.Add("PreDrawOpaqueRenderables", "LDM_HideWorldWeapons", HideLDMItems)

 hook.Add("TranslateActivity", "LDM_TranslateActivity", function(ply, act)
    if not ply:IsLegerdemainist() or ply == LocalPlayer() then return end

    if act == ACT_MP_STAND_IDLE   or act == ACT_RANGE_ATTACK1 then return ACT_HL2MP_IDLE        end
    if act == ACT_MP_CROUCH_IDLE  then return ACT_HL2MP_IDLE_CROUCH                              end
    if act == ACT_MP_WALK         then return ACT_HL2MP_WALK                                     end
    if act == ACT_MP_RUN          then return ACT_HL2MP_RUN                                      end
    if act == ACT_MP_CROUCHWALK   then return ACT_HL2MP_WALK_CROUCH                              end
end)

-- ── block weapon-triggered gesture events ─────────────────────
hook.Add("DoAnimationEvent", "LDM_BlockGestures", function(ply, event)
    if ply:IsLegerdemainist() and ply ~= LocalPlayer() then
        if event < 5 then --all attacking events
            return ACT_INVALID
        end
    end
end)


  -- 3) Also hide any dropped weapon entities they own
  hook.Add("Think", "LDM_CleanupDropped", function()
    for _, ent in ipairs(ents.FindByClass("weapon_*")) do
      local owner = ent:GetOwner()
      if IsValid(owner) and owner:IsLegerdemainist() then
        ent:SetNoDraw(true)
      end
    end
  end)
end
