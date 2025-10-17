local PLUGIN = PLUGIN

PLUGIN.isDatabaseReady = false

-- Initialize unified SQL table when database becomes available
function PLUGIN:DatabaseConnected()
    local voteTable = mysql:Create("ix_votes")
    voteTable:Create("id",        "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
    voteTable:Create("title",     "TEXT NOT NULL")
    voteTable:Create("options",   "TEXT NOT NULL")  -- JSON array of option strings
    voteTable:Create("results",   "TEXT NOT NULL")  -- JSON object: { ["Option A"] = 4 }
    voteTable:Create("creator",   "VARCHAR(32) NOT NULL")
    voteTable:Create("timestamp", "INT(11) NOT NULL")
    voteTable:PrimaryKey("id")
    voteTable:Execute()

    MsgC(Color(100, 255, 100), "[Voting] ix_votes table initialized\n")
    self.isDatabaseReady = true
end

-- Save vote metadata with empty results
function PLUGIN:SaveVoteMeta(vote, callback)
    local insertQuery = mysql:Insert("ix_votes")
    insertQuery:Insert("title",     vote.title or "Untitled")
    insertQuery:Insert("options",   util.TableToJSON(vote.options or {}))
    insertQuery:Insert("results",   util.TableToJSON({}))  -- initialize as empty map
    insertQuery:Insert("creator",   vote.creator or "unknown")
    insertQuery:Insert("timestamp", vote.timestamp or os.time())

    insertQuery:Callback(function(_, _, lastInsertID)
        if callback then
            callback(lastInsertID)
        end
    end)

    insertQuery:Execute()
end

-- Cast a vote: selectedOption must match one of the original strings
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
