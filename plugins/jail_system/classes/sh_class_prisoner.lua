CLASS.name = "Strafgefangene"
CLASS.faction = FACTION_PRISONER

function CLASS:CanSwitchTo(client)
	return false
end

CLASS_PRISONER = CLASS.index