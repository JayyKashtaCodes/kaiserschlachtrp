AddCSLuaFile()

SWEP.PrintName = "Police Baton"
SWEP.Slot = 0
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Category = "Police"
SWEP.Author = "Chessnut & Aspect™ & Dzhey Kashta"
SWEP.Instructions = "Primary Fire: Bash.\nSecondary Fire (Lowered): Push/Knock.\nSecondary Fire (Raised): Stun."
SWEP.Purpose = "Bashing, stunning, and pushing things."
SWEP.Drop = false

SWEP.SelectIcon = "hud/weaponicons/nightstick"

SWEP.HoldType = "melee"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "melee"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Primary.Damage = 10
SWEP.Primary.Delay = 0.8

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

SWEP.ViewModel = Model("models/drover/baton.mdl")
SWEP.WorldModel = Model("models/drover/w_baton.mdl")

SWEP.UseHands = true
SWEP.LowerAngles = Angle(15, -10, -20)

SWEP.FireWhenLowered = true

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Activated")
end

function SWEP:Precache()
    util.PrecacheSound("physics/wood/wood_box_impact_hard3.wav")
    util.PrecacheSound("physics/wood/wood_box_impact_hard4.wav")
    util.PrecacheSound("physics/wood/wood_crate_impact_soft4.wav")
	util.PrecacheModel(self.ViewModel)
	util.PrecacheModel(self.WorldModel)
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:OnRaised()
    self.lastRaiseTime = CurTime()
end

function SWEP:OnLowered()
    self:SetActivated(false)
end

function SWEP:Holster(nextWep)
    self:OnLowered()
    return true
end

function SWEP:DrawWorldModel()
    self:DrawModel()
end

function SWEP:PrimaryAttack(bSecondary)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()

    if not owner:IsWepRaised() then return end

    self:EmitSound("physics/wood/wood_box_impact_hard3.wav")
    self:SendWeaponAnim(ACT_VM_HITCENTER)

    local damage = self.Primary.Damage
    owner:SetAnimation(PLAYER_ATTACK1)
    owner:ViewPunch(Angle(1, 0, 0.125))

    owner:LagCompensation(true)
        local traceData = {
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * 72,
            filter = owner
        }
        local trace = util.TraceLine(traceData)
    owner:LagCompensation(false)

    if SERVER and trace.Hit then
        owner:EmitSound("physics/wood/wood_crate_impact_soft4.wav")

        local entity = trace.Entity
        if IsValid(entity) then
            if entity:IsPlayer() then
                entity:ViewPunch(Angle(-10, math.random(-5, 5), math.random(-5, 5)))

                local damageInfo = DamageInfo()
                damageInfo:SetAttacker(owner)
                damageInfo:SetInflictor(self)
                damageInfo:SetDamage(damage)
                damageInfo:SetDamageType(DMG_CLUB)
                entity:TakeDamageInfo(damageInfo)
            elseif entity:IsRagdoll() then
                local damageInfo = DamageInfo()
                damageInfo:SetAttacker(owner)
                damageInfo:SetInflictor(self)
                damageInfo:SetDamage(damage * 0.5)
                damageInfo:SetDamageType(DMG_CLUB)
                entity:TakeDamageInfo(damageInfo)
            elseif entity:IsDoor() then
                if hook.Run("PlayerCanKnockOnDoor", owner, entity) == false then return end
                owner:EmitSound("physics/wood/wood_box_impact_hard4.wav")
                owner:SetAnimation(PLAYER_ATTACK1)
            end
        end
    end
end

function SWEP:SecondaryAttack()
    local owner = self:GetOwner()

    if owner:IsWepRaised() then
        self:SetActivated(true)
        self:PrimaryAttack(true)

        self:EmitSound("physics/wood/wood_box_impact_hard4.wav")

        timer.Simple(0.3, function()
            if IsValid(self) then self:SetActivated(false) end
        end)

        self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
        return
    end

    owner:LagCompensation(true)
        local traceData = {
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * 72,
            filter = owner,
            mins = Vector(-8, -8, -30),
            maxs = Vector(8, 8, 10)
        }
        local trace = util.TraceHull(traceData)
    owner:LagCompensation(false)

    local entity = trace.Entity
    if not SERVER or not IsValid(entity) then return end

    local phys = entity:GetPhysicsObject()
    local bPushed = false

    if entity:IsDoor() then
        if hook.Run("PlayerCanKnockOnDoor", owner, entity) == false then return end

        owner:ViewPunch(Angle(-1.3, 1.8, 0))
        owner:EmitSound("physics/wood/wood_crate_impact_hard3.wav")
        owner:SetAnimation(PLAYER_ATTACK1)
        self:SetNextSecondaryFire(CurTime() + 0.4)
        bPushed = true
    elseif entity:IsPlayer() then
        local pushVector = owner:GetAimVector() * 300
        pushVector.z = 0
        entity:SetVelocity(pushVector)

        owner:EmitSound("Weapon_Crossbow.BoltHitBody")
        bPushed = true
    elseif IsValid(phys) then
        phys:ApplyForceCenter(owner:GetAimVector() * 1000)
        owner:EmitSound("physics/wood/wood_crate_impact_soft4.wav")
        bPushed = true
    end

    if bPushed then
        self:SetNextSecondaryFire(CurTime() + 1.5)
    end
end
