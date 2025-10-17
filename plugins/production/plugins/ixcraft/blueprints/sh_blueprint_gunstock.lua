
BLUEPRINT.name = "Gun Stock"
BLUEPRINT.description = "Craft a Gun Stock."
BLUEPRINT.model = "models/Gibs/wood_gib01e.mdl"
BLUEPRINT.category = "Firearms - Parts"
BLUEPRINT.requirements = {
	["wood"] = 2,
	["ore_ironingot"] = 3
}
BLUEPRINT.results = {
	["gunstock"] = {["min"] = 1, ["max"] = 2}
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