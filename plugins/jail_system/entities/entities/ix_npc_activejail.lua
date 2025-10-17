local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Active Jail Sentences NPC"
ENT.Author = "Dzhey Kashta"
ENT.Category = "IX: Jail System"
ENT.Spawnable = true
ENT.AdminOnly = true

if SERVER then

    function ENT:Initialize()
        self:SetModel("models/ksr/policesr/nco_05.mdl")
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

    local lastUse = {}

    function ENT:AcceptInput(name, activator, caller)
        if name ~= "Use" or not IsValid(caller) then return end

        if not PLUGIN:IsAuthorizedJailer(caller) then
            caller:ChatPrint("You are not authorized to use this.")
            return
        end

        local steamID = caller:SteamID()
        local now = CurTime()

        if lastUse[steamID] and now - lastUse[steamID] < 1 then return end
        lastUse[steamID] = now

        net.Start("OpenActiveJailMenu")
        net.Send(caller)

        timer.Simple(0.1, function()
            if IsValid(caller) then
                net.Start("RequestActiveJails")
                net.Send(caller)
            end
        end)
    end

    net.Receive("RequestActiveJails", function(_, ply)
        if not IsValid(ply) or not PLUGIN:IsAuthorizedJailer(ply) then return end

        local jailed = {}

        for _, target in ipairs(player.GetAll()) do
            local jailTime = target:GetNetVar("JailTime", 0)
            local jailReason = target:GetNetVar("JailReason", "Unknown")
            local jailJudge = target:GetNetVar("JailJudge", "Unknown")
            local jailStart = target:GetNetVar("JailStart", 0)

            if jailTime > 0 then
                local remaining = math.max(0, jailStart + jailTime - os.time())

                table.insert(jailed, {
                    name = target:Nick(),
                    steamID = target:SteamID(),
                    reason = jailReason,
                    judge = jailJudge,
                    startTime = jailStart,
                    jailTime = jailTime,
                    remaining = remaining
                })
            end
        end

        net.Start("SendActiveJails")
            net.WriteUInt(#jailed, 12)
            for _, data in ipairs(jailed) do
                net.WriteString(data.steamID)
                net.WriteString(data.name)
                net.WriteString(data.reason)
                net.WriteString(data.judge)
                net.WriteUInt(data.startTime, 32)
                net.WriteUInt(data.jailTime, 32)
                net.WriteUInt(data.remaining, 32)
            end
        net.Send(ply)
    end)

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
            draw.SimpleText("View Active Jail Sentences", "DermaLarge", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end

    local activeJailPanel = nil

    net.Receive("OpenActiveJailMenu", function()
        if IsValid(activeJailPanel) then
            activeJailPanel:MakePopup()
            activeJailPanel:Center()
            return
        end

        activeJailPanel = vgui.Create("ActiveJailMenu")
        activeJailPanel:MakePopup()
        activeJailPanel:Center()
    end)

    net.Receive("SendActiveJails", function()
        if not IsValid(activeJailPanel) or not IsValid(activeJailPanel.jailList) then return end

        local list = activeJailPanel.jailList
        list:Clear()

        local count = net.ReadUInt(12)
        if count == 0 then
            local line = list:AddLine("No active jail sentences found.")
            line:SetSelectable(false)
            return
        end

        for i = 1, count do
            local steamID   = net.ReadString()
            local name      = net.ReadString()
            local reason    = net.ReadString()
            local judge     = net.ReadString()
            local startTime = net.ReadUInt(32)
            local jailTime  = net.ReadUInt(32)
            local remaining = net.ReadUInt(32)

            local timeFormatted = string.ToMinutesSeconds(remaining)
            local line = list:AddLine(name, timeFormatted, reason, judge)
            line.steamID = steamID
        end
    end)
end
