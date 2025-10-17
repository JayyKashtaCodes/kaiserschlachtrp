AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/1910rp/civil_06.mdl")
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

    local offlineCharacters = {}
    local accounts = ix.banking.accountsByChar[char:GetID()]
    if accounts then
        for _, v in pairs(accounts) do
            for k in pairs(v.accountHolders) do
                if not ix.char.loaded[k] then
                    table.insert(offlineCharacters, k)
                end
            end
        end
    end

    if #offlineCharacters == 0 then
        net.Start("ixBankingViewService")
        net.Send(activator)
    else
        local queryOfflineCharacters = {}
        for k, v in ipairs(offlineCharacters) do
            if not ix.banking.offlineCharacters[v] then
                table.insert(queryOfflineCharacters, v)
            end
        end

        local function SendNetMsg()
            net.Start("ixBankingViewService")
                net.WriteUInt(#offlineCharacters, 10)
                for i = 1, #offlineCharacters do
                    local char = ix.banking.offlineCharacters[offlineCharacters[i]]
                    net.WriteUInt(char.id, 32)
                    net.WriteString(char.name)
                    net.WriteString(char.model)
                end
            net.Send(activator)
        end

        if #queryOfflineCharacters > 0 then
            local query = mysql:Select("ix_characters")
                query:Select("id")
                query:Select("name")
                query:Select("model")
                query:WhereIn("id", offlineCharacters)
                query:Callback(function(result)
                    if istable(result) and #result > 0 then
                        for k, v in ipairs(result) do
                            ix.banking.offlineCharacters[tonumber(v.id)] = {id = tonumber(v.id), name = v.name, model = v.model}
                        end

                        SendNetMsg()
                    end
                end)
            query:Execute()
            return
        end

        SendNetMsg()
    end
end

function ENT:Think()
	self:NextThink(CurTime())
	return true
end