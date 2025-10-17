local PLUGIN = PLUGIN or {}

PLUGIN.name = "Holstered Weapons"
PLUGIN.author = "Black Tea (converted by Dzhey Kashta)"
PLUGIN.description = "Displays holstered weapons on players."

ix.config.Add("showHolsteredWeps", true, "Should holstered weapons be visible on characters?", nil, {
    category = "Appearance"
})

HOLSTER_DRAWINFO = HOLSTER_DRAWINFO or {}

HOLSTER_DRAWINFO["weapon_pistol"] = {
    pos = Vector(4, -8, -1),
    ang = Angle(0, 90, 0),
    bone = "ValveBiped.Bip01_Pelvis",
    model = "models/weapons/w_pistol.mdl"
}


if (CLIENT) then
    function PLUGIN:PostPlayerDraw(client)
        if not ix.config.Get("showHolsteredWeps", true) then return end
        if not IsValid(client) or not client:GetCharacter() then return end
        if client == LocalPlayer() and not client:ShouldDrawLocalPlayer() then return end

        local activeWep = client:GetActiveWeapon()
        local activeClass = IsValid(activeWep) and activeWep:GetClass():lower() or ""

        client.holsteredWeapons = client.holsteredWeapons or {}

        -- Remove outdated holstered models
        for class, modelEnt in pairs(client.holsteredWeapons) do
            if not IsValid(client:GetWeapon(class)) then
                modelEnt:Remove()
                client.holsteredWeapons[class] = nil
            end
        end

        for _, weapon in ipairs(client:GetWeapons()) do
            local class = weapon:GetClass():lower()
            local drawInfo = HOLSTER_DRAWINFO[class]
            if not drawInfo or not drawInfo.model then continue end

            if not IsValid(client.holsteredWeapons[class]) then
                local modelEnt = ClientsideModel(drawInfo.model, RENDERGROUP_TRANSLUCENT)
                modelEnt:SetNoDraw(true)
                client.holsteredWeapons[class] = modelEnt
            end

            local modelEnt = client.holsteredWeapons[class]
            local boneId = client:LookupBone(drawInfo.bone)
            if not boneId then continue end

            local bonePos, boneAng = client:GetBonePosition(boneId)
            if not bonePos or not boneAng then continue end

            if activeClass ~= class and IsValid(modelEnt) then
                boneAng:RotateAroundAxis(boneAng:Right(), drawInfo.ang[1])
                boneAng:RotateAroundAxis(boneAng:Up(), drawInfo.ang[2])
                boneAng:RotateAroundAxis(boneAng:Forward(), drawInfo.ang[3])

                local offset =
                    drawInfo.pos[1] * boneAng:Right() +
                    drawInfo.pos[2] * boneAng:Forward() +
                    drawInfo.pos[3] * boneAng:Up()

                modelEnt:SetRenderOrigin(bonePos + offset)
                modelEnt:SetRenderAngles(boneAng)
                modelEnt:DrawModel()
            end
        end
    end

    function PLUGIN:EntityRemoved(entity)
        if entity.holsteredWeapons then
            for _, modelEnt in pairs(entity.holsteredWeapons) do
                modelEnt:Remove()
            end
        end
    end
end
