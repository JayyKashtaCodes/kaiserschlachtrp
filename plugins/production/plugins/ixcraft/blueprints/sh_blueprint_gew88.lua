-- Gewehr 88
BLUEPRINT.name = "Gewehr 88"
BLUEPRINT.description = "Craft a Gewehr 88."
BLUEPRINT.model = "models/weapons/w_verdun_g88.mdl"
BLUEPRINT.category = "Firearms - Rifles"
BLUEPRINT.requirements = {
    ["ore_steelingot"] = 2,
    ["gunstock"] = 1,
    ["longreciever"] = 1,
    ["longbarrel"] = 1,
}
BLUEPRINT.results = {
    ["tfa_gwsr_gewehr_88"] = 1
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
