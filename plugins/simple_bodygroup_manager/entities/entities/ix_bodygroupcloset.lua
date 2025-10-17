local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Bodygroup Closet"
ENT.Category = "Helix - Bodygroup Closet"
ENT.Author = "Dzhey Kashta"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
    self:SetModel("models/props_c17/FurnitureDresser001a.mdl")
    self:SetModelScale(1.2, 0)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:Wake() end
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    net.Start("SBMOpenMenu")
        net.WriteEntity(ply)
    net.Send(ply)
end

-- Restrict tool usage
function ENT:CanTool(ply, trace, tool)
    if not ply:IsUA() then
        if SERVER then
            ply:ChatPrint("You do not have permission to use tools on this entity.")
        end
        return false
    end
    return true
end

-- Restrict spawn from spawn menu
function ENT:SpawnFunction(ply, tr, ClassName)
    if not ply:IsUA() then
        if SERVER then
            ply:ChatPrint("You do not have permission to spawn this entity.")
        end
        return
    end

    if not tr.Hit then return end

    local spawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create(ClassName)
    ent:SetPos(spawnPos)
    ent:Spawn()
    ent:Activate()

    return ent
end