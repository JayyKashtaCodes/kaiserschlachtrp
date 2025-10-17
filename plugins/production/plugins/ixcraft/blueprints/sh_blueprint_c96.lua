-- Mauser C96
BLUEPRINT.name = "Mauser C96"
BLUEPRINT.description = "Craft a Mauser C96 \"Broomhandle\" pistol."
BLUEPRINT.model = "models/weapons/tfa_doi/w_doi_c96v2.mdl"
BLUEPRINT.category = "Firearms"
BLUEPRINT.requirements = {
    ["ore_steelingot"] = 3,
    ["gunstock"] = 1,
    ["longreciever"] = 1,
    ["shortbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsh_c96"] = 1
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
