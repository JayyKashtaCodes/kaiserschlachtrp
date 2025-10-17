local PLUGIN = PLUGIN

function PLUGIN:PlayerInitialSpawn(ply)
    timer.Simple(3, function()
        if IsValid(ply) and ply:GetCharacter() then
            local displayed = ply:GetCharacter():GetData("displayedMedals", {})

            net.Start("SyncDisplayedMedals")
                net.WriteEntity(ply)
                net.WriteTable(displayed)
            net.Broadcast()
        end
    end)
end
