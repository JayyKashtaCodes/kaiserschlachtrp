local PLUGIN = PLUGIN or {}

PLUGIN.name = "Medal System"
PLUGIN.description = "A system for awarding and displaying medals above player names."
PLUGIN.author = "Dzhey Kashta"

-- Include networking and command logic
ix.util.Include("sv_plugin.lua", "server")
ix.util.Include("sv_networking.lua", "server")
ix.util.Include("sh_commands.lua", "shared")
ix.util.Include("cl_medaldisplay.lua", "client")

-- Register 'm' flag for medal managers
ix.flag.Add("m", "Allows a player to manage medals (give and remove medals).")

-- Register character variables
ix.char.RegisterVar("medals", {
    field = "medals",
    default = {},
    isLocal = false,
    bNoDisplay = true
})

ix.char.RegisterVar("displayedMedals", {
    field = "displayedMedals",
    default = {},
    isLocal = false,
    bNoDisplay = true
})

-- Load medals from external list
PLUGIN.medals = ix.util.Include("sh_medals.lua", "shared")

-- Retrieve metadata for a specific medal
function PLUGIN:GetMedalData(medalID)
    return self.medals.list and self.medals.list[medalID] or nil
end

-- Remove invalid medals when character loads
function PLUGIN:CharacterLoaded(char)
    local owned = char:GetData("medals", {})
    local displayed = char:GetData("displayedMedals", {})
    local validList = self.medals.list or {}

    -- Filter owned medals
    local filteredOwned = {}
    for _, id in ipairs(owned) do
        if validList[id] then
            table.insert(filteredOwned, id)
        end
    end
    if #filteredOwned < #owned then
        char:SetData("medals", filteredOwned)
    end

    -- Filter displayed medals (must be in both lists)
    local filteredDisplayed = {}
    for _, id in ipairs(displayed) do
        if validList[id] and table.HasValue(filteredOwned, id) then
            table.insert(filteredDisplayed, id)
        end
    end
    if #filteredDisplayed < #displayed then
        char:SetData("displayedMedals", filteredDisplayed)
    end

    -- Broadcast
    if SERVER then
        local ply = char:GetPlayer()
        local displayed = char:GetData("displayedMedals", {})

        net.Start("SyncDisplayedMedals")
            net.WriteEntity(ply)
            net.WriteTable(displayed)
        net.Broadcast()
    end
end

-- Give a medal to a character (avoids duplicates)
function PLUGIN:GiveMedal(target, medalID, actor)
    if not IsValid(target) then return end

    local char = target:GetCharacter()
    if not char then return end

    local medals = char:GetData("medals", {})

    for _, id in ipairs(medals) do
        if id == medalID then
            if IsValid(actor) then
                local medalData = self:GetMedalData(medalID)
                local medalName = medalData and medalData.name or medalID

                actor:Notify(string.format(
                    "%s already has the medal '%s'.", target:Nick(), medalName
                ))
            end
            return
        end
    end

    table.insert(medals, medalID)
    char:SetData("medals", medals)

    if IsValid(actor) then
        local medalData = self:GetMedalData(medalID)
        local medalName = medalData and medalData.name or medalID

        actor:Notify(string.format(
            "You gave the medal '%s' to %s.", medalName, target:Nick()
        ))

        target:Notify(string.format(
            "%s awarded you the medal '%s'.", actor:Nick(), medalName
        ))
    end
end

-- Remove a medal from a character
function PLUGIN:RemoveMedal(target, medalID)
    if not IsValid(target) then return end

    local char = target:GetCharacter()
    if not char then return end

    local medals = char:GetData("medals", {})

    for i, id in ipairs(medals) do
        if id == medalID then
            table.remove(medals, i)
            char:SetData("medals", medals)
            break
        end
    end
end

-- Retrieve all medals a character has
function PLUGIN:GetPlayerMedals(target)
    if not IsValid(target) then return {} end

    local char = target:GetCharacter()
    return char and char:GetData("medals", {}) or {}
end
