local COMMAND = {}

COMMAND.superAdminOnly = true
COMMAND.description = "@bankingCmdCharRemoveBank"
COMMAND.arguments = {ix.type.number, ix.type.character}
COMMAND.OnRun = function(self, client, accountID, targetCharacter)
    local char = client:GetCharacter()

    local account = ix.banking.accounts[accountID]
    if account then
        local result, notify = account:RemoveAccountHolder(targetCharacter:GetID())
        if result then
            ix.banking.CreateLog("removeAccountHolder", nil, accountID, char:GetName(), char:GetID(), targetCharacter:GetName(), targetCharacter:GetID(), true)

            client:NotifyLocalized("bankingNotifyRemoveAccountHolderSuccess", targetCharacter:GetName())
        else
            return "@" .. notify
        end
    else
        return "@bankingNotifyAccountNotFound"
    end
end

ix.command.Add("CharRemoveBank", COMMAND)