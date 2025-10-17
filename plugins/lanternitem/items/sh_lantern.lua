ITEM.name = "Lantern"
ITEM.model = Model("models/weapons/w_lantern.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A standard Lantern that runs on oil."
ITEM.category = "Tools"
ITEM.bDropOnDeath = true

ITEM.maxOil = 500
ITEM.burnRate = 1
ITEM.burnInterval = 10

function ITEM:OnInstanced()
    if self:GetData("oil", nil) == nil then
        self:SetData("oil", 0)
    end
end

function ITEM:AddOil(amount)
    local current = self:GetData("oil", 0)
    local newAmount = math.min(current + amount, self.maxOil)
    self:SetData("oil", newAmount)
    return newAmount
end

function ITEM:BurnOil()
    local current = self:GetData("oil", 0)
    if current <= 0 then
        return false
    end
    self:SetData("oil", math.max(current - self.burnRate, 0))
    return self:GetData("oil") > 0
end

if (CLIENT) then
    function ITEM:PopulateTooltip(tooltip)
        local oil = self:GetData("oil", 0)
        local maxOil = self.maxOil or 500

        local percent = math.floor((oil / maxOil) * 100)

        local row = tooltip:AddRowAfter("description", "oilLevel")
        row:SetText(string.format("Oil: %d / %d  (%d%%)", oil, maxOil, percent))
        row:SetBackgroundColor(Color(255, 200, 50))
        row:SizeToContents()
    end
end

