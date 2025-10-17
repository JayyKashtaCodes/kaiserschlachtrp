local PANEL = {}

local MAT_GRADIENT = ix.util.GetMaterial("vgui/gradient-l")

function PANEL:Init()
    self:DockPadding(5, 5, 5, 5)

    self.dialogueLabel = self:Add("DLabel")
    self.dialogueLabel:Dock(TOP)
    self.dialogueLabel:SetFont("ixMediumLightFont")
    self.dialogueLabel:SetWrap(true)
    self.dialogueLabel:SetAutoStretchVertical(true)

    surface.SetFont(self.dialogueLabel:GetFont())
    local textHeight = select(2, surface.GetTextSize("@#"))
    self.dialogueLabel:SetTall(textHeight)

    self:SetTall(textHeight + self:GetHeightPadding())
end

function PANEL:GetWidthPadding()
    local r, _, l, _ = self:GetDockPadding()
    return r + l
end

function PANEL:GetHeightPadding()
    local _, t, _, b = self:GetDockPadding()
    return t + b
end

function PANEL:GetFont()
    return self.dialogueLabel:GetFont()
end

function PANEL:SetText(text)
    self.dialogueLabel:SetText(text)
    self.dialogueLabel:SizeToContents()
end

-- not ideal
function PANEL:CalculateWrap(text, font, maxWidth)
    surface.SetFont(font)
    local textWidth = surface.GetTextSize(text)

    if textWidth < maxWidth then
        return 1
    end

    local lastChars = {}
    local lines = 1
    local line = ""
    local words = string.Explode("%s", text, true)
    for k, v in ipairs(words) do
        line = line .. (line == "" and "" or " ") .. v

        if surface.GetTextSize(line) > maxWidth then
            lines = lines + 1
            lastChars[#line - #v] = true
            line = ""
        end
    end

    return lines, lastChars
end

function PANEL:AnimateText(text, time)
    if self.dialogueLabel:GetText() == text then
        return
    end

    time = time or 0.025

    if self.currentHeight then
        surface.SetFont(self.dialogueLabel:GetFont())
        local textHeight = select(2, surface.GetTextSize("@#"))
        self:CreateAnimation(0.1, {
            target = {currentHeight = textHeight + self:GetHeightPadding()},
            Think = function(anim, panel)
                panel:SetTall(self.currentHeight)
            end
        })
    end

    if self.timerName and timer.Exists(self.timerName) then
        timer.Remove(self.timerName)
    end

    local lines, lastChars = self:CalculateWrap(text, self.dialogueLabel:GetFont(), self:GetWide() - self:GetWidthPadding())

    local timerName = "ixBankingDialogue" .. math.random(1, 100)
    self.timerName = timerName

    local index = 1
    timer.Create(timerName, time, #text, function()
        if not IsValid(self) then
            timer.Remove(timerName)
            return
        end

        self.dialogueLabel:SetText(string.sub(text, 1, index))
        self.dialogueLabel:SizeToContents()

        if lastChars and lastChars[index] then
            self.currentHeight = self.dialogueLabel:GetTall() + self:GetHeightPadding()
            self:CreateAnimation(0.1, {
                target = {currentHeight = self.dialogueLabel:GetTall() + self.dialogueLabel:GetTall() + self:GetHeightPadding()},
                Think = function(anim, panel)
                    panel:SetTall(self.currentHeight)
                end
            })
        end

        index = index + 1
    end)
end

function PANEL:Paint(w, h)
    ix.util.DrawBlur(self)

    surface.SetDrawColor(Color(0, 0, 0, 180))
    surface.DrawOutlinedRect(0, 0, w, h)
end

vgui.Register("ixBankingDialogue", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    self.subpanels = {}
end

function PANEL:AddSubpanel(id, class)
    if self.subpanels[id] then
        return self.subpanels[id]
    end

    local subpanel = self:Add(class or "Panel")
    subpanel:SetVisible(false)
    subpanel.currentAlpha = 0
    subpanel.id = id

    self.subpanels[id] = subpanel

    return subpanel
end

function PANEL:SetActiveSubpanel(id, time, callback)
    time = time or 0.5

    local activeSubpanel = self.activeSubpanel
    local newPanel = self.subpanels[id]

    if IsValid(activeSubpanel) and IsValid(newPanel) then
        self.activeSubpanel = newPanel

        if activeSubpanel.OnInactive then
            activeSubpanel:OnInactive()
        end

        activeSubpanel:CreateAnimation(time * 0.5, {
            target = {currentAlpha = 0},
            Think = function(_, panel)
                panel:SetAlpha(panel.currentAlpha * 255)
            end,
            OnComplete = function(_, panel)
                panel:SetVisible(false)

                if newPanel.OnActive then
                    newPanel:OnActive()
                end
                
                if callback then
                    callback()
                end

                newPanel:SetVisible(true)
                newPanel:CreateAnimation(time * 0.5, {
                    target = {currentAlpha = 1},
                    Think = function(_, panel2)
                        panel2:SetAlpha(panel2.currentAlpha * 255)
                    end
                })
            end
        })
    elseif IsValid(newPanel) then
        newPanel:SetVisible(true)
        newPanel.currentAlpha = 1

        self.activeSubpanel = newPanel

        if newPanel.OnActive then
            newPanel:OnActive()
        end

        if callback then
            callback()
        end
    end
end

function PANEL:PerformLayout(w, h)
    for k, v in pairs(self.subpanels) do
        if IsValid(v) then
            v:SetSize(w, h)
        end
    end
end

vgui.Register("ixBankingCanvas", PANEL, "Panel")

PANEL = {}

AccessorFunc(PANEL, "iIndex", "Index", FORCE_NUMBER)

function PANEL:Init()
    self:DockMargin(0, 0, 0, 2)
    self:SetFont("ixSmallFont")
end

function PANEL:Paint(w, h)
    local index = self:GetIndex() or 0
    local col = index % 2 == 0 and 75 or 125

    surface.SetDrawColor(col, col, col, 50)
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("ixBankingButton", PANEL, "DButton")

PANEL = {}

function PANEL:Init()
    self:DockMargin(0, 0, 0, 2)
    self:SetFont("ixSmallFont")
    self:SetTall(self:GetTall() + 4)
    self:SetPlaceholderColor(Color(200, 200, 200))
end

vgui.Register("ixBankingEntry", PANEL, "ixTextEntry")

PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() * 0.5, ScrH() * 0.3)

    self:CenterHorizontal()
    self:SetY(ScrH() * 0.65)

    self:MakePopup()

    self.keyCodeHooks = {}

    self.nameAndClose = self:Add("Panel")
    self.nameAndClose:Dock(TOP)
    self.nameAndClose:DockMargin(0, 0, 0, 5)

    self.nameLabel = self.nameAndClose:Add("DLabel")
    self.nameLabel:Dock(FILL)
    self.nameLabel:SetTextInset(5, 0)
    self.nameLabel:SetFont("ixMediumFont")
    self.nameLabel:SetText("Bank")
    self.nameLabel:SetTall(self.nameLabel:GetTall() + 10)
    self.nameLabel.Paint = function(this, w, h)
        surface.SetFont(this:GetFont())
        local textW = surface.GetTextSize(this:GetText())

        surface.SetDrawColor(ix.config.Get("color"))
        surface.SetMaterial(MAT_GRADIENT)
        surface.DrawTexturedRect(0, 0, textW * 2, h)
    end

    self.nameAndClose:SetTall(self.nameLabel:GetTall())

    self.closeButton = self.nameAndClose:Add("DButton")
    self.closeButton:Dock(RIGHT)
    self.closeButton:SetText("X")
    self.closeButton.DoClick = function()
        self:Remove()
    end

    self.dialoguePanel = self:Add("ixBankingDialogue")
    self.dialoguePanel:Dock(TOP)
    self.dialoguePanel:DockMargin(0, 0, 0, 10)
    self.dialoguePanel:SetText("")

    self.canvas = self:Add("ixBankingCanvas")
    self.canvas:Dock(FILL)
end

function PANEL:PerformLayout(w, h)
    self.closeButton:SetWide(self.closeButton:GetTall())
end

function PANEL:RegisterKeyCode(keyCode, panel)
    self.keyCodeHooks[keyCode] = self.keyCodeHooks[keyCode] or {}
    
    table.insert(self.keyCodeHooks[keyCode], panel)
end

function PANEL:OnKeyCodePressed(keyCode)
    if self.keyCodeHooks[keyCode] then
        for k, v in ipairs(self.keyCodeHooks[keyCode]) do
            v:KeyCodePressed(keyCode)
        end
    end
end

vgui.Register("ixBanking", PANEL, "EditablePanel")