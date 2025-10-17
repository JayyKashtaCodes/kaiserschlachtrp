local COMMAND = {}

local closureRequests = {}

COMMAND.superAdminOnly = true
COMMAND.description = "@bankingCmdCloseBankAccount"
COMMAND.arguments = {ix.type.number}
COMMAND.OnRun = function(self, client, accountID)
    local account = ix.banking.accounts[accountID]
    if account then
        if not closureRequests[accountID] or closureRequests[accountID] + 10 < CurTime() then
            closureRequests[accountID] = CurTime()

            client:ChatNotifyLocalized("bankingNotifyCmdConfirmAccountClose")
            return
        end

        closureRequests[accountID] = nil

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

        return "@bankingNotifyAccountCloseSuccess"
    else
        if closureRequests[accountID] and closureRequests[accountID] + 10 > CurTime() then
            closureRequests[accountID] = nil

            local query = mysql:Delete("ix_banking_accounts")
                query:Where("id", accountID)
            query:Execute()

            query = mysql:Delete("ix_banking_users")
                query:Where("account_id", accountID)
            query:Execute()

            query = mysql:Delete("ix_banking_logs")
                query:Where("account_id", accountID)
            query:Execute()

            return "@bankingNotifyAccountCloseSuccess"
        else
            local query = mysql:Select("ix_banking_accounts")
                query:Where("id", accountID)
                query:Callback(function(result)
                    if result and #result > 0 then
                        closureRequests[accountID] = CurTime()

                        client:ChatNotifyLocalized("bankingNotifyCmdConfirmAccountClose")
                    else
                        client:NotifyLocalized("bankingNotifyAccountNotFound")
                    end
                end)
            query:Execute()
        end
    end
end

ix.command.Add("CloseBankAccount", COMMAND)