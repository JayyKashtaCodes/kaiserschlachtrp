local COMMAND = {}

COMMAND.superAdminOnly = true
COMMAND.description = "@bankingCmdTransferBankOwnership"
COMMAND.arguments = {
    ix.type.number,
    ix.type.character
}
COMMAND.OnRun = function(self, client, accountID, targetCharacter)
    local account = ix.banking.accounts[accountID]
    if account then
        if account.bHasSingleOwner == false then
            return "@bankingNotifyAccountTypeNotOwner"
        end

        if not account.accountHolders[targetCharacter:GetID()] then
            return "@bankingNotifyTargetNotAccountHolder"
        end

        if account:HasPermission(targetCharacter:GetID(), BANKINGPERM_OWNER) then
            return "@bankingNotifyTargetAlreadyOwner"
        end

        local ownerID = account:GetOwner()
        if ownerID then
            account:TakePermission(ownerID, BANKINGPERM_OWNER, true)
        end

        local targetID = targetCharacter:GetID()
        account.accountHolders[targetID] = ix.banking.GetBankingPermissionsSum()

        local query = mysql:Update("ix_banking_users")
            query:Update("permissions", account.accountHolders[targetID])
            query:Where("account_id", accountID)
            query:Where("character_id", targetID)
        query:Execute()

        net.Start("ixBankingTransferOwnership")
            net.WriteUInt(accountID, 32)
            net.WriteUInt(ownerID or 0, 32)
            net.WriteUInt(targetID, 32)
        net.Send(account:GetPlayerHolders())

        client:NotifyLocalized("bankingNotifyTransferredSuccess", targetCharacter:GetName())

        if ownerID > 0 then
            local ownerChar = ix.char.loaded[ownerID]
            if ownerChar then
                local ownerName = ownerChar and ownerChar:GetName() or (ix.banking.offlineCharacters[ownerID] and ix.banking.offlineCharacters[ownerID].name or "MISSING NAME")

                ix.banking.CreateLog("accountTransferred", nil, accountID, ownerName, ownerID, targetCharacter:GetName(), targetCharacter:GetID(), true)
            else
                local nameQuery = mysql:Select("ix_characters")
                    nameQuery:Select("name")
                    nameQuery:Where("id", ownerID)
                    nameQuery:Callback(function(nameResults)
                        if nameResults and #nameResults > 0 then
                            ix.banking.CreateLog("accountTransferred", nil, accountID, nameResults[1].name, ownerID, targetCharacter:GetName(), targetCharacter:GetID(), true)
                        else
                            ix.banking.CreateLog("accountTransferred", nil, accountID, "MISSING NAME", ownerID, targetCharacter:GetName(), targetCharacter:GetID(), true)
                        end
                    end)
                nameQuery:Execute()
            end
        else
            local char = client:GetCharacter()

            ix.banking.CreateLog("accountOwnerSet", nil, accountID, targetCharacter:GetName(), targetID)
        end
    else
        return "@bankingNotifyAccountNotFound"
    end
end

ix.command.Add("TransferBankOwnership", COMMAND)