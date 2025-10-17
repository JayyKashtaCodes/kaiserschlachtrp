ITEM.name = "Universal Ammo Box"
ITEM.description = "Refills all your weapons with their respective ammo types."
ITEM.model = "models/hts/ww2ns/props/ger/ger_crate_ammo_box_sm_02.mdl"
ITEM.category = "Ammo"
ITEM.bDropOnDeath = true
ITEM.width = 1
ITEM.height = 1
ITEM.price = 5

ITEM.maxStack = 4;
ITEM.defaultStack = 1;

ITEM.functions.Use = {
    name = "Use",
    icon = "icon16/box.png",
    OnRun = function(item)
        local client = item.player
        local char = client:GetCharacter()
        if not char then return false end

        for _, weapon in ipairs(client:GetWeapons()) do
            if weapon.Base and string.find(weapon.Base, "tfa") then
                local ammoType = weapon:GetPrimaryAmmoType()
                if ammoType and ammoType ~= -1 then
                    local currentAmmo = client:GetAmmoCount(ammoType)
                    local maxAmmo = weapon.Primary and weapon.Primary.ClipSize and weapon.Primary.ClipSize * 3 or 90

                    if currentAmmo < maxAmmo then
                        client:GiveAmmo(maxAmmo - currentAmmo, ammoType, true)
                    end
                end
            end
        end

        client:EmitSound("items/ammo_pickup.wav")
        return true
    end
}
