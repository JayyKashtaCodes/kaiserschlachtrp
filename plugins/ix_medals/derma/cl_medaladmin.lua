local PANEL = {}

function PANEL:Init()
    self:SetSize(400, 300)
    self:Center()
    self:SetTitle("Medal Administration")
    self:MakePopup()

    self.playerSelect = self:Add("DComboBox")
    self.playerSelect:SetPos(10, 30)
    self.playerSelect:SetSize(180, 30)
    self.playerSelect:SetValue("Select Player")

    self.medalSelect = self:Add("DComboBox")
    self.medalSelect:SetPos(200, 30)
    self.medalSelect:SetSize(180, 30)
    self.medalSelect:SetValue("Loading Medals...")

    -- Patch to force dropdown height limit
    function self.medalSelect:OpenMenu()
        if IsValid(self.Menu) then self.Menu:Remove() end
        self.Menu = DermaMenu()

        for k, v in ipairs(self.Choices) do
            self.Menu:AddOption(v, function()
                self:ChooseOption(v, k)
            end)
        end

        self.Menu:SetMaxHeight(250) -- Scrolls if too many items
        self.Menu:Open()
    end

    function self.playerSelect:OpenMenu()
        if IsValid(self.Menu) then self.Menu:Remove() end
        self.Menu = DermaMenu()

        for k, v in ipairs(self.Choices) do
            self.Menu:AddOption(v, function()
                self:ChooseOption(v, k)
            end)
        end

        self.Menu:SetMaxHeight(250) -- Match medal dropdown scroll limit
        self.Menu:Open()
    end

    -- Store player references
    self.playersByName = {}
    local sortedPlayers = {}

    for _, ply in ipairs(player.GetAll()) do
        table.insert(sortedPlayers, ply)
    end

    table.sort(sortedPlayers, function(a, b)
        return string.lower(a:Nick()) < string.lower(b:Nick())
    end)

    for _, ply in ipairs(sortedPlayers) do
        local name = ply:Nick()
        self.playerSelect:AddChoice(name)
        self.playersByName[name] = ply
    end


    -- Request medals
    net.Start("RequestAllMedals")
    net.SendToServer()

    net.Receive("SendAllMedals", function()
        local medals = net.ReadTable()

        self.medalSelect:Clear()
        self.medalSelect:SetValue("Select Medal")

        -- Build a sortable list of medal entries
        local sortedMedals = {}
        for medalID, data in pairs(medals) do
            local displayName = data.name or medalID
            table.insert(sortedMedals, {name = displayName, id = medalID})
        end

        -- Sort alphabetically by display name
        table.sort(sortedMedals, function(a, b)
            return string.lower(a.name) < string.lower(b.name)
        end)

        -- Populate the combobox in sorted order
        for _, medal in ipairs(sortedMedals) do
            self.medalSelect:AddChoice(medal.name, medal.id)
        end

    end)

    -- Give Medal
    self.giveButton = self:Add("DButton")
    self.giveButton:SetPos(10, 70)
    self.giveButton:SetSize(180, 30)
    self.giveButton:SetText("Give Medal")
    self.giveButton.DoClick = function()
        local selectedName = self.playerSelect:GetSelected()
        local _, selectedMedalID = self.medalSelect:GetSelected()
        local target = self.playersByName[selectedName]

        if IsValid(target) and selectedMedalID then
            net.Start("GiveMedal")
            net.WriteString(target:Nick())
            net.WriteString(selectedMedalID)
            net.SendToServer()
        end
    end

    -- Remove Medal
    self.removeButton = self:Add("DButton")
    self.removeButton:SetPos(200, 70)
    self.removeButton:SetSize(180, 30)
    self.removeButton:SetText("Remove Medal")
    self.removeButton.DoClick = function()
        local selectedName = self.playerSelect:GetSelected()
        local _, selectedMedalID = self.medalSelect:GetSelected()
        local target = self.playersByName[selectedName]

        if IsValid(target) and selectedMedalID then
            net.Start("RemoveMedal")
            net.WriteString(target:Nick())
            net.WriteString(selectedMedalID)
            net.SendToServer()
        end
    end
end

net.Receive("OpenMedalAdminMenu", function()
    vgui.Create("MedalAdminMenu")
end)

vgui.Register("MedalAdminMenu", PANEL, "DFrame")
