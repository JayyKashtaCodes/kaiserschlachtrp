FACTION.name = "Staff"
FACTION.description = "Staff."
FACTION.color = Color(137, 207, 240)
FACTION.isGloballyRecognized = true
FACTION.godModeEnabled = true
FACTION.includeNeeds = false -- Remove needs for this faction

function FACTION:OnTransferred(character)
    character:SetClass(CLASS_STAFF)
end

FACTION_STAFF = FACTION.index