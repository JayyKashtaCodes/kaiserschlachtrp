local PLUGIN = PLUGIN

local rowPaintFunctions = {
    function(width, height)
    end,

    function(width, height)
        surface.SetDrawColor(30, 30, 30, 25)
        surface.DrawRect(0, 0, width, height)
    end
}

local PANEL = {}
local BODYGROUPS_EMPTY = "000000000"

AccessorFunc(PANEL, "model", "Model", FORCE_STRING)
AccessorFunc(PANEL, "bHidden", "Hidden", FORCE_BOOL)

function PANEL:Init()
    self:SetSize(64, 64)
    self.bodygroups = BODYGROUPS_EMPTY
end

function PANEL:SetModel(model, skin, bodygroups)
    model = model:gsub("\\", "/")

    if (isstring(bodygroups)) then
        if (bodygroups:len() == 9) then
            for i = 1, bodygroups:len() do
                self:SetBodygroup(i, tonumber(bodygroups[i]) or 0)
            end
        else
            self.bodygroups = BODYGROUPS_EMPTY
        end
    end

    self.model = model
    self.skin = skin
    self.path = "materials/spawnicons/" ..
        model:sub(1, #model - 4) ..
        ((isnumber(skin) and skin > 0) and ("_skin" .. tostring(skin)) or "") ..
        (self.bodygroups != BODYGROUPS_EMPTY and ("_" .. self.bodygroups) or "") ..
        ".png"

    local material = Material(self.path, "smooth")

    if (material:IsError()) then
        self.id = "ixScoreboardIcon" .. self.path
        self.renderer = self:Add("ModelImage")
        self.renderer:SetVisible(false)
        self.renderer:SetModel(model, skin, self.bodygroups)
        self.renderer:RebuildSpawnIcon()

        hook.Add("SpawniconGenerated", self.id, function(lastModel, filePath, modelsLeft)
            filePath = filePath:gsub("\\", "/"):lower()

            if (filePath == self.path) then
                hook.Remove("SpawniconGenerated", self.id)

                self.material = Material(filePath, "smooth")
                self.renderer:Remove()
            end
        end)
    else
        self.material = material
    end
end

function PANEL:SetBodygroup(k, v)
    if (k < 0 or k > 8 or v < 0 or v > 9) then
        return
    end

    self.bodygroups = self.bodygroups:SetChar(k + 1, v)
end

function PANEL:GetModel()
    return self.model or "models/error.mdl"
end

function PANEL:GetSkin()
    return self.skin or 1
end

function PANEL:DoClick()
end

function PANEL:DoRightClick()
end

function PANEL:OnMouseReleased(key)
    if (key == MOUSE_LEFT) then
        self:DoClick()
    elseif (key == MOUSE_RIGHT) then
        self:DoRightClick()
    end
end

function PANEL:Paint(width, height)
    if (!self.material) then
        return
    end

    surface.SetMaterial(self.material)
    surface.SetDrawColor(self.bHidden and color_black or color_white)
    surface.DrawTexturedRect(0, 0, width, height)
end

function PANEL:Remove()
    if (self.id) then
        hook.Remove("SpawniconGenerated", self.id)
    end

    if (IsValid(self.player) and self.player.ixScoreboardSlot == self) then
        self.player.ixScoreboardSlot = nil
    end
    BaseClass.Remove(self)
end

vgui.Register("ixScoreboardIcon", PANEL, "Panel")

PANEL = {}

AccessorFunc(PANEL, "paintFunction", "BackgroundPaintFunction")

function PANEL:Init()
    self:SetTall(64)

    self.icon = self:Add("ixScoreboardIcon")
    self.icon:Dock(LEFT)
    self.icon:DockMargin(8, 5, 8, 5)
    self.icon.DoRightClick = function()
        local client = self.player

        if (!IsValid(client)) then
            return
        end

        local menu = DermaMenu()

        menu:AddOption(L("viewProfile"), function()
            client:ShowProfile()
        end)

        menu:AddOption(L("copySteamID"), function()
            SetClipboardText(client:IsBot() and client:EntIndex() or client:SteamID())
        end)

        hook.Run("PopulateScoreboardPlayerMenu", client, menu)
        menu:Open()
    end

    self.icon:SetHelixTooltip(function(tooltip)
        local client = self.player

        if (IsValid(self) and IsValid(client)) then
            ix.hud.PopulatePlayerTooltip(tooltip, client)
        end
    end)

    self.name = self:Add("DLabel")
    self.name:DockMargin(4, 4, 0, 0)
    self.name:Dock(TOP)
    self.name:SetTextColor(color_white)
    self.name:SetFont("ixGenericFont")

    self.description = self:Add("DLabel")
    self.description:DockMargin(5, 0, 0, 0)
    self.description:Dock(TOP)
    self.description:SetTextColor(color_white)
    self.description:SetFont("ixSmallFont")

    self.paintFunction = rowPaintFunctions[1]
    self.nextThink = CurTime() + 1
end

function PANEL:Update()
    local client = self.player
    local model = client:GetModel()
    local skin = client:GetSkin()
    local name = client:GetName()
    local description = hook.Run("GetCharacterDescription", client) or
        (client:GetCharacter() and client:GetCharacter():GetDescription()) or ""

    local bRecognize = false
    local localCharacter = LocalPlayer():GetCharacter()
    local character = IsValid(self.player) and self.player:GetCharacter()

    if (localCharacter and character) then
        bRecognize = hook.Run("IsCharacterRecognized", localCharacter, character:GetID())
            or hook.Run("IsPlayerRecognized", self.player)
    end

    self.icon:SetHidden(!bRecognize)
    self.name:SetVisible(bRecognize)
    self.description:SetVisible(bRecognize)

    self:SetZPos(bRecognize and 1 or 2)

    for _, v in pairs(client:GetBodyGroups()) do
        self.icon:SetBodygroup(v.id, client:GetBodygroup(v.id))
    end

    if (self.icon:GetModel() != model or self.icon:GetSkin() != skin) then
        self.icon:SetModel(model, skin)
        self.icon:SetTooltip(nil)
    end

    local displayName = bRecognize and name or "Unknown"
    local displayDescription = bRecognize and description or ""

    if (self.name:GetText() != displayName) then
        self.name:SetText(displayName)
        self.name:SizeToContents()
    end

    if (self.description:GetText() != displayDescription) then
        self.description:SetText(displayDescription)
        self.description:SizeToContents()
    end
end

function PANEL:Think()
    if (CurTime() >= self.nextThink) then
        local client = self.player

        if (!IsValid(client) or !client:GetCharacter() or self.character != client:GetCharacter() or self.team != client:Team()) then
            self:Remove()
            self:GetParent():SizeToContents()
        end

        self.nextThink = CurTime() + 1
    end
end

function PANEL:SetPlayer(client)
    self.player = client
    self.team = client:Team()
    self.character = client:GetCharacter()

    self:Update()
end

function PANEL:Paint(width, height)
    if self.paintFunction then
        self.paintFunction(width, height)
    end

    local outlineColor = Color(255, 255, 255, 100)
    local thickness = 3

    for i = 0, thickness - 1 do
        surface.SetDrawColor(outlineColor)
        surface.DrawOutlinedRect(i, i, width - (i * 2), height - (i * 2))
    end
end

vgui.Register("ixScoreboardRow", PANEL, "EditablePanel")

PANEL = {}

AccessorFunc(PANEL, "faction", "Faction")

function PANEL:Init()
    self:DockMargin(0, 0, 0, 16)
    self:SetTall(32)

    self.nextThink = 0
    self.playerRows = {}
end

function PANEL:AddPlayer(client, index)
    if (!IsValid(client) or !client:GetCharacter() or hook.Run("ShouldShowPlayerOnScoreboard", client) == false) then
        return false
    end

    if (IsValid(client.ixScoreboardSlot) and client.ixScoreboardSlot:GetParent() == self) then
        client.ixScoreboardSlot:Update()
        return true
    end

    if (IsValid(client.ixScoreboardSlot)) then
        client.ixScoreboardSlot:Remove()
    end

    local id = index % 2 == 0 and 1 or 2
    local panel = self:Add("ixScoreboardRow")
    panel:SetPlayer(client)
    panel:Dock(TOP)
    panel:DockMargin(8, 16, 8, 8)
    panel:SetZPos(2)
    panel:SetBackgroundPaintFunction(rowPaintFunctions[id])

    self:SizeToContents()
    client.ixScoreboardSlot = panel
    self.playerRows[client] = panel

    return true
end

function PANEL:SetFaction(faction)
    self.faction = faction

    self.titleText = L(faction.name)
    self.titleColor = faction.color

    local factionLogos = {
        [FACTION_STAFF] = "materials/factions/icons/staff.png",
        [FACTION_CITIZEN] = "materials/factions/icons/civ.png",
        [FACTION_INNERN] = "materials/factions/icons/innern.png",
        [FACTION_ARMY] = "materials/factions/icons/army.png",
        [FACTION_HOUSE] = "materials/factions/icons/house.png",
        [FACTION_GOV] = "materials/factions/icons/gov.png",
        [FACTION_MAFIA] = "materials/factions/icons/ring.png",
    }

    self.logoPath = factionLogos[faction.index]
end

function PANEL:Update()
    local faction = self.faction
    local currentFactionPlayers = {}

    for _, v in ipairs(team.GetPlayers(faction.index)) do
        currentFactionPlayers[v] = true
    end

    local playersToRemove = {}
    for client, rowPanel in pairs(self.playerRows) do
        if (!currentFactionPlayers[client] or !IsValid(client) or client:Team() != faction.index) then
            table.insert(playersToRemove, client)
        end
    end

    for _, client in ipairs(playersToRemove) do
        local rowPanel = self.playerRows[client]
        if (IsValid(rowPanel)) then
            rowPanel:Remove()
        end
        self.playerRows[client] = nil
    end

    local bHasPlayers = false
    local playerIndex = 0
    for _, client in ipairs(team.GetPlayers(faction.index)) do
        playerIndex = playerIndex + 1
        if (self:AddPlayer(client, playerIndex)) then
            bHasPlayers = true
        end
    end

    self:SetVisible(bHasPlayers)
    self:SizeToContents()
end

function PANEL:Paint(width, height)
    if self.titleText then
        local headerHeight = 40
        local gradientMaterial = Material("vgui/gradient-d")
        surface.SetDrawColor(self.titleColor or Color(50, 50, 50))
        surface.SetMaterial(gradientMaterial)
        surface.DrawTexturedRect(0, 0, width, headerHeight)

        local cornerRadius = 8
        draw.RoundedBox(cornerRadius, 0, 0, width, headerHeight, self.titleColor or Color(50, 50, 50, 255))

        local logoMaterial
        if self.logoPath then
            logoMaterial = Material(self.logoPath, "smooth")
            if logoMaterial:IsError() then
                logoMaterial = Material("error")
            end
        else
            logoMaterial = Material("error")
        end

        surface.SetMaterial(logoMaterial)
        surface.SetDrawColor(255, 255, 255, 255)
        local logoSize = headerHeight - 8
        surface.DrawTexturedRect((headerHeight - logoSize) / 2, 4, logoSize, logoSize)

        draw.SimpleText(
            self.titleText,
            "ixGenericFont",
            40,
            headerHeight / 2,
            color_white,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )

        local onlineCount = team.NumPlayers(self.faction.index)
        draw.SimpleText(
            string.format("Online: %d", onlineCount),
            "ixGenericFont",
            width - 8,
            headerHeight / 2,
            color_white,
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER
        )
    end

    local outlineThickness = 3
    local outlineColor = self.titleColor or Color(100, 100, 100, 255)

    for i = 1, outlineThickness do
        surface.SetDrawColor(outlineColor)
        surface.DrawOutlinedRect(0 + i - 1, 0 + i - 1, width - (2 * (i - 1)), height - (2 * (i * 2)))
    end
end

vgui.Register("ixScoreboardFaction", PANEL, "ixCategoryPanel")

local PANEL = {}

function PANEL:Init()
    if (IsValid(ix.gui.scoreboard)) then
        ix.gui.scoreboard:Remove()
    end

    self:SetSize(ScrW() * 0.4, ScrH() * 0.8)
    self:Center()
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)

    self.scrollPanel = self:Add("DScrollPanel")
    self.scrollPanel:Dock(FILL)
    self.scrollPanel.Paint = function() end

    self.factions = {}
    self.nextThink = 0

    for i = 1, #ix.faction.indices do
        local faction = ix.faction.indices[i]

        local panel = self.scrollPanel:Add("ixScoreboardFaction")
        panel:SetFaction(faction)
        panel:Dock(TOP)
        panel:DockMargin(0, 0, 0, 16)

        self.factions[i] = panel
    end

    ix.gui.scoreboard = self
end

function PANEL:Think()
    if (CurTime() >= self.nextThink) then
        for i = 1, #self.factions do
            local factionPanel = self.factions[i]
            factionPanel:Update()
        end
        self:InvalidateLayout()
        self.nextThink = CurTime() + 0.5
    end
end

function PANEL:Paint(width, height)
    local cornerRadius = 16

    draw.RoundedBox(cornerRadius, 0, 0, width, height, Color(0, 0, 0, 220))
end

vgui.Register("ixCustomTabScoreboard", PANEL, "DFrame")
