local COMMAND = {}

COMMAND.superAdminOnly = true
COMMAND.description = "@bankingCmdCharAddBank"
COMMAND.arguments = {ix.type.number, ix.type.character}
COMMAND.OnRun = function(self, client, accountID, targetCharacter)
    local char = client:GetCharacter()

    local account = ix.banking.accounts[accountID]
    if account then
        local result, notify = account:AddAccountHolder(targetCharacter:GetID())
        if result then
            account:Sync(targetCharacter:GetPlayer())

            ix.banking.CreateLog("addAccountHolder", nil, accountID, char:GetName(), char:GetID(), targetCharacter:GetName(), targetCharacter:GetID(), true)

            return "@bankingNotifyAddAccountHolderSuccess", targetCharacter:GetName()
        else
            return "@" .. notify
        end
    else
        -- if the account is not in memory already, we have to load it anyways, for the newly added account holder to see it
        -- additionally we dont have to worry about checking if they are already an account holder, if they were, the account
        -- would have been loaded when they joined (that being said the AddAccountHolder function checks that anyways)
        local query = mysql:Select("ix_banking_accounts")
            query:Where("id", accountID)
            query:Callback(function(result)
                if result and #result > 0 then
                    ix.banking.LoadAccount(accountID, function()
                        local account = ix.banking.accounts[accountID]

                        local result, notify = account:AddAccountHolder(targetCharacter:GetID())
                        if result then
                            account:Sync(targetCharacter:GetPlayer())

                            ix.banking.CreateLog("addAccountHolder", nil, accountID, char:GetName(), char:GetID(), targetCharacter:GetName(), targetCharacter:GetID(), true)
                            
                            client:NotifyLocalized("bankingNotifyAddAccountHolderSuccess", targetCharacter:GetName())
                        else
                            client:NotifyLocalized(notify)
                        end
                    end)
                else
                    client:NotifyLocalized("bankingNotifyAccountNotFound", accountID)
                end
            end)
        query:Execute()
    end
end

ix.command.Add("CharAddBank", COMMAND)