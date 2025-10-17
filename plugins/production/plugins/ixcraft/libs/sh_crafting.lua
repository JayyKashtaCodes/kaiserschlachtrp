
local PLUGIN = PLUGIN

PLUGIN.craft = PLUGIN.craft or {}
PLUGIN.craft.blueprints = PLUGIN.craft.blueprints or {}
PLUGIN.craft.stations = PLUGIN.craft.stations or {}

function PLUGIN.craft.LoadFromDir(directory, pathType)
	for _, v in ipairs(file.Find(directory.."/sh_*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		if (pathType == "blueprint") then
			BLUEPRINT = setmetatable({
				uniqueID = niceName
			}, PLUGIN.meta.blueprint)
				ix.util.Include(directory.."/"..v, "shared")

				PLUGIN.craft.blueprints[niceName] = BLUEPRINT
			BLUEPRINT = nil
		elseif (pathType == "station") then
			STATION = setmetatable({
				uniqueID = niceName
			}, PLUGIN.meta.station)
				ix.util.Include(directory.."/"..v, "shared")

				if (!scripted_ents.Get("ix_station_"..niceName)) then
					local STATION_ENT = scripted_ents.Get("ix_station")
					STATION_ENT.PrintName = STATION.name
					STATION_ENT.uniqueID = niceName
					STATION_ENT.Spawnable = true
					STATION_ENT.AdminOnly = true
					scripted_ents.Register(STATION_ENT, "ix_station_"..niceName)
				end

				PLUGIN.craft.stations[niceName] = STATION
			STATION = nil
		end
	end
end

function PLUGIN.craft.GetCategories(client)
	local categories = {}

	for k, v in pairs(PLUGIN.craft.blueprints) do
		local category = v.category or "Crafting"

		if (v:OnCanSee(client)) then
			if (!categories[category]) then
				categories[category] = {}
			end

			table.insert(categories[category], k)
		end
	end

	return categories
end

function PLUGIN.craft.FindByName(blueprint)
	blueprint = blueprint:lower()
	local uniqueID

	for k, v in pairs(PLUGIN.craft.blueprints) do
		if (blueprint:find(v.name:lower())) then
			uniqueID = k

			break
		end
	end

	return uniqueID
end

if (SERVER) then
	util.AddNetworkString("ixCraftBlueprint")
	util.AddNetworkString("ixCraftRefresh")

	function PLUGIN.craft.CraftBlueprint(client, uniqueID)
		local blueprintTable = PLUGIN.craft.blueprints[uniqueID]

		if (blueprintTable) then
			local bCanCraft, failString, c, d, e, f = blueprintTable:OnCanCraft(client)

			if (!bCanCraft) then
				if (failString) then
					if (failString:sub(1, 1) == "@") then
						failString = L(failString:sub(2), client, c, d, e, f)
					end

					client:Notify(failString)
				end

				return false
			end

			local success, craftString, c, d, e, f = blueprintTable:OnCraft(client)

			if (craftString) then
				if (craftString:sub(1, 1) == "@") then
					craftString = L(craftString:sub(2), client, c, d, e, f)
				end

				client:Notify(craftString)
			end

			return success
		end
	end

	net.Receive("ixCraftBlueprint", function(length, client)
		PLUGIN.craft.CraftBlueprint(client, net.ReadString())

		timer.Simple(0.2, function()
			net.Start("ixCraftRefresh")
			net.Send(client)
		end)
	end)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.string
	COMMAND.description = "@cmdCraftBlueprint"

	function COMMAND:OnRun(client, blueprint)
		PLUGIN.craft.CraftBlueprint(client, PLUGIN.craft.FindByName(blueprint))
	end

	ix.command.Add("CraftBlueprint", COMMAND)
end

hook.Add("DoPluginIncludes", "ixCrafting", function(path, pluginTable)
	if (!PLUGIN.paths) then
		PLUGIN.paths = {}
	end

	table.insert(PLUGIN.paths, path)
end)
