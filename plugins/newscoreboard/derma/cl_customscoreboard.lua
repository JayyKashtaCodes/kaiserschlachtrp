local PLUGIN = PLUGIN
-- Custom Scoreboard
local PANEL = {}

function PANEL:Init()
    -- Remove existing scoreboard if it exists
    if (IsValid(ix.gui.scoreboard)) then
        ix.gui.scoreboard:Remove()
    end

    -- Set size and position for a standalone panel
    self:SetSize(ScrW() * 0.4, ScrH() * 0.8)
    self:Center()
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)

    self.factions = {}
    self.nextThink = 0

    -- Add faction panels
    for i = 1, #ix.faction.indices do
        local faction = ix.faction.indices[i]

        local panel = self:Add("ixScoreboardFaction")
        panel:SetFaction(faction)
        panel:Dock(TOP)

        self.factions[i] = panel
    end

    -- Register the scoreboard instance globally for cleanup
    ix.gui.scoreboard = self
end

function PANEL:Think()
    -- Update factions periodically
    if (CurTime() >= self.nextThink) then
        for i = 1, #self.factions do
            local factionPanel = self.factions[i]
            factionPanel:Update()

            -- Removed the counter-related logic
        end

        self.nextThink = CurTime() + 0.5
    end
end

-- Override the Paint function to draw a custom background
function PANEL:Paint(width, height)
    local cornerRadius = 16 -- Radius for rounded corners

    -- Draw only the rounded rectangle background
    draw.RoundedBox(cornerRadius, 0, 0, width, height, Color(0, 0, 0, 220)) -- Semi-transparent dark background
end

vgui.Register("ixCustomTabScoreboard", PANEL, "DFrame")
