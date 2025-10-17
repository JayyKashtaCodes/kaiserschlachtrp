local PLUGIN = PLUGIN
local COMMAND = {}

local validPermissions = {
    deposit = BANKINGPERM_DEPOSIT_WITHDRAW,
    withdraw = BANKINGPERM_DEPOSIT_WITHDRAW,
    depositwithdraw = BANKINGPERM_DEPOSIT_WITHDRAW,

    send = BANKINGPERM_SEND,

    log = BANKINGPERM_LOG,
    logs = BANKINGPERM_LOG,

    manageaccountholders = BANKINGPERM_MANAGE_HOLDERS,
    accountholders = BANKINGPERM_MANAGE_HOLDERS,
}

COMMAND.superAdminOnly = true
COMMAND.description = "@bankingCmdCharTakeBankPerm"
COMMAND.arguments = {ix.type.number, ix.type.character, ix.type.string}
COMMAND.OnRun = function(self, client, accountID, targetCharacter, permission)
    local char = client:GetCharacter()

    local account = ix.banking.accounts[accountID]
    if not account then
        return "@bankingNotifyAccountNotFound"
    end

    local permissionString = permission:lower():Replace(" ", "")
    local perm = validPermissions[permissionString]
    if not perm then
        return "@bankingNotifyPermissionNotFound", permissionString
    end

    local result, notify = account:TakePermission(targetCharacter:GetID(), perm)
    if result then
        ix.banking.CreateLog("takePermission", nil, accountID, char:GetName(), char:GetID(), targetCharacter:GetName(), targetCharacter:GetID(), perm, true)

        client:NotifyLocalized("bankingNotifyTakePermissionSuccess", L(PLUGIN.PermissionTranslations[perm], client), targetCharacter:GetName())
    else
        return "@" .. notify
    end
end

ix.command.Add("CharTakeBankPerm", COMMAND)