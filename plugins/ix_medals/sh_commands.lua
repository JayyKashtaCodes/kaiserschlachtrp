local PLUGIN = PLUGIN

-- Command to open the Medal Admin menu
ix.command.Add("MedalAdmin", {
    description = "Opens the medal administration menu.",
    OnRun = function(self, client, arguments)
        local char = client:GetCharacter()
        if IsValid(client) and char and char:HasFlags("m") then
            net.Start("OpenMedalAdminMenu")
            net.Send(client)
        else
            client:Notify("You do not have permission to use this command.")
        end
    end
})

-- Command to open the Medal Selection menu
ix.command.Add("MedalSelect", {
    description = "Opens the medal selection menu.",
    OnRun = function(self, client, arguments)
        if IsValid(client) then
            net.Start("OpenMedalSelectionMenu")
            net.Send(client)
        end
    end
})
