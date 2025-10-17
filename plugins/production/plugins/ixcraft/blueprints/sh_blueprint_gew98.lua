-- Gewehr 98
BLUEPRINT.name = "Gewehr 98"
BLUEPRINT.description = "Craft a Gewehr 98."
BLUEPRINT.model = "models/weapons/w_verdun_g98.mdl"
BLUEPRINT.category = "Firearms - Rifles"
BLUEPRINT.requirements = {
    ["ore_steelingot"] = 2,
    ["ore_copperingot"] = 2,
    ["gunstock"] = 2,
    ["longreciever"] = 1,
    ["longbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsr_gewehr_98"] = 1
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
