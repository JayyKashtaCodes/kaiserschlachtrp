local PLUGIN = PLUGIN
PLUGIN.name = "Lantern Item and Glow"
PLUGIN.author = "Dzhey Kashta, Riggs, Inspired by SleepyMode"
PLUGIN.description = "Lanterns with persistent oil storage, burning over time, and refillable with oil bottles."

-- ########################
-- ## Flashlight Toggle
-- ########################
function PLUGIN:PlayerSwitchFlashlight(client, bEnabled)
    local character = client:GetCharacter()
    local inventory = character and character:GetInventory()
    if not inventory then return false end

    local lantern = inventory:HasItem("lantern")
    if not lantern then return false end

    if (client:GetMoveType() == MOVETYPE_NOCLIP) then
        return false
    end

    local hasFuel = lantern:GetData("oil", 0) > 0
    local isOn = client:GetNetVar("ixFlashlight", false)

    -- Trying to turn on but no fuel
    if not isOn and not hasFuel then
        client:Notify("The lantern is out of oil.")
        return false
    end

    local newStatus = not isOn
    client:SetNetVar("ixFlashlight", newStatus)

    if newStatus then
        client:EmitSound("sfx/latern_on.wav", 60, 100)
        self:StartBurningOil(client, lantern)
    else
        client:EmitSound("sfx/latern_off.wav", 60, 70)
        self:StopBurningOil(client)
    end

    return false
end

-- ########################
-- ## Client Rendering
-- ########################
if (CLIENT) then
    function PLUGIN:PostDrawOpaqueRenderables()
        local ply = LocalPlayer()
        if not ply:GetNetVar("ixFlashlight") then return end

        -- Get waist position from pelvis bone
        local boneIndex = ply:LookupBone("ValveBiped.Bip01_Pelvis")
        local lightPos

        if boneIndex then
            local bonePos, boneAng = ply:GetBonePosition(boneIndex)
            if bonePos then
                -- Offset a bit forward to avoid clipping into body
                lightPos = bonePos + ply:GetForward() * 6 + ply:GetRight() * 2
            end
        end

        -- Fallback: if bone not found, just use shoot pos
        lightPos = lightPos or (ply:GetShootPos() + ply:GetForward() * 10)

        local lanternLight = DynamicLight(ply:EntIndex())
        if (lanternLight) then
            lanternLight.pos = lightPos
            
            local brightness = 0.8 + math.sin(CurTime() * 12) * 0.2
            lanternLight.r = 255 * brightness
            lanternLight.g = 100 * brightness
            lanternLight.b = 20  * brightness
            lanternLight.Size   = 340 + math.random(-10, 10)

            lanternLight.Decay = 350
            lanternLight.Size = 300

            lanternLight.DieTime = CurTime() + 1
            lanternLight.Style = 1 -- flicker
        end
    end
end

-- ########################
-- ## Server Hooks
-- ########################
if (SERVER) then
    function PLUGIN:Initialize(ply)
        ply:SetNetVar("ixFlashlight", false)
    end

    function PLUGIN:PlayerSpawn(ply)
        ply:SetNetVar("ixFlashlight", false)
    end

    function PLUGIN:CharacterLoaded(character)
        local ply = character:GetPlayer()
        ply:SetNetVar("ixFlashlight", false)
    end

    -- Burn oil while lantern is on
    function PLUGIN:StartBurningOil(client, lantern)
        local timerID = "LanternBurn_" .. client:SteamID64()
        local burnInterval = lantern.burnInterval or 10
        timer.Create(timerID, burnInterval, 0, function()
            if not IsValid(client) or not client:GetCharacter() then
                timer.Remove(timerID)
                return
            end
            if not client:GetNetVar("ixFlashlight", false) then
                timer.Remove(timerID)
                return
            end
            if not lantern:BurnOil() then
                client:Notify("Your lantern has run out of oil!")
                client:SetNetVar("ixFlashlight", false)
                timer.Remove(timerID)
            end
        end)
    end

    function PLUGIN:StopBurningOil(client)
        timer.Remove("LanternBurn_" .. client:SteamID64())
    end
end
