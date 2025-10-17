local PLUGIN = PLUGIN
local voteResultPanel

local PANEL = {}

function PANEL:Init()
    self:SetSize(400, 250)
    self:Center()
    self:SetTitle("Vote Results")
    self:SetDeleteOnClose(true)
    self:MakePopup()

    self.resultLabel = self:Add("DLabel")
    self.resultLabel:SetPos(25, 40)
    self.resultLabel:SetSize(350, 25)
    self.resultLabel:SetFont("DermaDefaultBold")
    self.resultLabel:SetContentAlignment(5)
    self.resultLabel:SetText("")

    self.bars = {}

    self.OnRemove = function()
        voteResultPanel = nil
    end
end

function PANEL:SetResults(voteData)
    local title    = voteData.title or "Results"
    local options  = voteData.options or {}
    local results  = voteData.results or voteData.votes or {}  -- ← supports both keys
    local totalVotes = 0

    for _, count in pairs(results) do
        totalVotes = totalVotes + count
    end

    self.resultLabel:SetText(title)

    for index, option in ipairs(options) do
        if not isstring(option) or option:Trim() == "" then continue end

        local count = results[option] or 0
        local percentage = totalVotes > 0 and (count / totalVotes * 100) or 0

        local bar = self:Add("DPanel")
        bar:SetPos(25, 70 + ((index - 1) * 35))
        bar:SetSize(350, 25)

        bar.Paint = function(_, w, h)
            surface.SetDrawColor(50, 150, 250, 255)
            surface.DrawRect(0, 0, w * (percentage / 100), h)

            draw.SimpleText(
                string.format("%s - %d vote(s) (%.1f%%)", option, count, percentage),
                "DermaDefault", 5, 4, color_white, TEXT_ALIGN_LEFT
            )
        end

        table.insert(self.bars, bar)
    end
end

vgui.Register("ixVoteResultPanel", PANEL, "DFrame")

function PLUGIN:ixOpenVoteResults(voteData)
    if IsValid(voteResultPanel) then
        voteResultPanel:SetResults(voteData)
        voteResultPanel:MakePopup()
        return
    end

    voteResultPanel = vgui.Create("ixVoteResultPanel")
    voteResultPanel:SetResults(voteData)
end
