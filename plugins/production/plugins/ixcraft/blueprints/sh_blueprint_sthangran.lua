
BLUEPRINT.name = "Stielhandgranate"
BLUEPRINT.description = "Craft a Stielhandgranate."
BLUEPRINT.model = "models/weapons/w_stickgrenade_hgr39.mdl"
BLUEPRINT.category = "Firearms"

BLUEPRINT.requirements = {
	["ore_steelingot"] = 3,
	["nitrocellulose"] = 2
}

BLUEPRINT.results = {
	["tfa_gwswe_stielhandgranate"] = 1
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