local PLUGIN = PLUGIN

util.AddNetworkString("ixVoteStart")
util.AddNetworkString("ixVoteBroadcast")
util.AddNetworkString("ixVoteCast")
util.AddNetworkString("ixVoteEnd")
util.AddNetworkString("ixVotingBoxMenu")
util.AddNetworkString("ixVoteCreate")
util.AddNetworkString("ixOpenVoteHistory")
util.AddNetworkString("ixRequestVoteHistory")
util.AddNetworkString("ixReceiveVoteHistory")

PLUGIN.currentVote  = nil
PLUGIN.votedKeys    = {}

function PLUGIN:GetVoteKey(ply)
    return ply:SteamID()
end

net.Receive("ixOpenVoteHistory", function(_, ply)
    net.Start("ixOpenVoteHistory")
    net.Send(ply)
end)

-- Handles UI trigger via entity or command
net.Receive("ixVoteCreate", function(_, ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()
    local hasPermission =  char:HasFlags("V")
    if not hasPermission then
        return ply:Notify("You do not have permission to create votes.")
    end

    net.Start("ixVotingBoxMenu")
    net.Send(ply)
end)

-- Starts vote and broadcasts to all players
net.Receive("ixVoteStart", function(_, ply)
    local char = ply:GetCharacter()
    local hasPermission =  char:HasFlags("V")
    if not hasPermission then
        return ply:Notify("You do not have permission to start votes.")
    end

    local title   = net.ReadString()
    local count   = net.ReadUInt(8)
    local options = {}

    for i = 1, count do
        options[i] = net.ReadString()
    end

    local durationMinutes = math.Clamp(net.ReadUInt(16), 1, 720)
    local useCharID       = net.ReadBool()

    PLUGIN.voteKeyMode = useCharID and "charid" or "steamid"
    local durationSeconds = durationMinutes * 60

    if PLUGIN.currentVote then
        return ply:Notify("A vote is already in progress.")
    end

    local voteID = os.time() .. "_" .. ply:SteamID()
    PLUGIN.currentVote = {
        id        = voteID,
        title     = title,
        options   = options,
        votes     = {},                 -- results map: [option string] = count
        timestamp = os.time(),
        creator   = ply:SteamID()
    }

    for _, option in ipairs(options) do
        PLUGIN.currentVote.votes[option] = 0
    end

    PLUGIN.votedKeys = {}              -- voterKey → true

    net.Start("ixVoteBroadcast")
        net.WriteTable(PLUGIN.currentVote)
        net.WriteUInt(durationSeconds, 32)
    net.Broadcast()

    timer.Create("ixVoteTimer_" .. voteID, durationSeconds, 1, function()
        if PLUGIN.currentVote and PLUGIN.EndVote then
            PLUGIN:EndVote()
        end
    end)
end)

-- Casts individual vote
net.Receive("ixVoteCast", function(_, ply)
    if not IsValid(ply) or not PLUGIN.currentVote then return end

    local voteID = net.ReadString()
    local index  = net.ReadUInt(8)

    if voteID ~= PLUGIN.currentVote.id then return end

    local key    = PLUGIN:GetVoteKey(ply)
    if not key or PLUGIN.votedKeys[key] then
        return ply:Notify("You've already voted in this poll.")
    end

    local option = PLUGIN.currentVote.options[index]
    if not option then return end

    -- Increment mapped result
    PLUGIN.currentVote.votes[option] = (PLUGIN.currentVote.votes[option] or 0) + 1
    PLUGIN.votedKeys[key] = true

    ply:Notify("Your vote has been cast.")
end)

-- Ends vote and persists results to SQL anonymously
function PLUGIN:EndVote()
    if not self.currentVote or not self.currentVote.id then return end

    local voteID   = self.currentVote.id
    local voteData = table.Copy(self.currentVote)

    net.Start("ixVoteEnd")
        net.WriteTable(voteData)
    net.Broadcast()

    if self.SaveVoteMeta then
        self:SaveVoteMeta(voteData, function(lastID)
            if lastID and voteData.votes then
                self:SaveVoteResult(lastID, voteData.votes)
            end
        end)
    end

    self.currentVote = nil
    self.votedKeys   = {}

    timer.Remove("ixVoteTimer_" .. voteID)
end

-- Save full results table to SQL
function PLUGIN:SaveVoteResult(voteID, resultMap)
    if not resultMap or type(resultMap) ~= "table" then
        MsgC(Color(255, 100, 100), "[Voting] Invalid result data\n")
        return
    end

    local updateQuery = mysql:Update("ix_votes")
    updateQuery:Update("results", util.TableToJSON(resultMap))
    updateQuery:Where("id", voteID)
    updateQuery:Execute()

    MsgC(Color(100, 255, 200), "[Voting] Vote results recorded for ID: " .. voteID .. "\n")
end

-- Return historical votes to requesting client
net.Receive("ixRequestVoteHistory", function(_, ply)
    local query = mysql:Select("ix_votes")
    query:Callback(function(data)
        net.Start("ixReceiveVoteHistory")
            net.WriteTable(data or {})
        net.Send(ply)
    end)
    query:Execute()
end)

hook.Add("ShutDown", "FinalizeVoteOnShutdown", function()
    if ix.vote and ix.vote.active then
        local voteData = ix.vote.active

        -- Tally results
        local results = {}
        for _, v in ipairs(voteData.votes or {}) do
            results[v.option] = (results[v.option] or 0) + 1
        end

        -- Save to history table or SQL
        ix.vote.SaveResults({
            question = voteData.question,
            options = voteData.options,
            results = results,
            voters = voteData.voters,
            ended = os.time(),
            endedBy = "server_shutdown"
        })

        ix.vote.active = nil
    end
end)
