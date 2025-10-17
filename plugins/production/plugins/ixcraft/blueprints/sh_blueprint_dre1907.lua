-- Dreyse Model 1907
BLUEPRINT.name = "Dreyse 1907"
BLUEPRINT.description = "Craft a Dreyse Model 1907 pocket pistol."
BLUEPRINT.model = "models/weapons/w_isonzo_dreyse1907.mdl"
BLUEPRINT.category = "Firearms"
BLUEPRINT.requirements = {
    ["ore_copperingot"] = 2,
    ["ore_steelingot"] = 3,
    ["shortreciever"] = 1,
    ["shortbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsh_dreyse_1907"] = 1
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
