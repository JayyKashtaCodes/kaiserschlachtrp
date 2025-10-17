local COMMAND = {}

COMMAND.superAdminOnly = true
COMMAND.description = "@bankingCmdCreateBankAccount"
COMMAND.arguments = {
    bit.bor(ix.type.string, ix.type.optional),
    bit.bor(ix.type.string, ix.type.optional),
    bit.bor(ix.type.number, ix.type.optional),
    bit.bor(ix.type.bool, ix.type.optional),
    bit.bor(ix.type.bool, ix.type.optional),
}
COMMAND.OnRun = function(self, client, accountType, accountName, startingMoney, bAddSelfToAccount, bGenericCreationLog)
    local allowedTypes = {
        standard = true,
        government = true,
    }

    accountType = accountType or "standard"

    if not allowedTypes[accountType:lower():Trim()] then
        return "@bankingNotfyInvalidAccountType", accountType
    end

    accountName = accountName or ""
    startingMoney = math.max(startingMoney or 0, 0)

    if newBalance > 1000000000 then
        return "@bankingNotifyBalanceTooHigh"
    end

    local query = mysql:Insert("ix_banking_accounts")
        query:Insert("type", accountType)
        query:Insert("name", accountName)
        query:Insert("money", startingMoney)
        query:Insert("data", util.TableToJSON({}))
        query:Callback(function(result, status, lastID)
            if lastID then
                local accountType = ix.banking.accountTypes[accountType]

                local account = accountType:New(lastID, accountName, startingMoney, {})

                ix.banking.accounts[lastID] = account

                local char = client:GetCharacter()

                if bAddSelfToAccount then
                    local insertQuery = mysql:Insert("ix_banking_users")
                        insertQuery:Insert("account_id", lastID)
                        insertQuery:Insert("character_id", char:GetID())
                        insertQuery:Insert("permissions", ix.banking.GetBankingPermissionsSum())
                    insertQuery:Execute()

                    account.accountHolders[char:GetID()] = ix.banking.GetBankingPermissionsSum()

                    ix.banking.accountsByChar[char:GetID()] = ix.banking.accountsByChar[char:GetID()] or {}
                    ix.banking.accountsByChar[char:GetID()][lastID] = account

                    account:Sync(client)
                end

                ix.banking.CreateLog("accountOpened", nil, lastID, char:GetName(), char:GetID(), not bAddSelfToAccount)

                client:NotifyLocalized("bankingNotifyCreateAccountSuccess", lastID, ix.banking.accountIDOffset + lastID)
            else
                ErrorNoHalt(client:Name() .. " (" .. client:SteamID64() .. ")" .. " tried to create a bank account via command", accountType, accountName, startingMoney, bAddSelfToAccount, bGenericCreationLog, status)
                client:NotifyLocalized("bankingNotifyUnkownError")
            end
        end)
    query:Execute()
end

ix.command.Add("CreateBankAccount", COMMAND)