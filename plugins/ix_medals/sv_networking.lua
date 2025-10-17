local PLUGIN = PLUGIN

util.AddNetworkString("GiveMedal")
util.AddNetworkString("RemoveMedal")
util.AddNetworkString("SelectMedalDisplay")
util.AddNetworkString("RequestAllMedals")
util.AddNetworkString("SendAllMedals")
util.AddNetworkString("RequestOwnedMedals")
util.AddNetworkString("SendOwnedMedals")
util.AddNetworkString("OpenMedalAdminMenu")
util.AddNetworkString("OpenMedalSelectionMenu")
util.AddNetworkString("SyncDisplayedMedals")

net.Receive("GiveMedal", function(_, ply)
    local targetName = net.ReadString()
    local medalID = net.ReadString()

    local actorChar = ply:GetCharacter()
    if not actorChar or not actorChar:HasFlags("m") then
        ply:Notify("You do not have permission to give medals.")
        return
    end

    local target = ix.util.FindPlayer(targetName)
    if IsValid(target) then
        local char = target:GetCharacter()
        if char then
            local medals = char:GetData("medals", {})

            for _, id in ipairs(medals) do
                if id == medalID then
                    local medalData = PLUGIN:GetMedalData(medalID)
                    local medalName = medalData and medalData.name or medalID
                    ply:Notify(string.format(
                        "%s already has the medal '%s'.", target:Nick(), medalName
                    ))
                    return
                end
            end

            table.insert(medals, medalID)
            char:SetData("medals", medals)

            local medalData = PLUGIN:GetMedalData(medalID)
            local medalName = medalData and medalData.name or medalID

            ply:Notify(string.format(
                "You gave the medal '%s' to %s.", medalName, target:Nick()
            ))

            target:Notify(string.format(
                "%s awarded you the medal '%s'.", ply:Nick(), medalName
            ))
        else
            ply:Notify("Error: Target player does not have a character loaded.")
        end
    else
        ply:Notify("Error: Target player not found.")
    end
end)

net.Receive("RemoveMedal", function(_, ply)
    local targetName = net.ReadString()
    local medalID = net.ReadString()

    local actorChar = ply:GetCharacter()
    if not actorChar or not actorChar:HasFlags("m") then
        ply:Notify("You do not have permission to remove medals.")
        return
    end

    local target = ix.util.FindPlayer(targetName)
    if IsValid(target) then
        local char = target:GetCharacter()
        if char then
            local medals = char:GetData("medals", {})
            local removed = false
            for i, id in ipairs(medals) do
                if id == medalID then
                    table.remove(medals, i)
                    char:SetData("medals", medals)

                    local medalData = PLUGIN:GetMedalData(medalID)
                    local medalName = medalData and medalData.name or medalID

                    ply:Notify(string.format(
                        "You removed the medal '%s' from %s.", medalName, target:Nick()
                    ))

                    target:Notify(string.format(
                        "%s removed the medal '%s' from you.", ply:Nick(), medalName
                    ))
                    removed = true
                    break
                end
            end
            if not removed then
                ply:Notify(string.format("%s does not have the medal '%s'.", target:Nick(), medalID))
            end
        else
            ply:Notify("Error: Target player does not have a character loaded.")
        end
    else
        ply:Notify("Error: Target player not found.")
    end
end)

net.Receive("SelectMedalDisplay", function(_, ply)
    local selectedMedalIDs = net.ReadTable()
    local char = ply:GetCharacter()
    if not char then
        ply:Notify("Error: Could not find your character to update medals.")
        return
    end

    local owned = char:GetData("medals", {})
    local filtered = {}

    for _, medalID in ipairs(selectedMedalIDs) do
        if table.HasValue(owned, medalID) then
            table.insert(filtered, medalID)
            if #filtered >= 3 then
                break
            end
        end
    end

    char:SetData("displayedMedals", filtered)

    -- Broadcast to all clients
    net.Start("SyncDisplayedMedals")
        net.WriteEntity(ply)
        net.WriteTable(filtered)
    net.Broadcast()

    ply:Notify("Your displayed medals have been updated.")
end)

net.Receive("RequestAllMedals", function(_, ply)
    local char = ply:GetCharacter()
    if not char or not char:HasFlags("m") then
        ply:Notify("You do not have permission to view all medals.")
        return
    end

    net.Start("SendAllMedals")
    net.WriteTable(PLUGIN.medals.list or {})
    net.Send(ply)
end)

net.Receive("RequestOwnedMedals", function(_, ply)
    local char = ply:GetCharacter()
    if not char then return end

    local owned = char:GetData("medals", {})

    net.Start("SendOwnedMedals")
    net.WriteTable(owned)
    net.Send(ply)
end)
