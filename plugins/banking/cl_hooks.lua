local PLUGIN = PLUGIN

function PLUGIN:BankingAccountSync(account)
    local panel = ix.gui.bankingService
    if not IsValid(panel) then
        panel = ix.gui.bankingTeller

        if not IsValid(panel) then
            return
        end
    end

    local canvas = panel.canvas
    local activeSubpanel = canvas.activeSubpanel
    if activeSubpanel.waitingForOpen then
        activeSubpanel:Reset()
        canvas:SetActiveSubpanel("main")
    end

    panel:AddAccount(account)
end

function PLUGIN:BankingAccountClosed(account)
    local panel = ix.gui.bankingService
    if not IsValid(panel) then
        panel = ix.gui.bankingTeller

        if not IsValid(panel) then
            return
        end
    end

    panel:RemoveAccount(account)

    panel = ix.gui.bankingAccountHolders
    if IsValid(panel) and panel.account == account then
        panel:Close()
    end

    panel = ix.gui.bankingLog
    if IsValid(panel) and panel.accountID == account:GetID() then
        panel:Close()
    end
end

local function AddAccountHolder(account, charID, permissions)
    local guiAccountHolders = ix.gui.bankingAccountHolders
    if not IsValid(guiAccountHolders) then
        return
    end

    if guiAccountHolders.account != account then
        return
    end

    guiAccountHolders:AddEntry(charID, permissions, true)
end

local function AddService(account, charID, permissions)
    if LocalPlayer():GetCharacter():GetID() != charID then
        return
    end

    local panel = ix.gui.bankingService
    if not IsValid(panel) then
        return
    end

    panel:AddAccount(account)
end

local function AddTeller(account, charID, permissions)
    if LocalPlayer():GetCharacter():GetID() != charID then
        return
    end

    local panel = ix.gui.bankingTeller
    if not IsValid(panel) then
        return
    end

    panel:AddAccount(account)
end

function PLUGIN:BankingAccountHolderAdded(account, charID, permissions)
    AddAccountHolder(account, charID, permissions)
    AddService(account, charID, permissions)
    AddTeller(account, charID, permissions)
end

local function RemoveAccountHolder(account, charID)
    local guiAccountHolders = ix.gui.bankingAccountHolders
    if not IsValid(guiAccountHolders) then
        return
    end

    if guiAccountHolders.account != account then
        return
    end

    if LocalPlayer():GetCharacter():GetID() == charID then
        guiAccountHolders:Close()
        return
    end

    guiAccountHolders:RemoveEntry(charID)
end

local function RemoveService(account, charID)
    if LocalPlayer():GetCharacter():GetID() != charID then
        return
    end

    local panel = ix.gui.bankingService
    if not IsValid(panel) then
        return
    end

    panel:RemoveAccount(account)
end

local function RemoveTeller(account, charID)
    if LocalPlayer():GetCharacter():GetID() != charID then
        return
    end

    local panel = ix.gui.bankingTeller
    if not IsValid(panel) then
        return
    end

    panel:RemoveAccount(account)
end

function PLUGIN:BankingAccountHolderRemoved(account, charID)
    RemoveAccountHolder(account, charID)
    RemoveService(account, charID)
    RemoveTeller(account, charID)
end

local function PermChangedAccountHolder(account, charID, permission, add)
    local guiAccountHolders = ix.gui.bankingAccountHolders
    if not IsValid(guiAccountHolders) then
        return
    end

    if guiAccountHolders.account != account then
        return
    end

    if LocalPlayer():GetCharacter():GetID() == charID then
        if permission == BANKINGPERM_MANAGE_HOLDERS and not add then
            guiAccountHolders:Close()
            return
        end

        for k, v in pairs(guiAccountHolders.entries) do
            local perm = v.permissions[permission]
            if add then
                perm:Show()
            else
                perm:Hide()
            end

            v:UpdateIndexColors()
        end
    end

    local entry = guiAccountHolders.entries[charID]
    if not entry then
        return
    end

    if permission == BANKINGPERM_MANAGE_HOLDERS then
        if add and not account:HasPermission(LocalPlayer():GetCharacter():GetID(), BANKINGPERM_OWNER) then
            entry.entryButton:MakeEntryChar()
        else
            entry.entryButton:ClearEntryChar()
        end
    end

    local perm = entry.permissions[permission]
    if not perm then
        return
    end

    perm.icon:SetEnabled(add)

    local checkBox = perm.checkBox
    if checkBox:GetChecked() != add then
        checkBox:SetChecked(add, not entry.bExpanded)
    end
end

local function PermChangedService(account, charID, permission, add)
    if LocalPlayer():GetCharacter():GetID() != charID then
        return
    end

    local panel = ix.gui.bankingService
    if not IsValid(panel) then
        return
    end

    local subpanel = panel.canvas.subpanels[tostring(account:GetID())]
    if not subpanel then
        return
    end

    subpanel:PopulateButtons()
end

local function PermChangedTeller(account, charID, permission, add)
    if LocalPlayer():GetCharacter():GetID() != charID then
        return
    end

    local panel = ix.gui.bankingTeller
    if not IsValid(panel) then
        return
    end

    local subpanel = panel.canvas.subpanels[tostring(account:GetID())]
    if not subpanel then
        return
    end

    -- god this is so cancer
    if not add then
        if permission == BANKINGPERM_DEPOSIT_WITHDRAW then
            if panel.canvas.activeSubpanel.id == account:GetID() .. "withdrawDeposit" then
                panel.canvas:SetActiveSubpanel(tostring(account:GetID()))
            end
        elseif permission == BANKINGPERM_SEND then
            if panel.canvas.activeSubpanel.id == account:GetID() .. "send" then
                panel.canvas:SetActiveSubpanel(tostring(account:GetID()))
            end
        end
    end

    subpanel:UpdatePermission()
end

function PLUGIN:BankingPermissionChanged(account, charID, permission, add)
    PermChangedAccountHolder(account, charID, permission, add)
    PermChangedService(account, charID, permission, add)
    PermChangedTeller(account, charID, permission, add)

    local guiBankingLog = ix.gui.bankingLog
    if IsValid(guiBankingLog) then
        if LocalPlayer():GetCharacter():GetID() == charID then
            if permission == BANKINGPERM_LOG and not add then
                guiBankingLog:Close()
            end
        end
    end
end

local function AccountTransferredService(account, oldOwnerID, newOwnerID)
    local panel = ix.gui.bankingService
    if not IsValid(panel) then
        return
    end

    local subpanel = panel.canvas.subpanels[tostring(account:GetID())]
    if not subpanel then
        return
    end

    if LocalPlayer():GetCharacter():GetID() == oldOwnerID then
        if panel.canvas.activeSubpanel.id == account:GetID() .. "TransferOwner" or panel.canvas.activeSubpanel.id == account:GetID() .. "CloseAccount" then
            panel.canvas:SetActiveSubpanel(tostring(account:GetID()), nil, function()
                panel.canvas.subpanels[account:GetID() .. "TransferOwner"]:Remove()
                panel.canvas.subpanels[account:GetID() .. "TransferOwner"] = nil
                panel.canvas.subpanels[account:GetID() .. "CloseAccount"]:Remove()
                panel.canvas.subpanels[account:GetID() .. "CloseAccount"] = nil
            end)
        else
            panel.canvas.subpanels[account:GetID() .. "TransferOwner"]:Remove()
            panel.canvas.subpanels[account:GetID() .. "TransferOwner"] = nil
            panel.canvas.subpanels[account:GetID() .. "CloseAccount"]:Remove()
            panel.canvas.subpanels[account:GetID() .. "CloseAccount"] = nil
        end
    end

    if LocalPlayer():GetCharacter():GetID() == newOwnerID then
        subpanel:PopulateButtons()
    end
end

local function AccountTransferredAccountHolder(account, oldOwnerID, newOwnerID)
    local guiAccountHolders = ix.gui.bankingAccountHolders
    if not IsValid(guiAccountHolders) then
        return
    end

    if guiAccountHolders.account != account then
        return
    end

    local entry = guiAccountHolders.entries[oldOwnerID]
    if entry then
        entry.entryButton:ClearAccountOwner()
    end

    entry = guiAccountHolders.entries[newOwnerID]
    if entry then
        entry.entryButton:MakeAccountOwner()

        for k, v in pairs(entry.permissions) do
            v.icon:SetEnabled(true)

            local checkBox = v.checkBox
            if not checkBox:GetChecked() then
                checkBox:SetChecked(true, not entry.bExpanded)
            end
        end

        if entry.bExpanded then
            entry:Shrink()
        end
    end

    if LocalPlayer():GetCharacter():GetID() == newOwnerID then
        for k, v in pairs(guiAccountHolders.entries) do
            local perm = v.permissions[permission]
            for k2, v2 in pairs(v.permissions) do
                v2:Show()
            end
            v:UpdateIndexColors()
        end
    end
end

function PLUGIN:BankingAccountTransferred(account, oldOwnerID, newOwnerID)
    AccountTransferredService(account, oldOwnerID, newOwnerID)
    AccountTransferredAccountHolder(account, oldOwnerID, newOwnerID)
end

function PLUGIN:BankingShouldShowAccountHolder(char, account)
    if account.accountHolders[char:GetID()] then
        return false
    end
end
