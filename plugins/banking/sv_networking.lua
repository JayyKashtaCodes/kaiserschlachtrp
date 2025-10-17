local PLUGIN = PLUGIN

util.AddNetworkString("ixBankingSyncAccount")
util.AddNetworkString("ixBankingSyncMoney")
util.AddNetworkString("ixBankingSyncOffset")

util.AddNetworkString("ixBankingViewService")
util.AddNetworkString("ixBankingViewTeller")

util.AddNetworkString("ixBankingDeposit")
util.AddNetworkString("ixBankingWithdraw")
util.AddNetworkString("ixBankingSend")
util.AddNetworkString("ixBankingAccountHolder")
util.AddNetworkString("ixBankingPermission")
util.AddNetworkString("ixBankingNewAccount")
util.AddNetworkString("ixBankingCloseAccount")
util.AddNetworkString("ixBankingTransferOwnership")
util.AddNetworkString("ixBankingLogs")

util.AddNetworkString("ixBankingGetAccounts")

net.Receive("ixBankingNewAccount", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 1) then
        client:NotifyLocalized("bankingNotifyMustBeNearCustomerService")
        return
    end

    local char = client:GetCharacter()
    if not char then
        return
    end

    local result, reason = hook.Run("BankingCanCreateAccount", client)
    if result == false then
        if reason then
            client:NotifyLocalized(reason)
        end
        return
    end
    
    local name = net.ReadString()

    local query = mysql:Insert("ix_banking_accounts")
        query:Insert("type", "standard")
        query:Insert("name", name)
        query:Insert("money", 0)
        query:Insert("data", util.TableToJSON({}))
        query:Callback(function(result, status, lastID)
            local insertQuery = mysql:Insert("ix_banking_users")
                insertQuery:Insert("account_id", lastID)
                insertQuery:Insert("character_id", char:GetID())
                insertQuery:Insert("permissions", ix.banking.GetBankingPermissionsSum())
            insertQuery:Execute()

            local accountType = ix.banking.accountTypes.standard

            local account = accountType:New(lastID, name, 0, {})
            account.accountHolders[char:GetID()] = ix.banking.GetBankingPermissionsSum()

            ix.banking.accounts[lastID] = account
            ix.banking.accountsByChar[char:GetID()] = ix.banking.accountsByChar[char:GetID()] or {}
            ix.banking.accountsByChar[char:GetID()][lastID] = account

            account:Sync(client)

            ix.banking.CreateLog("accountOpened", nil, lastID, char:GetName(), char:GetID())
        end)
    query:Execute()
end)

net.Receive("ixBankingCloseAccount", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 1) then
        client:NotifyLocalized("bankingNotifyMustBeNearCustomerService")
        return
    end

    local char = client:GetChar()
    if not char then
        return
    end

    local accountID = net.ReadUInt(32)
    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    if not account:HasPermission(char:GetID(), BANKINGPERM_OWNER) then
        client:NotifyLocalized("bankingNotifyNeedPermission", L(PLUGIN.PermissionTranslations[BANKINGPERM_OWNER], client))
        return
    end

    local result, reason = hook.Run("BankingCanCloseAccount", account, char)
    if result == false then
        client:Notify(reason)
        return
    end

    local money = account.money
    if money > 0 then
        char:GiveMoney(money)
        client:NotifyLocalized("moneyTaken", ix.currency.Get(amount))
    end

    for k, v in pairs(account.accountHolders) do
        ix.banking.accountsByChar[k][account:GetID()] = nil
    end
    ix.banking.accounts[account:GetID()] = nil

    local query = mysql:Delete("ix_banking_accounts")
        query:Where("id", account:GetID())
    query:Execute()

    query = mysql:Delete("ix_banking_users")
        query:Where("account_id", account:GetID())
    query:Execute()

    query = mysql:Delete("ix_banking_logs")
        query:Where("account_id", account:GetID())
    query:Execute()

    net.Start("ixBankingCloseAccount")
        net.WriteUInt(account:GetID(), 32)
    net.Send(account:GetPlayerHolders())
end)

net.Receive("ixBankingTransferOwnership", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 1) then
        client:NotifyLocalized("bankingNotifyMustBeNearCustomerService")
        return
    end

    local char = client:GetChar()
    if not char then
        return
    end

    local accountID = net.ReadUInt(32)
    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    if not account:HasPermission(char:GetID(), BANKINGPERM_OWNER) then
        client:NotifyLocalized("bankingNotifyNeedPermission", L(PLUGIN.PermissionTranslations[BANKINGPERM_OWNER], client))
        return
    end

    local targetID = net.ReadUInt(32)
    if not account.accountHolders[targetID] then
        client:NotifyLocalized("bankingNotifyTargetNotAccountHolder")
        return
    end

    local result, reason = hook.Run("BankingCanTransferOwnership", account, char, targetID)
    if result == false then
        client:Notify(reason)
        return
    end

    account:TakePermission(char:GetID(), BANKINGPERM_OWNER, true)

    account.accountHolders[targetID] = ix.banking.GetBankingPermissionsSum()

    local query = mysql:Update("ix_banking_users")
        query:Update("permissions", account.accountHolders[targetID])
        query:Where("account_id", accountID)
        query:Where("character_id", targetID)
    query:Execute()

    net.Start("ixBankingTransferOwnership")
        net.WriteUInt(accountID, 32)
        net.WriteUInt(char:GetID(), 32)
        net.WriteUInt(targetID, 32)
    net.Send(account:GetPlayerHolders())

    local targetChar = ix.char.loaded[targetID]
    local targetName = targetChar and targetChar:GetName() or (ix.banking.offlineCharacters[targetID] and ix.banking.offlineCharacters[targetID].name or "MISSING NAME")

    ix.banking.CreateLog("accountTransferred", nil, accountID, char:GetName(), char:GetID(), targetName, targetID)
end)

net.Receive("ixBankingDeposit", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 0) then
        client:NotifyLocalized("bankingNotifyMustBeNearTeller")
        return
    end

    local accountID = net.ReadUInt(32)
    local money = ix.currency.FromCents(net.ReadUInt(32))

    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    local char = client:GetCharacter()
    if not char then
        return
    end

    if money <= 0 then
        client:NotifyLocalized("bankingNotifyMoneyMin")
        return
    end

    local balance, reason = account:Deposit(char, money)
    if balance then
        client:NotifyLocalized("bankingNotifyDeposit", ix.currency.Get(balance))
    else
        -- meh
        client:NotifyLocalized(istable(reason) and unpack(reason) or reason)
    end
end)

net.Receive("ixBankingWithdraw", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 0) then
        client:NotifyLocalized("bankingNotifyMustBeNearTeller")
        return
    end

    local accountID = net.ReadUInt(32)
    local money = ix.currency.FromCents(net.ReadUInt(32))

    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    local char = client:GetCharacter()
    if not char then
        return
    end

    if money <= 0 then
        client:NotifyLocalized("bankingNotifyMoneyMin")
        return
    end

    local balance, reason = account:Withdraw(char, money)
    if balance then
        client:NotifyLocalized("bankingNotifyWithdraw", ix.currency.Get(ix.currency.FromCents(balance)))
    else
        -- meh
        client:NotifyLocalized(istable(reason) and unpack(reason) or reason)
    end
end)

net.Receive("ixBankingSend", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 0) then
        client:NotifyLocalized("bankingNotifyMustBeNearTeller")
        return
    end

    local accountID = net.ReadUInt(32)
    local receiverAccountID = net.ReadUInt(32)
    local money = net.ReadUInt(32)

    local char = client:GetCharacter()
    if not char then
        return
    end

    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    if not account:HasPermission(char:GetID(), BANKINGPERM_SEND) then
        client:NotifyLocalized("bankingNotifyNeedPermission", L(PLUGIN.PermissionTranslations[BANKINGPERM_SEND], client))
        return
    end

    receiverAccountID = receiverAccountID - ix.banking.accountIDOffset

    if account:GetID() == receiverAccountID then
        client:NotifyLocalized("bankingNotifyCantSendToSelf")
        return
    end

    if account:GetMoney() < money then
        client:NotifyLocalized("bankingNotifyInsufficientBalance")
        return
    end

    if money <= 0 then
        client:NotifyLocalized("bankingNotifyMoneyMin")
        return
    end

    -- notify doubles as the accountSender Balance. probably pointless
    ix.banking.Transfer(accountID, receiverAccountID, money, function(result, notify, receiverBalance)
        if result == false then
            client:NotifyLocalized(notify)
            return
        end

        client:NotifyLocalized("bankingNotifySendSuccess", ix.currency.Get(money), receiverAccountID + ix.banking.accountIDOffset)

        ix.banking.CreateLog("sendMoney", nil, accountID, receiverAccountID, char:GetName(), char:GetID(), money, notify)
        ix.banking.CreateLog("receiveMoney", nil, receiverAccountID, accountID, char:GetName(), char:GetID(), money, receiverBalance)
    end)
end)

net.Receive("ixBankingAccountHolder", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 1) then
        client:NotifyLocalized("bankingNotifyMustBeNearCustomerService")
        return
    end

    local accountID = net.ReadUInt(32)
    local targetID = net.ReadUInt(32)
    local add = net.ReadBool()

    local account = ix.banking.accounts[accountID]
    if not account then
        -- notify
        return
    end

    local char = client:GetCharacter()
    if not char then
        -- notify
        return
    end

    if char:GetID() == targetID then
        client:NotifyLocalized("bankingNotifyCantTargetSelf")
        return
    end

    if not account:HasPermission(char:GetID(), BANKINGPERM_MANAGE_HOLDERS) then
        client:NotifyLocalized("bankingNotifyNeedPermission", L(PLUGIN.PermissionTranslations[BANKINGPERM_MANAGE_HOLDERS], client))
        return
    end

    local targetChar = ix.char.loaded[targetID]
    if not targetChar then
        -- notify
        return
    end

    if add then
        local bNoSave = false
        local targetPlayer = targetChar:GetPlayer()
        if targetPlayer:IsBot() then
            bNoSave = true
        end

        local result, notify = account:AddAccountHolder(targetID, nil, nil, bNoSave)
        if result then
            account:Sync(targetPlayer)

            if !bNoSave then
                ix.banking.CreateLog("addAccountHolder", nil, accountID, char:GetName(), char:GetID(), targetChar:GetName(), targetID)
            end
        else
            client:NotifyLocalized(notify)
        end
    else
        if account:HasPermission(targetID, BANKINGPERM_MANAGE_HOLDERS) then
            if not account:HasPermission(char:GetID(), BANKINGPERM_OWNER) then
                client:NotifyLocalized("bankingNotifyNeedOwner")
                return
            end
        end

        local bNoSave = false
        local targetPlayer = targetChar:GetPlayer()
        if IsValid(targetPlayer) and targetPlayer:IsBot() then
            bNoSave = true
        end

        local result, notify = account:RemoveAccountHolder(targetID, nil, bNoSave)
        if result then
            if !bNoSave then
                local targetName = targetChar and targetChar:GetName() or (ix.banking.offlineCharacters[targetID] and ix.banking.offlineCharacters[targetID].name or "MISSING NAME")
                ix.banking.CreateLog("removeAccountHolder", nil, accountID, char:GetName(), char:GetID(), targetName, targetID)
            end
        else
            client:NotifyLocalized(notify)
        end
    end
end)

net.Receive("ixBankingPermission", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 1) then
        client:NotifyLocalized("bankingNotifyMustBeNearCustomerService")
        return
    end

    local accountID = net.ReadUInt(32)
    local targetID = net.ReadUInt(32)
    local permission = net.ReadUInt(8)
    local add = net.ReadBool()

    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    local char = client:GetCharacter()
    if not char then
        return
    end

    if char:GetID() == targetID then
        client:NotifyLocalized("bankingNotifyCantTargetSelf")
        return
    end

    if not account:HasPermission(char:GetID(), BANKINGPERM_MANAGE_HOLDERS) then
        return
    end

    if account:HasPermission(targetID, BANKINGPERM_MANAGE_HOLDERS) then
        if not account:HasPermission(char:GetID(), BANKINGPERM_OWNER) then
            client:NotifyLocalized("bankingNotifyNeedOwner")
            return
        end
    end

    if hook.Run("BankingCanChangePermission", account, char, targetID, permission) == false then
        return
    end

    local bNoSave = false
    local targetChar = ix.char.loaded[targetID]
    if targetChar then
        local targetPlayer = targetChar:GetPlayer()
        if IsValid(targetPlayer) and targetPlayer:IsBot() then
            bNoSave = true
        end
    end

    local targetName = targetChar and targetChar:GetName() or (ix.banking.offlineCharacters[targetID] and ix.banking.offlineCharacters[targetID].name or "MISSING NAME")
    if add then
        local result, notify = account:GivePermission(targetID, permission, nil, bNoSave)
        if result then
            if !bNoSave then
                ix.banking.CreateLog("givePermission", nil, accountID, char:GetName(), char:GetID(), targetName, targetID, permission)
            end
        else
            client:NotifyLocalized(notify)
        end
    else
        local result, notify = account:TakePermission(targetID, permission, nil, bNoSave)
        if result then
            if !bNoSave then
                ix.banking.CreateLog("takePermission", nil, accountID, char:GetName(), char:GetID(), targetName, targetID, permission)
            end
        else
            client:NotifyLocalized(notify)
        end
    end
end)

net.Receive("ixBankingLogs", function(l, client)
    if not ix.banking.IsClientAtEnt(client, 1) then
        client:NotifyLocalized("bankingNotifyMustBeNearCustomerService")
        return
    end

    local accountID = net.ReadUInt(32)
    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    local char = client:GetCharacter()
    if not char then
        return
    end

    if not account:HasPermission(char:GetID(), BANKINGPERM_LOG) then
        return
    end

    if not ix.banking.CanRequestLogRateLimit(client, accountID) then
        client:NotifyLocalized("bankingNotifyNetworkTimeout")
        return
    end

    ix.banking.logRequests[client] = ix.banking.logRequests[client] or {}
    ix.banking.logRequests[client][accountID] = CurTime()

    local pageSize = net.ReadUInt(8)
    local lastLogID = net.ReadUInt(32)

    if pageSize < 25 or pageSize > 50 or pageSize % 5 ~= 0 then
        pageSize = 25
    end

    if lastLogID < 0 then
        lastLogID = 0
    end
    
    if lastLogID == 0 then
        local logCountQuery = mysql:Select("ix_banking_logs")
            logCountQuery.selectList[#logCountQuery.selectList + 1] = "COUNT(*)"
            logCountQuery:Where("account_id", accountID)
            logCountQuery:Callback(function(logCountResult)
                if logCountResult and logCountResult[1] then
                    local logCount = logCountResult[1]["COUNT(*)"]

                    local query = mysql:Select("ix_banking_logs")
                        query:Where("account_id", accountID)
                        if lastLogID > 0 then
                            query:WhereLT("id", lastLogID)
                        end
                        query:OrderByDesc("id")
                        query:Limit(pageSize)
                        query:Callback(function(result)
                            if result and #result > 0 then
                                local logs = {}
                                for k, v in ipairs(result) do
                                    table.insert(logs, {
                                        id = v.id,
                                        logType = v.log_type,
                                        time = tonumber(v.time),
                                        data = util.JSONToTable(v.data),
                                    })
                                end

                                net.Start("ixBankingLogs")
                                    net.WriteUInt(#logs, 8)
                                    for i = 1, #logs do
                                        local log = logs[i]
                                        net.WriteUInt(log.id, 32)
                                        net.WriteString(log.logType)
                                        net.WriteUInt(log.time, 32)
                                        net.WriteTable(log.data)
                                    end
                                    net.WriteUInt(logCount, 32)
                                net.Send(client)
                            end
                        end)
                    query:Execute()
                end
            end)
        logCountQuery:Execute()
    else
        local query = mysql:Select("ix_banking_logs")
            query:Where("account_id", accountID)
            if lastLogID > 0 then
                query:WhereLT("id", lastLogID)
            end
            query:OrderByDesc("id")
            query:Limit(pageSize)
            query:Callback(function(result, status, lastID)
                if result and #result > 0 then
                    local logs = {}
                    for k, v in ipairs(result) do
                        table.insert(logs, {
                            id = v.id,
                            logType = v.log_type,
                            time = tonumber(v.time),
                            data = util.JSONToTable(v.data),
                        })
                    end

                    net.Start("ixBankingLogs")
                        net.WriteUInt(#logs, 8)
                        for i = 1, #logs do
                            local log = logs[i]
                            net.WriteUInt(log.id, 32)
                            net.WriteString(log.logType)
                            net.WriteUInt(log.time, 32)
                            net.WriteTable(log.data)
                        end
                    net.Send(client)
                end
            end)
        query:Execute()
    end
end)
