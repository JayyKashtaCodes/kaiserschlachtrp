local PLUGIN = PLUGIN
PLUGIN.name = "Personal Doors"
PLUGIN.author = "Bilwin (modified by Jayy)"
PLUGIN.description = "Extended door system for personal ownership, key sharing, and rental."
PLUGIN.version = 2.0
PLUGIN.schema = "Any"

-- Ownership levels from Doors plugin
DOOR_OWNER  = DOOR_OWNER  or 3
DOOR_TENANT = DOOR_TENANT or 2
DOOR_GUEST  = DOOR_GUEST  or 1
DOOR_NONE   = DOOR_NONE   or 0

-- ##############################
-- ## COMMANDS
-- ##############################

ix.command.Add("SetDoorOwner", {
    description = "Set or clear the owner of the door you are looking at.",
    adminOnly = true,
    privilege = "DoorOwnership",
    arguments = {ix.type.optionalCharacter},
    OnRun = function(self, client, targetChar)
        local door = client:GetEyeTrace().Entity
        if (not IsValid(door) or not door:IsDoor()) then
            return "You are not looking at a valid door."
        end

        door.ixAccess = door.ixAccess or {}

        if targetChar then
            local targetClient = targetChar:GetPlayer()
            door.ixAccess = {} -- Clear previous keys entirely
            door.ixAccess[targetClient] = DOOR_OWNER
            door:SetNetVar("ixAccess", door.ixAccess)
            return string.format("%s is now the owner of this door.", targetChar:GetName())
        else
            door.ixAccess = {}
            door:SetNetVar("ixAccess", door.ixAccess)
            return "Door ownership cleared."
        end
    end
})

ix.command.Add("CharGiveKeys", {
    description = "Give keys to a door you own.",
    arguments = {ix.type.character},
    OnRun = function(self, client, targetChar)
        local door = client:GetEyeTrace().Entity
        if (not IsValid(door) or not door:IsDoor()) then
            return "Invalid door."
        end

        if (door.ixAccess and door.ixAccess[client] == DOOR_OWNER) then
            door.ixAccess[targetChar:GetPlayer()] = DOOR_GUEST
            door:SetNetVar("ixAccess", door.ixAccess)
            return string.format("%s now has keys to this door.", targetChar:GetName())
        else
            return "You don't own this door."
        end
    end
})

ix.command.Add("CharTakeKeys", {
    description = "Remove keys from a door you own.",
    arguments = {ix.type.character},
    OnRun = function(self, client, targetChar)
        local door = client:GetEyeTrace().Entity
        if (not IsValid(door) or not door:IsDoor()) then
            return "Invalid door."
        end

        local isOwner = door.ixAccess and door.ixAccess[client] == DOOR_OWNER
        if not isOwner and not client:IsAdmin() then
            return "You don’t have permission to remove keys."
        end

        local targetClient = targetChar:GetPlayer()
        if (door.ixAccess and door.ixAccess[targetClient]) then
            door.ixAccess[targetClient] = nil
            door:SetNetVar("ixAccess", door.ixAccess)
            return string.format("%s’s keys have been removed.", targetChar:GetName())
        else
            return string.format("%s has no keys to this door.", targetChar:GetName())
        end
    end
})

-- ##############################
-- ## RENTABLE PROPERTY
-- ##############################

if (CLIENT) then
    properties.Add("door_rentable", {
        MenuLabel = "Toggle Rentable",
        Order = 1000,
        MenuIcon = "icon16/money.png",

        Filter = function(self, ent, ply)
            return ent:IsDoor() and (ent.ixAccess and ent.ixAccess[ply] == DOOR_OWNER)
        end,

        Action = function(self, ent)
            local currentPrice = ix.currency.FromCents(ent:GetNetVar("rentPriceCents", 0))
            Derma_StringRequest("Rent Settings",
                "Enter rent price (" .. ix.currency.symbol .. "0.00):",
                string.format("%.2f", currentPrice),
                function(priceStr)
                    local priceFloat = tonumber(priceStr) or 0
                    net.Start("ixToggleRentableDoor")
                        net.WriteEntity(ent)
                        net.WriteBool(not ent:GetNetVar("rentable", false))
                        net.WriteUInt(ix.currency.ToCents(priceFloat), 32) -- cents
                    net.SendToServer()
                end
            )
        end
    })
end

if (SERVER) then
    util.AddNetworkString("ixToggleRentableDoor")

    net.Receive("ixToggleRentableDoor", function(_, ply)
        local door     = net.ReadEntity()
        local rentable = net.ReadBool()
        local priceC   = net.ReadUInt(32)

        if IsValid(door) and door:IsDoor() and (door.ixAccess and door.ixAccess[ply] == DOOR_OWNER) then
            door:SetNetVar("rentable", rentable)
            door:SetNetVar("rentPriceCents", priceC)
        end
    end)
end

-- ##############################
-- ## PRINT OWNERS
-- ##############################

ix.command.Add("DoorPrintOwners", {
    description = "List all current keyholders for the door you are looking at.",
    adminOnly = true,
    privilege = "DoorOwnership",
    OnRun = function(self, client)
        local door = client:GetEyeTrace().Entity
        if (not IsValid(door) or not door:IsDoor()) then
            return "You are not looking at a valid door."
        end

        local msg, owners = {}, {}
        for _, ply in ipairs(player.GetAll()) do
            if door.ixAccess and door.ixAccess[ply] then
                local char = ply:GetCharacter()
                if char then
                    table.insert(owners, string.format("%s (%s) - Level %d",
                        char:GetName(),
                        ply:SteamID(),
                        door.ixAccess[ply]
                    ))
                end
            end
        end

        if next(owners) then
            msg = table.Copy(owners)
        else
            msg = {"No one owns or has keys to this door."}
        end

        netstream.Start(client, "HeavyChatNotify", msg, color_white, "icon16/key.png")
    end
})
