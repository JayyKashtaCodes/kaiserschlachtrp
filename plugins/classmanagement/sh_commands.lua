local PLUGIN = PLUGIN

-- Set the top rank for a class member (superadmin only)
ix.command.Add("SetClassLeader", {
    description     = "Sets a player as the leader of their class.",
    superAdminOnly  = true,
    arguments       = { ix.type.player },
    OnRun           = function(self, client, target)
        local char    = target:GetCharacter()
        local classID = char:GetClass()
        local ranks   = PLUGIN:GetClassRanks(classID)
        local highestUID, highestName = 0, "Unknown"

        for name, data in pairs(ranks) do
            if data.uid > highestUID then
                highestUID  = data.uid
                highestName = name
            end
        end

        if highestUID > 0 then
            char:SetData("rankUID", highestUID, true) -- persist to SQL and sync
            if isfunction(char.Save) then char:Save() end
            if isfunction(char.SaveData) then char:SaveData() end
            
            client:Notify(target:GetName() .. " is now the leader of class: " .. highestName)
            target:Notify("You’ve been made the leader of your class: " .. highestName)
        else
            client:Notify("Failed to find the highest rank.")
        end
    end
})

-- Remove leadership and optionally assign a fallback rank (superadmin only)
ix.command.Add("RemoveClassLeader", {
    description     = "Removes leadership from a class member. Downgrades to specified rank or one below current.",
    superAdminOnly  = true,
    arguments = {
        ix.type.player,
        ix.type.string
    },

    OnRun = function(self, client, target, input)
        if not input or input == "" then
            return client:Notify("You must provide a rank name or UID.")
        end

        local character = target:GetCharacter()
        local classID   = character:GetClass()
        if not classID then
            return client:Notify("Target has no class assigned.")
        end

        local currentUID = character:GetData("rankUID", nil)
        if not currentUID then
            return client:Notify("Target has no rank assigned.")
        end

        local ranks = PLUGIN:GetClassRanks(classID)
        if not ranks then
            return client:Notify("No rank data available for target's class.")
        end

        local newUID, newName

        -- Manual override via name or UID
        if input and input ~= "" then
            local parsed = tonumber(input)
            if parsed then
                for name, data in pairs(ranks) do
                    if data.uid == parsed then
                        newUID  = data.uid
                        newName = name
                        break
                    end
                end
            elseif ranks[input] then
                newUID  = ranks[input].uid
                newName = input
            end

            if not newUID then
                return client:Notify("Invalid rank input provided.")
            end

        -- Fallback: downgrade one step
        else
            newUID = PLUGIN:GetNextRank(classID, currentUID, -1)
            if newUID then
                newName = PLUGIN:GetRankFromUID(classID, newUID)
            else
                return client:Notify("Cannot demote further — already at lowest rank.")
            end
        end

        character:SetData("rankUID", newUID, true) -- persist & sync
        if isfunction(character.Save) then character:Save() end
        if isfunction(character.SaveData) then character:SaveData() end

        client:Notify(target:GetName() .. " has been removed as class leader and assigned rank: " .. newName)
        target:Notify("You’ve been removed as leader and reassigned the rank: " .. newName)
    end
})

-- Debug command: print all ranks and UIDs for your current class
ix.command.Add("PrintClassRanks", {
    description = "Print all ranks and UIDs for your current class.",
    OnRun       = function(self, client)
        local classID = client:GetCharacter():GetClass()
        local ranks   = PLUGIN:GetClassRanks(classID)

        for name, data in pairs(ranks) do
            print(name .. " -> UID: " .. data.uid)
        end
    end
})

-- View your own rank/class/faction info
ix.command.Add("RankInfo", {
    description = "View your character's rank information.",
    arguments = {},
    OnRun = function(self, client)
        local char = client:GetCharacter()
        if not char then
            client:PrintMessage(HUD_PRINTCONSOLE, "[RankInfo] No character loaded.\n")
            return
        end

        -- Grab values
        local rankUID      = tonumber(char:GetData("rankUID", 1)) or 1
        local classID      = char:GetClass()
        local factionID    = char:GetFaction()
        local salaryBuffer = tonumber(char:GetData("salaryBuffer", 0)) or 0

        -- Resolve class and faction names
        local class        = ix.class.Get(classID)
        local faction      = ix.faction.Get(factionID)
        local className    = class and class.name or "Unknown"
        local factionName  = faction and faction.name or "Unknown"

        local rankName     = PLUGIN:GetRankFromUID(classID, rankUID)
        local rankData     = PLUGIN:GetRankPermissions(classID, rankUID)
        local salary       = tonumber(rankData.salary) or 0

        -- Permission parsing
        local perms = {}
        if rankData.canInvite  then table.insert(perms, "Invite") end
        if rankData.canPromote then table.insert(perms, "Promote") end
        if rankData.canKick    then table.insert(perms, "Kick") end
        local permissionString = #perms > 0 and table.concat(perms, ", ") or "None"

        -- Controlled classes
        local controlled       = PLUGIN.classManagementMap[classID] or {}
        local controlledNames  = {}
        for _, controlledID in ipairs(controlled) do
            local subClass = ix.class.Get(controlledID)
            if subClass then table.insert(controlledNames, subClass.name) end
        end
        local controlString = #controlledNames > 0 and table.concat(controlledNames, ", ") or "None"

        -- Output
        client:PrintMessage(HUD_PRINTCONSOLE, "\n== RANK INFORMATION ==\n")
        client:PrintMessage(HUD_PRINTCONSOLE, "• Rank: " .. rankName .. "\n")
        client:PrintMessage(HUD_PRINTCONSOLE, "• Class: " .. className .. "\n")
        client:PrintMessage(HUD_PRINTCONSOLE, "• Faction: " .. factionName .. "\n")
        client:PrintMessage(HUD_PRINTCONSOLE, "• Salary: " .. ix.currency.Get(salary) .. "\n")
        client:PrintMessage(HUD_PRINTCONSOLE, "• Uncollected Salary: " .. ix.currency.Get(ix.currency.FromCents(salaryBuffer)) .. "\n")
        client:PrintMessage(HUD_PRINTCONSOLE, "• Permissions: " .. permissionString .. "\n")
        client:PrintMessage(HUD_PRINTCONSOLE, "• Controls: " .. controlString .. "\n")
    end
})

-- Open the class management interface
ix.command.Add("ClassManagement", {
    description = "Open the class management interface.",
    adminOnly = false,
    OnRun = function(self, client)
        local char = client:GetCharacter()
        if not char then
            client:Notify("You don't have a character.")
            return
        end

        local classID = char:GetClass()
        local rankUID = char:GetData("rankUID", 0)

        if not PLUGIN:IsManagedClass(classID) then
            client:Notify("Your class is not eligible for management.")
            return
        end

        local permissions = {
            canInvite  = PLUGIN:CanPerformAction(client, "canInvite"),
            canPromote = PLUGIN:CanPerformAction(client, "canPromote"),
            canKick    = PLUGIN:CanPerformAction(client, "canKick")
        }

        -- Send permission flags to client
        net.Start("ixOpenClassManagement")
            net.WriteBool(permissions.canInvite)
            net.WriteBool(permissions.canPromote)
            net.WriteBool(permissions.canKick)
        net.Send(client)

        -- Send full class roster snapshot
        PLUGIN:SendClassRoster(client)
    end
})
