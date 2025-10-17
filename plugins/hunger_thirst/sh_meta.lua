local PLUGIN = PLUGIN or {}

local playerMeta = FindMetaTable("Player")

function playerMeta:SetNeedVar(need, amount)
    local currentAmount = self:GetLocalVar(need, 0)
    local newAmount = math.Clamp(currentAmount + amount, 0, 100)
    self:SetLocalVar(need, newAmount)
end

function playerMeta:Hunger(amount)
    self:SetNeedVar("hunger", amount)
end

function playerMeta:Thirst(amount)
    self:SetNeedVar("thirst", amount)
end

function playerMeta:Drunkenness(amount)
    self:SetNeedVar("drunkenness", amount)
end
