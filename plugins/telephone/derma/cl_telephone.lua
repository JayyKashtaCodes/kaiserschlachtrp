local PLUGIN = PLUGIN

local PANEL = {}

function PANEL:Init()
    self:SetSize(400, 400)
    self:SetTitle("Telephone")
    self:MakePopup()
    self:ShowCloseButton(false)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(true)
    self:Center()

    self.telephoneNumber = nil
    self.incomingCall = false
    self.inCall = false
    self.connectedTo = nil
    self.incomingFrom = nil
    self.dialBuffer = ""

    local topOffset = 30

    self.numberLabel = self:Add("DLabel")
    self.numberLabel:SetText("Your Number: ???")
    self.numberLabel:SetFont("ixSmallFont")
    self.numberLabel:SetContentAlignment(5)
    self.numberLabel:SetSize(380, 20)
    self.numberLabel:SetPos(10, topOffset)

    self.statusLabel = self:Add("DLabel")
    self.statusLabel:SetText("Status: Idle")
    self.statusLabel:SetFont("ixSmallFont")
    self.statusLabel:SetContentAlignment(5)
    self.statusLabel:SetSize(380, 20)
    self.statusLabel:SetPos(10, topOffset + 25)

    self.copyButton = self:Add("DButton")
    self.copyButton:SetText("Copy Number")
    self.copyButton:SetSize(120, 25)
    self.copyButton:SetPos(self:GetWide() * 0.5 - 60, topOffset + 55)
    self.copyButton.DoClick = function()
        if self.telephoneNumber then
            SetClipboardText(self.telephoneNumber)
            LocalPlayer():ChatPrint("Copied to clipboard: " .. self.telephoneNumber)
        else
            LocalPlayer():ChatPrint("No number assigned.")
        end
    end

    self.numberDisplay = self:Add("DLabel")
    self.numberDisplay:SetText("Number: ")
    self.numberDisplay:SetFont("ixSmallFont")
    self.numberDisplay:SetContentAlignment(4)
    self.numberDisplay:SetSize(250, 25)

    self.backspaceButton = self:Add("DButton")
    self.backspaceButton:SetText("←")
    self.backspaceButton:SetSize(30, 25)

    local totalWidth = 290
    local displayY = topOffset + 95
    local startX = self:GetWide() * 0.5 - totalWidth * 0.5
    self.backspaceButton:SetPos(startX, displayY)
    self.numberDisplay:SetPos(startX + 40, displayY)

    self.backspaceButton.DoClick = function()
        self.dialBuffer = self.dialBuffer:sub(1, -2)
        self.numberDisplay:SetText("Number: " .. self.dialBuffer)
    end

    local centerX, centerY = self:GetWide() * 0.5, self:GetTall() * 0.63
    local radius = 65
    for i = 1, 10 do
        local angle = math.rad((360 / 10) * (i - 1) - 90)
        local digit = (i % 10)

        local btn = self:Add("DButton")
        btn:SetSize(30, 30)
        btn:SetText(tostring(digit))
        btn:SetPos(centerX + math.cos(angle) * radius - 15, centerY + math.sin(angle) * radius - 15)

        btn.DoClick = function()
            if #self.dialBuffer < 8 then
                self.dialBuffer = self.dialBuffer .. tostring(digit)
                self.numberDisplay:SetText("Number: " .. self.dialBuffer)
            end
        end
    end

    -- Adjusted button placement
    local buttonOffsetY = centerY + radius + 15

    self.callButton = self:Add("DButton")
    self.callButton:SetText("Dial")
    self.callButton:SetSize(120, 30)
    self.callButton:SetPos(centerX - radius - self.callButton:GetWide() - 5, buttonOffsetY)
    -- Accept or dial
    self.callButton.DoClick = function()
        if self.incomingCall then
            net.Start("ixTelephone_Accept")
            net.SendToServer()
        else
            if #self.dialBuffer > 0 then
                net.Start("ixTelephone_Dial")
                    net.WriteString(self.telephoneNumber or "UNKNOWN")
                    net.WriteString(self.dialBuffer)
                net.SendToServer()
                self.statusLabel:SetText("Status: Calling " .. self.dialBuffer)
            end
        end
    end


    self.hangupButton = self:Add("DButton")
    self.hangupButton:SetText("Hang Up")
    self.hangupButton:SetSize(120, 30)
    self.hangupButton:SetPos(centerX + radius + 5, buttonOffsetY)
    -- Hang up / decline
    self.hangupButton.DoClick = function()
        net.Start("ixTelephone_End")
        net.SendToServer()

        self:OnCallEnded()
        self:Close()
    end
end

function PANEL:SetTelephoneNumber(number)
    self.telephoneNumber = number
    self.numberLabel:SetText("Your Number: " .. number)
end

function PANEL:SetIncomingCall(state)
    self.incomingCall = state
    if state then
        self.callButton:SetText("Accept")
        self.hangupButton:SetText("Decline")
        self.statusLabel:SetText("Status: Incoming Call")
    else
        self.callButton:SetText("Dial")
        self.hangupButton:SetText("Hang Up")
    end
end

function PANEL:SetIncomingFrom(number)
    self.incomingFrom = number
end

function PANEL:SetInCall(state)
    self.inCall = state
    if state then
        self.statusLabel:SetText("Status: Connected")
        self.callButton:SetEnabled(false)
    end
end

function PANEL:SetConnectedTo(number)
    self.connectedTo = number
end

function PANEL:OnCallEnded()
    self:SetInCall(false)
    self:SetIncomingCall(false)
    self.statusLabel:SetText("Status: Call Ended")
end

vgui.Register("ixTelephone", PANEL, "DFrame")
