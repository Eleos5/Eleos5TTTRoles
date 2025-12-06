local server_peanutMovingSound
local server_peanutMovingSoundCurrentlyPlaying = false

local oldPeanut
local oldPeanutHullDuckMin, oldPeanutHullDuckMax
local oldPeanutViewOffset
local oldPeanutViewOffsetDucked

local ROLE = {}

ROLE.nameraw = "peanut"
ROLE.name = "Peanut"
ROLE.nameplural = "Peanut's"
ROLE.nameext = "a Peanut"
ROLE.nameshort = "Pea"

ROLE.desc = [[In 30 seconds, you will transform into Peanut.
Peanut can only move when nobody is looking at it.
Peanut can instantaly kill people with it's snap ability.]]

ROLE.shortdesc = "Can only move when nobody is looking at it."

ROLE.team = ROLE_TEAM_MONSTER

ROLE.shop = nil
ROLE.loadout = {"weapon_ttt_peanut_snap"}

ROLE.startingcredits = nil

ROLE.startinghealth = 100
ROLE.maxhealth = 100

ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

if SERVER then
    CreateConVar("ttt_peanut_transform_health", "5000", FCVAR_NONE, "This sets the peanut's health on transformation.")
end
ROLE.convars = {
    {
        cvar = "ttt_peanut_transform_health",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0,
    }
}

RegisterRole(ROLE)

ROLE_IS_ACTIVE[ROLE_PEANUT] = function(ply)
    return ply:GetNWBool("TTT_PeanutActive")
end

sound.Add({
    name = "Peanut_Horror",
    channel = CHAN_STATIC,
    volume = 1.5,
    level = 80,
    pitch = {95, 110},
    sound = {"peanut/H1.ogg", "peanut/H2.ogg", "peanut/H3.ogg", "peanut/H9.ogg"}
})

sound.Add({
    name = "Peanut_Move",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 90,
    pitch = 100,
    sound = "peanut/StoneDrag.ogg",
})

local function testIfPlayerCanSeeOtherPlayer(ply, otherPly, traceResult, traceConfig)
    local ourEye = ply:EyePos()

    traceConfig.start = ply:EyePos()
    traceConfig.endpos = otherPly:EyePos()
    traceConfig.mask = MASK_VISIBLE
    traceConfig.output = traceResult
    
    if ply ~= otherPly and ply:IsActive() then
        if ply:IsOnScreen(otherPly, 0.7) then
            util.TraceLine(traceConfig)
            
            if not traceResult.Hit then
                return true
            end
        end
    end

    return false
end

-- local setPeanutTeam do -- Team change
--     if SERVER then
--         util.AddNetworkString("TTT_PeanutTeamChange")
--     end

--     setPeanutTeam = function(isMonster)
--         MONSTER_ROLES[ROLE_PEANUT] = isMonster
--         INNOCENT_ROLES[ROLE_PEANUT] = not isMonster

--         UpdateRoleColours()

--         if SERVER then
--             net.Start("TTT_PeanutTeamChange")
--             net.WriteBool(isMonster)
--             net.Broadcast()
--         end
--     end

--     if CLIENT then
--         net.Receive("TTT_PeanutTeamChange", function()
--             setPeanutTeam(net.ReadBool())
--         end)
--     end
-- end

hook.Add("PlayerCanPickupWeapon", "Peanut_NoPickup", function(ply, wep)
    if ply:IsActivePeanut() and ply:IsRoleActive() and wep:GetClass() ~= "weapon_ttt_peanut_snap" then
        return false
    end
end)

hook.Add("Move", "Peanut_Move", function( ply, mv, usrcmd )
    if ply:IsActivePeanut() and ply:IsRoleActive() then
        local modifier = ply:GetNWFloat("Peanut_SpeedModifier", 1)
        local speed = mv:GetMaxSpeed() * modifier
        mv:SetMaxSpeed(speed)
        mv:SetMaxClientSpeed(speed)

        if server_peanutMovingSound then
            local playing = ply:OnGround() and (mv:GetVelocity() * Vector(1, 0, 1)):LengthSqr() > 0
            if playing and not server_peanutMovingSoundCurrentlyPlaying then
                server_peanutMovingSound:Play()
            elseif not playing and server_peanutMovingSoundCurrentlyPlaying then
                server_peanutMovingSound:Stop()
            end

            server_peanutMovingSoundCurrentlyPlaying = playing
        end
    end
end)

hook.Add("PlayerFootstep", "Peanut_DisableFootsteps", function(ply, pos, foot, sound, volume, filter)
    return true
end)

if CLIENT then
    local blinkBarVisibleTimer = 0

    local blinkingTransparency = 0
    local barTransparency = 0

    local notSeenCooldown = 0

    hook.Add("PreDrawHUD", "Peanut_PreDrawHUD", function()
        cam.Start2D()
        
        local ply = LocalPlayer()
        local peanut = player.GetLivingRole(ROLE_PEANUT)
        if peanut and not peanut:IsRoleActive() then
            peanut = nil
        end

        local isBlinking = false
        if peanut and ply ~= peanut then
            isBlinking = peanut:GetNWFloat("Peanut_BlinkBars", 1) == 0
        end

        do
            blinkingTransparency = blinkingTransparency + (((isBlinking and blinkBarVisibleTimer > 0) and 1 or 0) - blinkingTransparency) * math.min(FrameTime() * 20, 1)
            surface.SetDrawColor(0, 0, 0, 255 * blinkingTransparency)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        end

        if not peanut then
            notSeenCooldown = 0
        end

        local barIsVisible = false

        if peanut then
            local peanutPos = peanut:EyePos()

            local isSeen = testIfPlayerCanSeeOtherPlayer(ply, peanut, {}, {})

            -- Jumpscare horror sounds
            if ply ~= peanut then
                if isSeen then
                    if notSeenCooldown <= 0 and peanutPos:Distance(ply:EyePos()) < 3000.0 then
                        surface.PlaySound("Peanut_Horror")
                    end

                    notSeenCooldown = 30
                else
                    notSeenCooldown = notSeenCooldown - FrameTime()
                end
            end

            if isSeen or ply == peanut then
                barIsVisible = true
                blinkBarVisibleTimer = 10
            end
        end

        local barVisiblePercent = 1
        if ply == peanut and peanut:GetNWFloat("Peanut_SpeedModifier", 0) ~= 0 then
            -- Peanut's bar fades if nobody is looking at him
            barVisiblePercent = 0.3
        end

        barTransparency = barTransparency + ((barIsVisible and barVisiblePercent or 0) - barTransparency) * math.min(FrameTime() * 20, 1)

        if barTransparency > 0 then
            local blinkBars = peanut and peanut:GetNWFloat("Peanut_BlinkBars", 0) or 0
    
            local blinkTimerHeight = 50
            
            local numBars = 3
            local barPadding = 5
            local barWidth = blinkTimerHeight * 0.5

            local blinkTimerWidth = numBars * barWidth + (numBars - 1) * barPadding
            
            local x, y = 350, ScrH() - blinkTimerHeight - 10
            
            surface.SetDrawColor(30, 30, 30, 200 * barTransparency)
            surface.DrawRect(x, y, blinkTimerWidth, blinkTimerHeight)
            surface.SetDrawColor(60, 60, 60, 200 * barTransparency)
            surface.DrawOutlinedRect(x - 3, y - 3, blinkTimerWidth + 6, blinkTimerHeight + 6, 3)

            for i = 1, blinkBars do
                surface.SetDrawColor(255, 255, 255, 255 * barTransparency)
                surface.DrawRect(x, y, barWidth, blinkTimerHeight)
                
                x = x + barWidth + barPadding
            end
        end

        cam.End2D()
    end)
end

do -- Disable peanut duck
    if CLIENT then
        net.Receive("TTT_Peanut_ResetHullDuck", function()
            local ply = net.ReadPlayer()
            local min = net.ReadVector()
            local max = net.ReadVector()

            if IsValid(ply) then
                ply:SetHullDuck(min, max)
            end
        end)
    end

    if SERVER then
        util.AddNetworkString("TTT_Peanut_ResetHullDuck")

        hook.Add("Tick", "Peanut_DisableDuck", function()
            local peanut = player.GetLivingRole(ROLE_PEANUT)

            if oldPeanut ~= peanut and oldPeanut then
                print("Resetting old peanut!", oldPeanut, CLIENT)
                if oldPeanut:IsActive() and oldPeanutViewOffsetDucked then
                    oldPeanut:SetViewOffset(oldPeanutViewOffset)
                    oldPeanut:SetViewOffsetDucked(oldPeanutViewOffsetDucked)
                    oldPeanut:SetHullDuck(oldPeanutHullDuckMin, oldPeanutHullDuckMax)

                    net.Start("TTT_Peanut_ResetHullDuck")
                    net.WritePlayer(oldPeanut)
                    net.WriteVector(oldPeanutHullDuckMin)
                    net.WriteVector(oldPeanutHullDuckMax)
                    net.Broadcast()

                    oldPeanutViewOffset = nil
                    oldPeanutViewOffsetDucked = nil
                    oldPeanutHullDuckMin, oldPeanutHullDuckMax = nil, nil

                end

                oldPeanut = nil
            end

            if peanut and peanut:IsRoleActive() then
                if not oldPeanut then
                    oldPeanut = peanut
                    oldPeanutViewOffset = peanut:GetViewOffset()
                    oldPeanutViewOffsetDucked = peanut:GetViewOffsetDucked()
                    oldPeanutHullDuckMin, oldPeanutHullDuckMax = peanut:GetHullDuck()
                    
                    
                    peanut:SetViewOffset(Vector(0, 0, 120))
                    peanut:SetViewOffsetDucked(peanut:GetViewOffset())
                    peanut:SetHullDuck(peanut:GetHull())

                    local hullMin, hullMax = peanut:GetHull()

                    net.Start("TTT_Peanut_ResetHullDuck")
                    net.WritePlayer(peanut)
                    net.WriteVector(hullMin)
                    net.WriteVector(hullMax)
                    net.Broadcast()
                end
            end
        end)
    end
end

hook.Add("HandlePlayerDucking", "Peanut_DisableDuckAnimation", function( ply, velocity )
    if ply:IsActivePeanut() and ply:IsRoleActive() then
        return true
    end
end)

if SERVER then
    resource.AddFile("materials/models/peanut/01__Default.vmt")
    resource.AddFile("materials/models/peanut/peanut_normal.vtf")
    resource.AddFile("materials/models/peanut/peanut.vtf")
    resource.AddFile("models/peanut/peanut.mdl")

    resource.AddFile("sound/peanut/H1.ogg")
    resource.AddFile("sound/peanut/H2.ogg")
    resource.AddFile("sound/peanut/H3.ogg")
    resource.AddFile("sound/peanut/H9.ogg")
    resource.AddFile("sound/peanut/NS1.ogg")
    resource.AddFile("sound/peanut/NS2.ogg")
    resource.AddFile("sound/peanut/NS3.ogg")
    resource.AddFile("sound/peanut/StoneDrag.ogg")

    local peanutCanTransform = false

    local blinkTimer = 3
    local activeBlinkingTimer = 0

    hook.Add("Tick", "Peanut_Tick", function()
        local peanut = player.GetLivingRole(ROLE_PEANUT)

        if not peanut and server_peanutMovingSound then
            server_peanutMovingSound = nil
            server_peanutMovingSoundCurrentlyPlaying = false
        end

        if peanut and peanutCanTransform then
            peanut:SetNWBool("TTT_PeanutActive", true)
            peanutCanTransform = false
        end

        if peanut and peanut:IsRoleActive() then
            if peanut:GetModel() ~= "models/peanut/peanut.mdl" then
                peanut:SetModel("models/peanut/peanut.mdl")
                peanut:RemoveAllItems()
                peanut:Give("weapon_ttt_peanut_snap")
                server_peanutMovingSound = CreateSound(peanut, "Peanut_Move")
                
                local h = GetConVar("ttt_peanut_transform_health"):GetInt()
                peanut:SetMaxHealth(h)
                peanut:SetHealth(h)
            end

            if blinkTimer > 0 then
                blinkTimer = blinkTimer - FrameTime()
                if blinkTimer <= 0 then
                    activeBlinkingTimer = 1
                end

                peanut:SetNWFloat("Peanut_BlinkBars", math.ceil(blinkTimer))
            end

            local isSeen = false
            
            if activeBlinkingTimer > 0 then
                activeBlinkingTimer = activeBlinkingTimer - FrameTime()
                if activeBlinkingTimer <= 0 then
                    blinkTimer = 3
                end
            else
                local traceResult = {}
                local traceConfig = {}
                
                for _, ply in player.Iterator() do
                    if ply ~= peanut and ply:IsActive() then
                        if testIfPlayerCanSeeOtherPlayer(ply, peanut, traceResult, traceConfig) then
                            isSeen = true
                            break
                        end
                    end
                end
            end

            if isSeen then
                if peanut:GetNWFloat("Peanut_SpeedModifier", 1) ~= 0 then
                    peanut:SetJumpPower(0)
                    peanut:SetNWFloat("Peanut_SpeedModifier", 0)
                    peanut:SetNWFloat("Peanut_Angle", peanut:GetAngles().y)
                end
            else
                peanut:SetJumpPower(200)
                peanut:SetNWFloat("Peanut_SpeedModifier", 4)
            end
        end
    end)
    
    -- We have to overwrite ttt's built in OnPlayerHitGround, because there's no way to modify
    -- the fall damage
    local oldOnPlayerHitGround = GM.OnPlayerHitGround 
    function GM:OnPlayerHitGround(ply, in_water, on_floater, speed)
        if ply:IsActivePeanut() and ply:IsRoleActive() then
            -- Took from ttt
            -- Everything over a threshold hurts you, rising exponentially with speed
            local damage = math.pow(0.05 * (speed - 420), 1.75) * 10 + 100

            -- if we fell on a dude, that hurts (him)
            local ground = ply:GetGroundEntity()
            if IsPlayer(ground) then
                if math.floor(damage) > 0 then
                    local att = ply

                    -- if the faller was pushed, that person should get attrib
                    local push = ply.was_pushed
                    if push then
                        if math.max(push.t or 0, push.hurt or 0) > CurTime() - 4 then
                            att = push.att
                        end
                    end

                    local dmg = DamageInfo()

                    if att == ply then
                        -- hijack physgun damage as a marker of this type of kill
                        dmg:SetDamageType(DMG_CRUSH + DMG_PHYSGUN)
                    else
                        -- if attributing to pusher, show more generic crush msg for now
                        dmg:SetDamageType(DMG_CRUSH)
                    end

                    dmg:SetAttacker(att)
                    dmg:SetInflictor(att)
                    dmg:SetDamageForce(Vector(0, 0, -1))
                    dmg:SetDamage(damage)

                    ground:TakeDamageInfo(dmg)
                end
            end

            return
        end

        return oldOnPlayerHitGround(self, ply, in_water, on_floater, speed)
    end

    hook.Add("TTTPrepareRound", "Peanut_PrepareRound", function()
        -- setPeanutTeam(false)
        peanutCanTransform = false

        for _, ply in player.Iterator() do
            if ply:GetNWBool("TTT_PeanutActive", false) == true then
                ply:SetNWBool("TTT_PeanutActive", false)
            end
        end
    end)

    hook.Add("TTTBeginRound", "Peanut_BeginRound", function()
        timer.Create("Peanut_Transform", 30, 1, function()
            -- setPeanutTeam(true)
            peanutCanTransform = true

            local peanut = player.GetLivingRole(ROLE_PEANUT)
            if peanut then
                peanut:QueueMessage(MSG_PRINTBOTH, "YOU HAVE AWAKENED! SNAP THEM ALL!")
            end
        end)
    end)

    hook.Add("TTTEndRound", "Peanut_BeginRound", function()
        timer.Remove("Peanut_Transform")
    end)

    AddCSLuaFile()
end

hook.Add("UpdateAnimation", "Peanut_FreezeRotation", function()
    local peanut = player.GetLivingRole(ROLE_PEANUT)

    if peanut and peanut:GetNWFloat("Peanut_SpeedModifier", 1) == 0 then
        peanut:SetRenderAngles(Angle(0, peanut:GetNWFloat("Peanut_Angle", 0), 0))
    end
end)