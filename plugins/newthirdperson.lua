local PLUGIN = PLUGIN

PLUGIN.name = "Thirdperson"
PLUGIN.author = "Riggs"
PLUGIN.description = "Enables third person camera usage."


if ( SERVER ) then
    ix.plugin.SetUnloaded("thirdperson", true)
elseif ( CLIENT ) then
    if ( IsValid(ix.gui.pluginManager) ) then
        ix.gui.pluginManager:UpdatePlugin("thirdperson", false)
    end
end


ix.config.Add("thirdperson", false, "Allow Thirdperson in the server.", nil, {
    category = "server"
})

if ( CLIENT ) then
    ix.option.Add("thirdpersonEnabled", ix.type.bool, false, {
        category = "thirdperson",
        hidden = isHidden,
        OnChanged = function(oldValue, value)
            hook.Run("ThirdPersonToggled", oldValue, value)
        end
    })

    ix.option.Add("thirdpersonVertical", ix.type.number, 0, {
        category = "thirdperson", min = 0, max = 30,
        hidden = isHidden
    })

    ix.option.Add("thirdpersonHorizontal", ix.type.number, 0, {
        category = "thirdperson", min = -30, max = 30,
        hidden = isHidden
    })

    ix.option.Add("thirdpersonDistance", ix.type.number, 50, {
        category = "thirdperson", min = 0, max = 100,
        hidden = isHidden
    })

    ix.option.Add("thirdpersonOrbitYaw", ix.type.number, 0, {
        category = "thirdperson", min = 0, max = 180,
        hidden = isHidden
    })

    concommand.Add("ix_togglethirdperson", function()
        local bEnabled = !ix.option.Get("thirdpersonEnabled", false)
        ix.option.Set("thirdpersonEnabled", bEnabled)
    end)

    function PLUGIN:ShouldDrawLocalPlayer(ply)
        if ( IsValid(ix.gui.characterMenu) and not ix.gui.characterMenu:IsClosing() ) then return end
        if ( ply.ixRagdoll ) then return end
        if ( ply.ixIntroState ) then return end
        if ( ply.ixAJSceneState ) then return end
        if ( ix.option.Get("thirdpersonEnabled") ) then
            return true
        end

        if ( Schema:IsViewingCamera() ) then
            return true
        end

        if ( ply:InVehicle() ) then
            return false
        end
    end

    local headPosLerp
    local headAngleLerp

    function PLUGIN:CalcView(ply, origin, angles, fov)
        if ( IsValid(ix.gui.characterMenu) and not ix.gui.characterMenu:IsClosing() ) then return end
        if ( ply.ixRagdoll or ply.ixIntroState ) then return end
        if ( ply:InVehicle() ) then return end
        if ( Schema:IsViewingCamera() ) then return end

        local frameTime = RealFrameTime()
        local view = {
            origin = origin,
            angles = angles,
            fov = fov
        }

        local thirdpersonEnabled = ix.option.Get("thirdpersonEnabled", false)
        if not thirdpersonEnabled then
            headPosLerp = origin
            headAngleLerp = angles
            return
        end

        if not headPosLerp then
            headPosLerp = origin
        end

        if not headAngleLerp then
            headAngleLerp = angles
        end

        if IsValid(ply) and ply:Alive() and ply:GetMoveType() != MOVETYPE_NOCLIP and not ply.ixRagdoll then
            local distance = ix.option.Get("thirdpersonDistance", 50)
            local horizontal = ix.option.Get("thirdpersonHorizontal", 0)
            local vertical = ix.option.Get("thirdpersonVertical", 0)
            local orbitYaw = ix.option.Get("thirdpersonOrbitYaw", 0)

            -- Create rotated camera angles
            local rotatedAngles = Angle(angles.p, angles.y, angles.r)
            rotatedAngles:RotateAroundAxis(rotatedAngles:Up(), orbitYaw)

            -- Calculate new camera origin with rotated orientation
            local newOrigin = ply:EyePos()
                - (rotatedAngles:Forward() * distance)
                + (rotatedAngles:Right() * horizontal)
                + (rotatedAngles:Up() * vertical)

            headPosLerp = LerpVector(frameTime * 10, headPosLerp, newOrigin)
            headAngleLerp = LerpAngle(frameTime * 10, headAngleLerp, rotatedAngles)

            view.origin = headPosLerp
            view.angles = headAngleLerp

            if ply:LookupBone("ValveBiped.Bip01_Head1") then
                ply:ManipulateBoneScale(ply:LookupBone("ValveBiped.Bip01_Head1"), Vector(1, 1, 1))
            end

            return view
        end
    end
end
