local ROLE = {}

ROLE.nameraw = "skunk"
ROLE.name = "Skunk"
ROLE.nameplural = "Skunks"
ROLE.nameext = "a Skunk"
ROLE.nameshort = "sknk"

ROLE.desc = [[Spray foes with a lingering stink.]]
ROLE.team = ROLE_TEAM_MONSTER
ROLE.shop = nil
ROLE.loadout = { "weapon_ttt_skunk_stink" }

ROLE.startingcredits = nil
ROLE.startinghealth = 125
ROLE.maxhealth = 125

ROLE.ispublic = true
ROLE.ispublicrole = true

RegisterRole(ROLE)

if SERVER then
    --util.AddNetworkString("skunk_reset")

    hook.Add("TTTPrepareRound", "TTT_SkunkStart", function()
        for _, p in ipairs(player.GetAll()) do
            p:SetNWBool("skunk_stinked", false)
        end
        --net.Start("skunk_reset")
        --net.Broadcast()
    


        local rng = 150 * 150
        local tickrate = 0.25
        timer.Create("Skunk_StinkDmg", tickrate, 0, function()
            for _, carrier in player.Iterator() do
                if carrier:GetNWBool("skunk_stinked") and carrier:Alive() then
                    for _, tgt in player.Iterator() do
                        if tgt ~= carrier and tgt:Alive() and tgt:GetPos():DistToSqr(carrier:GetPos()) <= rng and not tgt:IsSkunk() then
                            local d = DamageInfo()
                            d:SetDamage(2)
                            d:SetDamageType(DMG_POISON)
                            d:SetAttacker(carrier)
                            d:SetInflictor(carrier)
                            tgt:TakeDamageInfo(d)
                            print("damage")
                        end
                    end
                end
            end
        end)
    end)
else
    
    local part = "particle/smokesprites_000"
    hook.Add("Tick", "Skunk_Particles", function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWBool("skunk_stinked") then
                if not ply.nextStink or ply.nextStink < CurTime() then
                    ply.nextStink = CurTime() + 0.15
                    local emitter = ParticleEmitter(ply:GetPos())
                    local p = emitter:Add(part .. math.random(1,9), ply:GetPos() + Vector(0,0,40))
                    if p then
                        p:SetDieTime(1.2)
                        p:SetStartAlpha(130)
                        p:SetEndAlpha(0)
                        p:SetStartSize(12)
                        p:SetEndSize(30)
                        p:SetRoll(math.random()*360)
                        p:SetColor(50,200,50)
                    end
                    emitter:Finish()
                end
            end
        end
    end)
end
