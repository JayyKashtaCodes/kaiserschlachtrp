local PLUGIN = PLUGIN
local voteCreationFrame

local PANEL = {}

function PANEL:Init()
    self:SetSize(400, 420)
    self:Center()
    self:SetTitle("Create a Vote")
    self:SetDeleteOnClose(true)
    self:MakePopup()

    self.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 255))
    end

    local y = 40

    self.titleEntry = self:Add("DTextEntry")
    self.titleEntry:SetPos(25, y)
    self.titleEntry:SetSize(350, 25)
    self.titleEntry:SetPlaceholderText("Vote Title")
    y = y + 35

    self.optionList = self:Add("DScrollPanel")
    self.optionList:SetPos(25, y)
    self.optionList:SetSize(350, 110)
    y = y + 115

    self.optionEntry = self:Add("DTextEntry")
    self.optionEntry:SetPos(25, y)
    self.optionEntry:SetSize(260, 25)
    self.optionEntry:SetPlaceholderText("Enter option...")

    self.addOptionBtn = self:Add("DButton")
    self.addOptionBtn:SetPos(295, y)
    self.addOptionBtn:SetSize(80, 25)
    self.addOptionBtn:SetText("Add")
    self.addOptionBtn.DoClick = function()
        local value = self.optionEntry:GetValue():Trim()
        if value == "" then return end

        local container = self.optionList:GetCanvas():Add("DPanel")
        container:SetTall(30)
        container:Dock(TOP)
        container:DockMargin(0, 2, 0, 2)
        container.optionText = value

        local label = container:Add("DLabel")
        label:SetPos(5, 5)
        label:SetFont("DermaDefault")
        label:SetText(value)
        label:SizeToContents()

        local removeBtn = container:Add("DButton")
        removeBtn:SetText("✕")
        removeBtn:SetSize(25, 25)
        removeBtn:SetPos(320, 2)
        removeBtn.DoClick = function()
            container:Remove()
            self:ValidateInputs() -- Revalidate after removal
        end

        self.optionEntry:SetValue("")
        self:ValidateInputs()
    end

    y = y + 35

    local durationLabel = self:Add("DLabel")
    durationLabel:SetPos(25, y)
    durationLabel:SetSize(350, 20)
    durationLabel:SetText("Vote Settings")
    durationLabel:SetFont("DermaDefaultBold")
    durationLabel:SetContentAlignment(5)
    y = y + 25

    self.durationInput = self:Add("DNumberWang")
    self.durationInput:SetPos(225, y)
    self.durationInput:SetSize(150, 25)
    self.durationInput:SetMin(1)
    self.durationInput:SetMax(720)
    self.durationInput:SetValue(5)
    self.durationInput:SetTooltip("Vote duration in minutes (1–720)")
    y = y + 40

    self.submitButton = self:Add("DButton")
    self.submitButton:SetPos(25, y)
    self.submitButton:SetSize(350, 35)
    self.submitButton:SetText("Submit Vote")
    self.submitButton:SetEnabled(false)

    self.titleEntry.OnChange = function()
        self:ValidateInputs()
    end

    self.optionEntry.OnChange = function()
        self:ValidateInputs()
    end

    self.submitButton.DoClick = function()
        local title = self.titleEntry:GetValue():Trim()
        if title == "" then
            return LocalPlayer():Notify("Vote title cannot be empty.")
        end

        local options = {}
        for _, container in ipairs(self.optionList:GetCanvas():GetChildren()) do
            if container.optionText and container.optionText:Trim() ~= "" then
                table.insert(options, container.optionText:Trim())
            end
        end

        if #options < 2 then
            return LocalPlayer():Notify("Please provide at least two options.")
        end

        local duration = math.Clamp(self.durationInput:GetValue(), 1, 720)

        net.Start("ixVoteStart")
            net.WriteString(title)
            net.WriteUInt(#options, 8)
            for _, option in ipairs(options) do
                net.WriteString(option)
            end
            net.WriteUInt(duration, 16)
        net.SendToServer()

        self:Close()
    end

    self.OnRemove = function()
        voteCreationFrame = nil
    end
end

function PANEL:ValidateInputs()
    local titleValid = self.titleEntry:GetValue():Trim() ~= ""
    local hasOptions = #self.optionList:GetCanvas():GetChildren() >= 2

    self.submitButton:SetEnabled(titleValid and hasOptions)
end

vgui.Register("ixVoteCreationMenu", PANEL, "DFrame")

function PLUGIN:ixOpenVoteCreationMenu()
    if IsValid(voteCreationFrame) then
        voteCreationFrame:MakePopup()
        return
    end

    voteCreationFrame = vgui.Create("ixVoteCreationMenu")
end
