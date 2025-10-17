local PLUGIN = PLUGIN
local voteHistoryPanel

local PANEL = {}

function PANEL:Init()
    self:SetSize(500, 400)
    self:Center()
    self:SetTitle("Vote History")
    self:SetDeleteOnClose(true)
    self:MakePopup()

    self.scroll = self:Add("DScrollPanel")
    self.scroll:Dock(FILL)

    self.entries = {}

    self.OnRemove = function()
        voteHistoryPanel = nil
    end
end

function PANEL:PopulateFromHistory(data)
    if not istable(data) or #data == 0 then
        local label = self.scroll:Add("DLabel")
        label:SetText("No vote history available.")
        label:Dock(TOP)
        label:SetContentAlignment(5)
        label:SetFont("DermaDefaultBold")
        label:SetTall(30)
        return
    end

    for _, vote in ipairs(data) do
        local title     = vote.title or "Untitled"
        local results   = util.JSONToTable(vote.results or "{}") or {}
        local options   = util.JSONToTable(vote.options or "{}") or {}
        local timestamp = tonumber(vote.timestamp) or 0
        local total     = 0

        for _, count in pairs(results) do
            total = total + count
        end

        local entry = self.scroll:Add("DPanel")
        entry:Dock(TOP)
        entry:DockMargin(5, 5, 5, 5)
        entry:SetTall(80 + (#options * 20))

        entry.Paint = function(_, w, h)
            surface.SetDrawColor(40, 40, 40, 200)
            surface.DrawRect(0, 0, w, h)

            draw.SimpleText(" " .. title, "DermaDefaultBold", 10, 5, color_white)

            draw.SimpleText(
                " " .. os.date("%Y-%m-%d %H:%M:%S", timestamp),
                "DermaDefault", 10, 25, Color(180, 180, 180)
            )

            draw.SimpleText(
                " Total Votes: " .. total,
                "DermaDefault", 10, 45, Color(180, 180, 180)
            )

            for i, option in ipairs(options) do
                local count = results[option] or 0
                local percentage = total > 0 and (count / total * 100) or 0
                draw.SimpleText(
                    string.format("• %s — %d (%.1f%%)", option, count, percentage),
                    "DermaDefault", 15, 55 + (i * 18), color_white
                )
            end
        end

        table.insert(self.entries, entry)
    end
end

vgui.Register("ixVoteHistoryPanel", PANEL, "DFrame")

function PLUGIN:ixOpenVoteHistory()
    if IsValid(voteHistoryPanel) then
        voteHistoryPanel:MakePopup()
        return
    end

    voteHistoryPanel = vgui.Create("ixVoteHistoryPanel")

    -- Moved request here to prevent premature panel duplication
    net.Start("ixRequestVoteHistory")
    net.SendToServer()
end

-- Net hook only populates — does not create the panel
net.Receive("ixReceiveVoteHistory", function()
    local data = net.ReadTable()

    if IsValid(voteHistoryPanel) then
        voteHistoryPanel:PopulateFromHistory(data)
    end
end)
