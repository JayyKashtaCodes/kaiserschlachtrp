local PLUGIN = PLUGIN

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(PLUGIN.trashCanModel)
    self:SetUseType(SIMPLE_USE)
    self:SetMoveType(MOVETYPE_NONE)
    self:PhysicsInit(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    -- Create container inventory
    if not self:GetNetVar("id") then
        ix.inventory.New(0, "trashcan", function(inv)
            inv:SetSize(self.invWidth, self.invHeight)
            inv:SetOwner(nil) -- no owner, public
            inv:SetEntity(self)
            self:SetNetVar("id", inv:GetID())
        end)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local invID = self:GetNetVar("id")
    if invID then
        local inventory = ix.inventory.Get(invID)
        if inventory then
            activator:OpenInventory(inventory, self)
        end
    end
end
