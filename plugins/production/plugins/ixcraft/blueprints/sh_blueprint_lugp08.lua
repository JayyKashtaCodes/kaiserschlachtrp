-- Luger P08
BLUEPRINT.name = "Luger P08"
BLUEPRINT.description = "Craft a Luger P08."
BLUEPRINT.model = "models/weapons/tfa_doi/w_doi_lugerp08.mdl"
BLUEPRINT.category = "Firearms"
BLUEPRINT.requirements = {
    ["ore_steelingot"] = 2,
    ["ore_copperingot"] = 1,
    ["gunstock"] = 1,
    ["shortreciever"] = 1,
    ["shortbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsh_luger"] = 1
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
