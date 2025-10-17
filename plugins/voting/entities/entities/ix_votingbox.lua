local PLUGIN = PLUGIN

AddCSLuaFile()
DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Voting Box"
ENT.Author = "Dzhey Kashta"
ENT.Category = "Helix - Voting System"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.LastUsed = {}

function ENT:Initialize()
    self:SetModel("models/props/cs_office/file_box_p1.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local steamID = activator:SteamID()
    local cooldown = self.LastUsed[steamID] or 0

    if cooldown > CurTime() then return end
    self.LastUsed[steamID] = CurTime() + 1

    net.Start("ixVotingBoxMenu")
    net.Send(activator)
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local pos = self:GetPos() + Vector(0, 0, 20)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 180)

        cam.Start3D2D(pos, ang, 0.1)
            surface.SetFont("DermaLarge")
            local text = "Voting Box"
            local textWidth, textHeight = surface.GetTextSize(text)

            local padding = 20
            local boxWidth = textWidth + padding
            local boxHeight = textHeight + padding

            draw.RoundedBox(8,
                -boxWidth / 2, -boxHeight / 2,
                boxWidth, boxHeight,
                Color(20, 20, 20, 180)
            )

            draw.SimpleTextOutlined(
                text,
                "DermaLarge",
                0, 0,
                Color(255, 200, 200),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                1,
                Color(0, 0, 0, 200)
            )
        cam.End3D2D()
    end
end

if Server then
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
        -- Block if they’re holding the spawn tool
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "gmod_tool" then
            local tool = ply:GetTool()
            if tool and tool.Mode == "spawn" then
                ply:ChatPrint("You cannot spawn this entity with the toolgun.")
                return
            end
        end
        
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
end