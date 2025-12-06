local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "doomguy"
ROLE.name = "Doomguy"
ROLE.nameplural = "Doomguys"
ROLE.nameext = "a Doomguy"
ROLE.nameshort = "dmguy"

ROLE.desc = [[They know you are coming. They know they can't stop you]]
ROLE.shortdesc = "More health, speed, and can dash"
ROLE.team = ROLE_TEAM_MONSTER

ROLE.shop = {} --use convar for shop `ttt_%NAMERAW%_shop_mode = 2 
ROLE.loadout = {EQUIP_RADAR}

ROLE.startingcredits = 2

ROLE.startinghealth = 200
ROLE.maxhealth = 300

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then
    resource.AddFile("sound/doomguy/doomtheme.mp3")

    util.AddNetworkString("Doomguy_Dash")
    local dashCooldown = 1.0
    local dashSpeed = 600
    local nextDash = {}

    net.Receive("Doomguy_Dash", function(len, ply)
        if not ply:IsDoomguy() then return end
        if not ply:Alive() or ply:IsSpec() then return end

        local now = CurTime()
        if nextDash[ply] and now < nextDash[ply] then return end
        nextDash[ply] = now + dashCooldown

        local mv = net.ReadVector()
        if mv:LengthSqr() == 0 then
            mv = ply:GetForward()
        end

        local velocity = ply:GetVelocity()
        velocity = velocity + mv * dashSpeed
        ply:SetVelocity(velocity)
    end)

    hook.Add("EntityTakeDamage", "Frog_NoFallDamage", function(target, dmginfo)
        if not target:IsPlayer() then return end
        if not target:IsDoomguy() then return end
        if dmginfo:IsFallDamage() then
            dmginfo:SetDamage(0)
            return true
        end
    end)

else

    local dashDelay = 1.0 -- keep in sync with server
    local lastDash = 0
    hook.Add("PlayerButtonDown", "Doomguy_DashKey", function(ply, button)
        if ply ~= LocalPlayer() then return end
        if not ply:IsDoomguy() then return end
        if button ~= KEY_LSHIFT then return end
        if CurTime() < lastDash + dashDelay then return end
        lastDash = CurTime()

        -- Determine movement direction based on keys
        local mv = Vector(0,0,0)
        if input.IsKeyDown(KEY_W) then mv = mv + ply:GetForward() end
        if input.IsKeyDown(KEY_S) then mv = mv - ply:GetForward() end
        if input.IsKeyDown(KEY_A) then mv = mv - ply:GetRight() end
        if input.IsKeyDown(KEY_D) then mv = mv + ply:GetRight() end
        mv.z = 0
        if mv:LengthSqr() == 0 then
            mv = ply:GetForward() -- default to forward if no input
        end
        mv = mv:GetNormalized()

        net.Start("Doomguy_Dash")
        net.WriteVector(mv)
        net.SendToServer()
    end)
    
    hook.Add("TTTTutorialRoleText", "DOOMGUY_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_DOOMGUY then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]
            local html = ROLE_STRINGS[ROLE_REFLECTOR] .. "... Rip and tear"
            return html
        end
    end)
    hook.Add("TTTBeginRound", "Doomguy_RoleFeatures_TTTBeginRound", function()
        local playersounds = {}

        hook.Add("TTTPlayerRoleChanged", "Doomguy_Removed", function(ply, old_role)
            if old_role == ROLE_DOOMGUY then
                 if playersounds[ply] then
                    playersounds[ply]:Stop()
                    playersounds[ply] = nil 
                end
            end
        end)
       
        hook.Add("Think", "DoomguyMusic", function ()
            if GetRoundState() < ROUND_ACTIVE then return end
            for _, p in PlayerIterator() do
                if not playersounds[p] then
                    if p:IsValid() and p:IsDoomguy() then
                        local doomguy_station --stop it from becoming garbage collected
                        sound.PlayFile("sound/doomguy/doomtheme.mp3", "3d", function(station, _, errorStr)
                            if station then
                                playersounds[p] = station
                            else
                                print(errorStr)
                            end
                        end)
                    end
                else
                    if not p:IsDoomguy() then
                        playersounds[p]:Stop()
                        playersounds[p] = nil 
                    end
                    playersounds[p]:SetPos(p:GetPos())
                end
            end
        end)
    end)
end