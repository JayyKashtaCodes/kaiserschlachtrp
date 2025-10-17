--[[
function Schema:PlayerFootstep(ply, pos, foot, sound, volume)
    local pitch = math.random(90.0, 110.0)
    local newVolume = volume / 1
	local newSound = ""

    if ( ply:KeyDown(IN_SPEED) ) then
        newVolume = volume * 1
    end

    if not ( ply:WaterLevel() == 0 ) then
        newSound = "ambient/water/water_splash"..math.random(1,3)..".wav"
        sound = "ambient/water/rain_drip"..math.random(1,4)..".wav"
    end

    if ( SERVER ) then
        ply:EmitSound(newSound, 70, pitch, newVolume)
        ply:EmitSound(sound, 70, pitch, newVolume)
    end

    return true
end
]]--
-------------------------------------------
--[[ Content Loading ]]--
function Schema:Initialize()
    local ws = engine.GetAddons()
    for _, v in ipairs(ws) do
        resource.AddWorkshop(v.wsid)
    end
end
--[[ END ]]--
-------------------------------------------
--[[ Stop Staff Changing Rank to Donator. ]]--
function Schema:PlayerSay(client, text)
    -- Normalize the text for comparison
    local lowerText = string.lower(text)

    if lowerText == "!checkrank" then
        if client:IsStaff() then
            client:Notify("You cannot use this command because you are staff.")
            return ""
        end
    end

    if lowerText == "!menu" then
        if !client:IsStaff() then
            client:Notify("Fuck Off...")
            return ""
        end
    end
end
--[[ END ]]--
-------------------------------------------
--[[ Door Shadow Fix ]]--
function Schema:OnEntityCreated(ent)
    if ( IsValid(ent) ) then
        if ( ent:GetClass() == "prop_door_rotating" ) then
            ent:DrawShadow(false)
        elseif ( ent:GetClass() == "prop_ragdoll" ) then
            ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
        end
    end
end
--[[ END ]]--
-------------------------------------------
--[[ Anti-Crash ]]--
function Schema:ShouldCollide(a, b)
    if a:GetClass() == 'ix_item' && b:GetClass() == 'ix_item' then
        return false
    end
end
--[[ END ]]--
-------------------------------------------
--[[ Simphy Fix ]]--
function Schema:simfphysPhysicsCollide()
    return true
end
--[[ END ]]--
-------------------------------------------
--[[ Player Class ]]--
function Schema:CanPlayerJoinClass()
    return false
end
--[[ END ]]--
-------------------------------------------
--[[ Can Drive ]]--
function Schema:CanDrive()
	return false
end
-------------------------------------------
--[[ Anti-bHop ]]--
--[[
function Schema:OnPlayerHitGround(client)
    local vel = client:GetVelocity()
    client:SetVelocity( Vector( - ( vel.x * 0.45 ), - ( vel.y * 0.45 ), 0) )
end
]]--
--[[ END ]]--
-------------------------------------------
--[[ Auto Recognize ]]--
function Schema:IsCharacterRecognized(character)
    return character:GetFaction() == FACTION_STAFF
end
--[[ END ]]--
-------------------------------------------
--[[ Menu Binds Bypass ]]--
function Schema:PlayerBindPress(client, bind, pressed)
    if not pressed or not IsValid(client) then return end
    
    if bind == "+zoom" then
        return true
    end
    

    -- Handle F1 (Show Help)
    if bind == "gm_showhelp" then
        if client:GetCharacter() then
            vgui.Create("ixCustomMenu") -- Open the Helix Menu
        end
        return true
    end
end

hook.Add("ScoreboardShow", "OpenCustomScoreboard", function()
    if LocalPlayer():GetCharacter() then
        if not IsValid(Schema.CustomScoreboard) then
            Schema.CustomScoreboard = vgui.Create("ixCustomTabScoreboard")
        end
        Schema.CustomScoreboard:SetVisible(true)
        Schema.CustomScoreboard:MakePopup()
        gui.EnableScreenClicker(true)
    end
    return true
end)

hook.Add("ScoreboardHide", "CloseCustomScoreboard", function()
    if LocalPlayer():GetCharacter() and IsValid(Schema.CustomScoreboard) then
        Schema.CustomScoreboard:SetVisible(false)
        gui.EnableScreenClicker(false)
    end
    return true
end)
--[[ END ]]--
-------------------------------------------