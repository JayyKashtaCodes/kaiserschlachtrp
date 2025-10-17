local PLUGIN = PLUGIN

PLUGIN.name = "Laws and Rules"
PLUGIN.description = "Adds an Laws and Rules to the menu."
PLUGIN.author = "Dzhey Kashta"

ix.config.Add("lawsDocID", "1qKFghVA_ULjySv6si27mdbYRtkHz8-hIBIiT8ECZ7a8", "Unique ID for the Laws Google Doc", nil, {
    category = PLUGIN.name,
})

ix.config.Add("rulesDocID", "1qKFghVA_ULjySv6si27mdbYRtkHz8-hIBIiT8ECZ7a8", "Unique ID for the Rules Google Doc", nil, {
    category = PLUGIN.name,
})

function PLUGIN:CreateInformationMenuButtons(tabs)
    if (hook.Run("BuildInformationMenu") ~= false) then
        tabs["Laws and Rules"] = function(container)
            container:Add("ixInfoMenu")
        end
    end
end

hook.Add("CreateMenuButtons", "ixInformation", function(tabs)
    PLUGIN:CreateInformationMenuButtons(tabs)
end)
