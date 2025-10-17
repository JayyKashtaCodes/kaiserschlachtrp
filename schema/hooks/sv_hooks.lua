-------------------------------------------
--[[ Perma Body Groups ]]--
function Schema:SetCharBodygroup(ply, index, value)
    if ( !IsValid(ply) ) then return end

    local char = ply:GetCharacter()
    if ( !char ) then return end

    index = index or 1
    value = value or 1

    local groupsData = char:GetData("groups", {})
    groupsData[index] = value

    char:SetData("groups", groupsData)
    ply:SetBodygroup(index, value)
end
--[[ END ]]--
-------------------------------------------
--[[ Staff Faction Shift + E to Lock Toggle ]]--
function Schema:PlayerUse(client, entity)
    if ((client:Team() == FACTION_STAFF) and entity:IsDoor() and IsValid(entity.ixLock) and client:KeyDown(IN_SPEED)) then
        entity.ixLock:Toggle(client)
        return false
	end
end
--[[ END ]]--
-------------------------------------------
--[[ Action Block ]]--
-- Block attempts to start a new stared/timed action
hook.Add("PlayerStartAction", "SchemaBusyLock", function(ply, actionName)
    if Schema:IsBusy(ply) then
        ply:NotifyLocalized("You are already " .. Schema:IsBusy(ply) .. ".")
        return false -- cancel the new action
    end

    Schema:SetBusy(ply, actionName)
end)

-- Clear when any action completes
hook.Add("PlayerFinishAction", "SchemaBusyLockClear", function(ply, actionName, success)
    Schema:SetBusy(ply, false)
end)

-- Also clear if they’re interrupted by death, stun, etc.
hook.Add("PlayerDisconnected", "SchemaBusyLockCleanup", function(ply)
    Schema:SetBusy(ply, false)
end)
--[[ END ]]--
-------------------------------------------
--[[ Player Footstep sound ]]--
--[[
function Schema:EntityEmitSound(data)
    local ent = data.Entity
    if not IsValid(ent) or not ent:IsPlayer() then return end

    if ( data.SoundName:find("player/footsteps") ) then
        return false
    end
end
]]--
--[[ END ]]--
-------------------------------------------
--[[ Anti-Crash ]]--
function Schema:OnItemSpawned(ent)
    ent:SetCustomCollisionCheck(true)
end
--[[ END ]]--
-------------------------------------------
--[[ Door Noises ]]--
function Schema:PlayerUseDoor(ply, door)
    if door:GetSaveTable().m_bLocked then
        door:EmitSound("doors/door_locked2.wav")
    else
        if not door:GetSaveTable().soundname or door:GetSaveTable().soundname == "" then
            door:EmitSound("doors/default_move.wav")
        end
    end
end
--[[ END ]]--
-------------------------------------------
--[[ Player Security ]]--
function Schema:CanPlayerSpawnContainer()
    --return false
end

function Schema:PlayerSpray(ply)
    return true
end
--[[ END ]]--
-------------------------------------------
--[[ Staff Faction GodMode + Insta Headshot ]]--
function Schema:EntityTakeDamage(target, dmginfo)
    if (not IsValid(target) or not target:IsPlayer()) then return end

    -- === Staff faction godmode ===
    local char = target:GetCharacter()
    if char then
        local faction = ix.faction.indices[char:GetFaction()]
        if faction and faction.godModeEnabled then
            return true
        end
    end

    -- === Headshot detection via bone position ===
    local dt = dmginfo:GetDamageType()
    local isBullet = dmginfo:IsBulletDamage() or bit.band(dt, DMG_BUCKSHOT) ~= 0
    if (not isBullet) then return end

    local dmgPos = dmginfo:GetDamagePosition()
    local headBone = target:LookupBone("ValveBiped.Bip01_Head1")
    if not headBone then return end

    local headPos = target:GetBonePosition(headBone)

    -- Allow a small radius around the head position
    if headPos and dmgPos:DistToSqr(headPos) <= (15 * 15) then
        dmginfo:SetDamage(target:Health())
    end
end
--[[ END ]]--
-------------------------------------------