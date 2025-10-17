local PLUGIN = PLUGIN
local activeVotingPanel

local PANEL = {}

function PANEL:Init()
    self:SetSize(400, 200)
    self:Center()
    self:SetTitle("Cast Your Vote")
    self:SetDeleteOnClose(true)
    self:MakePopup()

    self.optionButtons = {}

    self.voteLabel = self:Add("DLabel")
    self.voteLabel:SetPos(25, 40)
    self.voteLabel:SetSize(350, 25)
    self.voteLabel:SetFont("DermaDefaultBold")
    self.voteLabel:SetContentAlignment(5)
    self.voteLabel:SetText("")

    self.OnRemove = function()
        activeVotingPanel = nil
    end
end

function PANEL:SetVoteData(data)
    self.voteData = data
    self.voteLabel:SetText(data.title and data.title:Trim() or "Vote")

    for index, option in ipairs(data.options or {}) do
        if not isstring(option) or option:Trim() == "" then continue end

        local btn = self:Add("DButton")
        btn:SetPos(25, 70 + ((index - 1) * 35))
        btn:SetSize(350, 30)
        btn:SetText(option)
        btn.DoClick = function()
            if hook.Run("ixPreVoteCast", index, option, data) == false then return end

            PLUGIN:CastVote(index)
            self:Close()
        end

        table.insert(self.optionButtons, btn)
    end
end

vgui.Register("ixVotingBox", PANEL, "DFrame")

function PLUGIN:ixOpenVotingBox(voteData)
    if IsValid(activeVotingPanel) then
        activeVotingPanel:MakePopup()
        return
    end

    activeVotingPanel = vgui.Create("ixVotingBox")
    activeVotingPanel:SetVoteData(voteData)
end
