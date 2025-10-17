PLUGIN.name = "PK Active"
PLUGIN.description = "Allows setting PK Active."
PLUGIN.author = "Dzhey Kashta, Doopie"

ix.command.Add("PKActive", {
    description = "Toggle PK active status for a character.",
    adminOnly = true,
    arguments = {ix.type.character},
    OnRun = function(self, client, character)
        local pkActive = character:GetData("pkactive", false)
        character:SetData("pkactive", not pkActive)
        
        if pkActive then
            client:Notify(character:GetName() .. " is no longer PK active.")
        else
            client:Notify(character:GetName() .. " has been set as PK active.")
        end
    end
})

function PLUGIN:PlayerDeath(victim, inflictor, attacker)
    local char = victim:GetCharacter()

    if char and char:GetData("pkactive", false) then
        char:Ban()
        char:SetData("pkactive", false)
        victim:Notify("Your character has been banned due to PK active status.")
    end
end

function PLUGIN:CharacterPreSave(character)
    if character:GetData("pkactive", false) then
        local client = character:GetPlayer()
        character:Ban()
        character:SetData("pkactive", false)
        if client then
            client:Notify("Your character has been banned due to PK active status.")
        end
    end
end