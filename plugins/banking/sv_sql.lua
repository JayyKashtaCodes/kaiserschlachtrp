local PLUGIN = PLUGIN

ix.banking.logRequests = ix.banking.logRequests or {}

function ix.banking.LoadDBTables()
    local query = mysql:Create("ix_banking_accounts")
        query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("type", "VARCHAR(255) NOT NULL")
        query:Create("name", "VARCHAR(255) NOT NULL")
        query:Create("money", "INT(11) UNSIGNED NOT NULL")
        query:Create("data", "TEXT")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("ix_banking_users")
        query:Create("account_id", "INT(11) UNSIGNED NOT NULL")
        query:Create("character_id", "INT(11) UNSIGNED NOT NULL")
        query:Create("permissions", "SMALLINT UNSIGNED NOT NULL")
    query:Execute()

    query = mysql:Create("ix_banking_logs")
        query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("log_type", "VARCHAR(255) NOT NULL")
        query:Create("time", "INT(11) UNSIGNED NOT NULL")
        query:Create("account_id", "INT(11) UNSIGNED NOT NULL")
        query:Create("data", "TEXT")
        query:PrimaryKey("id")
    query:Execute()
end

-- checks if the character id has accounts associated with it, loads said accounts, then loads all associated account holders as well
-- we out-building the pyramids with this one
function ix.banking.LoadAccounts(id, callback)
    local bCallback = false
    local query = mysql:Select("ix_banking_users")
        query:Select("account_id")
        if istable(id) then
            query:WhereIn("character_id", id)
        else
            query:Where("character_id", id)
        end
        -- exclude accounts that are already loaded
        -- this is to prevent loading the same accounts multiple times, which can happen if multiple characters are associated with the same account
        -- or if the same character is associated with multiple accounts
        -- this is also to prevent loading accounts that are not associated with the character at all
        local excludedIDs = table.GetKeys(ix.banking.accounts)
        if #excludedIDs > 0 then
            query:WhereNotIn("account_id", excludedIDs)
        end
        ------------
        query:Callback(function(result)
            if istable(result) and #result > 0 then
                local ids = {}
                for k, v in ipairs(result) do
                    ids[k] = tonumber(v.account_id)
                end

                local accountQuery = mysql:Select("ix_banking_accounts")
                    accountQuery:Select("id")
                    accountQuery:Select("type")
                    accountQuery:Select("name")
                    accountQuery:Select("money")
                    accountQuery:Select("data")
                    accountQuery:WhereIn("id", ids)
                    accountQuery:Callback(function(accountResults)
                        if istable(accountResults) and #accountResults > 0 then
                            for k, v in ipairs(accountResults) do
                                local metaType = ix.banking.accountTypes[v.type]
                                local account = metaType:New(
                                    tonumber(v.id),
                                    v.name,
                                    ix.currency.FromCents(tonumber(v.money)),
                                    util.JSONToTable(v.data)
                                )

                                ix.banking.accounts[tonumber(v.id)] = account
                            end

                            if #ids != #accountResults then
                                ids = {}
                                for k, v in ipairs(accountResults) do
                                    ids[k] = tonumber(v.id)
                                end
                            end

                            local usersQuery = mysql:Select("ix_banking_users")
                                usersQuery:Select("account_id")
                                usersQuery:Select("character_id")
                                usersQuery:Select("permissions")
                                usersQuery:WhereIn("account_id", ids)
                                usersQuery:Callback(function(userResults)
                                    if istable(userResults) and #userResults > 0 then
                                        for k, v in ipairs(userResults) do
                                            local accountID, charID, permissions = tonumber(v.account_id), tonumber(v.character_id), tonumber(v.permissions)
                                            local account = ix.banking.accounts[accountID]
                                            if account then
                                                account.accountHolders = account.accountHolders or {}

                                                account.accountHolders[charID] = permissions

                                                ix.banking.accountsByChar[charID] = ix.banking.accountsByChar[charID] or {}
                                                ix.banking.accountsByChar[charID][accountID] = account
                                            end
                                        end

                                        if callback then
                                            bCallback = true

                                            callback()
                                        end
                                    end
                                end)
                            usersQuery:Execute()
                        end
                    end)
                accountQuery:Execute()
            end
        end)
    query:Execute()

    if callback and not bCallback then
        callback()
    end
end

function ix.banking.LoadAccount(accountID, callback)
    local accountQuery = mysql:Select("ix_banking_accounts")
        accountQuery:Select("id")
        accountQuery:Select("type")
        accountQuery:Select("name")
        accountQuery:Select("money")
        accountQuery:Select("data")
        accountQuery:Where("id", accountID)
        accountQuery:Callback(function(accountResults)
            if istable(accountResults) and #accountResults > 0 then
                local v = accountResults[1]
                local metaType = ix.banking.accountTypes[v.type]
                local account = metaType:New(
                    tonumber(v.id),
                    v.name,
                    ix.currency.FromCents(tonumber(v.money)),
                    util.JSONToTable(v.data)
                )
                ix.banking.accounts[tonumber(v.id)] = account

                local usersQuery = mysql:Select("ix_banking_users")
                    usersQuery:Select("account_id")
                    usersQuery:Select("character_id")
                    usersQuery:Select("permissions")
                    usersQuery:Where("account_id", accountID)
                    usersQuery:Callback(function(userResults)
                        if istable(userResults) and #userResults > 0 then
                            for k, v in ipairs(userResults) do
                                local accountID, charID, permissions = tonumber(v.account_id), tonumber(v.character_id), tonumber(v.permissions)
                                local account = ix.banking.accounts[accountID]
                                if account then
                                    account.accountHolders = account.accountHolders or {}
                                    account.accountHolders[charID] = permissions
                                    ix.banking.accountsByChar[charID] = ix.banking.accountsByChar[charID] or {}
                                    ix.banking.accountsByChar[charID][accountID] = account
                                end
                            end
                        end
                        if callback then
                            callback()
                        end
                    end)
                usersQuery:Execute()
            else
                if callback then
                    callback()
                end
            end
        end)
    accountQuery:Execute()
end

-- check if client is actually at the service customer/teller ent
function ix.banking.IsClientAtEnt(client, entType)
    for k, v in ipairs(ents.FindByClass(entType == 1 and "ix_banking_service" or "ix_banking_teller")) do
        if client:GetPos():Distance(v:GetPos()) <= 96 then
            return true
        end
    end
    return false
end

function ix.banking.CreateLog(logType, time, id, ...)
    time = time or os.time()

    hook.Run("BankingLogCreated", logType, time, id, ...)

    local query = mysql:Insert("ix_banking_logs")
        query:Insert("log_type", logType)
        query:Insert("time", time)
        query:Insert("account_id", id)
        query:Insert("data", util.TableToJSON({...}))
    query:Execute()
end

function ix.banking.Transfer(id, receiverID, money, callback)
    local account = ix.banking.accounts[id]
    local receivingAccount = ix.banking.accounts[receiverID]

    if account and receivingAccount then
        if account:GetMoney() < money then
            callback(false, "bankingNotifyInsufficientBalance")
            return
        end

        account:SetMoney(account:GetMoney() - money)
        receivingAccount:SetMoney(receivingAccount:GetMoney() + money)

        callback(true, account:GetMoney(), receivingAccount:GetMoney())
    elseif account and not receivingAccount then
        if account:GetMoney() < money then
            callback(false, "bankingNotifyInsufficientBalance")
            return
        end

        local query = mysql:Select("ix_banking_accounts")
            query:Select("money")
            query:Where("id", receiverID)
            query:Callback(function(result)
                if result and #result == 1 then
                    local updateQuery = mysql:Update("ix_banking_accounts")
                        updateQuery:Update("money", tonumber(result[1].money) + money)
                        updateQuery:Where("id", id)
                    updateQuery:Execute()

                    account:SetMoney(account:GetMoney() - money)
                    
                    callback(true, account:GetMoney(), tonumber(result[1].money) + money)
                    return
                else
                    callback(false, "bankingNotifyAccountNotFound")
                end
            end)
        query:Execute()
    elseif not account and receivingAccount then -- i cant imagine the last two cases every happening but could be useful 
        local query = mysql:Select("ix_banking_accounts")
            query:Select("money")
            query:Where("id", id)
            query:Callback(function(result)
                if result and #result == 1 then
                    local accountMoney = tonumber(result[1].money)
                    if accountMoney < money then
                        callback(false, "bankingNotifyInsufficientBalance")
                        return
                    end

                    local updateQuery = mysql:Update("ix_banking_accounts")
                        updateQuery:Update("money", accountMoney - money)
                        updateQuery:Where("id", id)
                        updateQuery:Callback(function(updateResult)
                            if istable(updateResult) and #updateResult > 0 then
                                receivingAccount:SetMoney(receivingAccount:GetMoney() + money)

                                callback(true, accountMoney - money, receivingAccount:GetMoney())
                            end
                        end)
                    updateQuery:Execute()
                else
                    callback(false, "bankingNotifyAccountNotFound")
                end
            end)
        query:Execute()
    else
        local query = mysql:Select("ix_banking_accounts")
            query:Select("id")
            query:Select("money")
            query:WhereIn("id", {id, receiverID})
            query:Callback(function(result)
                if result and #result == 2 then
                    if tonumber(result[1].id) == id then
                        account = result[1]
                        receivingAccount = result[2]
                    else
                        account = result[2]
                        receivingAccount = result[1]
                    end

                    local accountMoney = tonumber(account.money)
                    if accountMoney < money then
                        callback(false, "bankingNotifyInsufficientBalance")
                        return
                    end

                    local updateQuery = mysql:Update("ix_banking_accounts")
                        updateQuery:Update("money", accountMoney - money)
                        updateQuery:Where("id", id)
                        updateQuery:Callback(function(updateResult)
                            local updateReceivingQuery = mysql:Update("ix_banking_accounts")
                                updateReceivingQuery:Update("money", tonumber(receivingAccount.money) + money)
                                updateReceivingQuery:Where("id", receiverID)
                            updateReceivingQuery:Execute()

                            callback(true, accountMoney - money, tonumber(receivingAccount.money) + money)
                        end)
                    updateQuery:Execute()
                else
                    callback(false, "bankingNotifyAccountNotFound")
                end
            end)
        query:Execute()
    end
end
