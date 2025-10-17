local PLUGIN = PLUGIN

local printedMedalDebugFor = {}
local DEBUG_MEDAL_DISPLAY = false

net.Receive("SyncDisplayedMedals", function()
    local ply = net.ReadEntity()
    local medals = net.ReadTable()

    if IsValid(ply) then
        ply.displayedMedals = medals
    end
end)

local function GetHeadBone(ply)
    local Bip01_Head1 = ply:LookupBone("ValveBiped.Bip01_Head1")
    if Bip01_Head1 then
        return ply:GetBonePosition(Bip01_Head1)
    end

    local Bip01_Head = ply:LookupBone("ValveBiped.Bip01_Head")
    if Bip01_Head then
        return ply:GetBonePosition(Bip01_Head)
    end

    return ply:EyePos()
end

local medalMaterials = {}

function PLUGIN:PostPlayerDraw(ply)
    if not DEBUG_MEDAL_DISPLAY and (not IsValid(ply) or ply == LocalPlayer()) then return end

    local char = ply:GetCharacter()
    if not char or not ply:Alive() then return end

    local displayedMedals = ply.displayedMedals or {}
    if #displayedMedals == 0 then return end

    local alpha = 1.0
    local basePos = GetHeadBone(ply) + Vector(0, 0, 18)
    local facingOffset = ply:GetForward() * 0

    for _, flip in ipairs({1, -1}) do
        local pos = basePos + facingOffset * flip

        --local ang = ply:GetAngles()
        local ang = ply:GetRenderAngles()
        if flip == 1 then
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Right(), 0)
        ang:RotateAroundAxis(ang:Forward(), 90)
        end
        if flip == -1 then
            ang:RotateAroundAxis(ang:Up(), 270)
            ang:RotateAroundAxis(ang:Right(), 0)
            ang:RotateAroundAxis(ang:Forward(), 90)
        end

        local totalMedalWidth = 0
        local medalsToDraw = {}

        for _, medalID in ipairs(displayedMedals) do
            local medalData = PLUGIN.medals and PLUGIN.medals.list and PLUGIN.medals.list[medalID]
            if not medalData then continue end

            local iconPath = medalData.icon
            if not iconPath then continue end

            if not medalMaterials[iconPath] or medalMaterials[iconPath]:IsError() then
                medalMaterials[iconPath] = Material(iconPath)
                if medalMaterials[iconPath]:IsError() then continue end
            end

            table.insert(medalsToDraw, {
                id = medalID,
                data = medalData,
                material = medalMaterials[iconPath]
            })
            totalMedalWidth = totalMedalWidth + (medalData.width or 60) + 4
        end

        if #medalsToDraw == 0 then continue end
        totalMedalWidth = totalMedalWidth - 4

        cam.Start3D2D(pos, ang, 0.1)
            local currentX = -totalMedalWidth / 2
            local startY = -40

            for _, medalEntry in ipairs(medalsToDraw) do
                local medalData = medalEntry.data
                local material = medalEntry.material

                local medalW = medalData.width or 60
                local medalH = medalData.height or 97

                surface.SetDrawColor(255, 255, 255, 255 * alpha)
                surface.SetMaterial(material)
                surface.DrawTexturedRect(currentX, startY, medalW, medalH)

                currentX = currentX + medalW + 4
            end
        cam.End3D2D()
    end
end
