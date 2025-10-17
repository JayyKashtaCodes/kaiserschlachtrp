-- Kar88
BLUEPRINT.name = "Kar88"
BLUEPRINT.description = "Craft a Kar88 carbine."
BLUEPRINT.model = "models/weapons/w_kar98az_remake.mdl"
BLUEPRINT.category = "FA - Rifles"
BLUEPRINT.requirements = {
    ["ore_copperingot"] = 2,
    ["ore_steelingot"] = 2,
    ["gunstock"] = 1,
    ["longreciever"] = 1,
    ["longbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsr_kar88"] = 1
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
