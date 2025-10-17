local PLUGIN = PLUGIN

AddCSLuaFile()
DEFINE_BASECLASS("base_gmodentity")

ENT.Type        = "anim"
ENT.Base        = "base_gmodentity"
ENT.PrintName   = "Jail Escape Trigger"
ENT.Author      = "Dzhey Kashta"
ENT.Category    = "IX: Jail System"
ENT.Spawnable   = false
ENT.AdminOnly   = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

if SERVER then
    AddCSLuaFile()

    -- Map door classes to ignore
    local DOOR_CLASSES = {
        ["func_door"] = true,
        ["func_door_rotating"] = true,
        ["prop_door_rotating"] = true
    }

    function ENT:Initialize()
        self:SetNWBool("Debug", false)

        if self:GetNWBool("Debug") then
            self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
            self:SetNoDraw(false)
        else
            self:SetNoDraw(true)
        end

        local mins, maxs = Vector(-32,-32,-16), Vector(16,32,180)
        self:SetCollisionBounds(mins, maxs)

        self:SetSolid(SOLID_BBOX)                -- simple bounding box solid
        self:SetMoveType(MOVETYPE_NONE)          -- never moves unless you move it manually
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) -- ignored by players/bullets/+use
        self:SetTrigger(true)                    -- fires StartTouch/EndTouch
    end

    function ENT:StartTouch(ent)
        if not IsValid(ent) or not ent:IsPlayer() then return end
        --print("Touch Triggered by", ent)

        local char = ent.GetCharacter and ent:GetCharacter()
        if not char then return end

        local jailData = char:GetData("activeJail")
        if not jailData or not jailData.time or jailData.time <= 0 then return end

        PLUGIN:EndJailSentence(ent, "ESCAPED")
        ent:Notify("You have Escaped...")
        --print(("[ESCAPE] %s has escaped jail via %s"):format(ent:Nick(), tostring(self)))
        hook.Run("JailPlayerEscaped", ent, self)
    end

    -- Make +use ignore this entity
    function ENT:Use(activator, caller)
        return false
    end

    function ENT:OnTakeDamage(dmginfo)
        return
    end

    hook.Add("FindUseEntity", "IgnoreEscapeBlockUse", function(ply, ent)
        local tr = ply:GetEyeTrace()
        if IsValid(tr.Entity) and tr.Entity:GetClass() == "ix_escapeblock" then
            local filter = {ply, tr.Entity}
            local tr2 = util.TraceLine({
                start  = ply:EyePos(),
                endpos = ply:EyePos() + ply:EyeAngles():Forward() * 85,
                filter = filter
            })
            return tr2.Entity
        end
    end)

    -- Only keep collision with world, ignore doors
    hook.Add("ShouldCollide", "JailEscapeTrigger_Filter", function(ent1, ent2)
        local trigger, other

        if IsValid(ent1) and ent1:GetClass() == "ix_escapeblock" then
            trigger, other = ent1, ent2
        elseif IsValid(ent2) and ent2:GetClass() == "ix_escapeblock" then
            trigger, other = ent2, ent1
        end

        if not trigger or not IsValid(other) then return end

        if DOOR_CLASSES[other:GetClass()] then
            return false -- ignore doors
        end
    end)
end

if CLIENT then
    function ENT:DrawTranslucent()
        if not self:GetNWBool("Debug") then return end

        local mins, maxs = self:GetCollisionBounds()
        local pos, ang = self:GetPos(), self:GetAngles()

        local defaultColour = Color(255, 0, 0, 100)
        local jailedColour  = Color(255, 100, 100, 150)
        local freeColour    = Color(100, 255, 100, 150)

        local drawColour = defaultColour
        local worldMins, worldMaxs = LocalToWorld(mins, Angle(), pos, ang), LocalToWorld(maxs, Angle(), pos, ang)

        local ply = LocalPlayer()
        if ply:Alive() and ply:GetPos():WithinAABox(worldMins, worldMaxs) then
            local char = ply.GetCharacter and ply:GetCharacter()
            local jailData = char and char:GetData("activeJail")
            drawColour = (jailData and jailData.time and jailData.time > 0) and jailedColour or freeColour
        end

        render.SetColorMaterial()
        render.DrawBox(pos, ang, mins, maxs, drawColour)
        render.DrawWireframeBox(pos, ang, mins, maxs, Color(255, 0, 0), true)

        -- Label at top of bounds
        local labelPos = pos + Vector(0, 0, maxs.z + 10)
        local labelAng = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

        cam.Start3D2D(labelPos, labelAng, 0.2)
            draw.SimpleTextOutlined(
                "ESCAPE ZONE", "DermaLarge", 0, 0,
                Color(255, 255, 255),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                1, Color(0, 0, 0)
            )
        cam.End3D2D()
    end
end
