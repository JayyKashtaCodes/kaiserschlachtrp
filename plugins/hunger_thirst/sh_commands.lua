local PLUGIN = PLUGIN or {}

CAMI.RegisterPrivilege({
    Name = "Helix - Ability to set needs",
    MinAccess = "admin"
})

properties.Add("ixSetPrimaryNeeds.Hunger", {
    MenuLabel = "#Set Hunger",
    Order = 450,
    MenuIcon = "icon16/eat.png",

    Filter = function(self, entity, client)
        return CAMI.PlayerHasAccess(client, "Helix - Ability to set needs", nil) and entity:IsPlayer()
    end,

    Action = function(self, entity)
        self:MsgStart()
            net.WriteEntity(entity)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        if CAMI.PlayerHasAccess(client, "Helix - Ability to set needs", nil) then
            local entity = net.ReadEntity()
            client:RequestString("Set the hunger level for the player", "New Hunger Level", function(text)
                local value = tonumber(text)
                if isnumber(value) and value <= 100 and value >= 0 then
                    entity:SetLocalVar("hunger", math.Clamp(value, 0, 100))
                    client:Notify(string.format('You set %s hunger to %s', entity:Name(), value))
                else
                    client:Notify('Invalid argument')
                end
            end, 0)
        end
    end
})

properties.Add("ixSetPrimaryNeeds.Thirst", {
    MenuLabel = "#Set Thirst",
    Order = 451,
    MenuIcon = "icon16/cup.png",

    Filter = function(self, entity, client)
        return CAMI.PlayerHasAccess(client, "Helix - Ability to set needs", nil) and entity:IsPlayer()
    end,

    Action = function(self, entity)
        self:MsgStart()
            net.WriteEntity(entity)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        if CAMI.PlayerHasAccess(client, "Helix - Ability to set needs", nil) then
            local entity = net.ReadEntity()
            client:RequestString("Set the thirst level for the player", "New Thirst Level", function(text)
                local value = tonumber(text)
                if isnumber(value) and value <= 100 and value >= 0 then
                    entity:SetLocalVar("thirst", math.Clamp(value, 0, 100))
                    client:Notify(string.format('You set %s thirst to %s', entity:Name(), value))
                else
                    client:Notify('Invalid argument')
                end
            end, 0)
        end
    end
})

properties.Add("ixSetPrimaryNeeds.Drunkenness", {
    MenuLabel = "#Set Drunkenness",
    Order = 452,
    MenuIcon = "icon16/cup.png",

    Filter = function(self, entity, client)
        return CAMI.PlayerHasAccess(client, "Helix - Ability to set needs", nil) and entity:IsPlayer()
    end,

    Action = function(self, entity)
        self:MsgStart()
            net.WriteEntity(entity)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        if CAMI.PlayerHasAccess(client, "Helix - Ability to set needs", nil) then
            local entity = net.ReadEntity()
            client:RequestString("Set the drunkenness level for the player", "New Drunkenness Level", function(text)
                local value = tonumber(text)
                if isnumber(value) and value <= 100 and value >= 0 then
                    entity:SetLocalVar("drunkenness", math.Clamp(value, 0, 100))
                    client:Notify(string.format('You set %s drunkenness to %s', entity:Name(), value))
                else
                    client:Notify('Invalid argument')
                end
            end, 0)
        end
    end
})

do
    ix.command.Add("CharSetHunger", {
        description = "Sets the hunger level of a character.",
        privilege = "Primary Needs",
        adminOnly = true,
        arguments = {
            ix.type.character,
            bit.bor(ix.type.number, ix.type.optional)
        },
        OnRun = function(self, client, target, amount)
            if not client:GetCharacter() then return end
            if target then
                if not amount then amount = 100 end
                local clamped = math.Round(math.Clamp(amount, 0, 100))
                target:GetPlayer():SetLocalVar("hunger", clamped)
            end
        end
    })

    ix.command.Add("CharSetThirst", {
        description = "Sets the thirst level of a character.",
        privilege = "Primary Needs",
        adminOnly = true,
        arguments = {
            ix.type.character,
            bit.bor(ix.type.number, ix.type.optional)
        },
        OnRun = function(self, client, target, amount)
            if not client:GetCharacter() then return end
            if target then
                if not amount then amount = 100 end
                local clamped = math.Round(math.Clamp(amount, 0, 100))
                target:GetPlayer():SetLocalVar("thirst", clamped)
            end
        end
    })

    ix.command.Add("CharSetDrunkenness", {
        description = "Sets the drunkenness level of a character.",
        privilege = "Primary Needs",
        adminOnly = true,
        arguments = {
            ix.type.character,
            bit.bor(ix.type.number, ix.type.optional)
        },
        OnRun = function(self, client, target, amount)
            if not client:GetCharacter() then return end
            if target then
                if not amount then amount = 0 end
                local clamped = math.Round(math.Clamp(amount, 0, 100))
                target:GetPlayer():SetLocalVar("drunkenness", clamped)
            end
        end
    })
end
