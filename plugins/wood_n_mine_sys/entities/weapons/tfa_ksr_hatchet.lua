local PLUGIN = PLUGIN

AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.Category = "KSR Tools"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.IsAlwaysRaised = true

SWEP.PrintName = "Hatchet"
SWEP.Author = "Dzhey Kashta"
SWEP.Slot = 1

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/yurie_rustalpha/c-vm-hatchet.mdl"
SWEP.WorldModel = "models/weapons/yurie_rustalpha/wm-hatchet.mdl"
SWEP.ViewModelFOV = 60
SWEP.HoldType = "melee"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1

SWEP.MeleeDamage = 20
SWEP.MeleeRange = 32

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- Attach world model to hand
function SWEP:DrawWorldModel()
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then
        local boneIndex = owner:LookupBone("ValveBiped.Bip01_R_Hand")
        if boneIndex then
            local pos, ang = owner:GetBonePosition(boneIndex)

            pos = pos + ang:Forward() * 4 + ang:Right() * 1 + ang:Up() * -2
            ang:RotateAroundAxis(ang:Right(), 180)
            ang:RotateAroundAxis(ang:Up(), 180)

            self:SetRenderOrigin(pos)
            self:SetRenderAngles(ang)
            self:DrawModel()
        end
    else
        self:SetRenderOrigin(nil)
        self:SetRenderAngles(nil)
        self:DrawModel()
    end
end

-- Primary attack (chop)
function SWEP:PrimaryAttack()
    if not IsValid(self:GetOwner()) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)

    local vm = self:GetOwner():GetViewModel()
    if IsValid(vm) then
        local seq = vm:LookupSequence("fire_1")
        if seq and seq > 0 then
            vm:SendViewModelMatchingSequence(seq)
        else
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        end
    end

    local hitSound

    if SERVER then
        local ply = self:GetOwner()
        local tr = util.TraceHull({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * self.MeleeRange,
            filter = ply,
            mins = Vector(-5, -5, -5),
            maxs = Vector(5, 5, 5),
            mask = MASK_SHOT
        })

        local hitEnt = tr.Entity
        if IsValid(hitEnt) then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(self.MeleeDamage)
            dmginfo:SetAttacker(ply)
            dmginfo:SetInflictor(self)
            dmginfo:SetDamageType(DMG_SLASH)
            dmginfo:SetDamageForce(ply:GetAimVector() * 1500)
            dmginfo:SetDamagePosition(tr.HitPos)
            hitEnt:TakeDamageInfo(dmginfo)

            -- Tree check and interaction
            local cls = hitEnt:GetClass()
            if cls == "j_lumberjack_tree" or cls == "j_lumberjack_bigtree" then
                hitEnt:CutTree(ply, self.MeleeDamage)
                hitSound = "weapons/yurie_rustalpha/hatchet/impact_wood.ogg"
            else
                hitSound = "weapons/yurie_rustalpha/hatchet/impact_generic.ogg"
            end

            -- Impact effect
            local fx = EffectData()
            fx:SetOrigin(tr.HitPos)
            fx:SetNormal(tr.HitNormal or Vector(0, 0, 1))
            fx:SetScale(1)
            fx:SetMagnitude(1)
            util.Effect("WoodImpact", fx)

            -- Play impact sound from player
            self:GetOwner():EmitSound(hitSound, 75, math.random(98, 103))
        end
    end

    self:EmitSound("weapons/yurie_rustalpha/hatchet/swing.ogg", 70)
end

-- Secondary attack (bash/shove)
function SWEP:SecondaryAttack()
    if not IsValid(self:GetOwner()) then return end

    self:SetNextSecondaryFire(CurTime() + 1)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    self:GetOwner():AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, true)

    local vm = self:GetOwner():GetViewModel()
    if IsValid(vm) then
        local seq = vm:LookupSequence("fire_2")
        if seq and seq > 0 then
            vm:SendViewModelMatchingSequence(seq)
        else
            self:SendWeaponAnim(ACT_VM_HITCENTER)
        end
    end

    if SERVER then
        local ply = self:GetOwner()
        local tr = util.TraceHull({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * (self.MeleeRange * 0.75),
            filter = ply,
            mins = Vector(-5, -5, -5),
            maxs = Vector(5, 5, 5),
            mask = MASK_SHOT
        })

        local hitEnt = tr.Entity

        if IsValid(hitEnt) then
            -- Push effect
            if hitEnt:IsPlayer() or hitEnt:IsNPC() then
                local force = ply:GetAimVector() * 500 + Vector(0, 0, 150)
                hitEnt:SetVelocity(hitEnt:GetVelocity() + force)
            end

            -- Play impact sound from player
            self:GetOwner():EmitSound("physics/body/body_medium_impact_soft1.wav", 70, math.random(95, 105))
        end
    end
end

-- Equip sound
function SWEP:Deploy()
    self:EmitSound("weapons/yurie_rustalpha/shared/draw_generic_rustle.ogg")
    return true
end
