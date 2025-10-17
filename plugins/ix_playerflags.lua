local PLUGIN = PLUGIN

PLUGIN.name = "Player Flag Manager"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Manages player-specific flags using rank checks."

-- Map meta checks → schema flag letters
function PLUGIN:GetRoleFlagsForPlayer(client)
    -- Priority order: GA > UA > Staff > Donator+ > Donator
    if client:IsGA() then
        return self:GetAllSchemaFlags()

    elseif client:IsUA() then
        return self:GetAllSchemaFlags()

    elseif client:IsUStaff() then
        return self:FilterInvalidFlags("petrCJm")

    elseif client:IsStaff() then
        return self:FilterInvalidFlags("petrCJ")

    elseif client:IsDonatorPlus() then
        return self:FilterInvalidFlags("petrC")

    elseif client:IsDonator() then
        return self:FilterInvalidFlags("petC")
    end

    return "" -- no matching rank → no auto flags
end

function PLUGIN:GetAllSchemaFlags()
    local allFlags = ""
    for flag, _ in pairs(ix.flag.list) do
        allFlags = allFlags .. flag
    end
    return allFlags
end

function PLUGIN:FilterInvalidFlags(flags)
    local validFlags = self:GetAllSchemaFlags()
    local filteredFlags = ""

    for flag in flags:gmatch(".") do
        if validFlags:find(flag, 1, true) then
            filteredFlags = filteredFlags .. flag
        end
    end

    return filteredFlags
end

function PLUGIN:UpdatePlayerFlags(client)
    local roleFlagsForGroup = self:GetRoleFlagsForPlayer(client)
    client.roleFlags = roleFlagsForGroup
end

function PLUGIN:RemoveRoleFlags(client, oldUserGroup)
    -- regenerate old role flags based on your meta checks for that group if needed
    local oldFlags = self:FilterInvalidFlags(client.roleFlags or "")
    local commandFlags = client.commandFlags or ""

    for flag in oldFlags:gmatch(".") do
        commandFlags = commandFlags:gsub(flag, "")
    end

    client.commandFlags = commandFlags
    self:SavePlayerFlags(client)
end

function PLUGIN:VerifyAndUpdateRoleFlags(client)
    local previousGroup = client.previousUserGroup or ""
    local currentFlags = self:GetRoleFlagsForPlayer(client)

    if client:GetUserGroup() ~= previousGroup then
        self:RemoveRoleFlags(client, previousGroup)
        client.previousUserGroup = client:GetUserGroup()
    end

    client.roleFlags = currentFlags
    self:SavePlayerFlags(client)
end

function PLUGIN:SavePlayerFlags(client)
    local steamID = client:SteamID()
    local data = self:GetData() or {}
    data[steamID] = {
        commandFlags = client.commandFlags or "",
        roleFlags = client.roleFlags or ""
    }
    self:SetData(data)
end

function PLUGIN:LoadPlayerFlags(client)
    local steamID = client:SteamID()
    local data = self:GetData() or {}

    if data[steamID] then
        client.commandFlags = self:FilterInvalidFlags(data[steamID].commandFlags or "")
        client.roleFlags = self:FilterInvalidFlags(data[steamID].roleFlags or "")
    else
        self:UpdatePlayerFlags(client)
    end
end

function PLUGIN:AssignCharacterFlags(client, character)
    if not IsValid(client) or not character then return end

    local allFlags = (client.commandFlags or "") .. (client.roleFlags or "")
    local assignedFlags = ""

    for flag in allFlags:gmatch(".") do
        if not character:HasFlags(flag) then
            character:GiveFlags(flag)
            assignedFlags = assignedFlags .. flag
        end
    end

    if assignedFlags ~= "" then
        client:Notify("Your character has been given the following flags: " .. assignedFlags)
    end
end

function PLUGIN:RemoveCharacterFlags(client, character)
    if not IsValid(client) or not character then return end
    for flag, _ in pairs(ix.flag.list) do
        if character:HasFlags(flag) then
            character:TakeFlags(flag)
        end
    end
end

function PLUGIN:PlayerLoadedCharacter(client, character, lastChar)
    if IsValid(client) and character then
        self:VerifyAndUpdateRoleFlags(client)

        if client.commandFlags or client.roleFlags then
            self:AssignCharacterFlags(client, character)
        else
            self:RemoveCharacterFlags(client, character)
        end
    end
end

function PLUGIN:PlayerInitialSpawn(client)
    self:LoadPlayerFlags(client)
    self:VerifyAndUpdateRoleFlags(client)
end

-- Commands
-- Add Player Flag
ix.command.Add("AddPlayerFlag", {
    description = "Add a flag to a player.",
    arguments = {ix.type.player, ix.type.string},
    OnCheckAccess = function(self, client)
        return client:IsUA()
    end,
    OnRun = function(self, client, target, flag)
        if not target.commandFlags:find(flag, 1, true) then
            target.commandFlags = (target.commandFlags or "") .. flag
            client:Notify("Flag '" .. flag .. "' added to " .. target:GetName())
            PLUGIN:SavePlayerFlags(target)
        else
            client:Notify("Player already has this flag.")
        end
    end
})

-- Remove Player Flag
ix.command.Add("RemovePlayerFlag", {
    description = "Remove a flag from a player.",
    arguments = {ix.type.player, ix.type.string},
    OnCheckAccess = function(self, client)
        return client:IsUA()
    end,
    OnRun = function(self, client, target, flag)
        if target.commandFlags:find(flag, 1, true) then
            target.commandFlags = target.commandFlags:gsub(flag, "")
            client:Notify("Flag '" .. flag .. "' removed from " .. target:GetName())
            PLUGIN:SavePlayerFlags(target)
        else
            client:Notify("Player does not have this flag.")
        end
    end
})

-- Give All Player Flags
ix.command.Add("GiveAllPlayerFlags", {
    description = "Assign all schema flags to a player.",
    arguments = {ix.type.player},
    OnCheckAccess = function(self, client)
        return client:IsUA()
    end,
    OnRun = function(self, client, target)
        local allFlags = PLUGIN:GetAllSchemaFlags()
        target.commandFlags = allFlags
        client:Notify(target:GetName() .. " has been given all flags.")
        PLUGIN:SavePlayerFlags(target)
    end
})

-- Take All Player Flags
ix.command.Add("TakeAllPlayerFlags", {
    description = "Remove all flags from a player.",
    arguments = {ix.type.player},
    OnCheckAccess = function(self, client)
        return client:IsUA()
    end,
    OnRun = function(self, client, target)
        target.commandFlags = ""
        client:Notify(target:GetName() .. " has had all flags removed.")
        PLUGIN:SavePlayerFlags(target)
    end
})

-- Check Player Flags
ix.command.Add("CheckPlayerFlags", {
    description = "Check the flags assigned to a player.",
    arguments = {ix.type.player},
    OnCheckAccess = function(self, client)
        return client:IsUA()
    end,
    OnRun = function(self, client, target)
        local flags = target.commandFlags or ""
        if flags ~= "" then
            client:Notify(target:GetName() .. " has the following flags: " .. flags)
        else
            client:Notify(target:GetName() .. " has no flags assigned.")
        end
    end
})
