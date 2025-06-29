local hook = hook
local timer = timer
local IsValid = IsValid
local player = player

local ROLE = {}
ROLE.nameraw = "observer"
ROLE.name = "Observer"
ROLE.nameplural = "Observers"
ROLE.nameext = "an observer"
ROLE.nameshort = "obsvr"
ROLE.desc = [[You can xray people. Hold your crosshair over a player to scan their role!]]
ROLE.team = ROLE_TEAM_INNOCENT

if true then return end
RegisterRole(ROLE)

local SCAN_TIME = 1.0 -- seconds needed to scan (change as you like)
local SCAN_CHECK_INTERVAL = 0.05

if SERVER then
    util.AddNetworkString("TTT_ObserverScanResult")
    util.AddNetworkString("TTT_ObserverScanProgress")
end

if CLIENT then
    local scanProgress = 0
    local scanTarget = nil

    hook.Add("Think", "Observer_ScanThink", function()
        local lp = LocalPlayer()
        if not lp:IsObserver() or not lp:Alive() then
            scanProgress = 0
            scanTarget = nil
            return
        end

        local tr = lp:GetEyeTrace()
        local ent = tr.Entity
        if IsValid(ent) and ent:IsPlayer() and ent ~= lp and ent:Alive() and tr.HitPos:DistToSqr(lp:GetShootPos()) < 10000 then
            -- Looking at a valid player, begin scanning
            if scanTarget ~= ent then
                scanTarget = ent
                scanProgress = 0
            end
            scanProgress = scanProgress + FrameTime()
            if scanProgress >= SCAN_TIME and not ent:GetNWBool("Observer_Scanned_" .. lp:SteamID(), false) then
                net.Start("TTT_ObserverScanResult")
                net.WriteEntity(ent)
                net.SendToServer()
                -- Locally mark as scanned so we don't spam the net message
                ent:SetNWBool("Observer_Scanned_" .. lp:SteamID(), true)
            end
            -- Send progress for HUD (optional)
            net.Start("TTT_ObserverScanProgress")
            net.WriteFloat(math.min(scanProgress / SCAN_TIME, 1))
            net.SendToServer()
        else
            scanTarget = nil
            scanProgress = 0
        end
    end)

    -- Draw progress bar
    hook.Add("HUDPaint", "Observer_ScanHUD", function()
        local lp = LocalPlayer()
        if not lp:IsObserver() or scanProgress <= 0 then return end
        local w, h = 200, 20
        local x, y = ScrW() / 2 - w / 2, ScrH() * 0.7
        surface.SetDrawColor(50, 150, 255, 220)
        surface.DrawRect(x, y, w * math.Clamp(scanProgress / SCAN_TIME, 0, 1), h)
        draw.SimpleText("Scanning...", "Trebuchet24", x + w/2, y + h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    -- Only show role if scanned
    hook.Add("TTTTargetIDPlayerText", "Observer_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
        if not cli:IsObserver() then return end
        if ent:GetNWBool("Observer_Scanned_" .. cli:SteamID(), false) then
            local newColor = ROLE_COLORS_RADAR[ent:GetRole()]
            local newText = string.upper(ROLE_STRINGS[ent:GetRole()])
            return newText, newColor, false
        end
    end)
else
    -- SERVER: handle scan result, mark the player as scanned for this observer
    net.Receive("TTT_ObserverScanResult", function(len, ply)
        local ent = net.ReadEntity()
        if not IsValid(ply) or not ply:IsObserver() or not ply:Alive() then return end
        if not IsValid(ent) or not ent:IsPlayer() or not ent:Alive() then return end
        ent:SetNWBool("Observer_Scanned_" .. ply:SteamID(), true)
    end)
    net.Receive("TTT_ObserverScanProgress", function(len, ply)
        -- You can handle scan progress here for server-side bars if you want, otherwise ignore
    end)
end

-- PLAYER:IsObserver function
local PLAYER = FindMetaTable("Player")
function PLAYER:IsObserver()
    return self.GetRole and self:GetRole() == ROLE_OBSERVER
end

if SERVER then
    AddCSLuaFile()
end
