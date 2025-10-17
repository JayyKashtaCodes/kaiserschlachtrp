-- Mauser 1914
BLUEPRINT.name = "Mauser 1914"
BLUEPRINT.description = "Craft a Mauser 1914."
BLUEPRINT.model = "models/weapons/w_ww1_mauser1914_remake.mdl"
BLUEPRINT.category = "Firearms"
BLUEPRINT.requirements = {
    ["ore_copperingot"] = 3,
    ["ore_steelingot"] = 1,
    ["gunstock"] = 1,
    ["shortreciever"] = 1,
    ["shortbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsh_mauser_1914"] = 1
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
