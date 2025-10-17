local PANEL = {}

function PANEL:Init()
    self.moneyPanel = self:Add("Panel")
    self.moneyPanel:Dock(TOP)
    self.moneyPanel:DockMargin(0, 0, 0, 2)
    self.moneyPanel:SetZPos(1)
    self.moneyPanel.Paint = function(this, w, h)
        -- not pretty
        draw.SimpleText(L("bankingAccountBalance", ix.currency.Get(self.account:GetMoney())), "ixMediumFont", 0, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(L("bankingWalletBalance", ix.currency.Get(LocalPlayer():GetCharacter():GetMoney())), "ixMediumFont", w, y, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    self.modeSelection = self:Add("DComboBox")
    self.modeSelection:Dock(TOP)
    self.modeSelection:DockMargin(0, 0, 0, 2)
    self.modeSelection:SetZPos(2)
    self.modeSelection:SetTall(ScreenScaleH(11))
    self.modeSelection:AddChoice(L"bankingDeposit", 0)
    self.modeSelection:AddChoice(L"bankingWithdraw", 1)
    self.modeSelection:ChooseOptionID(1)
    self.modeSelection.OnSelect = function(this, index, name, data)
        local value = tonumber(self.moneyEntry:GetValue()) or 0

        if data == 0 then
            self.moneyEntry:SetValue(math.min(value, LocalPlayer():GetCharacter():GetMoney()))
        else
            self.moneyEntry:SetValue(math.min(value, self.account:GetMoney()))
        end
    end
    self.modeSelection.Paint = function(this)
        ix.util.DrawBlur(this)
    end

    self.moneyEntry = self:Add("ixBankingEntry")
    self.moneyEntry:Dock(TOP)
    self.moneyEntry:SetZPos(3)
    --self.moneyEntry:SetNumeric(true)
    self.moneyEntry:SetPlaceholderText(L"bankingDepositWithdrawEntry")

    self.confirmButton = self:Add("ixBankingButton")
    self.confirmButton:Dock(TOP)
    self.confirmButton:SetZPos(4)
    self.confirmButton:SetText(L"bankingConfirm")
    self.confirmButton:SetTall(ScreenScaleH(11))
    self.confirmButton.DoClick = function()
        local money = tonumber(self.moneyEntry:GetValue()) or 0
        if money <= 0 then
            ix.util.NotifyLocalized("bankingNotifyMoneyMin")
            return
        end

        -- convert dollars → cents (e.g. 0.25 → 25)
        local moneyCents = ix.currency.ToCents(money)

        local _, mode = self.modeSelection:GetSelected()
        if mode == 0 then
            if LocalPlayer():GetCharacter():GetMoney() < money then
                ix.util.NotifyLocalized("bankingNotifyInsufficientWallet")
                return
            end

            net.Start("ixBankingDeposit")
                net.WriteUInt(self.account:GetID(), 32)
                net.WriteUInt(moneyCents, 32) -- send cents
            net.SendToServer()
        else
            if money > self.account:GetMoney() then
                ix.util.NotifyLocalized("bankingNotifyInsufficientBalance")
                return
            end

            net.Start("ixBankingWithdraw")
                net.WriteUInt(self.account:GetID(), 32)
                net.WriteUInt(moneyCents, 32) -- send cents
            net.SendToServer()
        end
    end

    self.backButton = self:Add("ixBankingButton")
    self.backButton:Dock(TOP)
    self.backButton:SetZPos(5)
    self.backButton:SetIndex(1)
    self.backButton:SetText(L"bankingBack")
    self.backButton.DoClick = function()
        ix.gui.bankingTeller.canvas:SetActiveSubpanel(tostring(self.account:GetID()))
    end
end

vgui.Register("ixBankingTellerWithdrawDeposit", PANEL, "DScrollPanel")

PANEL = {}

function PANEL:Init()
    self.moneyPanel = self:Add("Panel")
    self.moneyPanel:Dock(TOP)
    self.moneyPanel:DockMargin(0, 0, 0, 2)
    self.moneyPanel:SetZPos(1)
    self.moneyPanel.Paint = function(this, w, h)
        -- not pretty
        draw.SimpleText(L("bankingAccountBalance", ix.currency.Get(self.account:GetMoney())), "ixMediumFont", 0, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    self.accountIDEntry = self:Add("ixBankingEntry")
    self.accountIDEntry:Dock(TOP)
    self.accountIDEntry:SetZPos(2)
    self.accountIDEntry:SetNumeric(true)
    self.accountIDEntry:SetPlaceholderText(L"bankingAccountIDEntry")

    self.moneyEntry = self:Add("ixBankingEntry")
    self.moneyEntry:Dock(TOP)
    self.moneyEntry:SetZPos(3)
    --self.moneyEntry:SetNumeric(true)
    self.moneyEntry:SetPlaceholderText(L"bankingSendMoneyEntry")

    self.confirmButton = self:Add("ixBankingButton")
    self.confirmButton:Dock(TOP)
    self.confirmButton:SetZPos(4)
    self.confirmButton:SetText(L"bankingConfirm")
    self.confirmButton.DoClick = function()
        local accountID = tonumber(self.accountIDEntry:GetValue()) or 0
        local money = tonumber(self.moneyEntry:GetValue()) or 0

        if accountID < ix.banking.accountIDOffset + 1 then
            ix.util.NotifyLocalized("bankingNotifyInvalidAccountID")
            return
        end

        if accountID - ix.banking.accountIDOffset == self.account:GetID() then
            ix.util.NotifyLocalized("bankingNotifyCantSendToSelf")
            return
        end

        if money > self.account:GetMoney() then
            ix.util.NotifyLocalized("bankingNotifyInsufficientBalance")
            return
        end

        if money <= 0 then
            ix.util.NotifyLocalized("bankingNotifyMoneyMin")
            return
        end

        net.Start("ixBankingSend")
            net.WriteUInt(self.account:GetID(), 32)
            net.WriteUInt(accountID, 32)
            net.WriteUInt(money, 32)
        net.SendToServer()
    end

    self.backButton = self:Add("ixBankingButton")
    self.backButton:Dock(TOP)
    self.backButton:SetZPos(5)
    self.backButton:SetIndex(1)
    self.backButton:SetText(L"bankingBack")
    self.backButton.DoClick = function()
        ix.gui.bankingTeller.canvas:SetActiveSubpanel(tostring(self.account:GetID()))
    end
end

vgui.Register("ixBankingTellerSend", PANEL, "DScrollPanel")

PANEL = {}

AccessorFunc(PANEL, "account", "Account")

function PANEL:Init()
    self.withdrawDepositButton = self:Add("ixBankingButton")
    self.withdrawDepositButton:Dock(TOP)
    self.withdrawDepositButton:SetZPos(1)
    self.withdrawDepositButton:SetText(L"bankingWithdrawDeposit")
    self.withdrawDepositButton.DoClick = function()
        ix.gui.bankingTeller.canvas:SetActiveSubpanel(self:GetAccount():GetID() .. "withdrawDeposit")
    end

    self.sendButton = self:Add("ixBankingButton")
    self.sendButton:Dock(TOP)
    self.sendButton:SetZPos(2)
    self.sendButton:SetText(L"bankingSend")
    self.sendButton.DoClick = function()
        ix.gui.bankingTeller.canvas:SetActiveSubpanel(self:GetAccount():GetID() .. "send")
    end

    self.backButton = self:Add("ixBankingButton")
    self.backButton:Dock(TOP)
    self.backButton:SetZPos(3)
    self.backButton:SetText(L"bankingBack")
    self.backButton.DoClick = function()
        ix.gui.bankingTeller.canvas:SetActiveSubpanel("main")
    end
end

function PANEL:UpdatePermission()
    local account = self:GetAccount()
    local char = LocalPlayer():GetCharacter()

    self.withdrawDepositButton:SetVisible(account:HasPermission(char:GetID(), BANKINGPERM_DEPOSIT_WITHDRAW))
    self.sendButton:SetVisible(account:HasPermission(char:GetID(), BANKINGPERM_SEND))

    local index = 0
    for k, v in ipairs(self:GetCanvas():GetChildren()) do
        if v:IsVisible() then
            v:SetIndex(index)

            index = index + 1
        end
    end
    
    self:InvalidateChildren()
end

function PANEL:OnActive()
    ix.gui.bankingTeller.dialoguePanel:AnimateText(L("bankingDialogueAccountTeller", self.account:GetID() + ix.banking.accountIDOffset))
end

vgui.Register("ixBankingTellerAccount", PANEL, "DScrollPanel")

PANEL = {}

function PANEL:Init()
    self.accounts = {}
end

function PANEL:AddAccount(account, index)
    local accountName = (account.name or ""):Trim() == "" and "#" .. account:GetID() + ix.banking.accountIDOffset or "#" .. account:GetID() + ix.banking.accountIDOffset .. " (" .. account.name .. ")"

    local accountButton = self:Add("ixBankingButton")
    accountButton:Dock(TOP)
    accountButton:SetZPos(index)
    accountButton:SetText(L(account.type == "standard" and "bankingManageAccount" or "bankingManageGovAccount", accountName))
    accountButton:SetIndex(index)
    accountButton.DoClick = function()
        ix.gui.bankingTeller.canvas:SetActiveSubpanel(tostring(account:GetID()))
    end

    self.accounts[account:GetID()] = accountButton
end

function PANEL:OnActive()
    ix.gui.bankingTeller.dialoguePanel:AnimateText(L"bankingDialogueWelcomeBankTeller")
end

vgui.Register("ixBankingTellerMain", PANEL, "DScrollPanel")

PANEL = {}

function PANEL:Init()
    if IsValid(ix.gui.bankingTeller) then
        ix.gui.bankingTeller:Remove()
    end
    ix.gui.bankingTeller = self

    self.nameLabel:SetText(L"bankingBankTeller")
    
    self.mainSubpanel = self.canvas:AddSubpanel("main", "ixBankingTellerMain")

    -- fix this
    timer.Simple(0.025, function()
        self.canvas:SetActiveSubpanel("main")
    end)

    self:PopulateAccounts()
end

function PANEL:AddAccount(account, index)
    local subpanel = self.canvas:AddSubpanel(tostring(account:GetID()), "ixBankingTellerAccount")
    subpanel:SetAccount(account)
    subpanel:UpdatePermission()

    subpanel = self.canvas:AddSubpanel(account:GetID() .. "withdrawDeposit", "ixBankingTellerWithdrawDeposit")
    subpanel.account = account

    subpanel = self.canvas:AddSubpanel(account:GetID() .. "send", "ixBankingTellerSend")
    subpanel.account = account
    
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

vgui.Register("ixBankingTeller", PANEL, "ixBanking")