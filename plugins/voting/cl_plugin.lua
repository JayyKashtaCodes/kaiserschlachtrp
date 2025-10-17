local PLUGIN = PLUGIN
PLUGIN.voteHistoryPanel = nil

net.Receive("ixVotingBoxMenu", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 200)
    frame:Center()
    frame:SetTitle("Voting Options")
    frame:MakePopup()

    local createVoteBtn = frame:Add("DButton")
    createVoteBtn:SetText("Create Vote")
    createVoteBtn:SetSize(260, 40)
    createVoteBtn:SetPos(20, 30)
    createVoteBtn.DoClick = function()
        PLUGIN:OpenVoteCreationMenu()
        frame:Close()
    end

    local castVoteBtn = frame:Add("DButton")
    castVoteBtn:SetText("Cast Vote")
    castVoteBtn:SetSize(260, 40)
    castVoteBtn:SetPos(20, 80)
    castVoteBtn.DoClick = function()
        if PLUGIN.currentVote then
            PLUGIN:OpenVotingPanel(PLUGIN.currentVote)
        else
            LocalPlayer():Notify("There is no active vote.")
        end
        frame:Close()
    end

    local historyBtn = frame:Add("DButton")
    historyBtn:SetText("View Vote History")
    historyBtn:SetSize(260, 40)
    historyBtn:SetPos(20, 130)
    historyBtn.DoClick = function()
        net.Start("ixOpenVoteHistory")
        net.SendToServer()
        frame:Close()
    end

    local char = LocalPlayer():GetCharacter()
    local canCreate = LocalPlayer():IsStaff() or (IsValid(char) and char:HasFlags("V"))

    createVoteBtn:SetVisible(PLUGIN.currentVote == nil and canCreate)
    castVoteBtn:SetVisible(PLUGIN.currentVote ~= nil)
end)

-- Opens vote history panel
net.Receive("ixOpenVoteHistory", function()
    PLUGIN:ixOpenVoteHistory()
end)

function PLUGIN:ixOpenVoteHistory()
    if IsValid(self.voteHistoryPanel) then
        self.voteHistoryPanel:MakePopup()
        return
    end

    self.voteHistoryPanel = vgui.Create("ixVoteHistoryPanel")

    net.Start("ixRequestVoteHistory")
    net.SendToServer()
end

-- Populate vote history data
net.Receive("ixReceiveVoteHistory", function()
    local data = net.ReadTable()

    if IsValid(PLUGIN.voteHistoryPanel) then
        PLUGIN.voteHistoryPanel:PopulateFromHistory(data)
    end
end)

-- Vote started broadcast
net.Receive("ixVoteBroadcast", function()
    local voteData = net.ReadTable()
    local duration = net.ReadUInt(32)

    PLUGIN.currentVote = voteData
    PLUGIN:VoteStarted(voteData, duration)
end)

-- Vote ended broadcast
net.Receive("ixVoteEnd", function()
    local voteData = net.ReadTable()

    PLUGIN:VoteEnded(voteData)
    PLUGIN.currentVote = nil
end)

function PLUGIN:VoteStarted(voteData, duration)
    chat.AddText(Color(100, 200, 250), "[Vote Started] ", Color(255, 255, 255), voteData.title)
    --self:OpenVotingPanel(voteData)
end

function PLUGIN:VoteEnded(voteData)
    chat.AddText(Color(255, 150, 150), "[Vote Ended] ", Color(255, 255, 255), voteData.title)

    if self.ixOpenVoteResults then
        if voteData.creator == LocalPlayer():SteamID() then
            self:ixOpenVoteResults(voteData)
        end
    end
end


function PLUGIN:CastVote(index)
    if not self.currentVote or not self.currentVote.id then return end

    net.Start("ixVoteCast")
        net.WriteString(self.currentVote.id)
        net.WriteUInt(index, 8)
    net.SendToServer()
end

function PLUGIN:OpenVoteCreationMenu()
    local char = LocalPlayer():GetCharacter()
    if not LocalPlayer():IsStaff() and (not IsValid(char) or not char:HasFlags("V")) then
        return LocalPlayer():Notify("You do not have permission to start votes.")
    end

    self:ixOpenVoteCreationMenu()
end

function PLUGIN:OpenVotingPanel(voteData)
    if not voteData or not voteData.id then
        return LocalPlayer():Notify("There is no active vote to cast.")
    end

    self:ixOpenVotingBox(voteData)
end
