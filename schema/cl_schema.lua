
-------------------------------------------
--[[ Disable Observer by Default ]]--
ix.option.Set( "observerTeleportBack", false )
--[[ END ]]--
-------------------------------------------
--[[ Third Person ]]--
function ix.util.DrawTexture(material, color, x, y, w, h)
    surface.SetDrawColor(color or color_white)
    surface.SetMaterial(ix.util.GetMaterial(material))
    surface.DrawTexturedRect(x, y, w, h)
end

function Schema:IsViewingCamera()
    return LocalPlayer():GetNetVar("ixCurrentCamera", false)
end
--[[ END ]]--
-------------------------------------------
--[[ Player Footsteps ]]--
--[[
function Schema:PlayerFootstep(client, position, foot, soundName, volume)
	return true
end
]]--
--[[ END ]]--
-------------------------------------------