local PLUGIN = PLUGIN

local META = ix.banking.meta or ix.middleclass("ix_bankingAccount")

META.type = "standard"
META.name = META.name or "Bank Account"
META.money = META.money or 0
META.accountHolders = META.accountHolders or {}
META.data = META.data or {}

function META:Initialize(id, name, money, data)
    self.id = id
    self.name = name
    self.money = money
    self.data = data

    self.accountHolders = {}
end

function META:GetID()
    return self.id
end

function META:GetName()
    return self.name
end

function META:GetMoney()
    return self.money
end

function META:HasPermission(charID, permission)
    if not self.accountHolders[charID] then
        return false
    end

    if bit.band(self.accountHolders[charID], permission) != permission then
        return false
    end

    return true
end

function META:GetOwner()
    for k, v in pairs(self.accountHolders) do
        if self:HasPermission(k, BANKINGPERM_OWNER) then
            return k
        end
    end
end

function META:SetMoney(money, bNoReplication, bNoSave)
    local old = self.money

    self.money = money

    hook.Run("BankingMoneyChanged", self, old, money)

    if SERVER then
        if !bNoSave then
            local query = mysql:Update("ix_banking_accounts")
                query:Update("money", ix.currency.ToCents(money))
                query:Where("id", self:GetID())
            query:Execute()
        end

        if !bNoReplication then
            net.Start("ixBankingSyncMoney")
                net.WriteUInt(self:GetID(), 32)
                net.WriteUInt(ix.currency.ToCents(self.money), 32)
            net.Send(self:GetPlayerHolders())
        end
    end
end

if SERVER then
    function META:Deposit(character, money, bNoGenericLog, bNoReplication)
        if not self:HasPermission(character:GetID(), BANKINGPERM_DEPOSIT_WITHDRAW) then
            return false, {"bankingNotifyNeedPermission", L(PLUGIN.PermissionTranslations[BANKINGPERM_DEPOSIT_WITHDRAW], character:GetPlayer())}
        end

        if not character:HasMoney(money) then
            return false, "bankingNotifyInsufficientWallet"
        end

        character:TakeMoney(money)

        self:SetMoney(self.money + money, bNoReplication)

        if !bNoGenericLog then
            ix.banking.CreateLog("deposit", nil, self:GetID(), character:GetName(), character:GetID(), money, self.money)
        end

        return self.money
    end

    function META:Withdraw(character, money, bNoGenericLog, bNoReplication)
        if not self:HasPermission(character:GetID(), BANKINGPERM_DEPOSIT_WITHDRAW) then
            return false, {"bankingNotifyNeedPermission", L(PLUGIN.PermissionTranslations[BANKINGPERM_DEPOSIT_WITHDRAW], character:GetPlayer())}
        end

        if self.money < money then
            return false, "bankingNotifyInsufficientBalance"
        end

        self:SetMoney(self.money - money, bNoReplication)

        character:GiveMoney(money)

        if !bNoGenericLog then
            ix.banking.CreateLog("withdraw", nil, self:GetID(), character:GetName(), character:GetID(), money, self.money)
        end

        return self.money
    end

    function META:Transfer(id, money, callback)
        return ix.banking.Transfer(self:GetID(), id, money, callback)
    end

    function META:AddAccountHolder(charID, defaultPerm, bNoReplication, bNoSave)
        if self.accountHolders[charID] then
            return false, "bankingNotifyTargetAlreadyAccountHolder"
        end

        defaultPerm = defaultPerm or 0

        self.accountHolders[charID] = defaultPerm

        ix.banking.accountsByChar[charID] = ix.banking.accountsByChar[charID] or {}
        ix.banking.accountsByChar[charID][self:GetID()] = self

        if not bNoSave then
            local query = mysql:Insert("ix_banking_users")
                query:Insert("account_id", self:GetID())
                query:Insert("character_id", charID)
                query:Insert("permissions", defaultPerm)
            query:Execute()
        end

        if not bNoReplication then
            net.Start("ixBankingAccountHolder")
                net.WriteUInt(self:GetID(), 32)
                net.WriteUInt(charID, 32)
                net.WriteBool(true)
                net.WriteUInt(defaultPerm, 8)
            net.Send(self:GetPlayerHolders())
        end

        return true
    end

    function META:RemoveAccountHolder(charID, bNoReplication, bNoSave)
        if not self.accountHolders[charID] then
            return false, "bankingNotifyTargetNotAccountHolder"
        end

        self.accountHolders[charID] = nil

        ix.banking.accountsByChar[charID][self:GetID()] = nil

        if not bNoSave then
            local query = mysql:Delete("ix_banking_users")
                query:Where("account_id", self:GetID())
                query:Where("character_id", charID)
            query:Execute()
        end

        if not bNoReplication then
            local char = ix.char.loaded[charID]
            local removedPlayer
            if char then
                removedPlayer = char:GetPlayer()
            end

            local targets = self:GetPlayerHolders()
            targets[#targets + 1] = removedPlayer

            net.Start("ixBankingAccountHolder")
                net.WriteUInt(self:GetID(), 32)
                net.WriteUInt(charID, 32)
                net.WriteBool(false)
            net.Send(targets)
        end

        return true
    end

    function META:GivePermission(charID, permission, bNoReplication, bNoSave)
        if not self.accountHolders[charID] then
            return false, "bankingNotifyTargetNotAccountHolder"
        end

        if self:HasPermission(charID, permission) then
            return false, "bankingNotifyTargetAlreadyPermission"
        end

        self.accountHolders[charID] = self.accountHolders[charID] + permission

        if not bNoSave then
            local query = mysql:Update("ix_banking_users")
                query:Update("permissions", self.accountHolders[charID])
                query:Where("account_id", self:GetID())
                query:Where("character_id", charID)
            query:Execute()
        end

        if not bNoReplication then
            net.Start("ixBankingPermission")
                net.WriteUInt(self:GetID(), 32)
                net.WriteUInt(charID, 32)
                net.WriteUInt(permission, 8)
                net.WriteBool(true)
            net.Send(self:GetPlayerHolders())
        end

        return true
    end

    function META:TakePermission(charID, permission, bNoReplication, bNoSave)
        if not self.accountHolders[charID] then
            return false, "bankingNotifyTargetNotAccountHolder"
        end

        if not self:HasPermission(charID, permission) then
            return false, "bankingNotifyTargetNotPermission"
        end

        self.accountHolders[charID] = self.accountHolders[charID] - permission

        if not bNoSave then
            local query = mysql:Update("ix_banking_users")
                query:Update("permissions", self.accountHolders[charID])
                query:Where("account_id", self:GetID())
                query:Where("character_id", charID)
            query:Execute()
        end

        if not bNoReplication then
            net.Start("ixBankingPermission")
                net.WriteUInt(self:GetID(), 32)
                net.WriteUInt(charID, 32)
                net.WriteUInt(permission, 8)
                net.WriteBool(false)
            net.Send(self:GetPlayerHolders())
        end

        return true
    end

    function META:Sync(receiver)
        if not receiver then
            receiver = self:GetPlayerHolders()
        end

        net.Start("ixBankingSyncAccount")
            net.WriteUInt(self.id, 32)
            net.WriteString(self.type)
            net.WriteString(self.name)
            net.WriteUInt(ix.currency.ToCents(self.money), 32)
            net.WriteTable(self.data)

            net.WriteUInt(table.Count(self.accountHolders), 10)
            for k, v in pairs(self.accountHolders) do
                net.WriteUInt(k, 32)
                net.WriteUInt(v, 8)
            end
        net.Send(receiver)
    end

    function META:GetPlayerHolders()
        local clients = {}
        for k in pairs(self.accountHolders) do
            local char = ix.char.loaded[k]
            if char and IsValid(char:GetPlayer()) then
                clients[char:GetPlayer()] = true
            end
        end
        return table.GetKeys(clients)
    end
end

ix.banking.meta = META

META = ix.banking.governmentMeta or ix.middleclass("ix_bankingGovernmentAccount", ix.banking.meta)

META.type = "government"
META.bHasSingleOwner = false

function META:HasPermission(charID, permission)
    if not self.accountHolders[charID] then
        return false
    end

    if bit.band(self.accountHolders[charID], permission) != permission then
        return false
    end

    if permission == BANKINGPERM_MANAGE_HOLDERS or permission == BANKINGPERM_OWNER then
        return false
    end

    return true
end

function META:GetOwner()
    return false
end

ix.banking.governmentMeta = META