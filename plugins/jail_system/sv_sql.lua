local PLUGIN = PLUGIN

function PLUGIN:DatabaseConnected()
    -- Archived jail history table
    local query = mysql:Create("ix_jail_history")
        query:Create("id", "INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY")
        query:Create("steamID", "VARCHAR(32)")
        query:Create("characterName", "TEXT")
        query:Create("reason", "TEXT")
        query:Create("judge", "TEXT")
        query:Create("startTime", "BIGINT")
        query:Create("releaseTime", "BIGINT")
        query:Create("releaseReason", "TEXT")
        query:Create("sentenceLength", "INT")
    query:Execute()

    MsgC(Color(100, 255, 100), "[JailSystem] Jail history table registered\n")
end

-- Archive a completed jail sentence
function PLUGIN:AddJailHistory(
    steamID, name, reason, judge,
    startTime, releaseTime, releaseReason,
    sentenceLength
)
    local query = mysql:Insert("ix_jail_history")
        query:Insert("steamID", steamID)
        query:Insert("characterName", name)
        query:Insert("reason", reason)
        query:Insert("judge", judge)
        query:Insert("startTime", startTime)
        query:Insert("releaseTime", releaseTime)
        query:Insert("releaseReason", releaseReason)
        query:Insert("sentenceLength", sentenceLength or 0)
    query:Execute(nil, function(err)
        if err then
            MsgC(Color(255, 100, 100),
                "[JailSystem SQL Error] Failed to archive jail record: ",
                err, "\n"
            )
        end
    end)
end
