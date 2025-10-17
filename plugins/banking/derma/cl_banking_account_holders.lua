local MAT_GRADIENT = ix.util.GetMaterial("vgui/gradient-l")

local PANEL = {}

function PANEL:Init()
    self:Dock(TOP)
    self.index = 0
    -- we just do this as the dock operation takes a frame to update the size properly (i think)
    self:SetSize(self:GetParent():GetWide(), ScreenScaleH(24))
    self.animShowProgress = 1
    self.bVisible = true
    self.currentColor = Color(25, 25, 25)

    self.textLabel = self:Add("DLabel")
    self.textLabel:SetPos(4, 4)
    self.textLabel:SetTall(self:GetTall() - 8)
    self.textLabel:SetFont("ixMenuButtonFont")

    self.checkBox = self:Add("ixCheckBox")
    self.checkBox:SetPos(self:GetWide() - self.checkBox:GetWide() - 4, 4)
    self.checkBox:SetTall(self:GetTall() - 8)
    self.checkBox.DoClick = function(this)
        local accountID = ix.gui.bankingAccountHolders.account:GetID()

        net.Start("ixBankingPermission")
            net.WriteUInt(accountID, 32)
            net.WriteUInt(self.charID, 32)
            net.WriteUInt(self.permission, 8)
            net.WriteBool(this:GetChecked())
        net.SendToServer()
    end
end

function PANEL:SetText(text)
    self.textLabel:SetText(text)
    self.textLabel:SizeToContents()
end

function PANEL:Show(time)
    time = time or 0.15

    local targetTall = ScreenScaleH(24)
    local entryParent = self:GetParent():GetParent()

    self.bVisible = true
    self.bAnimating = true
    self:SetVisible(true)

    self:CreateAnimation(time, {
        index = 1,
        target = {animShowProgress = 1},
        Think = function(anim, panel)
            panel:SetTall(panel.animShowProgress * targetTall)

            if entryParent.bExpanded then
                entryParent:SetTall(entryParent.entryButton:GetTall() + self:GetParent():GetTall())
            end
        end,
        OnComplete = function(anim, panel)
            panel.bAnimating = false
        end
    })
end

function PANEL:Hide(time)
    time = time or 0.15

    local startTall = self:GetTall()
    local entryParent = self:GetParent():GetParent()

    self.bVisible = false
    self.bAnimating = true

    self:CreateAnimation(time, {
        index = 1,
        target = {animShowProgress = 0},
        Think = function(anim, panel)
            panel:SetTall(panel.animShowProgress * startTall)

            if entryParent.bExpanded then
                entryParent:SetTall(entryParent.entryButton:GetTall() + self:GetParent():GetTall())
            end
        end,
        OnComplete = function(anim, panel)
            panel.bAnimating = false
            panel:SetVisible(false)
        end
    })
end

function PANEL:SetColorIndex(newIndex)
    local colChannels = newIndex % 2 == 0 and 25 or 75

    self.currentColor = Color(colChannels, colChannels, colChannels)

    self.index = newIndex
end

function PANEL:ChangeColorIndex(newIndex)
    if newIndex == self.index or newIndex % 2 == self.index % 2 then
        self.index = newIndex
        return
    end

    self.animColorProgress = 1 - newIndex % 2

    self:CreateAnimation(0.25, {
        index = 2,
        target = {animColorProgress = newIndex % 2},
        Think = function(anim, panel)
            local colChannels = panel.animColorProgress * 50

            panel.currentColor = Color(25 + colChannels, 25 + colChannels, 25 + colChannels)
        end,
        OnComplete = function(anim, panel)
            panel:SetColorIndex(newIndex)
        end
    })
end

function PANEL:Paint(w, h)
    local col = self.currentColor

    surface.SetDrawColor(ColorAlpha(col, 50))
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("ixBankingPermissionEntry", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self:SetMouseInputEnabled(false)
    self.defaultColor = color_white
    self.enabledColor = ix.config.Get("color")

    self.currentColor = self.enabledColor
end

function PANEL:SetMaterial(mat)
    self.iconMaterial = mat
end

function PANEL:SetEnabled(enable, time)
    time = time or 0.15

    self.animProgress = 0

    local curColor = self.currentColor:ToVector()
    if enable then
        local targetColor = self.enabledColor:ToVector()
        self:CreateAnimation(time, {
            index = 1,
            target = {animProgress = 1},
            Think = function(anim, panel)
                panel:SetAlpha((panel.animProgress * 0.6 + 0.4) * 255)

                panel.currentColor = LerpVector(anim.clock / anim.duration, curColor, targetColor):ToColor()
            end
        })
    else
        local targetColor = self.defaultColor:ToVector()
        self:CreateAnimation(time, {
            index = 1,
            target = {animProgress = 1},
            Think = function(anim, panel)
                panel:SetAlpha(((1 - panel.animProgress) * 0.6 + 0.4) * 255)

                panel.currentColor = LerpVector(anim.clock / anim.duration, curColor, targetColor):ToColor()
            end
        })
    end
end

function PANEL:Paint(w, h)
    if IsValid(self.iconMaterial) then
        return
    end

    surface.SetDrawColor(self.currentColor)
    surface.SetMaterial(self.iconMaterial)
    surface.DrawTexturedRect(0, 0, w, h)
end

-- but wait, its EVEN LONGERRR
vgui.Register("ixBankingAccountHoldersEntryButtonIcon", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self:SetMaterial(Material("trash.png", "smooth"))
    self.animColorProgress = 1
end

function PANEL:OnCursorEntered()
    if not self:IsEnabled() then
        return
    end

    self:CreateAnimation(0.15, {
        index = 1,
        target = {animColorProgress = 0},
        Think = function(anim, panel)
            panel:SetColor(Color(255, 255 * panel.animColorProgress, 255 * panel.animColorProgress))
        end
    })
end

function PANEL:OnCursorExited()
    if not self:IsEnabled() then
        return
    end

    self:CreateAnimation(0.15, {
        index = 1,
        target = {animColorProgress = 1},
        Think = function(anim, panel)
            panel:SetColor(Color(255, 255 * panel.animColorProgress, 255 * panel.animColorProgress))
        end
    })
end

-- actually nvm this one is longer
vgui.Register("ixBankingAccountHoldersEntryDeleteButton", PANEL, "DImageButton")

PANEL = {}

function PANEL:Init()
    self:DockPadding(2, 2, 2, 2)
    self:SetMouseInputEnabled(true)
    self:SetCursor("hand")
    self.icons = {}

    self.modelIcon = self:Add("SpawnIcon")
    self.modelIcon:Dock(LEFT)
    self.modelIcon:SetMouseInputEnabled(false)

    self.nameLabel = self:Add("DLabel")
    self.nameLabel:Dock(LEFT)
    self.nameLabel:SetFont("ixMenuButtonFont")
    self.nameLabel:SetMouseInputEnabled(false)

    self.ownerIcon = self:Add("DImage")
    self.ownerIcon:Dock(RIGHT)
    self.ownerIcon:SetZPos(50)
    self.ownerIcon:DockMargin(0, 10, 35, 10)
    self.ownerIcon:SetVisible(false)
    self.ownerIcon:SetMaterial(Material("owner.png", "smooth"))
    self.ownerIcon:SetImageColor(Color(207, 207, 127))

    self.deleteButton = self:Add("ixBankingAccountHoldersEntryDeleteButton")
    self.deleteButton:Dock(RIGHT)
    self.deleteButton:DockMargin(20, 10, 10, 10)
    self.deleteButton.DoClick = function(this)
        net.Start("ixBankingAccountHolder")
            net.WriteUInt(ix.gui.bankingAccountHolders.account:GetID(), 32)
            net.WriteUInt(self.charID, 32)
            net.WriteBool(false)
        net.SendToServer()
    end
end

function PANEL:AddPermissionIcon(img)
    local icon = self:Add("ixBankingAccountHoldersEntryButtonIcon")
    icon:Dock(RIGHT)
    icon:DockMargin(0, 10, 15, 10)
    icon:SetMaterial(Material(img, "smooth"))

    self.icons[#self.icons + 1] = icon

    return icon
end

function PANEL:MakeEntryChar()
    self.deleteButton:SetEnabled(false)
    self:SetCursor("none")
    self:SetMouseInputEnabled(false)
end

function PANEL:ClearEntryChar()
    self.deleteButton:SetEnabled(true)
    self:SetCursor("hand")
    self:SetMouseInputEnabled(true)
end

function PANEL:MakeAccountOwner()
    self:MakeEntryChar()
    self.ownerIcon:SetVisible(true)
end

function PANEL:ClearAccountOwner()
    self:ClearEntryChar()
    self.ownerIcon:SetVisible(false)
end

function PANEL:PerformLayout(w, h)
    self.modelIcon:SetWide(self.modelIcon:GetTall())

    self.ownerIcon:SetWide(self.ownerIcon:GetTall())

    self.deleteButton:SetWide(self.deleteButton:GetTall())

    for i = 1, #self.icons do
        local icon = self.icons[i]

        icon:SetWide(icon:GetTall())
    end
end

function PANEL:Setup(charID)
    self.charID = charID

    if ix.char.loaded[charID] then
        local charInfo = ix.char.loaded[charID]

        self.modelIcon:SetModel(charInfo:GetModel())
        self.nameLabel:SetText(charInfo:GetName())
    elseif ix.banking.offlineCharacters[charID] then
        local charInfo = ix.banking.offlineCharacters[charID]

        self.modelIcon:SetModel(charInfo.model)
        self.nameLabel:SetText(charInfo.name)
    end

    self.nameLabel:SizeToContents()
end

function PANEL:OnMousePressed()
    if self.DoClick then
        self:DoClick()
    end
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(ix.config.Get("color"))
    surface.SetMaterial(MAT_GRADIENT)
    surface.DrawTexturedRect(0, 0, w * 0.5, h)
end

-- even longer!!!
vgui.Register("ixBankingAccountHoldersEntryButton", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self:Dock(TOP)
    self:DockMargin(0, 0, 0, 4)
    -- i dont know why this is needed, we already run invalidatelayout on our parent, further down
    self:InvalidateParent(true)

    self.currentAlpha = 1
    self.currentTall = ScreenScaleH(24)
    self.currentProgress = 0
    self.bExpanded = false

    self:SetTall(self.currentTall)

    self.entryButton = self:Add("ixBankingAccountHoldersEntryButton")
    self.entryButton:Dock(TOP)
    self.entryButton:SetSize(self:GetWide(), self.currentTall)
    self.entryButton.DoClick = function()
        if self.bExpanded then
            self:Shrink()
        else
            self:Expand()
        end
    end

    -- i dont really like using this panel class but it seemed easier to just let it do its thing
    -- than tell the panel to resize everytime an entry is hidden/shown
    self.permissionsPanel = self:Add("DSizeToContents")
    self.permissionsPanel:SetWide(self:GetWide())
    self.permissionsPanel:SetPos(0, self.entryButton:GetTall())

    self:PopulatePermissions()
end

function PANEL:Setup(charID, permissions)
    self.charID = charID

    local account = ix.gui.bankingAccountHolders.account
    if account:HasPermission(charID, BANKINGPERM_OWNER) then
        self.entryButton:MakeAccountOwner()
    elseif charID == LocalPlayer():GetCharacter():GetID()
        or (account:HasPermission(charID, BANKINGPERM_MANAGE_HOLDERS)
        and account:HasPermission(LocalPlayer():GetCharacter():GetID(), BANKINGPERM_MANAGE_HOLDERS)
        and not account:HasPermission(LocalPlayer():GetCharacter():GetID(), BANKINGPERM_OWNER)) then

        self.entryButton:MakeEntryChar()
    end
    self.entryButton:Setup(charID)

    for k, v in pairs(self.permissions) do
        local hasPerm = account:HasPermission(charID, v.permission)

        v.charID = charID
        v.icon:SetEnabled(hasPerm, 0)
        v.checkBox:SetChecked(hasPerm, true)
    end
end

function PANEL:PopulatePermissions()
    -- this is honestly quite silly and spaghetti code levels of bs, but it saves creating another table
    self.permissions = {
        [BANKINGPERM_DEPOSIT_WITHDRAW] = {"bankingPermissionDepositWithdraw", "deposit-withdraw.png"},
        [BANKINGPERM_SEND] = {"bankingPermissionSend", "send-money.png"},
        [BANKINGPERM_LOG] = {"bankingPermissionLog", "log.png"},
        [BANKINGPERM_MANAGE_HOLDERS] = {"bankingPermissionManageHolders", "manage-holders.png"},
    }

    local index = 0
    for k, v in pairs(self.permissions) do
        local icon = self.entryButton:AddPermissionIcon(v[2])

        local entry = self.permissionsPanel:Add("ixBankingPermissionEntry")
        entry:SetText(L(v[1]))
        entry.icon = icon
        entry.permission = k

        if not ix.gui.bankingAccountHolders.account:HasPermission(LocalPlayer():GetCharacter():GetID(), k) then
            entry:Hide(0)
        else
            entry:SetColorIndex(index)

            index = index + 1
        end

        self.permissions[k] = entry
    end
end

function PANEL:UpdateIndexColors()
    local index = 0
    for k, v in ipairs(self.permissionsPanel:GetChildren()) do
        if v.bVisible then
            if v.bAnimating then
                v:SetColorIndex(index)
            else
                v:ChangeColorIndex(index)
            end

            index = index + 1
        end
    end
end

function PANEL:Expand()
    self.bExpanded = true

    self:CreateAnimation(0.25, {
        target = {currentProgress = 1},
        Think = function(anim, panel)
            panel:SetTall(self.entryButton:GetTall() + panel.currentProgress * self.permissionsPanel:GetTall())
        end
    })
end

function PANEL:Shrink()
    self.bExpanded = false

    self:CreateAnimation(0.25, {
        target = {currentProgress = 0},
        Think = function(anim, panel)
            panel:SetTall(self.entryButton:GetTall() + panel.currentProgress * self.permissionsPanel:GetTall())
        end
    })
end

function PANEL:Show(time)
    time = time or 0.15

    self.currentAlpha = 0

    self:CreateAnimation(time, {
        target = {currentAlpha = 1},
        Think = function(anim, panel)
            panel:SetAlpha(panel.currentAlpha * 255)
        end
    })
end

function PANEL:Hide(time, callback)
    time = time or 0.15

    self.currentAlpha = 1

    self:CreateAnimation(time, {
        target = {currentAlpha = 0},
        Think = function(anim, panel)
            panel:SetAlpha(panel.currentAlpha * 255)
        end,
        OnComplete = function(anim, panel)
            if callback then
                callback()
            end
        end
    })
end

-- so long!!!
vgui.Register("ixBankingAccountHoldersEntry", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self:SetTall(ScreenScaleH(18))
    self:DockMargin(0, 0, 0, 2)
    self:SetVisible(false)
    self:SetMouseInputEnabled(true)
    self:SetCursor("hand")
    self.currentWidth = 0
    self.currentTall = 0

    self.modelIcon = self:Add("SpawnIcon")
    self.modelIcon:SetSize(self:GetTall() - 4, self:GetTall() - 4)
    self.modelIcon:SetPos(2, 2)
    self.modelIcon:SetMouseInputEnabled(false)

    self.nameLabel = self:Add("DLabel")
    self.nameLabel:SetFont("ixSmallFont")
    self.nameLabel:SetPos(self:GetTall() + 2, self:GetTall() * 0.5 - self:GetTall() * 0.25)
    self.nameLabel:SetMouseInputEnabled(false)
end

function PANEL:SetPlayer(client)
    self.player = client

    self:Update(true)
end

function PANEL:Update(bInitial)
    if not IsValid(self.player) then
        self:Hide(nil, function(panel)
            panel:OnClose()

            panel:Remove()
        end)
        return
    end

    local char = self.player:GetCharacter()
    if not char then
        if self:IsVisible() then
            self:Hide(bInitial and 0)
        end
        return
    end

    if hook.Run("BankingShouldShowAccountHolder", char, ix.gui.bankingAccountHolders.account) == false then
        if self:IsVisible() then
            self:Hide(bInitial and 0)
        end
        return
    end

    if not self:IsVisible() then
        self:Show(bInitial and 0)
    end

    self.modelIcon:SetModel(char:GetModel())
    self.nameLabel:SetText(char:GetName())
    self.nameLabel:SizeToContents()
end

function PANEL:Hide(time, callback)
    local startTall = self:GetTall()

    self:CreateAnimation(time or 0.2, {
        index = 2,
        target = {currentTall = 0},
        Think = function(anim, panel)
            panel:SetTall(panel.currentTall * startTall)
        end,
        OnComplete = function(anim, panel)
            panel:SetVisible(false)

            if callback then
                callback(panel)
            end
        end
    })
end

function PANEL:Show(time, callback)
    local targetTall = ScreenScaleH(18)

    self:SetVisible(true)

    self:CreateAnimation(time or 0.2, {
        index = 2,
        target = {currentTall = 1},
        Think = function(anim, panel)
            panel:SetTall(panel.currentTall * targetTall)
        end,
        OnComplete = function(anim, panel)
            if callback then
                callback(panel)
            end
        end
    })
end

function PANEL:OnMousePressed(keyCode)
    if keyCode == MOUSE_LEFT then
        net.Start("ixBankingAccountHolder")
            net.WriteUInt(ix.gui.bankingAccountHolders.account:GetID(), 32)
            net.WriteUInt(self.player:GetCharacter():GetID(), 32)
            net.WriteBool(true)
        net.SendToServer()

        ix.gui.bankingAccountHolders.addHolderPanel:Hide()
    end
end

function PANEL:OnCursorEntered()
    self:CreateAnimation(0.15, {
        index = 1,
        target = {currentWidth = 1},
    })
end

function PANEL:OnCursorExited()
    self:CreateAnimation(0.15, {
        index = 1,
        target = {currentWidth = 0},
    })
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(ix.config.Get("color"))
    surface.SetMaterial(MAT_GRADIENT)
    surface.DrawTexturedRect(0, 0, w * 0.75 + (w * 0.25 * (self.currentWidth or 0)), h)
end

vgui.Register("ixBankingAccountHolderAddEntry", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self.entries = {}
end

function PANEL:Start()
    self:UpdateList(true)

    local timerID = "ixBankingAccountHolderAddScroll" .. CurTime()
    timer.Create(timerID, 0.5, 0, function()
        if not IsValid(self) then
            timer.Remove(timerID)
            return
        end

        self:UpdateList()
    end)

    self.timerID = timerID
end

function PANEL:Stop()
    timer.Remove(self.timerID)
end

function PANEL:AddEntry(client, bInitial)
    local entry = self:Add("ixBankingAccountHolderAddEntry")
    entry:Dock(TOP)
    entry:SetPlayer(client)
    entry.OnClose = function(this)
        self.entries[client] = nil
    end

    self.entries[client] = entry

    return entry
end

function PANEL:UpdateList(bInitial)
    local visible = bInitial

    if bInitial then
        self:Clear()

        self.entries = {}
    end

    local count = 0
    for k, v in pairs(self.entries) do
        v:Update()

        if v:IsVisible() then
            visible = true
        end

        count = count + 1
    end

    local allPlayers = player.GetAll()
    if count < #allPlayers then
        if bInitial then
            table.sort(allPlayers, function(a, b)
                return a:Name():lower() < b:Name():lower()
            end)
        end

        for k, v in ipairs(allPlayers) do
            if not self.entries[v] then
                self:AddEntry(v)
            end
        end
    end

    self:GetParent().noPlayersLabel:SetVisible(not visible)
end

function PANEL:OnRemove()
    if self.timerID then
        timer.Remove(self.timerID)
    end
end

vgui.Register("ixBankingAccountHolderAddScroll", PANEL, "DScrollPanel")

PANEL = {}

function PANEL:Init()
    self.animProgress = 0
    self:SetAlpha(0.5 * 255)
    self:SetFont("ixSmallFont")
    self:SetText(L"bankingNoAvailablePlayers")
    self:SetVisible(false, 0)
end

function PANEL:SetVisible(enable, time)
    time = time or 0.15

    if enable then
        self:CreateAnimation(time, {
            index = 1,
            target = {animProgress = 1},
            Think = function(anim, panel)
                panel:SetAlpha(panel.animProgress * 0.5 * 255)
            end,
        })
    else
        self:CreateAnimation(time, {
            index = 1,
            target = {animProgress = 0},
            Think = function(anim, panel)
                panel:SetAlpha(panel.animProgress * 0.5 * 255)
            end
        })
    end
end

vgui.Register("ixBankingAccountHolderNoPlayersLabel", PANEL, "DLabel")

PANEL = {}

function PANEL:Init()
    self:DockPadding(15, 15, 15, 15)

    self.noPlayersLabel = self:Add("ixBankingAccountHolderNoPlayersLabel")
    self.noPlayersLabel:SetZPos(-5)
    self.noPlayersLabel:Dock(FILL)
    self.noPlayersLabel:SetContentAlignment(5)

    self.characterScroll = self:Add("ixBankingAccountHolderAddScroll")
    self.characterScroll:Dock(FILL)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(15, 0, 0, w, h, Color(50, 50, 50, 200))
end

vgui.Register("ixBankingAccountHolderAddPanel", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self:SetSize(self:GetParent():GetSize())
    self:SetPos(0, 0)
    self:SetZPos(100)

    self:SetVisible(false)
    self:SetAlpha(0)
    self.currentAlpha = 0

    local w, h = self:GetSize()
    self.addPanel = self:Add("ixBankingAccountHolderAddPanel")
    self.addPanel:SetSize(w * 0.30, h * 0.40)
    self.addPanel:Center()
end

function PANEL:SetPadding(left, top, right, bottom)
    local parentW, parentH = self:GetParent():GetSize()
    self:SetSize(parentW - left - right, parentH - top - bottom)
    self:SetPos(left, top)
end

function PANEL:OnMousePressed(keyCode)
    self:Hide()
end

function PANEL:Show(time)
    time = time or 0.25

    self.addPanel.characterScroll:Start()

    self:SetVisible(true)
    self:SetMouseInputEnabled(true)
    self:CreateAnimation(time, {
        target = {currentAlpha = 1},
        Think = function(_, panel)
            panel:SetAlpha(panel.currentAlpha * 255)
        end
    })
end

function PANEL:Hide(time)
    time = time or 0.25

    self.addPanel.characterScroll:Stop()

    self.addPanel.noPlayersLabel:SetVisible(false)

    self:SetMouseInputEnabled(false)
    self:CreateAnimation(time, {
        target = {currentAlpha = 0},
        Think = function(_, panel)
            panel:SetAlpha(panel.currentAlpha * 255)
        end,
        OnComplete = function(_, panel)
            panel:SetVisible(false)
        end
    })
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("ixBankingAccountHolderAdd", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    if IsValid(ix.gui.bankingAccountHolders) then
        ix.gui.bankingAccountHolders:Remove()
    end
    ix.gui.bankingAccountHolders = self

    self:SetSize(ScrW() * 0.5, ScrH() * 0.75)
    self:Center()
    self:MakePopup()
    self:DockPadding(10, 34, 10, 10)
    self:SetTitle(L"bankingAccountHolders")
    self.entries = {}

    self.addHolderPanel = self:Add("ixBankingAccountHolderAdd")
    self.addHolderPanel:SetPadding(2, 24, 2, 2)

    self.titleAndAdd = self:Add("Panel")
    self.titleAndAdd:Dock(TOP)
    self.titleAndAdd:DockMargin(0, 0, 0, 25)

    self.titleLabel = self.titleAndAdd:Add("DLabel")
    self.titleLabel:Dock(LEFT)
    self.titleLabel:SetFont("ixSubTitleFont")
    self.titleLabel:SetText(L"bankingAccountHolders")
    self.titleLabel:SetAutoStretchVertical(true)
    self.titleLabel:SizeToContents()

    self.addButton = self.titleAndAdd:Add("DButton")
    self.addButton:Dock(RIGHT)
    self.addButton:SetFont("ixSmallFont")
    self.addButton:SetText(L"bankingAddAccountHolder")
    self.addButton:SizeToContentsX(ScreenScale(20))
    self.addButton:SetMaterial(Material("user-add.png", "smooth"))
    self.addButton.Paint = nil
    self.addButton.DoClick = function()
        self.addHolderPanel:Show()
    end

    self.titleAndAdd:SizeToChildren(false, true)

    self.scrollPanel = self:Add("DScrollPanel")
    self.scrollPanel:Dock(FILL)

    self:InvalidateLayout(true)
    self.scrollPanel:InvalidateLayout(true)
end

function PANEL:AddEntry(charID, permission, bAnimate)
    permission = permission or self.account.accountHolders[charID]

    local entry = self.scrollPanel:Add("ixBankingAccountHoldersEntry")
    entry:Setup(charID, permission)

    if bAnimate then
        entry:Show()
    end

    self.entries[charID] = entry
end

function PANEL:RemoveEntry(charID)
    if self.entries[charID] then
        self.entries[charID]:Hide(nil, function()
            self.entries[charID]:Remove()
            self.entries[charID] = nil
        end)
    end
end

function PANEL:PopulateAccountHolders(account)
    self.account = account

    for k, v in pairs(account.accountHolders) do
        self:AddEntry(k, v)
    end
end

vgui.Register("ixBankingAccountHolders", PANEL, "DFrame")