AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Universal Ammo Crate"
ENT.Category = "Helix - Universal Ammo"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
    self:SetModel("models/hts/ww2ns/props/ger/ger_sfh18_ammo_crate_dirty_01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.lastUsed = {}
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local char = activator:GetCharacter()
    if not char then return end

    local cooldown = 2
    local steamID = activator:SteamID()
    local now = CurTime()

    if self.lastUsed[steamID] and now < self.lastUsed[steamID] + cooldown then
        return
    end
    self.lastUsed[steamID] = now

    local gaveAmmo = false

    for _, weapon in ipairs(activator:GetWeapons()) do
        if weapon.Base and string.find(weapon.Base, "tfa") then
            local ammoType = weapon:GetPrimaryAmmoType()
            if ammoType and ammoType ~= -1 then
                local currentAmmo = activator:GetAmmoCount(ammoType)
                local maxAmmo = weapon.Primary and weapon.Primary.ClipSize and weapon.Primary.ClipSize * 3 or 90

                if currentAmmo < maxAmmo then
                    activator:GiveAmmo(maxAmmo - currentAmmo, ammoType, true)
                    gaveAmmo = true
                end
            end
        end
    end

    if gaveAmmo then
        activator:EmitSound("items/ammo_pickup.wav")
        if ix and ix.util then
            ix.util.Notify("You refilled your ammo.", activator)
        end
    else
        if ix and ix.util then
            ix.util.Notify("You don't need ammo right now.", activator)
        end
    end
end

-- Render floating label
if CLIENT then
    
    surface.CreateFont("AmmoBoxBig", {
        font = "Open Sans Light",
        size = 64,
        weight = 800,
        antialias = true,
        shadow = true,
    })

    
    function ENT:Draw()
        self:DrawModel()

        local pos = self:GetPos() + Vector(0, 0, 25)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

        cam.Start3D2D(pos, ang, 0.1)
            surface.SetFont("AmmoBoxBig")
            local text = "Universal Ammo Box"
            local textW, textH = surface.GetTextSize(text)

            -- Draw a black rounded box behind the text
            draw.RoundedBox(6, -textW / 2 - 10, -textH / 2 - 6, textW + 20, textH + 12, Color(0, 0, 0, 200))

            -- Draw the actual text
            draw.SimpleTextOutlined(
                text,
                "AmmoBoxBig",
                0, 0,
                color_white,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                1,
                color_black
            )
        cam.End3D2D()
    end
end

-- Restrict tool usage
function ENT:CanTool(ply, trace, tool)
    if not ply:IsUA() then
        if SERVER then
            ply:ChatPrint("You do not have permission to use tools on this entity.")
        end
        return false
    end
    return true
end

-- Restrict spawn from spawn menu
function ENT:SpawnFunction(ply, tr, ClassName)
    if not ply:IsUA() then
        if SERVER then
            ply:ChatPrint("You do not have permission to spawn this entity.")
        end
        return
    end

    if not tr.Hit then return end

    local spawnPos = tr.HitPos + tr.HitNormal * 16
    local ent = ents.Create(ClassName)
    ent:SetPos(spawnPos)
    ent:Spawn()
    ent:Activate()

    return ent
end