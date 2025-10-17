AddCSLuaFile()

SWEP.ViewModel    = Model("models/weapons/c_arms_animations.mdl")
SWEP.WorldModel   = Model("models/oldprops/camera.mdl")

SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = false
SWEP.Primary.Ammo          = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = true
SWEP.Secondary.Ammo        = "none"

SWEP.PrintName     = "Camera"
SWEP.Author        = "Garry & Dzhey Kashta"

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.IsAlwaysRaised = true

SWEP.Slot          = 5
SWEP.SlotPos       = 1

SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = false

SWEP.ShootSound    = Sound("NPC_CScanner.TakePhoto")

if SERVER then
    SWEP.AutoSwitchTo   = false
    SWEP.AutoSwitchFrom = false

    concommand.Add("ksr_oldcamera", function(ply)
        ply:SelectWeapon("ksr_oldcamera")
    end)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "Zoom")
    self:NetworkVar("Float", 1, "Roll")
    if SERVER then
        self:SetZoom(70)
        self:SetRoll(0)
    end
end

function SWEP:Initialize()
    self:SetHoldType("camera")
end

function SWEP:Reload()
    if not self.Owner:KeyDown(IN_ATTACK2) then
        self:SetZoom(self.Owner:IsBot() and 75 or self.Owner:GetInfoNum("fov_desired", 75))
    end
    self:SetRoll(0)
end

local ShowFilterOverlay = false
local FilterEndTime = 0
local FilterDuration = 1.2

function SWEP:PrimaryAttack()
    self:DoShootEffect()
    if not game.SinglePlayer() and SERVER then return end
    if CLIENT and not IsFirstTimePredicted() then return end

    self.Owner:ConCommand("jpeg")

    if CLIENT then
        ShowFilterOverlay = true
        FilterEndTime = CurTime() + FilterDuration
    end
end

function SWEP:SecondaryAttack()
    -- SWEP:Tick
end

function SWEP:Tick()
    if CLIENT and self.Owner ~= LocalPlayer() then return end
    local cmd = self.Owner:GetCurrentCommand()
    if not cmd:KeyDown(IN_ATTACK2) then return end

    self:SetZoom(math.Clamp(self:GetZoom() + cmd:GetMouseY() * 0.1, 0.1, 175))
    self:SetRoll(self:GetRoll() + cmd:GetMouseX() * 0.025)
end

function SWEP:TranslateFOV(fov)
    return self:GetZoom()
end

function SWEP:Deploy()
    return true
end

function SWEP:Equip()
    if self:GetZoom() == 70 and self.Owner:IsPlayer() and not self.Owner:IsBot() then
        self:SetZoom(self.Owner:GetInfoNum("fov_desired", 75))
    end
end
--[[
function SWEP:ShouldDropOnDie()
    return false
end
]]--
function SWEP:DoShootEffect()
    self:EmitSound(self.ShootSound)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:SetAnimation(PLAYER_ATTACK1)

    if SERVER and not game.SinglePlayer() then
        local trace = util.TraceLine({
            start = self.Owner:GetShootPos(),
            endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 256,
            filter = self.Owner
        })

        local effectdata = EffectData()
        effectdata:SetOrigin(trace.HitPos)
        util.Effect("camera_flash", effectdata, true)
    end
end

if SERVER then return end

SWEP.WepSelectIcon = surface.GetTextureID("vgui/ksr_oldcamera")

function SWEP:DrawWorldModel()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then
        self:DrawModel()
        return
    end

    local boneIndex = owner:LookupBone("ValveBiped.Bip01_R_Hand")
    if not boneIndex then
        self:DrawModel()
        return
    end

    local handPos, handAng = owner:GetBonePosition(boneIndex)
    local offsetPos = handPos + handAng:Forward() * 8 + handAng:Right() * 6
    local offsetAng = handAng
    offsetAng:RotateAroundAxis(offsetAng:Right(), 180)

    self:SetRenderOrigin(offsetPos)
    self:SetRenderAngles(offsetAng)

    local matrix = Matrix()
    matrix:Scale(Vector(0.5, 0.5, 0.5))
    self:EnableMatrix("RenderMultiply", matrix)

    self:DrawModel()
end

function SWEP:DrawHUD()
    if not ShowFilterOverlay or CurTime() > FilterEndTime then return end

    -- Refined vintage look: lighter and hazier
    DrawColorModify({
        ["$pp_colour_addr"]      = 0,
        ["$pp_colour_addg"]      = 0,
        ["$pp_colour_addb"]      = 0,
        ["$pp_colour_brightness"]= -0.04,
        ["$pp_colour_contrast"]  = 0.6,
        ["$pp_colour_colour"]    = 0.0,
        ["$pp_colour_mulr"]      = 0,
        ["$pp_colour_mulg"]      = 0,
        ["$pp_colour_mulb"]      = 0
    })

    DrawBloom(0.85, 2.5, 10, 10, 2.2, 0.7, 1, 1.0, 0.9)
    DrawSharpen(0.8, 0.15)
end


function SWEP:PrintWeaponInfo(x, y, alpha) end

function SWEP:HUDShouldDraw(name)
    return name == "CHudWeaponSelection" or name == "CHudChat"
end

function SWEP:FreezeMovement()
    return self.Owner:KeyDown(IN_ATTACK2) or self.Owner:KeyReleased(IN_ATTACK2)
end

function SWEP:CalcView(ply, origin, angles, fov)
    if self:GetRoll() ~= 0 then
        angles.Roll = self:GetRoll()
    end
    return origin, angles, fov
end

function SWEP:AdjustMouseSensitivity()
    return self.Owner:KeyDown(IN_ATTACK2) and 1 or self:GetZoom() / 80
end
