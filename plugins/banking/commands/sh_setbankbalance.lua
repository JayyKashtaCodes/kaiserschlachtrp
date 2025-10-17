local COMMAND = {}

COMMAND.superAdminOnly = true
COMMAND.description = "@bankingCmdSetBankBalance"
COMMAND.arguments = {
    ix.type.number,
    ix.type.number
}
COMMAND.OnRun = function(self, client, accountID, newBalance)
    newBalance = math.max(newBalance or 0, 0)
    
    -- cap it at 1 billion, net writeuint 32 can handle a little past 4 bil but just to be safe
    if newBalance > 1000000000 then
        return "@bankingNotifyBalanceTooHigh"
    end

    local account = ix.banking.accounts[accountID]
    if account then
        account:SetMoney(newBalance)
        
        local char = client:GetCharacter()
        ix.banking.CreateLog("setMoney", nil, accountID, newBalance)

        return "@bankingNotifySetBalanceSuccess", ix.currency.Get(newBalance)
    else
        local query = mysql:Select("ix_banking_accounts")
            query:Where("id", accountID)
            query:Callback(function(results)
                if results and #results > 0 then
                    local updateQuery = mysql:Update("ix_banking_accounts")
                        updateQuery:Update("money", newBalance)
                        updateQuery:Where("id", accountID)
                        updateQuery:Callback(function(updateResults)
                            local char = client:GetCharacter()
                            ix.banking.CreateLog("setMoney", nil, accountID, newBalance)

                            client:NotifyLocalized("bankingNotifySetBalanceSuccess")
                        end)
                    updateQuery:Execute()
                else
                    client:NotifyLocalized("bankingNotifyAccountNotFound")
                end
            end)
        query:Execute()
    end
end

ix.command.Add("SetBankBalance", COMMAND)