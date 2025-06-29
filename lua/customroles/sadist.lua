local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table
local util = util

local PlayerIterator = player.Iterator

local ROLE = {}
ROLE.nameraw = "sadist"
ROLE.name = "Sadist"
ROLE.nameplural = "Sadists"
ROLE.nameext = "a Sadist"
ROLE.nameshort = "sadist"

ROLE.desc = [[Win if you witness enough deaths! You just can't cause them.]]

ROLE.team = ROLE_TEAM_JESTER

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil
ROLE.startinghealth = 100
ROLE.maxhealth = nil

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = function (arguments) 
    return false     
end

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then

    util.AddNetworkString("Sadist_DeathUpdate")

    local win_pct = 0.7 -- percent of deaths to win (70%)

    local sadist_data = {}

    local function HasLOS(sadist, victim)
        if not IsValid(sadist) or not IsValid(victim) then return false end
        local trace = util.TraceLine({
            start = sadist:EyePos(),
            endpos = victim:EyePos(),
            filter = function(ent)
                return ent ~= sadist and ent ~= victim
            end,
            mask = MASK_VISIBLE
        })
        return not trace.Hit
    end

    hook.Add("Initialize", "SadistInitialize", function()
        WIN_SADIST = GenerateNewWinID(ROLE_SADIST)
    end)
    SADIST_WON = false
    hook.Add("TTTCheckForWin", "SadistCheckForWin", function()
        if SADIST_WON  then
            return WIN_SADIST
        end
    end)

    hook.Add("TTTBeginRound", "Sadist_Reset", function()
        SADIST_WON = false
        timer.Simple(1, function()
            local alive = 0
            for _, p in PlayerIterator() do
                if p:Alive() then
                    alive = alive + 1
                end
            end
            
            local total_needed = math.ceil(alive * win_pct)
            local rf = RecipientFilter()
            rf:AddAllPlayers()
            
            net.Start("Sadist_DeathUpdate")
            net.WriteUInt(0, 8)
            net.WriteUInt(total_needed, 8)
            net.Send(rf)
        end)
    end)

    hook.Add("PlayerDeath", "Sadist_TrackDeaths", function(victim, inflictor, attacker)
        for _, ply in PlayerIterator() do
            if ply:IsActiveSadist() and ply:Alive() and ply ~= victim and attacker ~= ply then
                timer.Create("SadistDeath_"..tostring(victim:EntIndex()), 1, 5, function()
                    if HasLOS(ply, victim) then
                        sadist_data[ply] = sadist_data[ply] or {}
                        if not sadist_data[ply][victim] then
                            sadist_data[ply][victim] = true

                            local total_alive = 0
                            local total_seen = 0
                            for _, p in PlayerIterator() do
                                if p ~= ply and not p:Alive() then
                                    total_seen = total_seen + (sadist_data[ply][p] and 1 or 0)
                                elseif p ~= ply then
                                    total_alive = total_alive + 1
                                end
                            end

                            local total_needed = math.ceil((total_alive + total_seen) * win_pct)
                            if total_seen >= total_needed then
                                -- Win the game for Sadist
                                ply:PrintMessage(HUD_PRINTCENTER, "You have witnessed enough deaths and WIN... Unless another role is stopping you")
                                SADIST_WON = true
                                --hook.Call("TTTEndRound", GAMEMODE, WIN_SADIST or WIN_JESTER)
                            else
                                print("Seen body")
                            end

                            net.Start("Sadist_DeathUpdate")
                            net.WriteUInt(table.Count(sadist_data[ply] or {}), 8)
                            net.WriteUInt(total_needed, 8)
                            net.Send(ply)
                        end
                    end
                end)
            end
        end
    end)

    hook.Add("TTTEndRound", "Sadist_Cleanup", function()
        sadist_data = {}
    end)

else -- CLIENT

    local deaths_seen = 0
    local deaths_needed = 1

    hook.Add("TTTBeginRound", "Sadist_Reset", function()
        deaths_seen = 0
        deaths_needed = 1
    end)

    net.Receive("Sadist_DeathUpdate", function()
        deaths_seen = net.ReadUInt(8)
        deaths_needed = net.ReadUInt(8)
    end)

    hook.Add("HUDPaint", "SadistHUD", function()
        local ply = LocalPlayer()
        if not ply:IsSadist() then return end
        if deaths_seen == -1 then return end 

        draw.SimpleText(
            "Witnessed Deaths: " .. deaths_seen .. " / " .. deaths_needed,
            "Trebuchet24", ScrW() / 2, 80,
            Color(255, 100, 100, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
        )
    end)

    hook.Add("TTTSyncWinIDs", "SummonerTTTWinIDsSynced", function()
        WIN_SADIST = WINS_BY_ROLE[ROLE_SADIST]
    end)

    hook.Add("TTTScoringWinTitle", "SadistScoringWinTitle", function(wintype, wintitles, title, secondaryWinRole)
        if wintype == WIN_SADIST then
            return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_SADIST]) }, c = ROLE_COLORS[ROLE_SADIST] }
        end
    end)

    hook.Add("TTTTutorialRoleText", "SADIST_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_SADIST then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]
            local html = ROLE_STRINGS[ROLE_REFLECTOR] .. "Watch enough death to win"
            return html
        end
    end)

end
