local PANEL = {}

function PANEL:Init()
    self:SetSize(500, 440)
    self:Center()
    self:SetTitle("Jail Sentencing Menu")
    self:MakePopup()

    -- Player list
    self.playerList = self:Add("DListView")
    self.playerList:Dock(TOP)
    self.playerList:SetTall(200)
    self.playerList:AddColumn("Character Name")

    -- Style headers
    for _, column in ipairs(self.playerList.Columns) do
        column.Header:SetTextColor(Color(0, 0, 0))
    end

    -- Inputs container
    local formPanel = self:Add("DPanel")
    formPanel:Dock(FILL)
    formPanel:DockPadding(10, 10, 10, 10)
    formPanel:SetPaintBackground(false)

    local y = 0
    local spacing = 30

    -- Jail time
    local jailTimeLabel = vgui.Create("DLabel", formPanel)
    jailTimeLabel:SetText("Jail Time (minutes):")
    jailTimeLabel:SetPos(0, y)
    jailTimeLabel:SizeToContents()

    self.jailTimeEntry = vgui.Create("DTextEntry", formPanel)
    self.jailTimeEntry:SetPos(160, y)
    self.jailTimeEntry:SetSize(100, 20)

    y = y + spacing

    -- Reason
    local reasonLabel = vgui.Create("DLabel", formPanel)
    reasonLabel:SetText("Reason:")
    reasonLabel:SetPos(0, y)
    reasonLabel:SizeToContents()

    self.reasonEntry = vgui.Create("DTextEntry", formPanel)
    self.reasonEntry:SetPos(160, y)
    self.reasonEntry:SetSize(300, 20)

    y = y + spacing

    -- Judge
    local judgeLabel = vgui.Create("DLabel", formPanel)
    judgeLabel:SetText("Judge's Name:")
    judgeLabel:SetPos(0, y)
    judgeLabel:SizeToContents()

    self.judgeEntry = vgui.Create("DTextEntry", formPanel)
    self.judgeEntry:SetPos(160, y)
    self.judgeEntry:SetSize(300, 20)

    y = y + spacing + 10

    -- Confirm button
    local confirmButton = formPanel:Add("DButton")
    confirmButton:SetText("Confirm Sentence")
    confirmButton:SetTall(30)
    confirmButton:Dock(BOTTOM)
    confirmButton:DockMargin(0, 10, 0, 0)
    confirmButton:SetContentAlignment(5)

    confirmButton.DoClick = function()
        self:OnConfirmSentence()
    end

    -- Populate players initially
    self:PopulateNearbyPlayers(LocalPlayer(), 200)
end

function PANEL:PopulateNearbyPlayers(ply, radius)
    self.playerList:Clear()

    local radiusSqr = radius * radius
    local found = false

    for _, target in ipairs(player.GetAll()) do
        if target ~= ply
        and target:GetPos():DistToSqr(ply:GetPos()) <= radiusSqr
        and target:GetNetVar("restricted", false)
        and target:GetNetVar("restraintType", "") == "cuffs" then
            local char = target:GetCharacter()
            local charName = char and char:GetName() or target:Nick()
            local line = self.playerList:AddLine(charName)
            line.Player = target
            found = true
        end
    end

    if not found then
        local line = self.playerList:AddLine("No nearby restrained players found.")
        line:SetSelectable(false)
    end
end

function PANEL:OnConfirmSentence()
    local selectedLine = self.playerList:GetSelectedLine()
    if not selectedLine then
        Derma_Message("Please select a player.", "Error", "OK")
        return
    end

    local line = self.playerList:GetLine(selectedLine)
    if not IsValid(line) or not IsValid(line.Player) then
        Derma_Message("Invalid player selected.", "Error", "OK")
        return
    end

    local jailTime = tonumber(self.jailTimeEntry:GetValue())
    local reason = self.reasonEntry:GetValue():Trim()
    local judge = self.judgeEntry:GetValue():Trim()

    if not jailTime or jailTime < 1 or jailTime > 120 then
        Derma_Message("Please enter a jail time between 1 and 120 minutes.", "Error", "OK")
        return
    end

    if reason == "" or judge == "" then
        Derma_Message("Please fill in both a reason and a judge's name.", "Error", "OK")
        return
    end

    net.Start("JailPlayer")
        net.WriteEntity(line.Player)
        net.WriteInt(jailTime, 32)
        net.WriteString(reason)
        net.WriteString(judge)
    net.SendToServer()

    self:Close()
end

vgui.Register("JailMenu", PANEL, "DFrame")
