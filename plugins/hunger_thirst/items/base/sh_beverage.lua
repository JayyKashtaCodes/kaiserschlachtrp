ITEM.name = "Beverage"
ITEM.description = "A generic beverage item."
ITEM.category = "Beverage"
ITEM.model = "models/props_junk/GlassBottle01a.mdl"
ITEM.useSound = "npc/barnacle/barnacle_gulp1.wav"
ITEM.thirst = 0
ITEM.drunkenness = 0
ITEM.hunger = 0
ITEM.portion = 4
ITEM.bDropOnDeath = true
ITEM.returnItems = {}

function ITEM:OnInstanced(invID, x, y, item)
    if item then
        item:SetData("remaining", item.portion)
    end
end

if CLIENT then
    function ITEM:PopulateTooltip(tooltip)
        local panel = tooltip:AddRowAfter("name", "remaining")
        panel:SetText("Remaining: " .. self:GetData("remaining", self.portion))
        panel:SizeToContents()

        -- Hunger
        local hungerRow = tooltip:AddRow("hunger")
        hungerRow:SetBackgroundColor(Color(75, 75, 75, 200))
        
        if self.hunger > 0 then
            hungerRow:SetText("Hunger: " .. string.format("+%.2f", self.hunger / self.portion))
            hungerRow:SetTextColor(Color(0, 255, 0, 255))
        elseif self.hunger < 0 then
            hungerRow:SetText("Hunger: " .. string.format("-%.2f", math.abs(self.hunger / self.portion)))
            hungerRow:SetTextColor(Color(255, 0, 0, 255))
        else
            hungerRow:SetText("Hunger: 0")
            hungerRow:SetTextColor(Color(255, 255, 255, 255))
        end
        hungerRow:SizeToContents()

        -- Thirst
        local thirstRow = tooltip:AddRow("thirst")
        thirstRow:SetBackgroundColor(Color(75, 75, 75, 200))
        
        if self.thirst > 0 then
            thirstRow:SetText("Thirst: " .. string.format("+%.2f", self.thirst / self.portion))
            thirstRow:SetTextColor(Color(0, 255, 0, 255))
        elseif self.thirst < 0 then
            thirstRow:SetText("Thirst: " .. string.format("-%.2f", math.abs(self.thirst / self.portion)))
            thirstRow:SetTextColor(Color(255, 0, 0, 255))
        else
            thirstRow:SetText("Thirst: 0")
            thirstRow:SetTextColor(Color(255, 255, 255, 255))
        end
        thirstRow:SizeToContents()

        -- Drunkenness
        local drunkennessRow = tooltip:AddRow("drunkenness")
        drunkennessRow:SetBackgroundColor(Color(75, 75, 75, 200))
        
        if self.drunkenness > 0 then
            drunkennessRow:SetText("Drunkenness: " .. string.format("+%.2f", self.drunkenness / self.portion))
            drunkennessRow:SetTextColor(Color(0, 255, 0, 255))
        elseif self.drunkenness < 0 then
            drunkennessRow:SetText("Drunkenness: " .. string.format("-%.2f", math.abs(self.drunkenness / self.portion)))
            drunkennessRow:SetTextColor(Color(255, 0, 0, 255))
        else
            drunkennessRow:SetText("Drunkenness: 0")
            drunkennessRow:SetTextColor(Color(255, 255, 255, 255))
        end
        drunkennessRow:SizeToContents()
    end
end

ITEM.functions.Drink = {
    name = "Drink",
    tip = "useTip",
    icon = "icon16/drink.png",
    OnRun = function(item)
        local client = item.player
        local char = client:GetCharacter()

        -- Check if client is valid and has the Thirst method
        if not IsValid(client) or not client:IsPlayer() then
            print("Error: client is nil or not a player")
            return false
        end

        -- Play the use sound
        if istable(item.useSound) then
            ix.util.EmitQueuedSounds(client, item.useSound, 0, 0.1, 70, 100)
        else
            client:EmitSound(item.useSound, 70)
        end

        -- Add return items to the character's inventory
        if istable(item.returnItems) then
            for _, v in ipairs(item.returnItems) do
                char:GetInventory():Add(v)
            end
        elseif item.returnItems then
            char:GetInventory():Add(item.returnItems)
        end

        -- Restore thirst, drunkenness, and hunger using meta functions
        local remaining = item:GetData("remaining", item.portion)
        if remaining > 0 then
            if item.thirst then
                client:Thirst(item.thirst / item.portion)
            end
            if item.drunkenness then
                client:Drunkenness(item.drunkenness / item.portion)
            end
            if item.hunger then
                client:Hunger(item.hunger / item.portion)
            end

            -- Decrease the remaining uses of the item
            remaining = remaining - 1
            item:SetData("remaining", remaining)
        end

        -- Remove the item if no remaining uses
        if remaining <= 0 then
            return true
        end

        return false
    end,
    OnCanRun = function(item)
        return not IsValid(item.entity)
    end
}
