-- Reichsrevolver M1879
BLUEPRINT.name = "Reichsrevolver M1879"
BLUEPRINT.description = "Craft a Reichsrevolver M1879."
BLUEPRINT.model = "models/weapons/w_reichsrevolver_verdun2.mdl"
BLUEPRINT.category = "Firearms"
BLUEPRINT.requirements = {
    ["ore_copperingot"] = 1,
    ["ore_steelingot"] = 1,
    ["shortreciever"] = 1,
    ["shortbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsh_reichsrevolver"] = 1
}
BLUEPRINT.tools = {}

BLUEPRINT:PostHook("OnCanCraft", function(recipeTable, client)
    for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            return true
        end
    end
    return false, "You need to be near a workbench."
end)
