ITEM.name = "Lantern Oil"
ITEM.model = "models/props_junk/glassjug01.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A container of oil for lanterns."
ITEM.category = "Supplies"

ITEM.maxVolume = 250

function ITEM:OnInstanced()
    if self:GetData("volume", nil) == nil then
        self:SetData("volume", self.maxVolume)
    end
end

ITEM.functions.Refuel = {
    name = "Refuel Lantern",
    tip = "useTip",
    icon = "icon16/add.png",
    OnRun = function(item)
        local char = item.player:GetCharacter()
        local inv = char and char:GetInventory()
        local lantern = inv and inv:HasItem("lantern")

        if not lantern then
            item.player:Notify("You don't have a lantern to refuel.")
            return false
        end

        local lanternOil = lantern:GetData("oil", 0)
        local space = lantern.maxOil - lanternOil

        if space <= 0 then
            item.player:Notify("Your lantern is already full.")
            return false
        end

        local bottleOil = item:GetData("volume", 0)
        local transfer = math.min(bottleOil, space)

        lantern:AddOil(transfer)
        item:SetData("volume", bottleOil - transfer)

        item.player:Notify(string.format(
            "Transferred %d mL of oil. Lantern: %dmL / %dmL.",
            transfer, lantern:GetData("oil"), lantern.maxOil
        ))

        if item:GetData("volume") <= 0 then
            item.player:Notify("The oil container is now empty.")
            return true
        end

        return false
    end
}
