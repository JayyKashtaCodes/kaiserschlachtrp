AddCSLuaFile()

local PLUGIN = PLUGIN

if CLIENT then
    SWEP.PrintName = "Administrative Stick"
    SWEP.Slot = 0
    SWEP.SlotPos = 3
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = false
end

SWEP.Author = "berko - NS | Ported by Dzhey Kashta - Helix"
SWEP.PrintName = "Administrative Stick"
SWEP.Instructions = "R Key: Select somebody else\nR + Shift Key: Select yourself\nPrimary Fire: Open Menu\nSecondary Fire: Freeze"
SWEP.Purpose = "An administrative stick for servers to use!"
SWEP.ViewModelFOV = 100
SWEP.ViewModelFlip = false
SWEP.Category = "Administration Tools"
SWEP.IsAlwaysRaised = true
SWEP.Spawnable = true
SWEP.AnimPrefix = "stunstick"
SWEP.ViewModel = Model("models/weapons/v_stunstick.mdl")
SWEP.WorldModel = Model("models/weapons/w_stunbaton.mdl")
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Drop = false

function SWEP:Deploy()
    if SERVER and not (self:GetOwner():IsStaff() or self:GetOwner():Team() == FACTION_STAFF) then
        self:Remove()
        return
    end
    return true
end

function SWEP:Initialize()
    self.RGB = false
    self:SetHoldType("melee")
    if SERVER then
        hook.Add("Think", self, self.ThinkHook)
    end
end

function SWEP:ThinkHook()
    if self.RGB then
        local color = HSVToColor(CurTime() % 6 * 60, 1, 1)
        self:SetColor(color)
        self:SetMaterial("models/shiny")

        local owner = self:GetOwner()
        if IsValid(owner) then
            local viewModel = owner:GetViewModel()
            if IsValid(viewModel) then
                viewModel:SetColor(color)
                viewModel:SetMaterial("models/shiny")
            end
        end
    else
        self:SetColor(Color(255, 255, 255))
        self:SetMaterial("")

        local owner = self:GetOwner()
        if IsValid(owner) then
            local viewModel = owner:GetViewModel()
            if IsValid(viewModel) then
                viewModel:SetColor(Color(255, 255, 255))
                viewModel:SetMaterial("")
            end
        end
    end

    if CLIENT then
        self:Think()
    end
end

function SWEP:PrimaryAttack()
    if SERVER then return end
    local target = IsValid(LocalPlayer().AdminStickTarget) and LocalPlayer().AdminStickTarget or LocalPlayer():GetEyeTrace().Entity

    if IsValid(target) and not target:IsPlayer() then
        if target:IsVehicle() and IsValid(target:GetDriver()) then
            target = target:GetDriver()
        end
    end

    if IsValid(target) and (target:IsPlayer() or target:IsDoor() or target:GetClass() == "ix_storage") then
        AdminStick:OpenAdminStickUI(false, target)
    end
end

function SWEP:SecondaryAttack()
    if SERVER then return end
    if not IsFirstTimePredicted() then return end
    local target = IsValid(LocalPlayer().AdminStickTarget) and LocalPlayer().AdminStickTarget or LocalPlayer():GetEyeTrace().Entity

    if IsValid(target) and not target:IsPlayer() then
        if target:IsVehicle() and IsValid(target:GetDriver()) then
            target = target:GetDriver()
        end
    end

    if IsValid(target) and target:IsPlayer() and target ~= LocalPlayer() then
        local cmd = target:IsFrozen() and "sam unfreeze" or "sam freeze"
        LocalPlayer():ConCommand(cmd .. " " .. target:SteamID())
    else
        ix.util.Notify("You cannot freeze this!")
    end
end

function SWEP:DrawHUD()
    local x, y = ScrW() / 2, ScrH() / 2
    local target = IsValid(LocalPlayer().AdminStickTarget) and LocalPlayer().AdminStickTarget or LocalPlayer():GetEyeTrace().Entity
    local crossColor = Color(255, 0, 0)
    local information = {}

    if IsValid(target) then
        if not target:IsPlayer() then
            if target:IsVehicle() and IsValid(target:GetDriver()) then
                target = target:GetDriver()
            end
        end

        if target:IsPlayer() then
            crossColor = Color(0, 255, 0)

            information = {
                IsValid(LocalPlayer().AdminStickTarget) and "Player (Selected with Reload)" or "Player",
                "Nickname: " .. target:Nick(),
                "Steam Name: " .. (target.SteamName and target:SteamName() or target:Name()),
                "Steam ID: " .. target:SteamID(),
                "Health: " .. target:Health(),
                "Armor: " .. target:Armor(),
                "Usergroup: " .. target:GetUserGroup()
            }

            if target:GetCharacter() then
                local char = target:GetCharacter()
                local faction = ix.faction.indices[target:Team()]

                table.Add(information, {
                    "Character Name: " .. char:GetName(),
                    "Character Faction: " .. faction.uniqueID .. " (" .. faction.name .. ")"
                })
            else
                table.insert(information, "No Loaded Character")
            end
        elseif target:IsWorld() then
            if not LocalPlayer().NextRequestInfo or SysTime() >= LocalPlayer().NextRequestInfo then
                LocalPlayer().NextRequestInfo = SysTime() + 1
            end

            information = {
                "Entity",
                "Class: " .. target:GetClass(),
                "Model: " .. target:GetModel(),
                "Position: " .. tostring(target:GetPos()),
                "Angles: " .. tostring(target:GetAngles()),
                "Owner: " .. tostring(target:GetNWString("Creator_Nick", "NULL")),
                "EntityID: " .. target:EntIndex()
            }

            crossColor = Color(255, 255, 0)
        else
            if not LocalPlayer().NextRequestInfo or SysTime() >= LocalPlayer().NextRequestInfo then
                LocalPlayer().NextRequestInfo = SysTime() + 1
            end

            information = {
                "Entity",
                "Class: " .. target:GetClass(),
                "Model: " .. target:GetModel(),
                "Position: " .. tostring(target:GetPos()),
                "Angles: " .. tostring(target:GetAngles()),
                "Owner: " .. tostring(target:GetNWString("Creator_Nick", "NULL")),
                "EntityID: " .. target:EntIndex()
            }

            crossColor = Color(255, 255, 0)
        end
    end

    local length = 20
    local thickness = 1
    surface.SetDrawColor(crossColor)
    surface.DrawRect(x - length / 2, y - thickness / 2, length, thickness)
    surface.DrawRect(x - thickness / 2, y - length / 2, thickness, length)
    local startPosX, startPosY = ScrW() / 2 + 10, ScrH() / 2 + 10
    local font = "DebugFixed"
    local buffer = 0

    for _, v in pairs(information) do
        surface.SetFont(font)
        surface.SetTextColor(color_black)
        surface.SetTextPos(startPosX + 1, startPosY + buffer + 1)
        surface.DrawText(v)
        surface.SetTextColor(crossColor)
        surface.SetTextPos(startPosX, startPosY + buffer)
        surface.DrawText(v)
        local t_w, t_h = surface.GetTextSize(v)
        buffer = buffer + t_h
    end
end

function SWEP:Reload()
    if SERVER then return end
    if self.NextReload and self.NextReload > SysTime() then return end
    self.NextReload = SysTime() + 0.5
    local lookingAt = LocalPlayer():KeyDown(IN_SPEED) and LocalPlayer() or LocalPlayer():GetEyeTrace().Entity

    if IsValid(lookingAt) and not lookingAt:IsPlayer() then
        if lookingAt:IsVehicle() and IsValid(lookingAt:GetDriver()) then
            lookingAt = lookingAt:GetDriver()
        end
    end

    if IsValid(lookingAt) and lookingAt:IsPlayer() then
        LocalPlayer().AdminStickTarget = lookingAt
    else
        LocalPlayer().AdminStickTarget = nil
    end
end

function SWEP:DrawWorldModel()
    if self:GetOwner():IsStaff() and self:GetOwner():GetMoveType() == MOVETYPE_NOCLIP then
        return
    end
    self:DrawModel()
end
