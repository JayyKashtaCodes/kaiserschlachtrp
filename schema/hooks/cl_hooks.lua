-------------------------------------------
--[[ Custom Voicebox ]]--
local isTalking = false

function Schema:PlayerStartVoice(ply)
    if IsValid(g_VoicePanelList) then
        g_VoicePanelList:Remove()
    end

    if ply == LocalPlayer() then
        isTalking = true
    end
end

function Schema:PlayerEndVoice(ply)
    if ply == LocalPlayer() then
        isTalking = false
    end
end

local micIcon = Material("icon16/old_mic.png")

function Schema:HUDPaint()
    if isTalking then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(micIcon)
        surface.DrawTexturedRect(50, ScrH() - 100, 32, 32)
    end
end

--[[ END ]]--
-------------------------------------------
--[[ Staff Tag
function Schema:PostPlayerDraw(ply)
    if not IsValid(ply) or not ply:Alive() then return end

    local char = ply:GetCharacter()
    if not char or char:GetFaction() ~= FACTION_STAFF then return end

    if ply == LocalPlayer() then return end

    if LocalPlayer():GetPos():DistToSqr(ply:GetPos()) > (500 * 500) then return end

    local pos = ply:EyePos() + Vector(0, 0, 15)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        draw.SimpleTextOutlined(
            "STAFF",
            "DermaLarge",
            0, 0,
            FACTION.Get and FACTION.Get(FACTION_STAFF).color or Color(137, 207, 240),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            1, Color(0,0,0,200)
        )
    cam.End3D2D()
end
 END ]]--
-------------------------------------------
--[[ Play Sound Netstream2 Hook ]]--
--[[
netstream.Hook("PlaySound", function(sound)
	surface.PlaySound(sound)
end)
]]--
--[[ END ]]--
-------------------------------------------