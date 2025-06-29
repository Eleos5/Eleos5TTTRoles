-- File: lua/weapons/weapon_freecam.lua
if SERVER then
  AddCSLuaFile()
end

SWEP.Base               = "weapon_tttbase"
SWEP.PrintName          = "Freecam (Top-Down)"
SWEP.Author             = "ChatGPT"
SWEP.Instructions       = [[
WASD to pan.
Ctrl/Shift to zoom in, Space to zoom out.
Mouse freely aims at the ground.
Press ALT to exit freecam.
Reload to recenter above your body.
]]
SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

-- TTT equipment settings
SWEP.Kind               = WEAPON_EQUIP
SWEP.Slot               = 7
SWEP.CanBuy             = {}
SWEP.LimitedStock       = false
SWEP.AllowDrop          = false
SWEP.Category           = WEAPON_CATEGORY_ROLE

SWEP.BlockShopRandomization = true
SWEP.RequiredItems          = {}

-- Hide all models
SWEP.ViewModel          = ""
SWEP.WorldModel         = ""
SWEP.UseHands           = false
function SWEP:DrawViewModel() return false end
function SWEP:DrawWorldModel()    end
function SWEP:DrawWorldModelTranslucent() end

-- No firing or ammo
SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Automatic  = false
SWEP.Primary.Ammo       = "none"
SWEP.Secondary          = SWEP.Primary
function SWEP:PrimaryAttack()   end
function SWEP:SecondaryAttack() end

-- Movement & zoom
local OVERHEAD_HEIGHT = 600
local PAN_SPEED       = 800
local ZOOM_SPEED      = 400

if CLIENT then
  local groundMat = Material("sprites/glow04_noz")

  function SWEP:Deploy()
    local p = self.Owner:GetPos()
    self.FreecamPos = Vector(p.x, p.y, p.z + OVERHEAD_HEIGHT)
    self.FreecamAng = Angle(90, 0, 0)
    gui.EnableScreenClicker(true)
    self:InstallHooks()
    return true
  end

  function SWEP:Holster()
    local id = self:EntIndex()
    hook.Remove("CalcView",               "FreecamCV"..id)
    hook.Remove("CreateMove",             "FreecamCM"..id)
    hook.Remove("PostDrawTranslucentRenderables", "FreecamMarker"..id)
    gui.EnableScreenClicker(false)
    return true
  end
  function SWEP:OnRemove() self:Holster() end

  function SWEP:Reload()
    local p = self.Owner:GetPos()
    self.FreecamPos = Vector(p.x, p.y, p.z + OVERHEAD_HEIGHT)
  end

  function SWEP:InstallHooks()
    local id = self:EntIndex()

    -- override camera
    hook.Add("CalcView", "FreecamCV"..id, function(ply, _pos, _ang, fov)
      if ply == self.Owner and IsValid(self) then
        return { origin = self.FreecamPos, angles = self.FreecamAng, fov = fov }
      end
    end)

    -- pan/zoom + exit on ALT
    hook.Add("CreateMove", "FreecamCM"..id, function(cmd)
      if LocalPlayer() ~= self.Owner or not IsValid(self) then return end

      local ft  = FrameTime()
      local dir = Vector()

      -- pan
      if cmd:KeyDown(IN_FORWARD)   then dir = dir + Vector(1,  0, 0) end
      if cmd:KeyDown(IN_BACK)      then dir = dir + Vector(-1, 0, 0) end
      if cmd:KeyDown(IN_MOVELEFT)  then dir = dir + Vector(0,  1, 0) end
      if cmd:KeyDown(IN_MOVERIGHT) then dir = dir + Vector(0, -1, 0) end

      -- zoom in
      if cmd:KeyDown(IN_DUCK) or cmd:KeyDown(IN_SPEED) then
        self.FreecamPos.z = self.FreecamPos.z - ZOOM_SPEED * ft
      end
      -- zoom out
      if cmd:KeyDown(IN_JUMP) then
        self.FreecamPos.z = self.FreecamPos.z + ZOOM_SPEED * ft
      end

      if dir:LengthSqr() > 0 then
        dir:Normalize()
        self.FreecamPos = self.FreecamPos + dir * PAN_SPEED * ft
      end

      -- exit freecam on ALT
      if cmd:KeyDown(IN_WALK) then
        gui.EnableScreenClicker(false)
        LocalPlayer():ConCommand("lastinv")
      end

      -- lock view angle
      cmd:SetViewAngles(self.FreecamAng)
    end)

    -- draw ground marker at true mouse position
    hook.Add("PostDrawTranslucentRenderables", "FreecamMarker"..id, function()
      if LocalPlayer() ~= self.Owner or not IsValid(self) then return end

      -- get mouse within game window
      local mx, my = gui.MouseX(), gui.MouseY()
      if mx < 0 or my < 0 or mx > ScrW() or my > ScrH() then return end

      -- normalized coords
      local x = mx / ScrW()
      local y = my / ScrH()
      local nx =  x * 2 - 1
      local ny = 1 - y * 2

      local dirCam = gui.ScreenToVector(mx, my)


      local tr = util.TraceLine({
        start  = self.FreecamPos,
        endpos = self.FreecamPos + dirCam * 10000,
        mask   = MASK_SOLID
      })
      if not tr.Hit then return end

      local pos = tr.HitPos + Vector(0,0,2)
      render.SetMaterial(groundMat)
      render.DrawSprite(pos, 64, 64, Color(0,255,0,200))
    end)
  end
end
