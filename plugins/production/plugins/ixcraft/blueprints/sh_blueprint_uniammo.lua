
BLUEPRINT.name = "Universal Ammo Box"
BLUEPRINT.description = "Craft a Universal Ammo Pack."
BLUEPRINT.model = "models/Items/BoxMRounds.mdl"
BLUEPRINT.category = "Firearms"
BLUEPRINT.requirements = {
	["nitrocellulose"] = 5,
	["bulletcasing"] = 10
}
BLUEPRINT.results = {
	["genammo"] = {["min"] = 1, ["max"] = 2},
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