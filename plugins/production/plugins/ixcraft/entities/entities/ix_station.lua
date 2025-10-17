
local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Station"
ENT.Category = "Helix"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "StationID")

	if (SERVER) then
		self:NetworkVarNotify("StationID", self.OnVarChanged)
	end
end

if (SERVER) then
	function ENT:Initialize()
		if (!self.uniqueID) then
			self:Remove()

			return
		end

		self:SetStationID(self.uniqueID)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end
	end

	function ENT:OnVarChanged(name, oldID, newID)
		local stationTable = PLUGIN.craft.stations[newID]

		if (stationTable) then
			self:SetModel(stationTable:GetModel())
		end
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_PVS
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
else
	ENT.PopulateEntityInfo = true

	function ENT:OnPopulateEntityInfo(tooltip)
		local stationTable = self:GetStationTable()

		if (stationTable) then
			PLUGIN:PopulateStationTooltip(tooltip, stationTable)
		end
	end

	function ENT:Draw()
		self:DrawModel()
	end
end

function ENT:GetStationTable()
	return PLUGIN.craft.stations[self:GetStationID()]
end
