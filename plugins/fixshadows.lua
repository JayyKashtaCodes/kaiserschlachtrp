PLUGIN.name     = 'Disable player shadows.'
PLUGIN.author   = 'Bilwin, Dzhey Kashta'

if CLIENT then
    timer.Create(PLUGIN.name, 10, 0, function()
        for _, client in ipairs(player.GetAll()) do
            client:DrawShadow(false)
        end
    end)
end