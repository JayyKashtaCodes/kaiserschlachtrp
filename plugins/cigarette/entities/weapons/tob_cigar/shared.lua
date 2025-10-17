SWEP.Author              = "Mikael #"
SWEP.Spawnable           = true
SWEP.AdminSpawnable      = false
SWEP.PrintName           = "Tobaco Cigar"
SWEP.ViewModel           = "models/customhq/tobaccofarm/cigar_v.mdl"
SWEP.WorldModel          = "models/customhq/tobaccofarm/cig_w.mdl"
SWEP.UseHands            = true
SWEP.HoldType            = "melee2"
SWEP.DrawAmmo            = false
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo        = "none"
SWEP.Primary.AmmoType    = "none"
SWEP.Secondary.Ammo      = "none"
SWEP.DrawCrosshair       = true
SWEP.UseHands            = true
SWEP.ViewModelFOV        = 53
 
SWEP.Offset = {
    Pos = {
        Up = -1,
        Right = 0,
        Forward = 1,
    },
    Ang = {
        Up = 350,
        Right = 60,
        Forward = -15,
    }
}
function SWEP:AttachmentSetup(vm)
    self.LighterAttachment = vm:LookupAttachment("lighter")
    self.SmokeAttachment = vm:LookupAttachment("smoke")
end
 
function SWEP:Deploy()
    if CLIENT then
        if IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then
                self:AttachmentSetup(self.Owner:GetViewModel())
            end
        end
    end
end
 
function SWEP:Initialize()
    if CLIENT then
        self.emitter = ParticleEmitter(Vector(0,0,0))
        timer.Simple(0.1,function()
            if IsValid(self.Owner) then
                local vm = self.Owner:GetViewModel()
                if IsValid(vm) then
                    self:AttachmentSetup(self.Owner:GetViewModel())
                end
            end
        end)
    end
end
 
function SWEP:DrawWorldModel()
    local hand, offset, rotate
    if !IsValid( self.Owner ) then
        self:DrawModel( )
        return
    end
 
    if !self.Hand then
        self.Hand = self.Owner:LookupAttachment( "anim_attachment_rh" )
    end
 
    hand = self.Owner:GetAttachment( self.Hand )
 
    if !hand then
        self:DrawModel( )
        return
    end
 
    offset = hand.Ang:Right( ) * self.Offset.Pos.Right + hand.Ang:Forward( ) * self.Offset.Pos.Forward + hand.Ang:Up( ) * self.Offset.Pos.Up
    hand.Ang:RotateAroundAxis( hand.Ang:Right( ), self.Offset.Ang.Right )
    hand.Ang:RotateAroundAxis( hand.Ang:Forward( ), self.Offset.Ang.Forward )
    hand.Ang:RotateAroundAxis( hand.Ang:Up( ), self.Offset.Ang.Up )
    self:SetRenderOrigin( hand.Pos + offset )
    self:SetRenderAngles( hand.Ang )
    self:DrawModel( )
end
 
function SWEP:SmokeParti(pos,velo,ssize,esize)
    local parti = math.random(16)
    local particle = self.emitter:Add("particle/smokesprites_00"..(parti == 11 and 12 or parti < 10 and "0"..parti or parti),pos)
    particle:SetDieTime(1)
    particle:SetStartAlpha(30)
    particle:SetEndAlpha(0)
    particle:SetStartSize(ssize)
    particle:SetEndSize(esize)
    particle:SetRoll(math.random(360,480))
    particle:SetRollDelta(math.random(-2,2))
    particle:SetVelocity(velo)
    particle:SetGravity(Vector(math.random(-5,5),math.random(-5,5),0))
    particle:SetAirResistance(140)
    particle:SetCollide(false)
    particle:SetColor(255,255,255)
end
local firemat = Material("sprites/muzzleflash4")
function SWEP:PostDrawViewModel(vm,wep,ply)
    --ply:ChatPrint("Its happening")
    if vm then
        --ply:ChatPrint("Vm check")
 
        if not self.CurParti then return end
    
        if self.LighterAttachment and self.SmokeAttachment then
            --ply:ChatPrint("Bone check")
            --ply:ChatPrint(self.SmokeAttachment)
            local ct = CurTime()
 
            if (self.PartiDelay or 0) < ct then
                self.PartiDelay = ct + 0.03
                if self.CurParti > 1 then
                    local posis = vm:GetAttachment(self.SmokeAttachment)
                    if not posis then return end
                    --ply:ChatPrint(posis.Pos.x..", "..posis.Pos.y..", "..posis.Pos.z)
                    --ply:ChatPrint(posis.Ang.p..", "..posis.Ang.y..", "..posis.Ang.r)
                    self:SmokeParti(posis.Pos,posis.Ang:Right() * -5 + Vector(0,0,5) + ply:GetVelocity(),0,math.random(1,2) / 2)
                    if self.CurParti == 3 then
                        self:SmokeParti(ply:GetShootPos() - Vector(0,0,2),EyeAngles():Forward() * 50,1,math.random(2,3))
                    elseif self.CurParti == 4 then
                        local parti = math.random(16)
                        local particle = self.emitter:Add("particle/smokesprites_00"..(parti == 11 and 12 or parti < 10 and "0"..parti or parti),posis.Pos)
                        particle:SetDieTime(2)
                        particle:SetStartAlpha(150)
                        particle:SetEndAlpha(10)
                        particle:SetStartSize(1)
                        particle:SetEndSize(1)
                        particle:SetRoll(math.random(360,480))
                        particle:SetRollDelta(math.random(-2,2))
                        particle:SetVelocity(Vector(0,0,-4))
                        particle:SetGravity(Vector(math.random(-5,5),math.random(-5,5),-90))
                        particle:SetAirResistance(30)
                        particle:SetCollide(true)
                        particle:SetColor(0,0,0)
                    end
                end
            end
            if self.CurParti == 1 then
                local posil = vm:GetAttachment(self.LighterAttachment)
                if not posil then return end
                render.SetMaterial(firemat)
                render.DrawSprite(posil.Pos + posil.Ang:Right() * -5 + posil.Ang:Up() * 1.5,2 + (math.random(-3,3) / 50),5 + (math.random(-4,4) / 6),Color(185,185,185,255 - math.random(0,60)))
            end
        end
    end
end
 
local tobacoanimlist = {
    [1] = ACT_VM_PRIMARYATTACK,
    [2] = ACT_VM_SECONDARYATTACK,
    [3] = ACT_VM_SWINGHIT,
    [4] = ACT_VM_DRYFIRE,
    [5] = ACT_VM_RELOAD,
    [6] = ACT_VM_THROW
 
}
 
function SWEP:PrimaryAttack() 
    local value
    local ply = self.Owner
    local trace = ply:GetEyeTrace()
    --local dist = trace.HitPos
    
    if timer.Exists( "cooldowntimer"..self:EntIndex() ) then
        return
    end
    
    --[[if !( ply:GetPos():Distance(dist) <= 200 ) then
        return
    end]]
 
    self.cigar = ((self.cigar || 0) + 1)
    local anim = math.Clamp( self.cigar, 1, 6 ) 
    self.Weapon:SendWeaponAnim( tobacoanimlist[anim] )
    
    if CLIENT then
        if self.cigar > 1 then
            self.SwayScale = 0.1
            self.BobScale = 0.1
        end
        if self.cigar == 2 then
            timer.Simple(1.2,function()
                if not IsValid(self) then return end
                self.CurParti = 1
            end)
        elseif self.cigar == 3 then
            self.CurParti = 2
        elseif self.cigar == 4 then
            timer.Simple(0.8,function()
                if not IsValid(self) then return end
                self.CurParti = 3
            end)
            timer.Simple(1.06,function()
                if not IsValid(self) then return end
                self.CurParti = 2
            end)
        elseif self.cigar == 5 then
            timer.Simple(0.76,function()
                if not IsValid(self) then return end
                self.CurParti = 4
            end)
            timer.Simple(1.08,function()
                if not IsValid(self) then return end
                self.CurParti = 2
            end)
        end
    end
    
    if ( self.cigar >= 6 )then
        --if SERVER then
            timer.Create( "cooldowntimer"..self:EntIndex(), 2.3, 1, function()
                if !IsValid(self) then return end
                self.cigar = 0
                self.CurParti = 0
                self:SendWeaponAnim(ACT_VM_DRAW)
                self.SwayScale = 1
                self.BobScale = 1
            end)
        --end
    end
end
 
function SWEP:SecondaryAttack()     
end
 
function SWEP:OnRemove()
    if self.emitter then
        self.emitter:Finish()
    end
end