local PLUGIN = PLUGIN
local PANEL = {}

local DEFAULT_FONT = "VintageFont18-Bold"
local VALUE_FONT   = "VintageFont16"
local HEADER_FONT  = "VintageFont24-Bold" -- ensure this is created; otherwise set to DEFAULT_FONT

local COLOR_BG     = Color(235, 230, 220)
local COLOR_TEXT   = Color(0, 0, 0)
local COLOR_WHITE  = Color(255, 255, 255)

local HEADINGS = {
    name       = "Name",
    dob        = "Date of Birth",
    pob        = "Place of Birth",
    ethnicity  = "Ethnicity",
    hairColour = "Hair Colour",
    eyeColour  = "Eye Colour",
    height     = "Height",
    weight     = "Weight",
    blood      = "Blood Type",
    job        = "Job",
    rank       = "Rank"
}

-- Shared, stable order (left then right)
local FIELD_ORDER = {
    "dob", "weight", "ethnicity", "hairColour", "job", -- left column
    "pob", "height", "blood", "eyeColour", "rank"      -- right column
}

-- Preload and cache the background material so it’s hot on first open
if CLIENT then
    local PRELOAD_PATH = "vgui/scoreboard/scoreback" -- no extension for surface.GetTextureID

    hook.Add("Initialize", "ixDocsBackgroundPreload", function()
        -- Force texture into memory, then create/store the material
        surface.GetTextureID(PRELOAD_PATH)
        PLUGIN.backgroundMaterial = Material(PRELOAD_PATH .. ".vmt")

        -- If the engine was a tick behind, retry next frame
        if PLUGIN.backgroundMaterial:IsError() then
            timer.Simple(0, function()
                surface.GetTextureID(PRELOAD_PATH)
                PLUGIN.backgroundMaterial = Material(PRELOAD_PATH .. ".vmt")
            end)
        end
    end)
end

function PANEL:Init()
    self:SetSize(800, 400)
    self:Center()
    self:SetTitle("")
    self:SetVisible(true)
    self:SetDraggable(true)
    self:SetDeleteOnClose(true)
    self:MakePopup()
    self:ShowCloseButton(false)

    gui.EnableScreenClicker(true)

    -- Inline passport/ID photo
    self.modelPanel = self:Add("DModelPanel")
    self.modelPanel:SetSize(180, 180)
    self.modelPanel:SetPos(20, 40)
    self.modelPanel:SetFOV(20)
    self.modelPanel:SetCamPos(Vector(50, 0, 55))
    self.modelPanel:SetLookAt(Vector(0, 0, 65))
    self.modelPanel:SetModel("models/error.mdl")
    self.modelPanel.LayoutEntity = function(_, ent)
        if IsValid(ent) then ent:SetAngles(Angle(0, 0, 0)) end
    end
    self.modelPanel:SetMouseInputEnabled(false)

    -- Big name header (beneath model)
    self.nameLabel = self:Add("DLabel")
    self.nameLabel:SetSize(self.modelPanel:GetWide(), 30)
    self.nameLabel:SetPos(self.modelPanel.x, self.modelPanel.y + self.modelPanel:GetTall() + 5)
    self.nameLabel:SetFont(HEADER_FONT)
    self.nameLabel:SetText("Character Name")
    self.nameLabel:SetContentAlignment(5)
    self.nameLabel:SetTextColor(COLOR_TEXT)

    -- Data panel (two-column canvas)
    self.dataPanel = self:Add("DPanel")
    self.dataPanel:SetSize(self:GetWide() - 220, self:GetTall() - 80)
    self.dataPanel:SetPos(210, 80)
    self.dataPanel.Paint = function(pnl, w, h)
        if not self._renderData then
            draw.SimpleText("No data available.", DEFAULT_FONT, 10, 10, COLOR_TEXT)
            return
        end

        local padding  = 10
        local half     = math.ceil(#FIELD_ORDER / 2)
        local colW     = (w - padding * 3) / 2
        local leftX    = padding
        local rightX   = colW + padding * 2
        local rowGap   = 8
        local headH    = 20
        local valH     = 20
        local rowStep  = headH + valH + rowGap

        for i, fieldName in ipairs(FIELD_ORDER) do
            local colX = (i <= half) and leftX or rightX
            local indexInColumn = (i - 1) % half
            local rowY = indexInColumn * rowStep

            local meta = self._renderData[fieldName]
            local heading = meta and meta.heading or (HEADINGS[fieldName] or fieldName)
            local value   = meta and meta.value   or "N/A"

            draw.SimpleText(heading, DEFAULT_FONT, colX, rowY, COLOR_TEXT)
            draw.DrawText(value, VALUE_FONT, colX, rowY + headH, COLOR_TEXT, TEXT_ALIGN_LEFT)
        end
    end

    -- Close button
    self.closeButton = self:Add("DButton")
    self.closeButton:SetSize(30, 30)
    self.closeButton:SetPos(self:GetWide() - 35, 5)
    self.closeButton:SetText("X")
    self.closeButton:SetFont(DEFAULT_FONT)
    self.closeButton:SetTextColor(COLOR_TEXT)
    self.closeButton.Paint = function() end
    self.closeButton.DoClick = function()
        self:Close()
    end
end

-- Class-level paint so it’s not redefined per instance; guard against cold/error materials
function PANEL:Paint(w, h)
    local mat = PLUGIN and PLUGIN.backgroundMaterial

    if mat and not mat:IsError() then
        surface.SetDrawColor(COLOR_WHITE)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, w, h)
    else
        -- Attempt a one-time resolve if we hit a cold error material on first paint
        if not mat or mat:IsError() then
            local path = "vgui/scoreboard/scoreback"
            surface.GetTextureID(path)
            PLUGIN.backgroundMaterial = Material(path .. ".vmt")
            mat = PLUGIN.backgroundMaterial
            if mat and not mat:IsError() then
                surface.SetDrawColor(COLOR_WHITE)
                surface.SetMaterial(mat)
                surface.DrawTexturedRect(0, 0, w, h)
                return
            end
        end

        surface.SetDrawColor(COLOR_BG)
        surface.DrawRect(0, 0, w, h)
    end
end

-- Normalize once, not every Paint
function PANEL:SetCharacterData(name, data, model)
    self.characterData = data or {}

    if IsValid(self.nameLabel) then
        self.nameLabel:SetText(name or "Unknown")
    end

    if IsValid(self.modelPanel) then
        self.modelPanel:SetModel(model or "models/error.mdl")
    end

    -- Build render cache
    local render = {}
    for _, key in ipairs(FIELD_ORDER) do
        local raw = self.characterData[key]
        local val = (raw ~= nil and raw ~= "") and tostring(raw) or "N/A"

        if key == "job" then
            -- One-time newline after the first comma
            val = val:gsub(",%s*", ",\n", 1)
        end

        if key == "weight" and tonumber(val) then
            val = string.format("%s kg", val)
        end

        render[key] = {
            heading = HEADINGS[key] or key,
            value   = val
        }
    end

    -- Rank/job defaults
    render.rank = render.rank or { heading = HEADINGS.rank, value = "Unranked" }
    render.job  = render.job  or { heading = HEADINGS.job,  value = "Unknown Faction\nUnknown Class" }

    self._renderData = render

    if IsValid(self.dataPanel) then
        self.dataPanel:InvalidateLayout(true)
    end
end

function PANEL:OnRemove()
    gui.EnableScreenClicker(false)
end

function PANEL:Close()
    gui.EnableScreenClicker(false)
    self:SetVisible(false)
    self:Remove()
end

netstream.Hook("ixViewPersonalDocuments", function(data)
    if IsValid(ix.gui.personalDocsPanel) then
        LocalPlayer():Notify("You're already viewing personal documents.")
        return
    end

    surface.PlaySound("sfx/paper-2.wav")

    local frame = vgui.Create("ixPersonalDocumentsPanel")
    ix.gui.personalDocsPanel = frame

    frame:SetCharacterData(
        data.name or "Unknown",
        data.identification or {},
        data.model
    )

    frame.OnRemove = function()
        ix.gui.personalDocsPanel = nil
    end
end)

vgui.Register("ixPersonalDocumentsPanel", PANEL, "DFrame")
