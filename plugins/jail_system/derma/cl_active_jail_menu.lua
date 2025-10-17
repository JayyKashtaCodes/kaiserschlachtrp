local PANEL = {}
local activeJailPanel = nil

function PANEL:Init()
    self:SetSize(700, 500)
    self:Center()
    self:SetTitle("Active Jail Sentences")
    self:MakePopup()

    activeJailPanel = self

    self.jailList = self:Add("DListView")
    self.jailList:Dock(FILL)
    self.jailList:AddColumn("Character Name")
    self.jailList:AddColumn("Time Left")
    self.jailList:AddColumn("Reason")
    self.jailList:AddColumn("Judge")

    self.statusLabel = self:Add("DLabel")
    self.statusLabel:Dock(BOTTOM)
    self.statusLabel:SetTall(20)
    self.statusLabel:SetText("Select a player to release")

    self.releaseButton = self:Add("DButton")
    self.releaseButton:Dock(BOTTOM)
    self.releaseButton:SetTall(40)
    self.releaseButton:SetText("Release Selected")
    self.releaseButton:SetEnabled(false)

    -- Track current selection index
    self.selectedIndex = nil

    -- Selection handler
    self.jailList.OnRowSelected = function(_, index, line)
        self.selectedIndex = index
        local name = line and line:GetColumnText(1) or "Unknown"

        --print("[Debug] Row selected:", index, name)

        self.releaseButton:SetEnabled(true)
        self.statusLabel:SetText("Selected: " .. name)
    end

    -- Release button: send index to server
    self.releaseButton.DoClick = function()
        if not self.selectedIndex then
            self.statusLabel:SetText("Invalid selection")
            return
        end

        local line = self.jailList:GetLine(self.selectedIndex)
        if not IsValid(line) then
            self.statusLabel:SetText("Invalid selection")
            return
        end

        local charName = line:GetColumnText(1)

        self:PromptReasonAndRelease(self.selectedIndex, charName)
    end

    -- Ask server for jail data
    timer.Simple(0.1, function()
        if IsValid(self) then
            --print("[Client] Requesting active jail data...")
            net.Start("RequestActiveJails")
            net.SendToServer()
        end
    end)
end

net.Receive("SendActiveJails", function()
    --print("[Client] Received SendActiveJails")

    if not IsValid(activeJailPanel) or not IsValid(activeJailPanel.jailList) then
        --print("[Client] Panel/list invalid")
        return
    end

    local list = activeJailPanel.jailList
    list:ClearSelection()
    list:Clear()
    activeJailPanel.selectedIndex = nil

    local count = net.ReadUInt(12)
    --print("[Client] Jail count received:", count)

    if count == 0 then
        local line = list:AddLine("No active jail sentences found.", "", "", "")
        line:SetSelectable(false)
        activeJailPanel.releaseButton:SetEnabled(false)
        activeJailPanel.statusLabel:SetText("No players jailed")
        return
    end

    for i = 1, count do
        local _steamID   = net.ReadString() -- still read to keep net order
        local charName   = net.ReadString()
        local reason     = net.ReadString()
        local judge      = net.ReadString()
        local _startTime = net.ReadUInt(32)
        local _jailTime  = net.ReadUInt(32)
        local remaining  = net.ReadUInt(32)

        local timeFormatted = string.ToMinutesSeconds(remaining)

        list:AddLine(charName, timeFormatted, reason, judge)
    end
end)

-- Prompt and send release by index
function PANEL:PromptReasonAndRelease(rowIndex, name)
    local reasonFrame = vgui.Create("DFrame")
    reasonFrame:SetTitle("Release " .. name)
    reasonFrame:SetSize(300, 140)
    reasonFrame:Center()
    reasonFrame:MakePopup()

    local entry = reasonFrame:Add("DTextEntry")
    entry:SetPos(20, 40)
    entry:SetSize(260, 25)
    entry:SetPlaceholderText("Enter a reason for release...")

    local confirm = reasonFrame:Add("DButton")
    confirm:SetText("Confirm")
    confirm:SetSize(260, 30)
    confirm:SetPos(20, 80)
    confirm.DoClick = function()
        local reason = entry:GetValue()
        if reason and reason:Trim() ~= "" then
            net.Start("ReleasePlayer")
                net.WriteUInt(rowIndex, 12) -- send the list index
                net.WriteString(reason)
            net.SendToServer()

            reasonFrame:Close()
            self:Close()
        else
            Derma_Message("Please enter a valid release reason.", "Error", "OK")
        end
    end
end

function PANEL:OnRemove()
    activeJailPanel = nil
end

vgui.Register("ActiveJailMenu", PANEL, "DFrame")
