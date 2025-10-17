local PLUGIN = PLUGIN
local PANEL = {}

function PANEL:Init()
    self:SetTitle("Edit Information Booth")
    self:SetSize(600, 400)
    self:Center()
    self:MakePopup()

    self.topics = {}

    self.list = self:Add("DListView")
    self.list:Dock(LEFT)
    self.list:SetWide(200)
    self.list:AddColumn("Topics")

    self.editorPanel = self:Add("DPanel")
    self.editorPanel:Dock(FILL)
    self.editorPanel:DockPadding(5, 5, 5, 5)

    self.titleEntry = self.editorPanel:Add("DTextEntry")
    self.titleEntry:Dock(TOP)
    self.titleEntry:SetPlaceholderText("Topic Title")

    self.contentEntry = self.editorPanel:Add("DTextEntry")
    self.contentEntry:Dock(FILL)
    self.contentEntry:SetMultiline(true)
    self.contentEntry:SetPlaceholderText("Topic Content")

    local btnPanel = self.editorPanel:Add("DPanel")
    btnPanel:Dock(BOTTOM)
    btnPanel:SetTall(30)
    btnPanel:SetPaintBackground(false)

    local addBtn = btnPanel:Add("DButton")
    addBtn:Dock(LEFT)
    addBtn:SetText("Add / Update")
    addBtn.DoClick = function()
        local title = self.titleEntry:GetValue()
        local content = self.contentEntry:GetValue()
        if title == "" or content == "" then return end

        local found = false
        for _, topic in ipairs(self.topics) do
            if topic.title == title then
                topic.content = content
                found = true
                break
            end
        end
        if not found then
            table.insert(self.topics, { title = title, content = content })
        end
        self:RefreshList()
    end

    local removeBtn = btnPanel:Add("DButton")
    removeBtn:Dock(LEFT)
    removeBtn:SetText("Remove")
    removeBtn.DoClick = function()
        local selected = self.list:GetSelectedLine()
        if not selected then return end
        table.remove(self.topics, selected)
        self:RefreshList()
    end

    local saveBtn = btnPanel:Add("DButton")
    saveBtn:Dock(RIGHT)
    saveBtn:SetText("Save")
    saveBtn.DoClick = function()
        if not IsValid(self.boothEnt) then return end
        net.Start("ixInfoBooth_Update")
            net.WriteEntity(self.boothEnt)
            net.WriteTable(self.topics)
        net.SendToServer()
        self:Close()
    end

    self.list.OnRowSelected = function(_, id, row)
        local topic = self.topics[id]
        if topic then
            self.titleEntry:SetValue(topic.title)
            self.contentEntry:SetValue(topic.content)
        end
    end
end

function PANEL:SetBooth(ent)
    self.boothEnt = ent
end

function PANEL:SetTopics(topics)
    self.topics = table.Copy(topics or {})
    self:RefreshList()
end

function PANEL:RefreshList()
    self.list:Clear()
    if #self.topics == 0 then
        self.list:AddLine("[No topics set]")
        return
    end
    for _, topic in ipairs(self.topics) do
        self.list:AddLine(topic.title)
    end
end

vgui.Register("ixInfoBoothEditor", PANEL, "DFrame")
