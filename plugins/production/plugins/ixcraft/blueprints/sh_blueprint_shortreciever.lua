
BLUEPRINT.name = "Short Reciever"
BLUEPRINT.description = "Craft a Short Reciever."
BLUEPRINT.model = "models/props_c17/canisterchunk01m.mdl"
BLUEPRINT.category = "Firearms - Parts"
BLUEPRINT.requirements = {
	["ore_copperingot"] = 1,
	["ore_steelingot"] = 2
}
BLUEPRINT.results = {
	["shortreciever"] = {["min"] = 1, ["max"] = 2}
}
BLUEPRINT.tools = {
}

BLUEPRINT:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "You need to be near a workbench."
end)

--BLUEPRINT.flag = "W"