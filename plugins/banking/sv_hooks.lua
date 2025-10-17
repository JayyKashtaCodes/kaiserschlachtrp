local PLUGIN = PLUGIN

function PLUGIN:DatabaseConnected()
    ix.banking.LoadDBTables()
end

function PLUGIN:SaveData()
    self:SaveBankService()
    self:SaveBankTeller()
end

function PLUGIN:LoadData()
    self:LoadBankService()
    self:LoadBankTeller()

    self:InitAccountIDOffset()
end

function PLUGIN:PlayerInitialSpawn(client)
    net.Start("ixBankingSyncOffset")
        net.WriteUInt(ix.banking.accountIDOffset, 24)
    net.Send(client)
end

function PLUGIN:CharacterRestored(character)
    local client = character:GetPlayer()
    timer.Create("ixBankingLoadAccounts" .. client:UserID(), 1, 1, function()
        if IsValid(client) and client.ixLoaded then
            local charIDs = {}
            for _, v in ipairs(client.ixCharList) do
                if not ix.banking.accountsByChar[v] then
                    table.insert(charIDs, v)
                end
            end
        
            ix.banking.LoadAccounts(charIDs)
        end
    end)
end

function PLUGIN:PlayerLoadedCharacter(client, character)
    if ix.banking.accountsByChar[character:GetID()] then
        for _, v in pairs(ix.banking.accountsByChar[character:GetID()]) do
            v:Sync(client)
        end
    end
end

local allowedPerms = {
    [BANKINGPERM_DEPOSIT_WITHDRAW] = true,
    [BANKINGPERM_LOG] = true,
    [BANKINGPERM_MANAGE_HOLDERS] = true,
    [BANKINGPERM_SEND] = true,
}

function PLUGIN:BankingCanChangePermission(account, char, targetID, permission)
    if not allowedPerms[permission] then
        return false
    end

    if not account:HasPermission(char:GetID(), permission) then
        return false
    end
end
