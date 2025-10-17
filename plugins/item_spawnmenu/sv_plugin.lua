util.AddNetworkString("ixItemSpawnmenuSpawn")
util.AddNetworkString("ixItemSpawnmenuGive")

ix.log.AddType("ItemSpawned", function(client, item)
    return string.format("%s spawned a '%s' #%d.", client:Name(), item:GetName(), item:GetID())
end)

ix.log.AddType("ItemGiven", function(client, ply, item)
    if client == ply then
        return string.format("%s gave themselves a '%s'.", client:Name(), item)
    end

    return string.format("%s gave %s a '%s'.", client:Name(), ply:Name(), item)
end)

net.Receive("ixItemSpawnmenuSpawn", function(l, ply)
    local uniqueid = net.ReadString()

    if not CAMI.PlayerHasAccess(ply, "Item Spawnmenu - Use Menu", nil) then
        ply:Notify("You do not have access to this menu!")
        return
    end

    if not ix.item.list[uniqueid] then return end

    local tr = util.TraceLine({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 96,
        filter = ply
    })

    local pos = tr.HitPos + tr.HitNormal

    local ang = ply:EyeAngles()
    ang.p = 0
    ang.y = ang.y + 180

    ix.item.Spawn(uniqueid, pos, function(item, ent)
        ix.log.Add(ply, "ItemSpawned", item)
        ply:EmitSound("items/ammo_pickup.wav", 75, 100)
        ent:SetPos(tr.HitPos + (ent:GetPos() - ent:NearestPoint(tr.HitPos - (tr.HitNormal * 512))))

        undo.Create("Item")
            undo.AddEntity(ent)
            undo.SetPlayer(ply)
        undo.Finish()
    end, ang)
end)

local reasons = {
    ["noFit"] = "You do not have enough space in your inventory to add this item!",
    ["invalidItem"] = "The item you tried to spawn does not exist!", -- this should never happen
    ["itemOwned"] = "Error Code 1, contact a developer immediately!", -- https://github.com/NebulousCloud/helix/blob/4d1922407c93828cfd951aec70f89e834ee0f836/gamemode/core/meta/sh_inventory.lua#L809
    ["notAllowed"] = "Error Code 2, contact a developer immediately!", -- https://github.com/NebulousCloud/helix/blob/4d1922407c93828cfd951aec70f89e834ee0f836/gamemode/core/meta/sh_inventory.lua#L813
}

net.Receive("ixItemSpawnmenuGive", function(l, ply)
    local uniqueid = net.ReadString()
    local quantity = net.ReadUInt(4)
    local bool = net.ReadBool()
    local target = ply

    if not CAMI.PlayerHasAccess(ply, "Item Spawnmenu - Use Menu", nil) then
        ply:Notify("You do not have access to this menu!")
        return
    end

    if not uniqueid then return end

    if not ix.item.list[uniqueid] then return end

    if bool == true then
        local tr = ply:GetEyeTraceNoCursor().Entity
        if IsValid(tr) and tr:IsPlayer() then
            target = tr
        else
            ply:Notify("You must be looking at a player to give them an item!")
            return
        end
    end

    local char = target:GetCharacter()

    if not char then return end

    local inv = char:GetInventory()

    if not inv then return end

    local result, reason = inv:Add(uniqueid, quantity > 0 and quantity)
    reason = reasons[reason] or reason

    if not result then
        ply:Notify(reason)
    else
        ix.log.Add(ply, "ItemGiven", target, uniqueid)
        --ply:EmitSound("items/ammo_pickup.wav", 75, 100)
    end
end)