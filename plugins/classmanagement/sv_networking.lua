local PLUGIN = PLUGIN

-- Network Strings
util.AddNetworkString("ixOpenClassManagement")
util.AddNetworkString("ixClassInviteSend")
util.AddNetworkString("ixClassInviteResponse")
util.AddNetworkString("ixClassInvitePrompt")
util.AddNetworkString("ixClassTransfer")
util.AddNetworkString("ixClassKick")
util.AddNetworkString("ixClassRosterSync")
util.AddNetworkString("ixRequestClassRoster")

-- Net: Invite to Class
net.Receive("ixClassInviteSend", function(_, client)
    local target  = net.ReadEntity()
    local classID = net.ReadUInt(8)
    if not IsValid(target) then return end

    local inviterChar = client:GetCharacter()
    if not inviterChar then return end
    if not PLUGIN:CanPerformAction(client, "canInvite") then return end

    local classTable = ix.class.Get(classID)
    if not classTable then return end
    if not PLUGIN:CanManageClass(inviterChar:GetClass(), classID) then return end

    net.Start("ixClassInvitePrompt")
        net.WriteEntity(client)
        net.WriteUInt(classID, 8)
    net.Send(target)
end)

-- Net: Invite response
net.Receive("ixClassInviteResponse", function(_, target)
    local accepted  = net.ReadBool()
    local inviter   = net.ReadEntity()
    local classID   = net.ReadUInt(8)

    if not accepted then
        target:Notify("You declined the class invite.")
        if IsValid(inviter) then inviter:Notify(target:Nick() .. " declined your invite.") end
        return
    end

    local char = target:GetCharacter()
    local classTable = ix.class.Get(classID)
    if not char or not classTable then return end

    if target:Team() ~= classTable.faction then
        char:SetFaction(classTable.faction)
    end

    local ok = char:JoinClass(classTable.index)
    if not ok then
        local oldClass = char:GetClass()
        char:SetClass(classTable.index)
        hook.Run("PlayerJoinedClass", target, classTable.index, oldClass)
    end

    local startUID
    if PLUGIN.GetDefaultRankUID then
        startUID = PLUGIN:GetDefaultRankUID(classID)
    else
        local ranks = PLUGIN:GetClassRanks(classID) or {}
        for _, data in pairs(ranks) do
            if not startUID or data.uid < startUID then startUID = data.uid end
        end
    end

    if startUID then
        char:SetData("rankUID", startUID, true)
        if isfunction(char.Save) then char:Save() end
        if isfunction(char.SaveData) then char:SaveData() end
    end

    target:Notify(("You joined %s."):format(classTable.name or "Class"))
    if IsValid(inviter) then inviter:Notify(target:Nick() .. " accepted your invite.") end
end)

-- Net: Kick
net.Receive("ixClassKick", function(_, client)
    local steamID = net.ReadString()
    local classID = net.ReadUInt(8)

    if not PLUGIN:CanPerformAction(client, "canKick") then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == steamID then
            local char = ply:GetCharacter()
            if not char or char:GetClass() ~= classID then return end

            char:SetData("rankUID", 0, true)

            local citizenClass = ix.class.Get(CLASS_CITIZEN)
            if not citizenClass then
                client:Notify("Citizen class not found.")
                return
            end

            if ply:Team() ~= citizenClass.faction then
                char:SetFaction(citizenClass.faction)
            end

            local oldClass = char:GetClass()
            char:SetClass(citizenClass.index or CLASS_CITIZEN)
            hook.Run("PlayerJoinedClass", ply, citizenClass.index or CLASS_CITIZEN, oldClass)

            if isfunction(char.Save) then char:Save() end
            if isfunction(char.SaveData) then char:SaveData() end

            client:Notify("Kicked " .. ply:Nick() .. " from class. Moved to Citizen.")
            ply:Notify("You’ve been removed from your class and moved to Citizen.")

            if PLUGIN.BuildClassRoster then
                PLUGIN:BuildClassRoster()
            end
            if PLUGIN.BroadcastRoster then
                PLUGIN:BroadcastRoster()
            elseif PLUGIN.SendRosterTo then
                for _, receiver in ipairs(player.GetAll()) do
                    PLUGIN:SendRosterTo(receiver)
                end
            end

            break
        end
    end
end)

-- Net: Transfer
net.Receive("ixClassTransfer", function(_, client)
    local steamID    = net.ReadString()
    local oldClassID = net.ReadUInt(8)
    local newClassID = net.ReadUInt(8)
    local newRankUID = net.ReadUInt(8)

    if not PLUGIN:CanPerformAction(client, "canPromote") then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == steamID then
            local char = ply:GetCharacter()
            if not char or char:GetClass() ~= oldClassID then return end

            local managerClass = client:GetCharacter():GetClass()

            if oldClassID == newClassID then
                local targetUID = char:GetData("rankUID", 0)

                local resolvedUID
                if newRankUID == 255 then
                    resolvedUID = PLUGIN:GetNextRank(newClassID, targetUID, 1)
                elseif newRankUID == 254 then
                    resolvedUID = PLUGIN:GetNextRank(newClassID, targetUID, -1)
                else
                    resolvedUID = newRankUID
                end

                if not resolvedUID then
                    client:Notify("No higher rank available.")
                    return
                end

                local finalRankData = PLUGIN:GetRankData(newClassID, resolvedUID)
                if not finalRankData then
                    client:Notify("Invalid rank UID for class.")
                    return
                end

                char:SetData("rankUID", resolvedUID, true)
                if isfunction(char.Save) then char:Save() end
                if isfunction(char.SaveData) then char:SaveData() end

                local verb = (newRankUID == 254) and "Demoted" or "Promoted"
                client:Notify(("%s %s to %s"):format(verb, ply:Nick(), finalRankData.displayName))
                ply:Notify(("You were %s to: %s"):format(verb:lower(), finalRankData.displayName))

                print(("[ClassTransfer] %s → %s | Class: %d, Rank: %s")
                    :format(client:Nick(), ply:Nick(), newClassID, finalRankData.displayName))

                if PLUGIN.BuildClassRoster then PLUGIN:BuildClassRoster() end
                if PLUGIN.BroadcastRoster then
                    PLUGIN:BroadcastRoster()
                elseif PLUGIN.SendRosterTo then
                    for _, receiver in ipairs(player.GetAll()) do
                        PLUGIN:SendRosterTo(receiver)
                    end
                end

            else
                if not PLUGIN:CanManageClass(managerClass, oldClassID) or
                   not PLUGIN:CanManageClass(managerClass, newClassID) then return end

                local finalRankData = PLUGIN:GetRankData(newClassID, newRankUID)
                if not finalRankData then
                    client:Notify("Invalid rank UID for class.")
                    return
                end

                char:SetClass(newClassID)
                char:SetData("rankUID", newRankUID, true)
                if isfunction(char.Save) then char:Save() end
                if isfunction(char.SaveData) then char:SaveData() end

                client:Notify("Transferred " .. ply:Nick() .. " to new class and rank.")
                ply:Notify("You have been transferred to a new class and rank.")

                print(("[ClassTransfer] %s → %s | Class: %d, Rank: %s")
                    :format(client:Nick(), ply:Nick(), newClassID, finalRankData.displayName))

                if PLUGIN.BuildClassRoster then PLUGIN:BuildClassRoster() end
                if PLUGIN.BroadcastRoster then
                    PLUGIN:BroadcastRoster()
                elseif PLUGIN.SendRosterTo then
                    for _, receiver in ipairs(player.GetAll()) do
                        PLUGIN:SendRosterTo(receiver)
                    end
                end
            end

            break
        end
    end
end)

-- Net: Roster refresh
net.Receive("ixRequestClassRoster", function(_, client)
    PLUGIN:SendClassRoster(client)
end)
