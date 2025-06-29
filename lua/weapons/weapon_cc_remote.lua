----------------------------------------------------------------
--  Command Uplink – free-cam, ability UI, live HUD            --
----------------------------------------------------------------
if SERVER then AddCSLuaFile() end

SWEP.Base          = "weapon_tttbase"
SWEP.PrintName     = "Command Uplink"
SWEP.Slot          = 7
SWEP.Kind          = WEAPON_EQUIP
SWEP.CanBuy        = { ROLE_COMMANDCENTER }
SWEP.InLoadoutFor  = { ROLE_COMMANDCENTER }
SWEP.AutoSpawnable = false
SWEP.LimitedStock  = true
SWEP.AllowDrop     = false
SWEP.NoSights      = true
SWEP.ViewModel     = ""
SWEP.WorldModel    = ""
function SWEP:DrawWorldModel() end

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"
SWEP.Secondary           = SWEP.Primary

----------------------------------------------------------------
--  Ability metadata
----------------------------------------------------------------
local AB = {
    { id = 1, name = "Summon",       subs = { "Barrel", "Zombie", "Manhack" } },
    { id = 2, name = "Grenade",      subs = { "Smoke", "Disco",  "Fire"    } },
    { id = 3, name = "Heal" },
    { id = 4, name = "Abduct" },
    { id = 5, name = "Rain Bullets" },
    { id = 6, name = "Vortex" },
    { id = 7, name = "Gravity Ward" }
}

----------------------------------------------------------------
--  Networking & datatables
----------------------------------------------------------------
if SERVER then util.AddNetworkString("cc_use") end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "Ability")
    self:NetworkVar("Int", 1, "Sub")
end

function SWEP:Initialize()
    self:SetAbility(1)
    self:SetSub(1)
end

----------------------------------------------------------------
--  CLIENT-side implementation
----------------------------------------------------------------
----------------------------------------------------------------
--  CLIENT-side (replace everything between if CLIENT … end)
----------------------------------------------------------------
if CLIENT then
    surface.CreateFont("CC_HUD", { font = "Roboto", size = 22, weight = 700 })
    local matDot  = Material("sprites/glow04_noz")
    local sndCast = Sound("buttons/button24.wav")

    local PANEL, hooksInstalled = nil, {}
    local START_H, PAN_SPD, ZOOM_SPD = 600, 800, 400

    ----------------------------------------------------------------
    --  Local ability state  (no networking needed)
    ----------------------------------------------------------------
    function SWEP:GetLocalAbility() return self.SelectedAbility or 1 end
    function SWEP:GetLocalSub()     return self.SelectedSub     or 1 end
    local function setLocalAbility(wep,a,s)
        wep.SelectedAbility = a
        wep.SelectedSub     = s or 1
    end

    ----------------------------------------------------------------
    --  Full UI & hook clean-up
    ----------------------------------------------------------------
    local function clearAll()
        if hooksInstalled.id then
            local id = hooksInstalled.id
            hook.Remove("CalcView",      "CC_CV_"  .. id)
            hook.Remove("CreateMove",    "CC_CM_"  .. id)
            hook.Remove("HUDPaint",      "CC_HUD_" .. id)
            hook.Remove("PostDrawTranslucentRenderables", "CC_PDTR_" .. id)
            hook.Remove("GUIMousePressed",            "CC_Mouse_" .. id)
            hooksInstalled = {}
        end
        if IsValid(PANEL) then PANEL:Remove() PANEL = nil end
        gui.EnableScreenClicker(false)
    end

    ----------------------------------------------------------------
    --  Ability panel (bottom-right)
    ----------------------------------------------------------------
    local function openPanel(wep)
        if IsValid(PANEL) then PANEL:Remove() end
        local W,H = 260, 10 + #AB*28
        PANEL = vgui.Create("DFrame")
        PANEL:SetSize(W,H)
        PANEL:SetPos(ScrW()-W-10, ScrH()-H-10)
        PANEL:SetTitle("") PANEL:ShowCloseButton(false) PANEL:SetDraggable(false)
        PANEL.Paint = function(_,w,h) surface.SetDrawColor(0,0,0,180) surface.DrawRect(0,0,w,h) end

        local y = 5
        for a,meta in ipairs(AB) do
            local btn=vgui.Create("DButton",PANEL)
            btn:SetPos(5,y) btn:SetSize(120,24) btn:SetText(meta.name)
            if meta.subs then
                local box=vgui.Create("DComboBox",PANEL)
                box:SetPos(130,y) box:SetSize(120,24)
                for k,n in ipairs(meta.subs) do box:AddChoice(n,k) end
                box:ChooseOptionID(1)
                box.OnSelect=function(_,_,_,k) setLocalAbility(wep,a,k) end
                btn.DoClick   =function() setLocalAbility(wep,a,box:GetSelectedID() or 1) end
            else
                btn.DoClick=function() setLocalAbility(wep,a,1) end
            end
            y=y+28
        end
        -- Exit button
        local exitBtn = vgui.Create("DButton", PANEL)
        exitBtn:SetSize(240,24)
        exitBtn:SetPos(10, PANEL:GetTall() - 29)
        exitBtn:SetText("Exit Uplink")
        exitBtn.DoClick = function()
            LocalPlayer():ConCommand("lastinv")
        end

    end

    ----------------------------------------------------------------
    --  Install camera, HUD, and mouse-cast hooks
    ----------------------------------------------------------------
    local function installHooks(wep)
        local ply,id = wep.Owner, tostring(wep:EntIndex())
        hooksInstalled.id = id
        wep.CamPos = ply:GetPos()+Vector(0,0,START_H)
        gui.EnableScreenClicker(true)

        -- free-cam view
        hook.Add("CalcView","CC_CV_"..id,function(p,_,_,fov)
            if p~=ply or not IsValid(wep) then return end
            return {origin=wep.CamPos, angles=Angle(90,0,0), fov=fov}
        end)

        -- WASD pan + zoom
        hook.Add("CreateMove","CC_CM_"..id,function(cmd)
            if not IsValid(wep) then return end
            local ft,dir = FrameTime(),Vector()
            if cmd:KeyDown(IN_FORWARD)   then dir.x =  dir.x + 1 end
            if cmd:KeyDown(IN_BACK)      then dir.x =  dir.x - 1 end
            if cmd:KeyDown(IN_MOVELEFT)  then dir.y =  dir.y + 1 end
            if cmd:KeyDown(IN_MOVERIGHT) then dir.y =  dir.y - 1 end
            if dir:LengthSqr()>0 then wep.CamPos = wep.CamPos + dir:GetNormalized()*PAN_SPD*ft end
            if cmd:KeyDown(IN_DUCK) or cmd:KeyDown(IN_SPEED) then wep.CamPos.z = wep.CamPos.z - ZOOM_SPD*ft end
            if cmd:KeyDown(IN_JUMP)                           then wep.CamPos.z = wep.CamPos.z + ZOOM_SPD*ft end
            if cmd:KeyDown(IN_WALK) then ply:ConCommand("lastinv") end
        end)

        -- HUD (energy + ability text)
        hook.Add("HUDPaint","CC_HUD_"..id,function()
            if not IsValid(wep) then return end
            local energy = ply:GetNWInt("CC_Energy",0)
            local pct    = math.Clamp(energy/100,0,1)
            local panelH = IsValid(PANEL) and PANEL:GetTall() or 0
            local bx,by,bw,bh = ScrW()-270, ScrH()-panelH-40, 250, 18
            surface.SetDrawColor(0,0,0,180)          surface.DrawRect(bx,by,bw,bh)
            surface.SetDrawColor(60,180,60,220)      surface.DrawRect(bx+2,by+2,(bw-4)*pct,bh-4)
            draw.SimpleText("Energy: "..energy,"CC_HUD",bx+bw/2,by-20,Color(255,255,255),TEXT_ALIGN_CENTER)

            local abi  = wep:GetLocalAbility()
            local meta = AB[abi]
            local sub  = wep:GetLocalSub()
            local label = meta.name .. (meta.subs and (" : "..meta.subs[sub]) or "")
            draw.SimpleText(label,"CC_HUD",bx+bw/2,by-44,Color(255,255,200),TEXT_ALIGN_CENTER)
        end)

        -- green ground marker
        hook.Add("PostDrawTranslucentRenderables","CC_PDTR_"..id,function()
            if not IsValid(wep) then return end
            local mx,my=gui.MouseX(),gui.MouseY()
            if mx<0 or my<0 or mx>ScrW() or my>ScrH() then return end
            local dir=gui.ScreenToVector(mx,my)
            local tr=util.TraceLine({start=wep.CamPos,endpos=wep.CamPos+dir*10000,mask=MASK_SOLID})
            if tr.Hit then render.SetMaterial(matDot) render.DrawSprite(tr.HitPos+Vector(0,0,2),64,64,Color(0,255,0,200)) end
        end)

        -- FIX ③ — cast ability on **GUIMousePressed** (works with screen-clicker)
        hook.Add("GUIMousePressed","CC_Mouse_"..id,function(mc)
            if not IsValid(wep) or mc ~= MOUSE_LEFT then return end
           local hp = vgui.GetHoveredPanel()
            while IsValid(hp) do
                if hp == PANEL then return end          -- clicked inside the UI → ignore
                hp = hp:GetParent()
            end
            local mx,my = gui.MouseX(), gui.MouseY()
            local dir   = gui.ScreenToVector(mx,my)
            local tr    = util.TraceLine({start=wep.CamPos,endpos=wep.CamPos+dir*10000,mask=MASK_SOLID})
            if not tr.Hit then return end
            surface.PlaySound(sndCast)
            net.Start("cc_use")
                net.WriteUInt(wep:GetLocalAbility(),4)
                net.WriteUInt(wep:GetLocalSub(),3)
                net.WriteVector(tr.HitPos)
                net.WriteEntity(IsValid(tr.Entity) and tr.Entity or Entity(0))
            net.SendToServer()
        end)
    end

    ----------------------------------------------------------------
    --  SWEP lifecycle
    ----------------------------------------------------------------
    function SWEP:Deploy()   setLocalAbility(self,1,1) openPanel(self) installHooks(self) return true end
    function SWEP:Holster()  clearAll() return true end
    function SWEP:OnRemove() clearAll() end
    function SWEP:OnDrop()   clearAll() end
    function SWEP:Reload()   self.CamPos = self.Owner:GetPos()+Vector(0,0,START_H) end

    ----------------------------------------------------------------
    --  Watchdog: auto-clear UI when weapon not active
    ----------------------------------------------------------------
    hook.Add("Think","CC_UICleanup",function()
        local w=LocalPlayer():GetActiveWeapon()
        if not (IsValid(w) and w:GetClass()=="weapon_cc_remote") then clearAll() end
    end)
end -- CLIENT end

----------------------------------------------------------------
--  SERVER: freeze while active  (ability handling remains in role code)
----------------------------------------------------------------
if SERVER then
    hook.Add("Move","CC_Freeze",function(ply,mv)
        local w=ply:GetActiveWeapon()
        if IsValid(w) and w:GetClass()=="weapon_cc_remote" then
            mv:SetVelocity(vector_origin)
            mv:SetMaxSpeed(1)
            mv:SetMaxClientSpeed(1)
        end
    end)
    -- Removed placeholder net.Receive: role file already processes cc_use
end
