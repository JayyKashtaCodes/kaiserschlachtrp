local PLUGIN = PLUGIN

ix.banking.logRequests = ix.banking.logRequests or {}

function PLUGIN:SaveBankService()
    local data = {}
    for k, v in ipairs(ents.FindByClass("ix_banking_service")) do
        data[#data + 1] = {
            v:GetPos(),
            v:GetAngles(),
        }
    end
    ix.data.Set("bankingService", data)
end

function PLUGIN:SaveBankTeller()
    local data = {}
    for k, v in ipairs(ents.FindByClass("ix_banking_teller")) do
        data[#data + 1] = {
            v:GetPos(),
            v:GetAngles(),
        }
    end
    ix.data.Set("bankingTeller", data)
end

function PLUGIN:LoadBankService()
    local data = ix.data.Get("bankingService", {})
    for k, v in ipairs(data) do
        local ent = ents.Create("ix_banking_service")
        ent:SetPos(v[1])
        ent:SetAngles(v[2])
        ent:Spawn()
    end
end

function PLUGIN:LoadBankTeller()
    local data = ix.data.Get("bankingTeller", {})
    for k, v in ipairs(data) do
        local ent = ents.Create("ix_banking_teller")
        ent:SetPos(v[1])
        ent:SetAngles(v[2])
        ent:Spawn()
    end
end

function PLUGIN:InitAccountIDOffset()
    local offset = ix.data.Get("bankingOffset", nil, false, true)
    if not offset then
        offset = {math.random(143712, 16572182)}

        ix.data.Set("bankingOffset", offset, false, true)
    end

    ix.banking.accountIDOffset = offset[1]
end

function ix.banking.CanRequestLogRateLimit(client, accountID)
    local account = ix.banking.accounts[accountID]

    if not ix.banking.logRequests[client] then
        return true
    end

    if not ix.banking.logRequests[client][accountID] then
        return true
    end

    if ix.banking.logRequests[client][accountID] + 0.25 < CurTime() then
        return true
    end

    return false
end