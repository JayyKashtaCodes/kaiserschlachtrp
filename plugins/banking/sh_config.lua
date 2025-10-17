local PLUGIN = PLUGIN

-- this also needs to be reworked...
-- some data should not be shared with clients that dont need it (char ids, i saved them for admins but i didnt get around to implementing that)
-- also saving data and loading it based on the order its given in the function arguments is not ideal
ix.banking.RegisterLogType("deposit", function(accountID, _, charName, charID, depositedMoney, money)
    return L("bankingDepositedLog", charName, ix.currency.Get(depositedMoney), ix.currency.Get(money))
end, Color(100, 180, 100))

ix.banking.RegisterLogType("withdraw", function(accountID, _, charName, charID, withdrawnMoney, money)
    return L("bankingWithdrawnLog", charName, ix.currency.Get(withdrawnMoney), ix.currency.Get(money))
end, Color(170, 80, 80))


ix.banking.RegisterLogType("sendMoney", function(accountID, _, targetID, charName, charID, sendMoney, money)
    return L("bankingSendMoneyLog", charName, ix.currency.Get(sendMoney), ix.currency.Get(money), targetID + ix.banking.accountIDOffset)
end)

ix.banking.RegisterLogType("receiveMoney", function(accountID, _, senderID, receiverCharName, receiverCharID, receiveMoney, money)
    return L("bankingReceiveMoneyLog", ix.currency.Get(receiveMoney), ix.currency.Get(money), senderID + ix.banking.accountIDOffset, receiverCharName)
end)

ix.banking.RegisterLogType("setMoney", function(accountID, _, money)
    return L("bankingSetMoneyLog", ix.currency.Get(money))
end)

ix.banking.RegisterLogType("addAccountHolder", function(accountID, _, charName, charID, targetName, targetID, bAdminAction)
    return L(bAdminAction and "bankingAddAccountHolderAdminLog" or "bankingAddAccountHolderLog", charName, targetName)
end, Color(134, 104, 138))

ix.banking.RegisterLogType("removeAccountHolder", function(accountID, _, charName, charID, targetName, targetID, bAdminAction)
    return L(bAdminAction and "bankingRemoveAccountHolderAdminLog" or "bankingRemoveAccountHolderLog", charName, targetName)
end, Color(134, 104, 138))

ix.banking.RegisterLogType("givePermission", function(accountID, _, charName, charID, targetName, targetID, permission, bAdminAction)
    return L(bAdminAction and "bankingGivePermissionAdminLog" or "bankingGivePermissionLog", charName, targetName, L(PLUGIN.PermissionTranslations[permission]))
end, Color(100, 121, 180))

ix.banking.RegisterLogType("takePermission", function(accountID, _, charName, charID, targetName, targetID, permission, bAdminAction)
    return L(bAdminAction and "bankingTakePermissionAdminLog" or "bankingTakePermissionLog", charName, L(PLUGIN.PermissionTranslations[permission]), targetName)
end, Color(180, 132, 100))

ix.banking.RegisterLogType("accountOpened", function(accountID, time, charName, charID, bAdminAction)
    return bAdminAction and L"bankingAccountOpenedGenericLog" or L("bankingAccountOpenedLog", charName)
end, Color(150, 80, 160))

ix.banking.RegisterLogType("accountTransferred", function(accountID, time, charName, charID, targetName, targetID, bAdminAction)
    return L(bAdminAction and "bankingAccountTransferredAdminLog" or "bankingAccountTransferredLog", charName, targetName)
end, Color(209, 97, 166))

ix.banking.RegisterLogType("accountOwnerSet", function(accountID, time, newOwnerCharName, newOwnerCharID)
    return L("bankingAccountOwnerSetLog", newOwnerCharName)
end, Color(209, 97, 166))

ix.banking.RegisterType("standard", ix.banking.meta)
ix.banking.RegisterType("government", ix.banking.governmentMeta)
-- savings?

ix.config.Add("bankingMaxAccounts", 3, "The maximum amount of accounts a character can have.", nil, {
    data = {min = 0, max = 100},
    category = PLUGIN.name,
})

PLUGIN.PermissionTranslations = {
    [BANKINGPERM_DEPOSIT_WITHDRAW] = "bankingPermissionDepositWithdraw",
    [BANKINGPERM_SEND] = "bankingPermissionSend",
    [BANKINGPERM_LOG] = "bankingPermissionLog",
    [BANKINGPERM_MANAGE_HOLDERS] = "bankingPermissionManageHolders",
    [BANKINGPERM_OWNER] = "bankingPermissionOwner"
}