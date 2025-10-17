
BLUEPRINT.name = "Short Barrel"
BLUEPRINT.description = "Craft a Short Barrel."
BLUEPRINT.model = "models/props_c17/TrapPropeller_Lever.mdl"
BLUEPRINT.category = "Firearms - Parts"
BLUEPRINT.requirements = {
	["ore_copperingot"] = 1,
	["ore_steelingot"] = 2
}
BLUEPRINT.results = {
	["shortbarrel"] = {["min"] = 1, ["max"] = 2}
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