ITEM.name = "Intermediate Medkit"
ITEM.description = "A compact intermediate medical kit capable of restoring health."
ITEM.model = "models/oldprops/medkit.mdl"
ITEM.category = "Medical"
ITEM.width = 2
ITEM.height = 2
ITEM.maxUses = 3
ITEM.healAmount = 25

function ITEM:GetDescription()
    local usesLeft = self:GetData("usesLeft", self.maxUses or 1)
    return ("A compact medical kit capable of restoring health.\nUses remaining: %s"):format(usesLeft)
end

ITEM.functions.Use = {
    name = "Use",
    tip = "Heal yourself.",
    icon = "icon16/heart.png",
    OnRun = function(itemTable)
        local client = itemTable.player
        local usesLeft = itemTable:GetData("usesLeft", itemTable.maxUses)
        local healAmount = itemTable.healAmount

        if (client:Health() >= client:GetMaxHealth()) then
            client:Notify("You're already at full health.")
            return false
        end

        local newHealth = math.min(client:Health() + healAmount, client:GetMaxHealth())
        client:SetHealth(newHealth)
        client:EmitSound("items/smallmedkit1.wav")

        usesLeft = usesLeft - 1

        if usesLeft <= 0 then
            return true
        else
            itemTable:SetData("usesLeft", usesLeft)
            return false
        end
    end
}

ITEM.functions.UseOnTarget = {
    name = "Use on Target",
    tip = "Heal someone nearby.",
    icon = "icon16/user_add.png",
    OnRun = function(itemTable)
        local client = itemTable.player
        local usesLeft = itemTable:GetData("usesLeft", itemTable.maxUses)
        local healAmount = itemTable.healAmount

        local trace = client:GetEyeTrace()
        local target = trace.Entity

        if not (IsValid(target) and target:IsPlayer()) then
            client:Notify("You must be looking at another player.")
            return false
        end

        if (client:GetPos():DistToSqr(target:GetPos()) > 10000) then
            client:Notify("You're too far away to heal them.")
            return false
        end

        if (target:Health() >= target:GetMaxHealth()) then
            client:Notify(target:Name() .. " is already at full health.")
            return false
        end

        local newHealth = math.min(target:Health() + healAmount, target:GetMaxHealth())
        target:SetHealth(newHealth)
        target:EmitSound("items/smallmedkit1.wav")
        client:Notify("You healed " .. target:Name() .. " for " .. (newHealth - target:Health()) .. " HP.")

        usesLeft = usesLeft - 1

        if usesLeft <= 0 then
            return true
        else
            itemTable:SetData("usesLeft", usesLeft)
            return false
        end
    end
}
