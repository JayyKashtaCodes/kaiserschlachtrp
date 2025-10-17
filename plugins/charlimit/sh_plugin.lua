local PLUGIN = PLUGIN or {}
PLUGIN.name = "Role-Based Character Limits"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Overrides default character slot limits based on user group."

-- Role-based slot configuration
ix.config.Add("charLimitGA", 20, "Max characters for owners.", nil, {
    data = {min = 1, max = 20},
    category = PLUGIN.name
})

ix.config.Add("charLimitUA", 10, "Max characters for community managers.", nil, {
    data = {min = 1, max = 10},
    category = PLUGIN.name
})

ix.config.Add("charLimitUStaff", 6, "Max characters for developers.", nil, {
    data = {min = 1, max = 10},
    category = PLUGIN.name
})

ix.config.Add("charLimitStaff", 5, "Max characters for donators and admins.", nil, {
    data = {min = 1, max = 10},
    category = PLUGIN.name
})

ix.config.Add("charLimitDonatorplus", 4, "Max characters for donators and admins.", nil, {
    data = {min = 1, max = 10},
    category = PLUGIN.name
})

ix.config.Add("charLimitDonator", 3, "Max characters for donators and admins.", nil, {
    data = {min = 1, max = 10},
    category = PLUGIN.name
})

ix.config.Add("charLimitDefault", 2, "Max characters for default players.", nil, {
    data = {min = 1, max = 10},
    category = PLUGIN.name
})

-- Get the highest applicable character limit for a client
local function getLimitFor(client)
    local limits = {}

    if client:IsGA() then
        table.insert(limits, ix.config.Get("charLimitGA", 10))
    end

    if client:IsUA() then
        table.insert(limits, ix.config.Get("charLimitUA", 5))
    end

    if client:IsUStaff() then
        table.insert(limits, ix.config.Get("charLimitUStaff", 5))
    end

    if client:IsStaff() then
        table.insert(limits, ix.config.Get("charLimitStaff", 4))
    end

    if client:IsDonatorPlus() then
        table.insert(limits, ix.config.Get("charLimitDonatorplus", 3))
    end

    if client:IsDonator() then
        table.insert(limits, ix.config.Get("charLimitDonator", 3))
    end

    table.insert(limits, ix.config.Get("charLimitDefault", 2))

    return math.max(unpack(limits))
end

function PLUGIN:GetMaxPlayerCharacter(client)
    return getLimitFor(client)
end

ix.util.Include("libs/sh_character.lua", "shared")