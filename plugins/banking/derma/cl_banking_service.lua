local PANEL = {}

function PANEL:Init()
    self.charSelect = self:Add("DComboBox")
    self.charSelect:Dock(TOP)
    self.charSelect:SetZPos(1)

    self.nameEntry = self:Add("ixBankingEntry")
    self.nameEntry:Dock(TOP)
    self.nameEntry:SetZPos(2)
    self.nameEntry:SetPlaceholderText(L"bankingTransferOwnershipNameEntry")

    self.confirmButton = self:Add("ixBankingButton")
    self.confirmButton:Dock(TOP)
    self.confirmButton:SetZPos(3)
    self.confirmButton:SetText(L"bankingTransferOwnershipConfirm")
    self.confirmButton.DoClick = function(this)
        if not self.charSelect:GetSelected() then
            ix.util.NotifyLocalized("bankingNotifyNoTransferTarget")
            return
        end

        if self.nameEntry:GetValue() != LocalPlayer():Name() then
            ix.util.NotifyLocalized("bankingNotifySignatureNotMatch")
            return
        end

        net.Start("ixBankingTransferOwnership")
            net.WriteUInt(self.account:GetID(), 32)
            net.WriteUInt(select(2, self.charSelect:GetSelected()), 32)
        net.SendToServer()
    end

    -- perhaps in the future a more g eneral use panel could be made that has the back button built in or easily createable
    -- in general i think id just get rid of all of this and remake it. the ui is very impractical
    self.backButton = self:Add("ixBankingButton")
    self.backButton:Dock(TOP)
    self.backButton:SetZPos(4)
    self.backButton:SetText(L"bankingBack")
    self.backButton.DoClick = function()
        ix.gui.bankingService.canvas:SetActiveSubpanel(tostring(self.account:GetID()))
    end
end

function PANEL:SetAccount(account)
    self.account = account
end

function PANEL:OnActive()
    ix.gui.bankingService.dialoguePanel:AnimateText(L"bankingDialogueTransferOwnership")

    self.charSelect:Clear()
    self.charSelect:SetValue(L"bankingSelectTransferChar")
    for k, v in pairs(self.account.accountHolders) do
        if k == LocalPlayer():GetCharacter():GetID() then
            continue
        end

        local char = ix.char.loaded[k]
        local name
        if char then
            name = char:GetName()
        elseif ix.banking.offlineCharacters[k] then
            name = ix.banking.offlineCharacters[k].name
        end

        self.charSelect:AddChoice(name, k)
    end
end

vgui.Register("ixBankingServiceTransferOwner", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self.nameEntry = self:Add("ixBankingEntry")
    self.nameEntry:Dock(TOP)
    self.nameEntry:SetZPos(1)
    self.nameEntry:SetPlaceholderText(L"bankingCloseAccountNameEntry")

    self.confirmButton = self:Add("ixBankingButton")
    self.confirmButton:Dock(TOP)
    self.confirmButton:SetZPos(2)
    self.confirmButton:SetText(L"bankingCloseAccountConfirm")
    self.confirmButton.DoClick = function(this)
        if self.nameEntry:GetValue() != LocalPlayer():Name() then
            ix.util.NotifyLocalized("bankingNotifySignatureNotMatch")
            return
        end

        net.Start("ixBankingCloseAccount")
            net.WriteUInt(self.account:GetID(), 32)
        net.SendToServer()
    end

    self.backButton = self:Add("ixBankingButton")
    self.backButton:Dock(TOP)
    self.backButton:SetZPos(3)
    self.backButton:SetText(L"bankingBack")
    self.backButton.DoClick = function()
        ix.gui.bankingService.canvas:SetActiveSubpanel(tostring(self.account:GetID()))
    end
end

function PANEL:SetAccount(account)
    self.account = account
end

function PANEL:OnActive()
    ix.gui.bankingService.dialoguePanel:AnimateText(L"bankingDialogueCloseAccount")
end

vgui.Register("ixBankingServiceCloseAccount", PANEL, "Panel")

PANEL = {}

AccessorFunc(PANEL, "account", "Account")

function PANEL:Init()
    self.backButton = self:Add("ixBankingButton")
    self.backButton:Dock(TOP)
    self.backButton:SetZPos(1000)
    self.backButton:SetText(L"bankingBack")
    self.backButton.DoClick = function()
        ix.gui.bankingService.canvas:SetActiveSubpanel("main")
    end
end

function PANEL:PopulateButtons()
    local char = LocalPlayer():GetCharacter()
    local account = self:GetAccount()
    local canvas = ix.gui.bankingService.canvas

    for k, v in ipairs(self:GetCanvas():GetChildren()) do
        if v == self.backButton then
            continue
        end

        v:Remove()
    end

    local options = {
        {BANKINGPERM_LOG, "bankingLog", function()
            local panel = vgui.Create("ixBankingLog")
            panel:Populate(account:GetID())
        end},
        {BANKINGPERM_MANAGE_HOLDERS, "bankingManageHolders", function()
            local panel = vgui.Create("ixBankingAccountHolders")
            panel:PopulateAccountHolders(account)
        end},
        {BANKINGPERM_OWNER, "bankingTransferOwner", "TransferOwner"},
        {BANKINGPERM_OWNER, "bankingCloseAccount", "CloseAccount"}
    }

    local index = 0
    for k, v in ipairs(options) do
        if not account:HasPermission(char:GetID(), v[1]) then
            continue
        end

        local button = self:Add("ixBankingButton")
        button:Dock(TOP)
        button:SetText(L(v[2]))
        button:SetIndex(index)
        button:SetZPos(index)
        button.DoClick = function()
            if isfunction(v[3]) then
                v[3]()
            else
                canvas:SetActiveSubpanel(account:GetID() .. v[3])
            end
        end

        if isstring(v[3]) then
            local subpanel = canvas:AddSubpanel(account:GetID() .. v[3], "ixBankingService" .. v[3])
            subpanel:SetAccount(account)
        end

        index = index + 1
    end

    self.backButton:SetIndex(index)
end

function PANEL:OnActive()
    local accountHolderCount = table.Count(self.account.accountHolders)

    ix.gui.bankingService.dialoguePanel:AnimateText(L("bankingDialogueAccountService", self.account:GetID() + ix.banking.accountIDOffset, ix.currency.Get(self.account:GetMoney()), accountHolderCount, accountHolderCount > 1 and L"bankingDialogueAccountHolders" or L"bankingDialogueAccountHolder"))
end

vgui.Register("ixBankingServiceAccount", PANEL, "DScrollPanel")

PANEL = {}

function PANEL:Init()
    self.nameEntry = self:Add("ixBankingEntry")
    self.nameEntry:Dock(TOP)
    self.nameEntry:SetZPos(1)
    self.nameEntry:SetPlaceholderText(L"bankingOpenAccountEnterAccountName")

    self.confirmButton = self:Add("ixBankingButton")
    self.confirmButton:Dock(TOP)
    self.confirmButton:SetZPos(2)
    self.confirmButton:SetText(L"bankingConfirm")
    self.confirmButton.DoClick = function(this)
        self.waitingForOpen = true

        net.Start("ixBankingNewAccount")
            net.WriteString(self.nameEntry:GetValue())
        net.SendToServer()
    end

    self.backButton = self:Add("ixBankingButton")
    self.backButton:Dock(TOP)
    self.backButton:SetZPos(3)
    self.backButton:SetText(L"bankingBack")
    self.backButton.DoClick = function()
        ix.gui.bankingService.canvas:SetActiveSubpanel("main")
    end
end

function PANEL:Reset()
    self.nameEntry:SetValue("")
    self.waitingForOpen = nil
end

vgui.Register("ixBankingServiceOpenAccount", PANEL, "DScrollPanel")

PANEL = {}

function PANEL:Init()
    self.accounts = {}

    self.openAccount = self:Add("ixBankingButton")
    self.openAccount:Dock(TOP)
    self.openAccount:SetZPos(1000)
    self.openAccount:SetText(L"bankingOpenAccount")
    self.openAccount.DoClick = function()
        local result, reason = hook.Run("BankingCanCreateAccount")
        if result == false then
            ix.util.NotifyLocalized(reason)
            return
        end

        ix.gui.bankingService.canvas:SetActiveSubpanel("openAccount")
    end

    ix.gui.bankingService.canvas:AddSubpanel("openAccount", "ixBankingServiceOpenAccount")
end

function PANEL:AddAccount(account, index)
    if not index then
        index = table.Count(self.accounts)
    end

    local accountName = (account.name or ""):Trim() == "" and "#" .. account:GetID() + ix.banking.accountIDOffset or "#" .. account:GetID() + ix.banking.accountIDOffset .. " (" .. account.name .. ")"

    local accountButton = self:Add("ixBankingButton")
    accountButton:Dock(TOP)
    accountButton:SetText(L(account.type == "standard" and "bankingManageAccount" or "bankingManageGovAccount", accountName))
    accountButton:SetIndex(index)
    accountButton:SetZPos(index)
    accountButton.DoClick = function()
        ix.gui.bankingService.canvas:SetActiveSubpanel(tostring(account:GetID()))
    end

    self.openAccount:SetIndex(index + 1)

    self.accounts[account:GetID()] = accountButton
end

function PANEL:OnActive()
    ix.gui.bankingService.dialoguePanel:AnimateText(L"bankingDialogueWelcomeCustomerService")
end

vgui.Register("ixBankingServiceMain", PANEL, "DScrollPanel")

PANEL = {}

function PANEL:Init()
    if IsValid(ix.gui.bankingService) then
        ix.gui.bankingService:Remove()
    end
    ix.gui.bankingService = self

    self.nameLabel:SetText(L"bankingCustomerService")
    
    self.mainSubpanel = self.canvas:AddSubpanel("main", "ixBankingServiceMain")

    -- fix this
    timer.Simple(0.025, function()
        self.canvas:SetActiveSubpanel("main")
    end)

    self:PopulateAccounts()
end

function PANEL:AddAccount(account, index)
    local subpanel = self.canvas:AddSubpanel(tostring(account:GetID()), "ixBankingServiceAccount")
    subpanel:SetAccount(account)
    subpanel:PopulateButtons()

    self.mainSubpanel:AddAccount(account, index)
end

function PANEL:RemoveAccount(account)
    local function ClearSubpanels()
        for k, v in pairs(self.canvas.subpanels) do
            if string.StartsWith(v.id, tostring(account.id)) then
                v:Remove()

                self.canvas.subpanels[v.id] = nil
            end
        end
    end

    if string.StartsWith(self.canvas.activeSubpanel.id, tostring(account.id)) then
        self.canvas:SetActiveSubpanel("main", nil, function()
            ClearSubpanels()
        end)
    else
        ClearSubpanels()
    end

    local mainSubpanel = self.canvas.subpanels["main"]
    mainSubpanel.accounts[account.id]:Remove()
    mainSubpanel.accounts[account.id] = nil
end

function PANEL:PopulateAccounts()
    local char = LocalPlayer():GetCharacter()
    if char then
        if ix.banking.accountsByChar[char:GetID()] then
            local index = 0
            for k, v in pairs(ix.banking.accountsByChar[char:GetID()]) do
                self:AddAccount(v, index)

                index = index + 1
            end
        end
    end
end

vgui.Register("ixBankingService", PANEL, "ixBanking")