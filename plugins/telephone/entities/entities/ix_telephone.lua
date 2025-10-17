-- entities/entities/ix_telephone.lua
local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Telephone"
ENT.Author = "Dzhey Kashta"
ENT.Category = "IX: Communications"
ENT.Spawnable = true
ENT.AdminOnly = true

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/par_rotary_phone_01/par_rotary_phone_01.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(true)
        end

        self:SetUseType(SIMPLE_USE)
        self.currentUser = nil

        if not self.number or not PLUGIN:IsValidTelephoneNumber(self.number) then
            self.number = PLUGIN:GenerateTelephoneNumber()
        end

        PLUGIN:RegisterTelephone(self.number, self)

        if not self.fromDatabase then
            PLUGIN:SaveTelephone(self)
        end
    end

    function ENT:OnPhysgunFreeze(ply, phys)
        if self.number then
            PLUGIN:SaveTelephone(self)
        end
        return true
    end

    function ENT:Use(ply)
        if IsValid(self.currentUser) and self.currentUser ~= ply then
            ply:ChatPrint("This phone is currently in use.")
            return
        end

        if not IsValid(self.currentUser) then
            self.currentUser = ply
            ply.ixUsingPhone = self
        end

        if not self.number or not PLUGIN.telephones[self.number] then
            PLUGIN:RegisterTelephone(self.number, self)
        end

        local state = PLUGIN.callState and PLUGIN.callState[self.number]
        if state and not state.isActive then
            net.Start("ixTelephone_OpenPanel")
                net.WriteString(state.incomingFrom)
                net.WriteBool(true)
            net.Send(ply)
        else
            net.Start("ixTelephone_OpenPanel")
                net.WriteString(self.number)
                net.WriteBool(false)
            net.Send(ply)
        end
    end

    function ENT:SetEmergencyNumber(number)
        if not PLUGIN.emergencyNumbers[number] then return end

        for num, ent in pairs(PLUGIN.telephones) do
            if num == number and IsValid(ent) and ent ~= self then
                if ent.number and PLUGIN.telephones[ent.number] == ent then
                    PLUGIN.telephones[ent.number] = nil
                end
                ent.number = PLUGIN:GenerateTelephoneNumber()
                PLUGIN:RegisterTelephone(ent.number, ent)
                PLUGIN:SaveTelephone(ent)
            end
        end

        if self.number and PLUGIN.telephones[self.number] == self then
            PLUGIN.telephones[self.number] = nil
        end

        self.number = number
        PLUGIN:RegisterTelephone(self.number, self)
        PLUGIN:SaveTelephone(self)

        self:EmitSound("buttons/button3.wav")
    end

    function ENT:OnRemove()
        if IsValid(self.currentUser) then
            self.currentUser.ixUsingPhone = nil
            self.currentUser = nil
        end

        if self.number and PLUGIN.telephones[self.number] == self then
            PLUGIN.telephones[self.number] = nil
        end

        if self._permanentDelete then
            PLUGIN:DeleteTelephone(self)
        end
    end

    function ENT:SetPersistent(persist)
        return
    end

    function ENT:CanTool(ply, trace, tool)
        if not ply:IsUA() then
            if SERVER then
                ply:ChatPrint("You do not have permission to use tools on this entity.")
            end
            return false
        end
        return true
    end

    function ENT:SpawnFunction(ply, tr, ClassName)
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
    if properties and properties.List and properties.List["persist"] then
        local oldFilter = properties.List["persist"].Filter
        properties.List["persist"].Filter = function(self, ent, ply, ...)
            if IsValid(ent) and ent:GetClass() == "ix_telephone" then
                return false
            end
            if oldFilter then
                return oldFilter(self, ent, ply, ...)
            end
            return true
        end
    end

    if properties and istable(PLUGIN.emergencyNumbers) then
        for num, service in pairs(PLUGIN.emergencyNumbers) do
            local telNumber = tostring(num)
            local serviceLabel = tostring(service or num)

            properties.Add("ixTelephone_" .. telNumber, {
                MenuLabel = "Set as " .. serviceLabel .. " phone",
                Order = 1000,
                MenuIcon = "icon16/telephone.png",

                Filter = function(self, ent, ply)
                    return ent:GetClass() == "ix_telephone" and ply:IsUA()
                end,

                Action = function(self, ent)
                    if CLIENT then
                        net.Start("ixTelephone_SetEmergency")
                            net.WriteEntity(ent)
                            net.WriteString(telNumber)
                        net.SendToServer()
                    else
                        ent:SetEmergencyNumber(telNumber)
                    end
                end
            })
        end
    end

    local oldRemove = properties.List and properties.List["remove"]
    if oldRemove then
        properties.Add("ixTelephone_remove", {
            MenuLabel = oldRemove.MenuLabel,
            Order = oldRemove.Order,
            MenuIcon = oldRemove.MenuIcon,

            Filter = function(self, ent, ply, ...)
                return oldRemove.Filter(self, ent, ply, ...) and ent:GetClass() == "ix_telephone"
            end,

            Action = function(self, ent)
                net.Start("ixTelephone_PermanentRemove")
                    net.WriteEntity(ent)
                net.SendToServer()
            end
        })
    end
end

if SERVER then
    util.AddNetworkString("ixTelephone_PermanentRemove")
    net.Receive("ixTelephone_PermanentRemove", function(_, ply)
        local ent = net.ReadEntity()
        if IsValid(ent) and ent:GetClass() == "ix_telephone" and ply:IsUA() then
            ent._permanentDelete = true
            ent:Remove()
        end
    end)
end
