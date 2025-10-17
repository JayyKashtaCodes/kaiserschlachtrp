local PLUGIN = PLUGIN

PLUGIN.name = "Auto Server Restart"
PLUGIN.description = "Restarts the server every x amount of minutes with notifications."
PLUGIN.author = "Dzhey Kashta"

ix.config.Add("restartTime", 720, "Time in minutes before the server restarts. (Default: 12 Hours)", nil, {
    data = {min = 60, max = 5000},
    category = "Server"
})

ix.config.Add("autoRestartEnabled", true, "Toggle auto server restart on/off.", nil, {
    category = "Server"
})

local function notifyPlayers(timeLeft, isSeconds)
    local timeUnit = isSeconds and "seconds" or "minutes"
    for _, player in ipairs(player.GetAll()) do
        player:Notify("Server will restart in " .. timeLeft .. " " .. timeUnit .. ".")
    end
end

local function saveAllCharacters()
    for _, player in ipairs(player.GetAll()) do
        char = player:GetCharacter()
        if isfunction(char.Save) then char:Save() end
        if isfunction(char.SaveData) then char:SaveData() end
    end
end

local function startCountdown(timeLeft)
    if timeLeft == 10 or timeLeft == 5 or timeLeft == 1 then
        print("[AutoRestart] Countdown started with " .. timeLeft .. " minutes.")
        notifyPlayers(timeLeft, false)
    elseif timeLeft == 0 then
        for i = 10, 1, -1 do
            timer.Simple(11 - i, function()
                notifyPlayers(i, true)
            end)
        end

        timer.Simple(11, function()
            saveAllCharacters()
            RunConsoleCommand("_restart")
        end)
    end

    if timeLeft > 0 then
        timer.Simple(60, function()
            startCountdown(timeLeft - 1)
        end)
    end
end

function PLUGIN:LoadData()
    local restartTime = ix.config.Get("restartTime")
    local autoRestartEnabled = ix.config.Get("autoRestartEnabled")

    if autoRestartEnabled then
        startCountdown(restartTime)
        print("[AutoRestart] Timer started with " .. restartTime .. " minutes.")
    end
end

ix.command.Add("ServerRestart", {
    description = "Manually trigger the server restart.",
    superAdminOnly = true,
    OnRun = function(self, client)
        notifyPlayers(1, false)
        timer.Simple(1, function()
            notifyPlayers(10, true)
            for i = 9, 1, -1 do
                timer.Simple(10 - i, function()
                    notifyPlayers(i, true)
                end)
            end
            timer.Simple(11, function()
                saveAllCharacters()
                --RunConsoleCommand("changelevel", game.GetMap())
                RunConsoleCommand("_restart")
            end)
        end)
    end
})
