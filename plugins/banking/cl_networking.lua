local PLUGIN = PLUGIN

net.Receive("ixBankingSyncAccount", function()
    local id = net.ReadUInt(32)
    local type = net.ReadString()
    local name = net.ReadString()
    local money = ix.currency.FromCents(net.ReadUInt(32))
    local data = net.ReadTable()

    local accountHolders = {}
    for i = 1, net.ReadUInt(10) do
        accountHolders[net.ReadUInt(32)] = net.ReadUInt(8)
    end

    local metaType = ix.banking.accountTypes[type]
    local account = metaType:New(id, name, money, data)
    account.accountHolders = accountHolders

    ix.banking.accounts[id] = account
    ix.banking.accountsByChar[LocalPlayer():GetCharacter():GetID()] = ix.banking.accountsByChar[LocalPlayer():GetCharacter():GetID()] or {}
    ix.banking.accountsByChar[LocalPlayer():GetCharacter():GetID()][account.id] = account

    hook.Run("BankingAccountSync", account)
end)

net.Receive("ixBankingSyncMoney", function()
    local accountID = net.ReadUInt(32)
    local money = ix.currency.FromCents(net.ReadUInt(32))

    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    account:SetMoney(money)
end)

net.Receive("ixBankingCloseAccount", function()
    local id = net.ReadUInt(32)
    local account = ix.banking.accounts[id]

    if not account then
        return
    end

    ix.banking.accounts[id] = nil
    ix.banking.accountsByChar[LocalPlayer():GetCharacter():GetID()][id] = nil

    hook.Run("BankingAccountClosed", account)
end)

net.Receive("ixBankingTransferOwnership", function()
    local id = net.ReadUInt(32)
    local oldOwnerID = net.ReadUInt(32)
    local newOwnerID = net.ReadUInt(32)

    local account = ix.banking.accounts[id]
    if not account then
        return
    end

    if account.accountHolders[oldOwnerID] then
        account.accountHolders[oldOwnerID] = account.accountHolders[oldOwnerID] - BANKINGPERM_OWNER
    end
    account.accountHolders[newOwnerID] = ix.banking.GetBankingPermissionsSum()

    hook.Run("BankingAccountTransferred", account, oldOwnerID, newOwnerID)
end)

net.Receive("ixBankingSyncOffset", function()
    local offset = net.ReadUInt(24)

    ix.banking.accountIDOffset = offset
end)

net.Receive("ixBankingViewService", function(l)
    vgui.Create("ixBankingService")

    if l > 0 then
        local charCount = net.ReadUInt(10)
        for i = 1, charCount do
            ix.banking.offlineCharacters[net.ReadUInt(32)] = {name = net.ReadString(), model = net.ReadString()}
        end
    end
end)

net.Receive("ixBankingViewTeller", function(l)
    vgui.Create("ixBankingTeller")
end)

net.Receive("ixBankingAccountHolder", function(l)
    local accountID = net.ReadUInt(32)
    local charID = net.ReadUInt(32)
    local add = net.ReadBool()

    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end

    if add then
        local permissions = net.ReadUInt(8)

        account.accountHolders[charID] = permissions
        
        hook.Run("BankingAccountHolderAdded", account, charID, permissions)
    else
        account.accountHolders[charID] = nil

        if LocalPlayer():GetCharacter():GetID() == charID then
            ix.banking.accounts[accountID] = nil

            if ix.banking.accountsByChar[charID] then   
                ix.banking.accountsByChar[charID][accountID] = nil
            end
        end

        hook.Run("BankingAccountHolderRemoved", account, charID)
    end
end)

net.Receive("ixBankingPermission", function(l)
    local accountID = net.ReadUInt(32)
    local charID = net.ReadUInt(32)
    local permission = net.ReadUInt(8)
    local add = net.ReadBool()

    local account = ix.banking.accounts[accountID]
    if not account then
        return
    end
    
    if add then
        account.accountHolders[charID] = account.accountHolders[charID] + permission
    else
        account.accountHolders[charID] = account.accountHolders[charID] - permission
    end

    hook.Run("BankingPermissionChanged", account, charID, permission, add)
end)

net.Receive("ixBankingLogs", function()
    local count = net.ReadUInt(8)
    local logs = {}

    for i = 1, count do
        local log = {}
        log.id = net.ReadUInt(32)
        log.type = net.ReadString()
        log.time = net.ReadUInt(32)
        log.data = net.ReadTable()
        logs[i] = log
    end

    local totalLogCount = net.ReadUInt(32)

    local panel = ix.gui.bankingLog
    if not IsValid(panel) then
        return
    end

    if not panel.waitingForLogs then
        return
    end

    if totalLogCount > 0 then
        panel.logCount = totalLogCount
    end

    panel:CreateNewPage(panel.waitingForLogs, logs)

    panel.leftButton:SetEnabled(true)
    panel.rightButton:SetEnabled(true)

    panel.waitingForLogs = nil
end)

net.Receive("ixBankingGetAccounts", function()
    local targetCharID = net.ReadUInt(32)
    local targetChar = ix.char.loaded[targetCharID]

    MsgN("---- " .. targetChar:GetName() .. " ----")

    local count = net.ReadUInt(10)
    for i = 1, count do
        local ownerID = net.ReadUInt(32)
        local ownerName = net.ReadString()
        local id = net.ReadUInt(32)
        local name = net.ReadString()
        local money = net.ReadUInt(32)
        local accountHolders = net.ReadTable()

        MsgN("Account: " .. id .. " (#" .. id + ix.banking.accountIDOffset .. ")")
        MsgN("Owner: " .. ownerName .. " (" .. ownerID .. ")")
        MsgN("Name: " .. name)
        MsgN("Balance: " .. money)
        MsgN("Account Holders:")

        for k, v in pairs(accountHolders) do
            MsgN("\n" .. v.name .. " (" .. k .. ")")

            for k2, v2 in pairs(PLUGIN.PermissionTranslations) do
                if k2 == BANKINGPERM_OWNER then
                    continue
                end

                if bit.band(v.permissions, k2) == k2 then
                    MsgN("- " .. L(v2))
                end
            end
        end

        MsgN("--")
    end
end)