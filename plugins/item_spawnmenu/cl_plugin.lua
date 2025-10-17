spawnmenu.AddContentType("item", function(container, obj)
	if !obj.name then return end
	if !obj.uniqueid then return end
	if !obj.model then return end
	if !obj.skin then return end

	local icon = vgui.Create("ixSpawnmenuItemIcon", container)
	icon:SetName(obj.name)
    icon:SetModel(obj.model)
    icon:SetSkinID(obj.skin)
    icon:SetUniqueID(obj.uniqueid)
	icon:SetMaterial(obj.material)
    icon:SetColor(obj.color or color_white)

	if IsValid(container) then
		container:Add(icon)
	end

	return icon
end)

spawnmenu.AddCreationTab("Items", function()
	local pnl = vgui.Create("SpawnmenuContentPanel")
	pnl:EnableSearch("items", "PopulateItems")
	pnl:CallPopulateHook("PopulateItems")
	return pnl
end, "icon16/script_key.png")

search.AddProvider(function(str)
    local items = ix.item.list
    local results = {}

    for k, v in pairs(items) do
        if string.find(string.lower(v.name), string.lower(str)) or string.find(v.uniqueID, str:lower()) then
            local new = {
                text = v.uniqueID, -- not needed lol
                func = function() -- not needed lol
                    net.Start("ixItemSpawnmenuSpawn")
                        net.WriteString(v.uniqueID)
                    net.SendToServer()
                end,
                icon = spawnmenu.CreateContentIcon("item", nil, {
					name = v.name or v.uniqueID,
					uniqueid = v.uniqueID,
					model = v.model,
					skin = v.skin or 0
				}),
                words = {v} -- not needed lol
            }

            table.insert(results, new)
        end
    end

    return results
end, "items")

RunConsoleCommand("spawnmenu_reload")