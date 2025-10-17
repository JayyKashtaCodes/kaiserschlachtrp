local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Information Booth"
ENT.Category = "IX: Information"
ENT.Spawnable = true
ENT.AdminOnly = true

if SERVER then
    -- Called when the entity is first created
    function ENT:Initialize()
        self:SetModel("models/aac_hotel_host_stand_01.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end

        -- Load saved topics if available
        local saved = ix.data.Get("info_booth_" .. self:EntIndex())
        if istable(saved) then
            self:SetNetVar("topics", saved)
        end
    end

    -- Called when a player presses +use on the entity
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end

        local topics = (PLUGIN and PLUGIN.GetEntityTopics) and PLUGIN:GetEntityTopics(self) or {}

        net.Start("ixInfoBooth_OpenView")
            net.WriteEntity(self)
            net.WriteTable(PLUGIN:GetEntityTopics(self))
        net.Send(activator)
    end

    -- Save topics when duplicating entity
    function ENT:OnDuplicated(entTable)
        local topics = self:GetNetVar("topics")
        if istable(topics) then
            entTable.EntityMods = entTable.EntityMods or {}
            entTable.EntityMods.InfoBoothTopics = topics
        end
    end

    -- Restore topics when pasted
    function ENT:PostEntityPaste(ply, ent, createdEntities)
        if ent.EntityMods and ent.EntityMods.InfoBoothTopics then
            self:SetNetVar("topics", ent.EntityMods.InfoBoothTopics)
            ix.data.Set("info_booth_" .. self:EntIndex(), ent.EntityMods.InfoBoothTopics)
        end
    end

    -- Save topics on remove
    function ENT:OnRemove()
        local topics = self:GetNetVar("topics")
        if istable(topics) then
            ix.data.Set("info_booth_" .. self:EntIndex(), topics)
        end
    end

    properties.Add("ix_info_booth_edit", {
        Receive = function(self, len, ply)
            local ent = net.ReadEntity()
            if not IsValid(ent) or ent:GetClass() ~= "ix_info_booth" then return end
            if not ply:IsUA() then return end

            net.Start("ixInfoBooth_OpenEditor")
                net.WriteEntity(ent)
                net.WriteTable(PLUGIN:GetEntityTopics(ent))
            net.Send(ply)
        end
    })

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
-- Client-side drawing and context menu
if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local basePos = self:GetPos()
            + self:GetUp() * 70      -- height above entity
            + self:GetForward() * 10 -- forward offset

        local spinSpeed = 30 -- degrees per second
        local yaw = CurTime() * spinSpeed % 360

        -- First side
        local ang1 = Angle(0, yaw, 90)
        cam.Start3D2D(basePos, ang1, 0.1)
            draw.SimpleTextOutlined(
                "Information Booth",
                "DermaLarge",
                0, 0,
                Color(255, 255, 255),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                1, Color(0, 0, 0)
            )
        cam.End3D2D()

        -- Opposite side (rotate 180° around vertical axis)
        local ang2 = Angle(0, yaw + 180, 90)
        cam.Start3D2D(basePos, ang2, 0.1)
            draw.SimpleTextOutlined(
                "Information Booth",
                "DermaLarge",
                0, 0,
                Color(255, 255, 255),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                1, Color(0, 0, 0)
            )
        cam.End3D2D()
    end



    properties.Add("ix_info_booth_edit", {
        MenuLabel = "Edit Booth",
        Order = 1000,
        MenuIcon = "icon16/application_edit.png",

        Filter = function(self, ent, ply)
            return IsValid(ent) and ent:GetClass() == "ix_info_booth" and IsValid(ply) and ply:IsUA()
        end,

        Action = function(self, ent)
            self:MsgStart()
                net.WriteEntity(ent)
            self:MsgEnd()
        end
    })
end
