CLASS.name = "Kriminalpolizeiamt"
CLASS.faction = FACTION_INNERN
CLASS.weapons = {
    "ix_baton",
    "ix_whistle"
}


function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
    for _, weapon in ipairs(self.weapons) do
        client:Give(weapon)
    end
end

function CLASS:OnSpawn(client)
    for _, weapon in ipairs(self.weapons) do
        if not client:HasWeapon(weapon) then
            client:Give(weapon)
        end
    end
end

function CLASS:OnLeave(client)
    for _, weapon in ipairs(self.weapons) do
        if client:HasWeapon(weapon) then
            client:StripWeapon(weapon)
        end
    end
end

CLASS_KPA = CLASS.index