FACTION.name = "Bürger"
FACTION.description = "Citizens of Berlin."
FACTION.color = Color(141, 57, 34)
FACTION.isDefault = true

function FACTION:OnTransferred(character)
    character:SetClass(CLASS_CITIZEN)
end

FACTION.models = {
    "models/1910rp/civil_01.mdl",
    "models/1910rp/civil_02.mdl",
    "models/1910rp/civil_03.mdl",
    "models/1910rp/civil_04.mdl",
    "models/1910rp/civil_05.mdl",
    "models/1910rp/civil_06.mdl"
}

FACTION_CITIZEN = FACTION.index
