-- Gewehr 98 Trench
BLUEPRINT.name = "Gewehr 98 Trench"
BLUEPRINT.description = "Craft a Gewehr 98 Trench variant."
BLUEPRINT.model = "models/weapons/w_verdun_g98_trenchmag.mdl"
BLUEPRINT.category = "FA - Rifles"
BLUEPRINT.requirements = {
    ["ore_steelingot"] = 2,
    ["ore_copperingot"] = 2,
    ["gunstock"] = 3,
    ["shortreciever"] = 2,
    ["shortbarrel"] = 2,
}
BLUEPRINT.results = {
    ["tfa_gwsr_gewehr_98_trench"] = 1
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
