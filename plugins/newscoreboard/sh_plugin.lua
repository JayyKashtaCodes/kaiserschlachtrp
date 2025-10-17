local PLUGIN = PLUGIN or {}

PLUGIN.name = "Tab Scoreboard"
PLUGIN.description = "Tab Scoreboard."
PLUGIN.author = "Dzhey Kashta"

hook.Add("ScoreboardShow", "ixCustomTabScoreboardShow", function()
    if (!IsValid(ix.gui.scoreboard)) then
        local scoreboard = vgui.Create("ixCustomTabScoreboard")
        scoreboard:Show()
    end
end)

hook.Add("ScoreboardHide", "ixCustomTabScoreboardHide", function()
    if (IsValid(ix.gui.scoreboard)) then
        ix.gui.scoreboard:Remove()
    end
end)

hook.Add("CreateMenuButtons", "ixScoreboard", function(tabs)
    return
end)