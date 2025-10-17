local PLUGIN = PLUGIN or {}

PLUGIN.name = "Float Currency"
PLUGIN.description = "Adds support for float-based currency values."
PLUGIN.author = "Dzhey Kashta"
PLUGIN.schema = "Any"

ix.util.Include("sh_config.lua", "shared")
ix.util.Include("sh_commands.lua", "shared")

--[[
if SERVER then
    function PLUGIN:PlayerLoadedCharacter(client, character, lastChar)
        if (not character or not character.GetData or not character.SetData) then return end

        if (character:GetData("money_is_cents", false)) then return end

        local stored = character:GetData("money", 0)
        local migrated = false

        if (stored % 1 ~= 0) then
            character:SetData("money", math.Round(stored * 100))
            migrated = true

        elseif (stored >= 0 and stored < 1000000) then
            character:SetData("money", stored * 100)
            migrated = true
        end

        character:SetData("money_is_cents", true)

        if (migrated and IsValid(client)) then
            ix.log.Add(client, "generic", string.format(
                "Migrated money to cents: %s -> %s",
                tostring(stored),
                tostring(character:GetData("money", 0))
            ))
        end
    end
end
]]--