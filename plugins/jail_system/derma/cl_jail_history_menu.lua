local jailHistoryPanel

local PANEL = {}

function PANEL:Init()
    self:SetSize(600, 500)
    self:Center()
    self:SetTitle("Jail History")
    self:SetDeleteOnClose(true)
    self:MakePopup()

    -- Search bar
    self.searchBar = self:Add("DTextEntry")
    self.searchBar:Dock(TOP)
    self.searchBar:SetPlaceholderText("Search by character name...")

    self.scroll = self:Add("DScrollPanel")
    self.scroll:Dock(FILL)

    self.categories = {}

    self.OnRemove = function()
        jailHistoryPanel = nil
    end

    -- Filter when typing
    self.searchBar.OnChange = function(s)
        local query = string.Trim(s:GetValue()):lower()

        for name, cat in pairs(self.categories) do
            if query == "" or string.find(name:lower(), query, 1, true) then
                cat:SetVisible(true)
                cat:Dock(TOP)
            else
                cat:SetVisible(false)
                cat:Dock(NODOCK)
            end
        end
    end
end

function PANEL:PopulateFromHistory(data)
    if not istable(data) or #data == 0 then
        local label = self.scroll:Add("DLabel")
        label:SetText("No jail history records found.")
        label:Dock(TOP)
        label:SetContentAlignment(5)
        label:SetFont("DermaDefaultBold")
        label:SetTall(30)
        return
    end

    -- Group by character name
    local grouped = {}
    for _, record in ipairs(data) do
        local name = record.characterName or "Unknown"
        grouped[name] = grouped[name] or {}
        table.insert(grouped[name], record)
    end

    for name, records in pairs(grouped) do
        local cat = self.scroll:Add("DCollapsibleCategory")
        cat:SetLabel(name)
        cat:Dock(TOP)
        cat:DockMargin(5, 5, 5, 5)
        cat:SetExpanded(false)

        local list = vgui.Create("DPanel", cat)
        list:Dock(FILL)
        list.Paint = nil
        cat:SetContents(list)

        for _, record in ipairs(records) do
            local entry = list:Add("DPanel")
            entry:Dock(TOP)
            entry:DockMargin(0, 0, 0, 5)
            entry:SetTall(90)
            entry.Paint = function(_, w, h)
                surface.SetDrawColor(40, 40, 40, 200)
                surface.DrawRect(0, 0, w, h)

                local sentenceMins = math.floor((tonumber(record.sentenceLength) or 0) / 60)
                local servedSecs = (tonumber(record.releaseTime) or 0) - (tonumber(record.startTime) or 0)
                local servedMins = math.floor(servedSecs / 60)

                draw.SimpleText("Reason: " .. (record.reason or ""), "DermaDefault", 10, 5, color_white)
                draw.SimpleText("Judge: " .. (record.judge or ""), "DermaDefault", 10, 20, color_white)
                draw.SimpleText("From: " .. os.date("%Y-%m-%d %H:%M", tonumber(record.startTime) or 0), "DermaDefault", 250, 5, color_white)
                draw.SimpleText("To: " .. os.date("%Y-%m-%d %H:%M", tonumber(record.releaseTime) or 0), "DermaDefault", 250, 20, color_white)

                draw.SimpleText(
                    string.format("Sentence: %dm, Served: %dm", sentenceMins, servedMins),
                    "DermaDefault",
                    10, 40,
                    color_white
                )
                draw.SimpleText("Release Reason: " .. (record.releaseReason or "N/A"),
                "DermaDefault", 10, 55, color_white)
            end
        end

        self.categories[name] = cat
    end
end

vgui.Register("ixJailHistoryPanel", PANEL, "DFrame")

function PLUGIN:OpenJailHistory()
    if IsValid(jailHistoryPanel) then
        jailHistoryPanel:MakePopup()
        return
    end

    jailHistoryPanel = vgui.Create("ixJailHistoryPanel")

    --print("[Client] Sending jail history request to server")
    net.Start("RequestJailHistory")
    net.SendToServer()
end

net.Receive("ReceiveJailHistory", function()
    local data = net.ReadTable()

    if IsValid(jailHistoryPanel) then
        jailHistoryPanel:PopulateFromHistory(data)
    end
end)
