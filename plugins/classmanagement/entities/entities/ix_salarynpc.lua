local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Pay Clerk"
ENT.Author = "Dzhey Kashta"
ENT.Category = "IX: Payment"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.LookDistance = 300 -- units

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/1910rp/civil_04.mdl")
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

    function ENT:Use(ply)
        local char = ply:GetCharacter()
        if not char then return end

        local payoutCents = char:GetData("salaryBuffer", 0)

        if payoutCents > 0 then
            char:SetData("salaryBuffer", 0)
            char:GiveMoney(ix.currency.FromCents(payoutCents))
            ply:Notify("You've collected " ..
                ix.currency.Get(ix.currency.FromCents(payoutCents)))
        else
            ply:Notify("You have no pending salary to collect.")
        end
    end

    -- Head tracking
    function ENT:Think()
        local nearest
        local nearestDistSqr = self.LookDistance * self.LookDistance
        local myPos = self:GetPos()

        for _, ply in ipairs(player.GetAll()) do
            if ply:Alive() then
                local distSqr = myPos:DistToSqr(ply:GetPos())
                if distSqr < nearestDistSqr then
                    nearest = ply
                    nearestDistSqr = distSqr
                end
            end
        end

        local headBone = self:LookupBone("ValveBiped.Bip01_Head1")
        if headBone and IsValid(nearest) then
            local headPos = self:GetBonePosition(headBone)
            local targetPos = nearest:EyePos()
            local ang = (targetPos - headPos):Angle()

            -- Convert world angles to local bone angles
            local localAng = self:WorldToLocalAngles(ang)

            -- Apply only yaw/pitch adjustments
            self:ManipulateBoneAngles(headBone, Angle(localAng.p, localAng.y, 0))
        else
            -- Reset head if no target
            if headBone then
                self:ManipulateBoneAngles(headBone, Angle(0, 0, 0))
            end
        end

        self:NextThink(CurTime() + 0.05)
        return true
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

if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local pos = self:GetPos() + Vector(0, 0, 80)
        local ang = EyeAngles()
        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), -90)

        cam.Start3D2D(pos, ang, 0.075)
            draw.SimpleText("Salary Collection", "DermaLarge", 0, 0, Color(255, 215, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
