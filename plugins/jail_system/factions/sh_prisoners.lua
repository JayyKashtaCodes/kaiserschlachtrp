FACTION.name = "Strafgefangene"
FACTION.description = "Prisoners of Berlin."
FACTION.color = Color(0, 0, 0)

function FACTION:OnTransferred(character)
    character:SetClass(CLASS_PRISONER)
end

FACTION_PRISONER = FACTION.index