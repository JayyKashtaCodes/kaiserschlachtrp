local PLUGIN = PLUGIN or {}

ix.config.Add("primaryNeedsDelay", 120, "How long does it take to calculate the character's primary needs? (In seconds)", function(oldValue, newValue)
    if (SERVER) then
        for _, pl in ipairs(player.GetAll()) do
            if IsValid(pl) and pl:GetCharacter() then
                if timer.Exists("ixPrimaryNeeds." .. pl:AccountID()) then timer.Remove("ixPrimaryNeeds." .. pl:AccountID()) end
                PLUGIN:CreateNeedsTimer(pl, pl:GetCharacter())
            end
        end
    end
end, {data = {min = 1, max = 1000}, category = PLUGIN.name})

ix.config.Add("deathCountdown", 300, "How long will it take for a character to die if starving", nil, {
    data = {min = 0, max = 1000},
    category = PLUGIN.name
})

ix.config.Add("hungerConsume", 3, "How much hunger will be taken from the character", nil, {
    data = {min = 0, max = 100},
    category = PLUGIN.name
})

ix.config.Add("thirstConsume", 2, "How much thirst will be taken from the character", nil, {
    data = {min = 0, max = 100},
    category = PLUGIN.name
})

ix.config.Add("drunkennessDecayAmount", 1, "The amount of drunkenness to decay by each tick.", nil, {
    data = {min = 1, max = 10},
    category = PLUGIN.name
})

ix.config.Add("unconsciousDuration", 60, "Duration of unconsciousness when drunkenness hits 100 (in seconds)", nil, {
    data = {min = 1, max = 600},
    category = PLUGIN.name
})

ix.config.Add("wakeupDrunkenness", 30, "How much Drunkenness remains when waking up.", nil, {
    data = {min = 0, max = 100},
    category = PLUGIN.name
})
