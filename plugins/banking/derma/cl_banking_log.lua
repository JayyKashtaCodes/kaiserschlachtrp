local PANEL = {}

function PANEL:Init()
    self.text = ""
end

function PANEL:SetAccentColor(color)
    self.accentColor = color or Color(200, 200, 200)
end

function PANEL:SetMarkup(text)
    self.text = text

    self.markup = ix.markup.Parse("<font=ixMediumFont>" .. self.text, self:GetWide() - 10)

    self:SetTall(self.markup:GetHeight() + 10)
    self:GetParent():SizeToChildren(false, true)
end

local GRADIENT_L = ix.util.GetMaterial("vgui/gradient-l")

function PANEL:Paint(w, h)
    surface.SetDrawColor(ColorAlpha(self.accentColor, 75))
    surface.SetMaterial(GRADIENT_L)
    surface.DrawTexturedRect(0, 0, w, h)

    if self.markup then
        self.markup:draw(5, 5)
    end
end

vgui.Register("ixBankingLogEntryMarkup", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self:Dock(TOP)
    self:DockMargin(0, 0, 0, 5)
    self.animProgress = 0

    self.timePanel = self:Add("Panel")
    self.timePanel:SetPos(0, 0)
    self.timePanel:DockPadding(5, 5, 5, 5)
    self.timePanel:SetMouseInputEnabled(false)
    self.timePanel:SetPaintedManually(true)
    self.timePanel.Paint = function(_, w, h)
        surface.SetDrawColor(Color(200, 200, 200, 150))
        surface.SetMaterial(GRADIENT_L)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    self.timeLabel = self.timePanel:Add("DLabel")
    self.timeLabel:Dock(LEFT)
    self.timeLabel:SetFont("ixSmallFont")
    self.timeLabel:SetExpensiveShadow(1, Color(0, 0, 0, 150))
    self.timeLabel:SetContentAlignment(4)
    self.timeLabel:SetAutoStretchVertical(true)

    self.markupPanel = self:Add("ixBankingLogEntryMarkup")
    self.markupPanel:SetMouseInputEnabled(false)
end

function PANEL:SetAccentColor(color)
    self.markupPanel:SetAccentColor(color)
end

function PANEL:SetMarkup(text)
    self.markupPanel:SetPos(0, 0)
    self.markupPanel:SetSize(self:GetSize())

    self.markupPanel:SetMarkup(text)
end

function PANEL:SetTime(time)
    if not time then
        return
    end

    local date = os.date("%c", time)
    self.timeLabel:SetText(date)
    self.timeLabel:SizeToContents()

    self.timePanel:SizeToChildren(true, true)
end

function PANEL:OnCursorEntered()
    self:CreateAnimation(0.2, {
        index = 1,
        target = {animProgress = 1},
        easing = "outQuad",
        Think = function(anim, panel)
            self.markupPanel:SetY((self.timePanel:GetTall() + ScreenScaleH(2)) * panel.animProgress)

            self:SizeToChildren(false, true)

            -- jank
            if not self:IsHovered() then
                self:OnCursorExited()
            end
        end
    })
end

function PANEL:OnCursorExited()
    self:CreateAnimation(0.2, {
        index = 1,
        target = {animProgress = 0},
        easing = "outQuad",
        Think = function(anim, panel)
            self.markupPanel:SetY((self.timePanel:GetTall() + ScreenScaleH(2)) * panel.animProgress)

            self:SizeToChildren(false, true)
        end
    })
end

function PANEL:Paint(w, h)
    ix.util.ResetStencilValues()

	render.SetStencilEnable(true)
	render.SetStencilReferenceValue(1)
	render.SetStencilCompareFunction(STENCIL_NEVER)
	render.SetStencilFailOperation(STENCIL_REPLACE)

	surface.SetDrawColor(color_white)
	draw.NoTexture()
	surface.DrawRect(0, 0, w, (self.timePanel:GetTall() + ScreenScaleH(2)) * self.animProgress)

	render.SetStencilCompareFunction(STENCIL_EQUAL)
	render.SetStencilFailOperation(STENCIL_KEEP)

	self.timePanel:PaintManual()

	render.SetStencilEnable(false)
end

vgui.Register("ixBankingLogEntry", PANEL, "Panel")

PANEL = {}

function PANEL:Populate(accountID, logs)
    local account = ix.banking.accounts[accountID]

    for i = 1, #logs do
        local logInfo = logs[i]
        if not logInfo then
            break
        end

        local logTypeInfo = ix.banking.logTypes[logInfo.type]

        local entryPanel = self:Add("ixBankingLogEntry")
        entryPanel:SetWide(self:GetWide())
        entryPanel:SetAccentColor(logTypeInfo.accentColor)
        entryPanel:SetMarkup(ix.banking.ParseLog(logInfo.type, accountID, logInfo.time, logInfo.data))
        entryPanel:SetTime(logInfo.time)
    end
end

vgui.Register("ixBankingLogPage", PANEL, "DScrollPanel")

PANEL = {}

function PANEL:Init()
    if IsValid(ix.gui.bankingLog) then
        ix.gui.bankingLog:Remove()
    end
    ix.gui.bankingLog = self

    self.logs = {}
    self.logCount = 0
    self.lastLogID = 0
    self.pageSize = 25

    self:SetSize(ScrW() * 0.4, ScrH() * 0.75)
    self:SetTitle(L"bankingLog")
    self:Center()
    self:MakePopup()

    self.canvas = self:Add("ixSubpanelParent")
    self.canvas:SetPadding(0, true)
    self.canvas:Dock(FILL)
    
    self.bottomPanel = self:Add("Panel")
    self.bottomPanel:Dock(BOTTOM)
    self.bottomPanel:DockMargin(0, 5, 0, 0)
    self.bottomPanel:SetTall(self:GetTall() * 0.05)

    self.leftBottomPanel = self.bottomPanel:Add("Panel")
    self.leftBottomPanel:SetSize(256, self.bottomPanel:GetTall())

    self.leftButton = self.leftBottomPanel:Add("DImageButton")
    self.leftButton:Dock(LEFT)
    self.leftButton:DockMargin(10, 10, 0, 10)
    self.leftButton:SetMaterial(Material("left-arrow.png", "smooth"))
    self.leftButton.DoClick = function()
        local activePageIndex = self.canvas.activeSubpanel
        if not activePageIndex then
            return
        end

        if activePageIndex > 1 then
            self:TransitionPage(activePageIndex - 1)
        end
    end

    self.pageNumber = self.leftBottomPanel:Add("DLabel")
    self.pageNumber:Dock(LEFT)
    self.pageNumber:DockMargin(15, 0, 15, 0)
    self.pageNumber:SetFont("ixMediumFont")

    self.rightButton = self.leftBottomPanel:Add("DImageButton")
    self.rightButton:Dock(LEFT)
    self.rightButton:DockMargin(0, 10, 10, 10)
    self.rightButton:SetMaterial(Material("right-arrow.png", "smooth"))
    self.rightButton.DoClick = function()
        local activePageIndex = self.canvas.activeSubpanel
        if not activePageIndex then
            return
        end

        if activePageIndex * self.pageSize < self.logCount then
            if not self.canvas.subpanels[activePageIndex + 1].bPopulated then
                self.waitingForLogs = activePageIndex + 1

                self.leftButton:SetEnabled(false)
                self.rightButton:SetEnabled(false)

                net.Start("ixBankingLogs")
                    net.WriteUInt(self.accountID, 32)
                    net.WriteUInt(self.pageSize, 8)
                    net.WriteUInt(self.lastLogID, 32)
                net.SendToServer()
                return
            end

            self:TransitionPage(activePageIndex + 1)
        end
    end

    self.pageSizeSelect = self.bottomPanel:Add("DComboBox")
    self.pageSizeSelect:Dock(RIGHT)
    for i = 25, 50, 5 do
        self.pageSizeSelect:AddChoice(i, i)
    end
    self.pageSizeSelect.OnSelect = function(_, _, value)
        self.pageSize = tonumber(value) or 25

        self:RefreshLogs()
    end

    self.canvas:InvalidateParent(true)
end

function PANEL:Populate(accountID)
    self.accountID = accountID

    self.pageSizeSelect:ChooseOptionID(1)
end

function PANEL:RefreshLogs()
    if not self.accountID then
        return
    end

    self.logs = {}
    self.logCount = 0
    self.lastLogID = 0

    self.canvas:Clear()
    self.canvas.subpanels = {}
	self.canvas.childPanels = {}
    self.canvas.activeSubpanel = nil

    local subpanel = self.canvas:AddSubpanel(tostring(1))
    subpanel:SetTitle(nil)

    self.waitingForLogs = 1

    net.Start("ixBankingLogs")
        net.WriteUInt(self.accountID, 32)
        net.WriteUInt(self.pageSize, 8)
    net.SendToServer()
end

function PANEL:TransitionPage(pageIndex)
    -- yes lol

    self.pageNumber:SetText(pageIndex)
    self.pageNumber:SizeToContents()

    self.canvas:SetActiveSubpanel(pageIndex)
end

function PANEL:CreateNewPage(pageIndex, logs)
    if not self.canvas.subpanels[pageIndex].bPopulated then
        local subpanel = self.canvas.subpanels[pageIndex]
        subpanel.bPopulated = true

        local logPage = subpanel:Add("ixBankingLogPage")
        logPage:SetSize(subpanel:GetSize())
        logPage:Populate(self.accountID, logs)

        subpanel.panel = logPage

        self.lastLogID = logs[#logs].id or 0

        local nextSubpanel = self.canvas:AddSubpanel(tostring(pageIndex + 1))
        nextSubpanel:SetTitle(nil)
    end
    self:TransitionPage(pageIndex)
end

DEFINE_BASECLASS("DFrame")
function PANEL:PerformLayout(w, h)
    BaseClass.PerformLayout(self, w, h)

    if IsValid(self.rightButton) then
        self.leftButton:SetWide(self.leftButton:GetTall())
        self.rightButton:SetWide(self.rightButton:GetTall())
    end
end

vgui.Register("ixBankingLog", PANEL, "DFrame")