local PLUGIN = PLUGIN

PLUGIN.name = "Meth"
PLUGIN.description = "Walter White moment"
PLUGIN.author = "Riggs, Dzhey White"

ix.config.Add("highTime", 90, "How long Meth last's.", nil, {
    data = {min = 0, max = 600},
    category = "Drugs"
})

if (SERVER) then
    -- Reset the "high" state and related effects
    local function resetHigh(char, ply)
        if char and char:GetData("ixHigh") then
            char:SetData("ixHigh", nil)
            char:SetData("ixHighTimer", nil)

            if IsValid(ply) then
                -- Restore original movement speeds
                local stamina = char:GetAttribute("stm", 0) -- Default to 0
                ply:SetRunSpeed(ix.config.Get("runSpeed") + stamina)
                ply:SetWalkSpeed(ix.config.Get("walkSpeed"))
            end
        end
    end

    -- Update the "high" timer and clean up effects when expired
    local function updateHighTimer(ply)
        local char = ply:GetCharacter()
        if not (char and char:GetData("ixHigh")) then return end

        local highTimer = char:GetData("ixHighTimer", 0)
        if highTimer > 0 then
            char:SetData("ixHighTimer", highTimer - 1)
        else
            resetHigh(char, ply)
        end
    end

    function PLUGIN:PlayerLoadedCharacter(ply, char, oldChar)
        if oldChar then resetHigh(oldChar, ply) end

        if char and char:GetData("ixHigh") then
            -- Start the persistent effect timer
            timer.Create("HighEffectTimer_" .. ply:SteamID(), 1, 0, function()
                if not IsValid(ply) or not ply:GetCharacter() then
                    timer.Remove("HighEffectTimer_" .. ply:SteamID())
                    return
                end
                updateHighTimer(ply)
            end)
        end
    end

    function PLUGIN:DoPlayerDeath(ply)
        resetHigh(ply:GetCharacter(), ply)
    end

    function PLUGIN:StartCommand(ply, cmd)
        if not (ply:IsValid() and ply:Alive() and ply:GetCharacter() and ply:GetCharacter():GetData("ixHigh")) then
            return
        end

        -- Prevent stamina drain
        ply:SetLocalVar("stm", 100)

        -- Add random jitter to movement
        local jitterStrength = 12
        local jitterForward = math.random(-jitterStrength, jitterStrength)
        local jitterSide = math.random(-jitterStrength, jitterStrength)

        cmd:SetForwardMove(cmd:GetForwardMove() + jitterForward)
        cmd:SetSideMove(cmd:GetSideMove() + jitterSide)
    end

    function PLUGIN:Think()
        for _, ply in ipairs(player.GetAll()) do
            local char = ply:GetCharacter()
            if char and char:GetData("ixHigh") then
                -- Get the stamina attribute, defaulting to 0 if missing
                local stamina = char:GetAttribute("stm", 0)

                -- Apply speed boost using constant base values
                local boostedRunSpeed = (ix.config.Get("runSpeed") + stamina) * 1.75
                local boostedWalkSpeed = (ix.config.Get("walkSpeed") + stamina) * 1.75

                ply:SetRunSpeed(boostedRunSpeed)
                ply:SetWalkSpeed(boostedWalkSpeed)
            else
                -- Restore original movement speeds using constant base values
                local stamina = char and char:GetAttribute("stm", 0) or 0
                ply:SetRunSpeed(ix.config.Get("runSpeed") + stamina)
                ply:SetWalkSpeed(ix.config.Get("walkSpeed"))
            end
        end
    end    

    function PLUGIN:PlayerDisconnected(ply)
        local char = ply:GetCharacter()
        if char and char:GetData("ixHigh") then
            -- Stop the timer on disconnect
            timer.Remove("HighEffectTimer_" .. ply:SteamID())
        end
    end
end

if (CLIENT) then
    function PLUGIN:PopulateCharacterInfo(ply, char, tooltip)
        if (char:GetData("ixHigh")) then
            local panel = tooltip:AddRowAfter("description", "methstate")
            panel:SetText("Their eyes are flared up")
            panel:SizeToContents()
        end
    end

    function PLUGIN:HUDPaint()
        local ply, char = LocalPlayer(), LocalPlayer():GetCharacter()
        if not (ply:IsValid() and ply:Alive() and char and char:GetData("ixHigh")) then return end

        ply.ixMethSound = ply.ixMethSound or 0
        if ply.ixMethSound < CurTime() then
            ply:EmitSound("interlock/ambient/combine/combine_tech_spaces_0" .. math.random(1, 7) .. ".ogg", nil, math.random(100, 200))
            ply.ixMethSound = CurTime() + math.random(1, 3)
        end
    end

    function PLUGIN:CalcView(ply, pos, ang, fov)
        local char = ply:GetCharacter()
        if not (char and char:GetData("ixHigh")) then return end

        local view = {
            origin = pos,
            angles = ang + Angle(math.sin(RealTime() * 5) * 3, math.cos(RealTime() * 5) * 3, 0),
            fov = fov + math.sin(RealTime() * 5) * 2 + 25
        }
        return view
    end

    function PLUGIN:RenderScreenspaceEffects()
        local ply, char = LocalPlayer(), LocalPlayer():GetCharacter()
        if not (char and char:GetData("ixHigh")) then return end
    
        -- Intensified color modification
        local fade = math.abs(math.sin(CurTime() * 2)) -- This creates dynamic pulsing
        DrawColorModify({
            ["$pp_colour_colour"] = 2.0 + fade, -- Boosted color saturation (default was 1.5)
            ["$pp_colour_brightness"] = -0.1, -- Keeps brightness low
            ["$pp_colour_contrast"] = 1.5, -- Increased contrast for a sharper effect
            ["$pp_colour_mulr"] = math.sin(CurTime() * 2) * fade * 3, -- Stronger red pulse
            ["$pp_colour_mulg"] = math.sin(CurTime() * 2 + 2) * fade * 3, -- Stronger green pulse
            ["$pp_colour_mulb"] = math.sin(CurTime() * 2 + 4) * fade * 3, -- Stronger blue pulse
        })
    
        -- Enhanced blackout effect
        local blackoutAlpha = math.Clamp(math.sin(CurTime() * 1.2)^2 * 150 + 100, 160, 210)
        surface.SetDrawColor(0, 0, 0, blackoutAlpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    
        -- Enhanced motion blur
        DrawMotionBlur(0.2, math.abs(math.sin(CurTime() * 3)) * 0.7 + 0.2, 0.04)
    end    
end
