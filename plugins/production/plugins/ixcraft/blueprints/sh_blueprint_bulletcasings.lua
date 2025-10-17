
BLUEPRINT.name = "Bullet Casings"
BLUEPRINT.description = "Craft Bullet Casings."
BLUEPRINT.model = "models/weapons/shell.mdl"
BLUEPRINT.category = "Firearms - Parts"
BLUEPRINT.requirements = {
	["ore_copperingot"] = 2,
	["ore_ironingot"] = 1
}
BLUEPRINT.results = {
	["bulletcasing"] = {["min"] = 10, ["max"] = 20}
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