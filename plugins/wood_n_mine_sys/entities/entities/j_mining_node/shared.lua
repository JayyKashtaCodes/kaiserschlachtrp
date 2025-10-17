ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Nodes"
ENT.Category = "Setorian Mining System"

ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "NodeName" )
	-- self:NetworkVar( "Int", 0, "NodeHP" )

end
if SERVER then
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