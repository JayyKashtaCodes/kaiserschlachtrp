FACTION.name = "Ringvereine"
FACTION.description = "Mafia."
FACTION.color = Color(141, 57, 34)

function FACTION:OnTransferred(character)
    character:SetClass(CLASS_MAFIA)
end

FACTION_MAFIA = FACTION.index
