local PLUGIN = PLUGIN
local PANEL = {}

function PANEL:Init()
    self:SetSize(500, 450)
    self:Center()
    self:SetTitle("Select Displayed Medals")
    self:MakePopup()

    self.medalList = self:Add("DScrollPanel")
    self.medalList:SetPos(10, 30)
    self.medalList:SetSize(480, 360)

    self.selectedMedals = {}

    net.Start("RequestOwnedMedals")
    net.SendToServer()

    net.Receive("SendOwnedMedals", function()
        local ownedMedalIDs = net.ReadTable()
        local panel = self

        local char = LocalPlayer():GetCharacter()
        if char then
            self.selectedMedals = char:GetData("displayedMedals", {})
        end

        self.medalList:Clear()

        for _, medalID in ipairs(ownedMedalIDs) do
            local data = PLUGIN.medals and PLUGIN.medals.list and PLUGIN.medals.list[medalID]

            if not data then
                print("[MedalUI DEBUG] Owned medal ID '" .. medalID .. "' has no corresponding data in PLUGIN.medals.list. Skipping.")
                continue
            end

            local displayName = data.name or medalID
            local iconPath = data.icon or "icon16/award_star_gold_1.png"

            local iconW = data.width or 32
            local iconH = data.height or 32
            local rowHeight = math.max(iconH + 8, 40)

            local row = panel.medalList:Add("DPanel")
            row:SetTall(rowHeight)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 4)
            row:SetPaintBackground(false)

            local inner = row:Add("DPanel")
            inner:Dock(FILL)
            inner:SetPaintBackground(false)

            local icon = inner:Add("DImage")
            icon:SetSize(iconW, iconH)
            icon:Dock(LEFT)
            icon:DockMargin(4, 4, 12, 4)
            icon:SetImage(iconPath)

            local checkBox = inner:Add("DCheckBoxLabel")
            checkBox:SetText(displayName)
            checkBox:Dock(FILL)
            checkBox:DockMargin(0, 0, 4, 0)
            checkBox:SetContentAlignment(4)

            if table.HasValue(self.selectedMedals, medalID) then
                checkBox:SetChecked(true)
            end

            checkBox.OnChange = function(_, checked)
                if checked then
                    if #panel.selectedMedals < 3 and not table.HasValue(panel.selectedMedals, medalID) then
                        table.insert(panel.selectedMedals, medalID)
                    else
                        checkBox:SetChecked(false)
                        if #panel.selectedMedals >= 3 then
                            LocalPlayer():Notify("You can only display up to 3 medals.")
                        end
                    end
                else
                    for i, id in ipairs(panel.selectedMedals) do
                        if id == medalID then
                            table.remove(panel.selectedMedals, i)
                            break
                        end
                    end
                end
            end
        end
    end)

    self.saveButton = self:Add("DButton")
    self.saveButton:Dock(BOTTOM)
    self.saveButton:SetTall(30)
    self.saveButton:DockMargin(10, 10, 10, 10)
    self.saveButton:SetText("Save Display Selection")

    self.saveButton.DoClick = function()
        net.Start("SelectMedalDisplay")
        net.WriteTable(self.selectedMedals)
        net.SendToServer()
        self:Close()
    end
end

net.Receive("OpenMedalSelectionMenu", function()
    vgui.Create("MedalSelectionMenu")
end)

vgui.Register("MedalSelectionMenu", PANEL, "DFrame")