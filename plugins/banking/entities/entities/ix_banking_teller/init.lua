AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/iamhaed/ksr/newsuit/suit_02.mdl")
        self:SetUseType(SIMPLE_USE)
        self:SetMoveType(MOVETYPE_NONE)
        self:DrawShadow(true)
        self:InitPhysObj()

        timer.Simple(0, function()
            if IsValid(self) then
                self:SetAnim()
            end
        end)
    end
end

function ENT:InitPhysObj()
    local mins, maxs = self:GetAxisAlignedBoundingBox()
    local created = self:PhysicsInitBox(mins, maxs)
    if created then
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
            phys:Sleep()
        end
    end
end

function ENT:GetAxisAlignedBoundingBox()
    local mins, maxs = self:GetModelBounds()
    mins = Vector(mins.x, mins.y, 0)
    mins, maxs = self:GetRotatedAABB(mins, maxs)
    return mins, maxs
end

function ENT:SetAnim()
    -- Try common idle sequence names first
    local preferred = { "idle_all_01", "idle_all", "idle_subtle", "pose_standing", "idle" }
    for _, name in ipairs(preferred) do
        local seq = self:LookupSequence(name)
        if seq and seq > 0 then
            self:ResetSequence(seq)
            return
        end
    end

    -- Fallback: pick the first sequence that isn't the reference pose
    local sequences = self:GetSequenceList()
    if #sequences > 0 then
        -- Sequence 1 is often the bind pose; skip it if possible
        local fallbackIndex = (#sequences > 1) and 2 or 1
        self:ResetSequence(fallbackIndex)
    end
end

function ENT:Use(activator)
    local char = activator:GetCharacter()
    if not char then
        return
    end

    net.Start("ixBankingViewTeller")
    net.Send(activator)
end

function ENT:Think()
	self:NextThink(CurTime())
	return true
end