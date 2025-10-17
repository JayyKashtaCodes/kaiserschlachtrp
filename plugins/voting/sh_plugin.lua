-- sh_plugin.lua
local PLUGIN = PLUGIN or {}

PLUGIN.name        = "Voting System"
PLUGIN.author      = "Dzhey Kashta"
PLUGIN.description = "Allows in-game votes with SQL logging."

PLUGIN.voteKeyMode = "steamid"

PLUGIN.DefaultVote = {
    id        = nil,
    title     = "",
    options   = {},
    votes     = {},
    timestamp = 0,
    creator   = nil
}

-- Admin command to manually end vote
ix.command.Add("EndVote", {
    name = "End Vote",
    description = "Ends the currently active vote.",
    adminOnly = false,
    OnRun = function(self, client)
        if not IsValid(client) then return end

        local char = client:GetCharacter()
        local hasPermission =  char:HasFlags("V")
        if not hasPermission then
            return client:Notify("You do not have permission to end votes.")
        end

        if not PLUGIN.currentVote then
            return client:Notify("There is no vote currently in progress to end.")
        end

        PLUGIN:EndVote()
        client:Notify("You have successfully ended the vote.")
    end
})

ix.command.Add("ViewVoteHistory", {
    description = "View historical voting results.",
    adminOnly = false,
    OnRun = function(_, ply)
        net.Start("ixOpenVoteHistory")
        net.Send(ply)
    end
})

-- Include modular logic
ix.util.Include("cl_plugin.lua", "client")
ix.util.Include("sv_plugin.lua", "server")
ix.util.Include("sv_sql.lua",    "server")
