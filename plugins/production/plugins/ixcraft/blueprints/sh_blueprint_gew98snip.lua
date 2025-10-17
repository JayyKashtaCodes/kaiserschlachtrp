-- Gewehr 98 Sniper
BLUEPRINT.name = "Gewehr 98 Sniper"
BLUEPRINT.description = "Craft a scoped Gewehr 98."
BLUEPRINT.model = "models/weapons/w_verdun_g98.mdl"
BLUEPRINT.category = "Firearms - Rifles"
BLUEPRINT.requirements = {
    ["ore_steelingot"] = 3,
    ["ore_copperingot"] = 2,
    ["gunstock"] = 2,
    ["longreciever"] = 1,
    ["longbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsr_gewehr_98_sniper"] = 1
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
