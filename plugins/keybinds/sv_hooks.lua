local PLUGIN = PLUGIN

local raiseCooldown = 0

function PLUGIN:KeyPress(client, key)
    if (key == IN_RELOAD and client:KeyDown(IN_USE) and client:KeyDown(IN_SPEED)) then return end
    if (key == IN_RELOAD and client:KeyDown(IN_SPEED)) then
        local lastToggle = client._lastRaiseToggle or 0
        if (CurTime() - lastToggle > raiseCooldown) then
            client._lastRaiseToggle = CurTime()
            if (IsValid(client)) then
                client:ToggleWepRaised() 
            end
        end
    end
end
