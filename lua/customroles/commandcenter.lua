----------------------------------------------------------------
--  Command Center  –  CR-for-TTT role (server-side abilities)
----------------------------------------------------------------
local ROLE = {
    nameraw         = "commandcenter",
    name            = "Command Center",
    nameplural      = "Command Centers",
    nameext         = "a Command Center",
    nameshort       = "cmdc",
    desc            = [[Use the Command Uplink to assist traitors remotely.]],
    team            = ROLE_TEAM_TRAITOR,
    loadout         = { "weapon_cc_remote" },
    startinghealth  = 100,
    maxhealth       = 100,
    startingcredits = 0
}
RegisterRole(ROLE)

if CLIENT then return end  ----------------------------------------------------

util.AddNetworkString("cc_use")

----------------------------------------------------------------
--  Energy & helpers
----------------------------------------------------------------
local MAX_ENERGY, REGEN = 100, 10
local COST = {                          -- ❶  base costs
    [1] = { 10, 30, 20 },               -- summon
    [2] = { 10, 15, 20 },               -- grenade
    [3] = 25,                           -- heal
    [4] = 10,                           -- abduct  (per second drain!)
    [5] = 40,                           -- rain bullets
    [6] = 30,                           -- vortex
    [7] = 25                            -- gravity ward
}

local function syncEnergy(p) p:SetNWInt("CC_Energy", p.CCEnergy or 0) end
timer.Create("cc_regen",1,0,function()
    for _,p in player.Iterator() do
        if p:IsCommandCenter() and p:IsActive() then
            p.CCEnergy = math.min((p.CCEnergy or MAX_ENERGY)+REGEN,MAX_ENERGY)
            syncEnergy(p)
        end
    end
end)

local function spend(p,a,s)
    local c = istable(COST[a]) and COST[a][s] or COST[a]
    if (p.CCEnergy or 0) >= c then p.CCEnergy = p.CCEnergy - c syncEnergy(p) return true end
end

local function clear(pos,r)
    for _,e in ipairs(ents.FindInSphere(pos,r)) do
        if e:IsPlayer() and e:Alive() then return false end
    end
    return true
end

local function spawn(class,pos,ang)
    local e = ents.Create(class)
    if not IsValid(e) then return nil end
    e:SetPos(pos); if ang then e:SetAngles(ang) end
    e:Spawn()
    return e
end

----------------------------------------------------------------
--  Main ability dispatcher
----------------------------------------------------------------
net.Receive("cc_use",function(_,ply)
    local ability = net.ReadUInt(4)
    local sub     = net.ReadUInt(3)
    local pos     = net.ReadVector()
    local target  = net.ReadEntity()

    ----------------------------------------------------------------
    if ability == 1 and spend(ply,1,sub) and clear(pos,64) then   -- SUMMON
        if sub == 1 then
            local b = ents.Create("prop_physics")
            if IsValid(b) then
                b:SetModel("models/props_c17/oildrum001_explosive.mdl")
                b:SetPos(pos)
                b:Spawn()
                b:Ignite(0,30)
            end
        elseif sub == 2 then spawn("npc_zombie", pos)
        else                  spawn("npc_manhack", pos)
        end

    ----------------------------------------------------------------
    elseif ability == 2 and spend(ply,2,sub) then                 -- GRENADE
        local cls = (sub==1 and "ttt_smokegrenade_proj")
                 or (sub==2 and "ttt_confgrenade_proj")
                 or "ttt_firegrenade_proj"
        local g = spawn(cls, pos + Vector(0,0,8))
        if IsValid(g) and g.SetDetonateExact then g:SetDetonateExact(CurTime()+3) end

    ----------------------------------------------------------------
    elseif ability == 3 and spend(ply,3) and IsValid(target) then -- HEAL
        target:SetHealth(math.min(target:GetMaxHealth(), target:Health()+20))

    ----------------------------------------------------------------
    -- ABDUCT • drains 10 energy / sec while lifting everything in radius
   elseif ability == 4 and spend(ply,4) then        -- ABDUCT
        -- cancel any previous abduct owned by this player
        if ply.CC_AbductID then timer.Remove(ply.CC_AbductID) end

        local id = "cc_abduct_" .. ply:EntIndex()
        ply.CC_AbductID = id

        timer.Create(id,0.5,0,function()             -- runs every 0.5 s
            if not IsValid(ply) or not ply:IsActive() then timer.Remove(id) return end
            if not spend(ply,4) then timer.Remove(id) return end

            for _,e in ipairs(ents.FindInSphere(pos,160)) do
                if IsValid(e) then e:SetVelocity(Vector(0,0,500)) end     -- faster lift
            end
        end)

    ----------------------------------------------------------------
    -- RAIN BULLETS • actual bullet traces
    elseif ability == 5 and spend(ply,5) then
        for i=1,60 do
            timer.Simple(i*0.04,function()
                if not IsValid(ply) then return end
                local src = pos + Vector(0,0,500) + VectorRand()*100
                local dir = (VectorRand()*0.4 + Vector(0,0,-1)):GetNormalized()
                local b = {}
                b.Num    = 1
                b.Src    = src
                b.Dir    = dir
                b.Spread = Vector(0,0,0)
                b.Damage = 8
                b.Tracer = 0
                b.Force  = 5
                b.Attacker = ply
                b.IgnoreEntity = ply
                ply:FireBullets(b)
            end)
        end

    ----------------------------------------------------------------
    -- VORTEX • 6-sec pull
    elseif ability == 6 and spend(ply,6) then
        local id = "cc_vortex_" .. util.CRC(pos.x..","..pos.y..","..pos.z)
        timer.Create(id,0.1,60,function()
            for _,e in ipairs(ents.FindInSphere(pos,384)) do
                if not IsValid(e) then continue end
                local dir = (pos - e:GetPos()):GetNormalized()
                if e:IsPlayer() then e:SetVelocity(dir * 300)
                else
                    local ph = e:GetPhysicsObject()
                    if IsValid(ph) then ph:ApplyForceCenter(dir * 8000) end
                end
            end
        end)

    ----------------------------------------------------------------
    -- GRAVITY WARD • 8-sec downward push
    elseif ability == 7 and spend(ply,7) then
        local id = "cc_gw_" .. util.CRC(pos.x..","..pos.y..","..pos.z)
        hook.Add("Move", id, function(pl, mv)
            if mv:GetOrigin():DistToSqr(pos) < (256*256) then
                local vel = mv:GetVelocity()
                mv:SetVelocity(vel + Vector(0,0,-350))       -- push down every tick
            end
        end)
        timer.Simple(8,function() hook.Remove("Move",id) end)
    end
end)
