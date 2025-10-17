local PLUGIN = PLUGIN

-----------------------------------------
-- Modern Dialogue Booth
-----------------------------------------
local PANEL = {}

function PANEL:Init()
    if IsValid(ix.gui.infoBooth) then
        ix.gui.infoBooth:Remove()
    end
    ix.gui.infoBooth = self

    -- Main frame
    self:SetSize(ScrW() * 0.6, ScrH() * 0.8)
    self:Center()
    self:MakePopup()

    -- Background paint for whole panel
    self.Paint = function(_, w, h)
        -- Dark translucent background
        surface.SetDrawColor(20, 20, 20, 230)
        surface.DrawRect(0, 0, w, h)

        -- Border
        surface.SetDrawColor(255, 255, 255, 20)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    -- Title
    self.nameLabel = self:Add("DLabel")
    self.nameLabel:Dock(TOP)
    self.nameLabel:SetFont("ixBigFont" or "Trebuchet24")
    self.nameLabel:SetText("Information Booth")
    self.nameLabel:SetContentAlignment(5)
    self.nameLabel:SetTall(50)
    self.nameLabel.Paint = function(s, w, h)
        -- Accent underline
        surface.SetDrawColor(255, 215, 0, 255)
        surface.DrawRect(w * 0.25, h - 4, w * 0.5, 2)
    end

    -- Content area
    self.contentArea = self:Add("DLabel")
    self.contentArea:Dock(FILL)
    self.contentArea:SetWrap(true)
    self.contentArea:SetFont("ixMediumFont")
    self.contentArea:SetText("Select a topic from the list...")
    self.contentArea:SetContentAlignment(7) -- top-left
    self.contentArea:SetMouseInputEnabled(false)
    self.contentArea:DockMargin(16, 8, 16, 120) -- leave space for bottom list
    self.contentArea.Paint = function(s, w, h)
        -- Dialogue box background
        surface.SetDrawColor(30, 30, 30, 200)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255, 10)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    -- Topic list panel (bottom-centre)
    self.topicListPanel = self:Add("DPanel")
    self.topicListPanel:SetWide(300)
    self.topicListPanel:DockPadding(8, 8, 8, 8)
    self.topicListPanel.Paint = function(_, w, h)
        surface.SetDrawColor(25, 25, 25, 240)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255, 15)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    -- Holder for topic buttons
    self.listHolder = self.topicListPanel:Add("EditablePanel")
    self.listHolder:Dock(FILL)

    -- Position topic list bottom-centre
    self.PerformLayout = function(_, w, h)
        local listW, listH = self.topicListPanel:GetWide(), self.topicListPanel:GetTall()
        self.topicListPanel:SetPos((w - listW) / 2, h - listH - 20)
    end
end

function PANEL:SetTopics(topics)
    self.topics = topics or {}
    self.listHolder:Clear()

    local totalHeight = 0
    local spacing = 6

    local function CreateStyledButton(text, onClick, isExit)
        local btn = self.listHolder:Add("DButton")
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, spacing)
        btn:SetText(text)
        btn:SetFont("ixSmallFont")
        btn:SetTextColor(color_white)
        btn.Paint = function(s, w, h)
            local bg = isExit and Color(150, 50, 50, 200) or Color(50, 50, 50, 200)
            if s:IsHovered() then
                bg = isExit and Color(200, 70, 70, 220) or Color(70, 70, 70, 220)
            end
            surface.SetDrawColor(bg)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 255, 255, 15)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        btn.DoClick = onClick
        btn:SizeToContentsY()
        totalHeight = totalHeight + btn:GetTall() + spacing
    end

    if #self.topics == 0 then
        CreateStyledButton("No topics available.", function() end)
    else
        for _, topic in ipairs(self.topics) do
            CreateStyledButton(topic.title, function()
                self.contentArea:SetText(topic.content)
            end)
        end
    end

    -- Exit button
    CreateStyledButton("Exit", function()
        if IsValid(self) then
            self:Remove()
        end
    end, true)

    -- Resize topic list to fit content
    self.topicListPanel:SetTall(totalHeight + 16)
end

vgui.Register("ixInfoBoothView", PANEL, "EditablePanel")
