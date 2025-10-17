
BLUEPRINT.name = "Long Barrel"
BLUEPRINT.description = "Craft a Long Barrel."
BLUEPRINT.model = "models/crossbow_bolt.mdl"
BLUEPRINT.category = "Firearms - Parts"
BLUEPRINT.requirements = {
	["ore_copperingot"] = 2,
	["ore_steelingot"] = 4
}
BLUEPRINT.results = {
	["longbarrel"] = {["min"] = 1, ["max"] = 2}
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