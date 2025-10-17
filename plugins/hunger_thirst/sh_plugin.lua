local PLUGIN = PLUGIN or {}

PLUGIN.name = "Hunger & Thirst"
PLUGIN.description = "Adds Hunger, Thirst, and Alcoholism."
PLUGIN.author = "Dzhey Kashta"

ix.util.Include("sh_config.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("sh_meta.lua")
ix.util.Include("sh_commands.lua")

if CLIENT then
    local function DrawBlur(strength)
        local blur = Material("pp/blurscreen")
        surface.SetMaterial(blur)
        surface.SetDrawColor(255, 255, 255)

        local scrW, scrH = ScrW(), ScrH()
        local x, y = 0, 0

        for i = 1, 3 do
            blur:SetFloat("$blur", (i / 3) * (strength or 1))
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
        end
    end

    function PLUGIN:RenderScreenspaceEffects()
        local client = LocalPlayer()
        local drunkenness = client:GetLocalVar("drunkenness", 0)
    
        if drunkenness <= 0 then
            return
        end
    
        -- Scale the blur effect directly with drunkenness level
        local blurStrength = drunkenness / 100
        DrawBlur(blurStrength * 5)
    
        -- Add wobble effect scaled evenly with drunkenness
        local wobbleIntensity = (drunkenness / 100) * 0.2 -- Scale wobble directly with drunkenness
        local angleOffset = Angle(
            math.sin(CurTime() * 2) * wobbleIntensity, -- Pitch wobble
            math.cos(CurTime() * 2) * wobbleIntensity, -- Yaw wobble
            0 -- No roll wobble
        )
        client:SetEyeAngles(client:EyeAngles() + angleOffset)
    
        -- Enhanced blackout effect with breathing fade, scaling directly with drunkenness
        local timeFactor = CurTime() * 2 -- Adjust the multiplier for breathing speed
        local fadeOscillation = math.abs(math.sin(timeFactor)) -- Oscillates between 0 and 1
        local blackoutAlpha = math.Clamp((drunkenness / 100) * 255 * fadeOscillation, 0, 255)
    
        surface.SetDrawColor(0, 0, 0, blackoutAlpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end    

    hook.Add("RenderScreenspaceEffects", "DrunkBlurEffect", function()
        PLUGIN:RenderScreenspaceEffects()
    end)

    ix.bar.Add(function()
        return math.max(LocalPlayer():GetLocalVar("hunger", 0) / 100, 0)
    end, Color(255, 140, 0), nil, "hunger", "hudHunger")

    ix.bar.Add(function()
        return math.max(LocalPlayer():GetLocalVar("thirst", 0) / 100, 0)
    end, Color(0, 255, 255), nil, "thirst", "hudThirst")

    ix.bar.Add(function()
        return math.max(LocalPlayer():GetLocalVar("drunkenness", 0) / 100, 0)
    end, Color(128, 0, 128), nil, "drunkenness", "hudDrunkenness")
end
