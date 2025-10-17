local Schema = Schema
---------------------------------------------------------------------------------------------------------------------------------
--[[ Logs ]]--
ix.command.Add("logs", {
    description = "Opens the Billy's Logs menu.",
    OnRun = function(self, client)
        if !client:IsStaff() then 
            client:Notify("You cannot open Billy Logs.")
            return 
        end
        client:ConCommand("say !logs")
    end
})

ix.command.Add("gas", {
    description = "Opens the Gmod Admin Suite menu.",
    OnRun = function(self, client)
        if !client:IsUA() then 
            client:Notify("You cannot open Gmod Admin Suite Menu.")
            return 
        end
        client:ConCommand("say !gas")
    end
})
--[[ END ]]--
---------------------------------------------------------------------------------------------------------------------------------
--[[ Door Kick ]]--
ix.command.Add("DoorKick", {
    description = "Kick down a door in front of you.",
    adminOnly = false,
    arguments = {},
    factions = {FACTION_INNERN, FACTION_STAFF, FACTION_ARMY}, -- Allowed factions

    -- Only allow whitelisted factions to run this command
    OnCheckAccess = function(self, client)
        local playerFaction = client:Team()
        for _, factionIndex in ipairs(self.factions) do
            if playerFaction == factionIndex then
                return true
            end
        end
        return false
    end,

    OnRun = function(self, client)
        local trace = client:GetEyeTrace()
        local entity = trace.Entity
        local maxDistance = 100 -- Maximum distance (in units) from which the door can be kicked

        -- Validate the target entity
        if not (IsValid(entity) and entity:GetClass() == "prop_door_rotating") then
            client:Notify("You are not looking at a valid door.")
            return
        end

        local playerPosition = client:GetPos()
        local doorPosition = entity:GetPos()
        local distance = playerPosition:Distance(doorPosition)

        -- Check if the player is within the allowed range
        if distance > maxDistance then
            client:Notify("You are too far away from the door to kick it.")
            return
        end

        local doorAngles = entity:GetAngles()

        -- Play a "big bang" sound effect
        entity:EmitSound("physics/wood/wood_box_break1.wav", 100, 100, 4)

        -- Create a "blasted door" effect
        local Door = ents.Create("prop_physics")
        Door:SetModel(entity:GetModel())
        Door:SetPos(doorPosition)
        Door:SetAngles(doorAngles)
        Door:SetSkin(entity:GetSkin())
        Door:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        Door:Spawn()

        -- Apply force to simulate the door being kicked
        local direction = (doorPosition - playerPosition):GetNormalized()
        local phys = Door:GetPhysicsObject()
        if IsValid(phys) then
            phys:ApplyForceCenter(direction * 1500)
        end

        -- Hide the original door
        entity:Fire("Unlock")
        entity:Fire("Open")
        entity:SetNoDraw(true)
        entity:SetNotSolid(true)
        entity:SetPos(entity:GetPos() + Vector(0, 0, -1000))
        client:Notify("You have kicked the door off its hinges!")

        -- Respawn the original door after a set duration
        timer.Simple(ix.config.Get("Door Kick Respawn", 60), function()
            if IsValid(entity) then
                entity:SetNoDraw(false)
                entity:SetNotSolid(false)
                entity:SetPos(doorPosition)
            end

            if IsValid(Door) then
                Door:Remove()
            end
        end)
    end
})
--[[ END ]]--
---------------------------------------------------------------------------------------------------------------------------------
--[[ Set Name ]]--
ix.command.Add("CharSetName", {
    description = "@cmdCharSetName",
    adminOnly = false,
    arguments = {
        ix.type.character,
        bit.bor(ix.type.text, ix.type.optional)
    },
    OnCheckAccess = function(self, client)
        local char = client:GetCharacter()
        if not char then return false end

        local class = char:GetClass()
        return client:IsAdmin() or class == CLASS_ARMYJUS or class == CLASS_JUST
    end,
    OnRun = function(self, client, target, newName)

        if (newName:len() == 0) then
            return client:RequestString("@chgName", "@chgNameDesc", function(text)
                ix.command.Run(client, "CharSetName", {target:GetName(), text})
            end, target:GetName())
        end

        for _, v in player.Iterator() do
            if (self:OnCheckAccess(v) or v == target:GetPlayer()) then
                v:NotifyLocalized("cChangeName", client:GetName(), target:GetName(), newName)
            end
        end

        target:SetName(newName:gsub("#", "#​"))
    end
})
--[[ END ]]--
---------------------------------------------------------------------------------------------------------------------------------