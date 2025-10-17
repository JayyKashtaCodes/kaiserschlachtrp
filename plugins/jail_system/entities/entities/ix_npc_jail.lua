local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Jail NPC"
ENT.Author = "Dzhey Kashta"
ENT.Category = "IX: Jail System"
ENT.Spawnable = true
ENT.AdminOnly = true

if SERVER then

    function ENT:Initialize()
        self:SetModel("models/ksr/policesr/nco_06.mdl")
        self:SetUseType(SIMPLE_USE)
        self:SetMoveType(MOVETYPE_NONE)
        self:DrawShadow(true)
        self:InitPhysObj()

        timer.Simple(0, function()
            if IsValid(self) then
                self:SetAnim()
            end
        end)
    end

    -- Static physics box
    function ENT:InitPhysObj()
        local mins, maxs = self:GetAxisAlignedBoundingBox()
        local created = self:PhysicsInitBox(mins, maxs)
        if created then
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
                phys:Sleep()
            end
        end
    end

    function ENT:GetAxisAlignedBoundingBox()
        local mins, maxs = self:GetModelBounds()
        mins = Vector(mins.x, mins.y, 0)
        mins, maxs = self:GetRotatedAABB(mins, maxs)
        return mins, maxs
    end

    -- Idle animation selection
    function ENT:SetAnim()
        local preferred = { "idle_all_01", "idle_all", "idle_subtle", "pose_standing", "idle" }
        for _, name in ipairs(preferred) do
            local seq = self:LookupSequence(name)
            if seq and seq > 0 then
                self:ResetSequence(seq)
                return
            end
        end

        local sequences = self:GetSequenceList()
        if #sequences > 0 then
            local fallbackIndex = (#sequences > 1) and 2 or 1
            self:ResetSequence(fallbackIndex)
        end
    end

    function ENT:AcceptInput(name, activator, caller)
        if name == "Use" and IsValid(caller) and PLUGIN:IsAuthorizedJailer(caller) then
            net.Start("OpenJailMenu")
            net.Send(caller)
        else
            caller:ChatPrint("You are not authorized to use this.")
        end
    end

    function ENT:Think()
        self:NextThink(CurTime())
        return true
    end

    -- Restrict tool usage
    function ENT:CanTool(ply, trace, tool)
        if not ply:IsUA() then
            ply:ChatPrint("You do not have permission to use tools on this entity.")
            return false
        end
        return true
    end

    -- Restrict spawn from spawn menu
    function ENT:SpawnFunction(ply, tr, ClassName)
        if not ply:IsUA() then
            ply:ChatPrint("You do not have permission to spawn this entity.")
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

if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local ang = LocalPlayer():EyeAngles()
        local pos = self:GetPos() + Vector(0, 0, 85)

        cam.Start3D2D(pos, Angle(0, ang.y - 90, 90), 0.25)
            draw.SimpleText("Sentence Player", "DermaLarge", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end

    net.Receive("OpenJailMenu", function()
        vgui.Create("JailMenu")
    end)
end
