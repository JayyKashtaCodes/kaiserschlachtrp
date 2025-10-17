PLUGIN.name = "Auto Whitelist All Factions"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Automatically whitelists players to all factions on join."

ix.config.Add("autoWhitelistEnabled", true, "Whether auto-whitelisting all factions is enabled.", nil, {
    category = "Plugins"
})

function PLUGIN:PlayerLoadedCharacter(client, character, lastChar)
    if not ix.config.Get("autoWhitelistEnabled", true) then return end

    if not client:GetData("autoWhitelisted", false) then
        for _, faction in ipairs(ix.faction.indices) do
            client:SetWhitelisted(faction.index, true)
        end
        client:SetData("autoWhitelisted", true)
    end
end
