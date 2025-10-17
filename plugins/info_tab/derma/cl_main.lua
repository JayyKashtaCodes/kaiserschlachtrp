local baseGoogleDocsURL = "https://docs.google.com/document/d/"

local PANEL = {}

function PANEL:Init()
    self:SetSize(self:GetParent():GetSize())

    self.tabs = self:Add("DPropertySheet")
    self.tabs:Dock(FILL)

    self.tabs.Paint = function(self, w, h)
        surface.SetDrawColor(236, 214, 189)
        surface.DrawRect(0, 0, w, h)
    end

    self.lawsTab = self.tabs:AddSheet("Laws", CreateLawsPanel(self.tabs), "icon16/shield.png")
    self.rulesTab = self.tabs:AddSheet("Rules", CreateRulesPanel(self.tabs), "icon16/application_form.png")
end

vgui.Register("ixInfoMenu", PANEL, "EditablePanel")

function CreateLawsPanel(parent)
    local lawsPanel = vgui.Create("DPanel", parent)
    lawsPanel:Dock(FILL)
    local lawsBrowser = vgui.Create("DHTML", lawsPanel)
    lawsBrowser:Dock(FILL)
    local lawsDocID = ix.config.Get("lawsDocID")
    lawsBrowser:OpenURL(baseGoogleDocsURL .. lawsDocID .. "/preview")

    return lawsPanel
end

function CreateRulesPanel(parent)
    local rulesPanel = vgui.Create("DPanel", parent)
    rulesPanel:Dock(FILL)
    local rulesBrowser = vgui.Create("DHTML", rulesPanel)
    rulesBrowser:Dock(FILL)
    local rulesDocID = ix.config.Get("rulesDocID")
    rulesBrowser:OpenURL(baseGoogleDocsURL .. rulesDocID .. "/preview")

    return rulesPanel
end
