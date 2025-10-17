local Schema = Schema
-------------------------------------------
--[[ Weapon Giver ]]--
function Schema:GiveWeapons(ply, weapons)
    for i, weapon in ipairs(weapons) do
        ply:Give(weapon)
    end
end
--[[ END ]]--
-------------------------------------------
--[[ Zoom Remove ]]--
function Schema:PlayerSpawn(a)
	a:SetCanZoom( false )
end
--[[ END ]]--
-------------------------------------------
--[[ Clear Ent on Shutdown ]]--
local clear_ents = {
	["ix_item"] = true,
	["ix_money"] = true
}

function Schema:ShutDown()
	for _, v in ipairs(ents.GetAll()) do
		if (clear_ents[v:GetClass()]) then
			v:Remove()
		end
	end
end
--[[ END ]]--
-------------------------------------------
--[[ Anti-Bhop ]]--
function Schema:OnPlayerHitGround( pl )
    local vel = pl:GetVelocity()
    pl:SetVelocity(Vector( - (vel.x * 1), - (vel.y*1), 0))
end
--[[ END ]]--
-------------------------------------------
--[[ Positioning ]]--
function Schema:PlayerLoadedCharacter( ply, curChar, prevChar )
	timer.Simple(0, function()
		if (IsValid(ply)) then
			local position = curChar:GetData("pos")

			if (position) then
				if (position[3] and position[3]:lower() == game.GetMap():lower()) then
					ply:SetPos(position[1].x and position[1] or ply:GetPos())
					ply:SetEyeAngles(position[2].p and position[2] or Angle(0, 0, 0))
				end

				curChar:SetData("pos", nil)
			end
		end
	end)
end
--[[ END ]]--
-------------------------------------------
--[[ Logs ]]--
ix.log.AddType("mapEntRemoved", function(client, index, model)
	return string.format("%s has removed map entity #%d (%s).", client:Name(), index, model)
end)
--[[ END ]]--
-------------------------------------------