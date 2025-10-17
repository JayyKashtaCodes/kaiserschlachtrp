-- Shared constants / helpers
local PLUGIN = PLUGIN

local DEFAULT_FONT = "VintageFont18-Bold"
local VALUE_FONT   = "VintageFont16"
local HEADER_FONT  = "VintageFont24-Bold"

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

local FIELD_ORDER = {
    "dob", "weight", "ethnicity", "hairColour", "job", -- left column
    "pob", "height", "blood", "eyeColour", "rank"      -- right column
}

local function CreateFieldBlock(parent, x, y, w, headingText, valueText, editable)
    local row = vgui.Create("DPanel", parent)
    row:SetPos(x, y)
    row:SetSize(w, 46)
    row.Paint = nil

    local heading = vgui.Create("DLabel", row)
    heading:SetFont(DEFAULT_FONT)
    heading:SetText(headingText or "")
    heading:SetTextColor(COLOR_TEXT)
    heading:SetPos(0, 0)
    heading:SetSize(w, 20)

    if editable then
        local entry = vgui.Create("DTextEntry", row)
        entry:SetPos(0, 22)
        entry:SetSize(w, 22)
        entry:SetValue(valueText or "")
        entry:SetUpdateOnType(true)
        entry:SetTextColor(COLOR_TEXT)
        entry:SetFont(VALUE_FONT)
        entry.Paint = function(self, pw, ph)
            surface.SetDrawColor(255, 255, 255, 230)
            surface.DrawRect(0, 0, pw, ph)
            self:DrawTextEntryText(COLOR_TEXT, Color(60, 120, 160), COLOR_TEXT)
        end
        return row, entry
    else
        local value = vgui.Create("DLabel", row)
        value:SetFont(VALUE_FONT)
        value:SetText(valueText or "")
        value:SetTextColor(COLOR_TEXT)
        value:SetPos(0, 22)
        value:SetWide(w)
        value:SetWrap(true)
        value:SetAutoStretchVertical(true)
        value:SetContentAlignment(1)
        row.PerformLayout = function()
            row:SetTall(20 + value:GetTall())
        end
        return row, value
    end
end

local function PaintBackground(self, w, h)
    local mat = PLUGIN and PLUGIN.backgroundMaterial
    if mat and not mat:IsError() then
        surface.SetDrawColor(COLOR_WHITE)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, w, h)
    else
        surface.SetDrawColor(COLOR_BG)
        surface.DrawRect(0, 0, w, h)
    end
end

local function PopulateFields(self, fields, editable)
    local padding  = 10
    local totalW   = self.canvas:GetWide()
    local half     = math.ceil(#FIELD_ORDER / 2)
    local colW     = (totalW - padding * 3) / 2
    local leftX    = padding
    local rightX   = colW + padding * 2
    local headH    = 20
    local valH     = 22
    local rowGap   = 8
    local rowStep  = headH + valH + rowGap

    for i, key in ipairs(FIELD_ORDER) do
        local headingText = HEADINGS[key] or key
        local raw = fields[key]
        local value = (raw ~= nil and raw ~= "") and tostring(raw) or ""
        if key == "weight" and value ~= "" and not value:find("kg", 1, true) and tonumber(value) then
            value = string.format("%s kg", value)
        end
        if key == "job" and value ~= "" then
            value = value:gsub(",%s*", ",\n", 1)
        end

        local colX = (i <= half) and leftX or rightX
        local indexInColumn = (i - 1) % half
        local rowY = padding + indexInColumn * rowStep

        local _, ctrl = CreateFieldBlock(self.canvas, colX, rowY, colW, headingText, value, editable)
        if editable and IsValid(ctrl) then
            self.entries[key] = ctrl
        end
    end
end

-- =========================
-- EDIT PANEL
-- =========================
local PANEL_EDIT = {}
function PANEL_EDIT:Init()
    self:SetSize(800, 400)
    self:Center()
    self:SetTitle("")
    self:MakePopup()
    self:ShowCloseButton(false)
    gui.EnableScreenClicker(true)

    self.Paint = PaintBackground

    -- Close button (top‑right)
    self.closeButton = self:Add("DButton")
    self.closeButton:SetSize(30, 30)
    self.closeButton:SetPos(self:GetWide() - 35, 5)
    self.closeButton:SetText("X")
    self.closeButton:SetFont(DEFAULT_FONT)
    self.closeButton:SetTextColor(COLOR_TEXT)
    self.closeButton.Paint = function() end
    self.closeButton.DoClick = function() self:Close() end

    self.modelPanel = self:Add("DModelPanel")
    self.modelPanel:SetSize(180, 180)
    self.modelPanel:SetPos(20, 40)
    self.modelPanel:SetFOV(20)
    self.modelPanel:SetCamPos(Vector(50, 0, 55))
    self.modelPanel:SetLookAt(Vector(0, 0, 65))
    self.modelPanel.LayoutEntity = function(_, ent) if IsValid(ent) then ent:SetAngles(Angle(0, 0, 0)) end end
    self.modelPanel:SetMouseInputEnabled(false)

    -- Editable heading under model
    self.nameEntry = self:Add("DTextEntry")
    self.nameEntry:SetSize(self.modelPanel:GetWide(), 30)
    self.nameEntry:SetPos(20, 225)
    self.nameEntry:SetFont(HEADER_FONT)
    self.nameEntry:SetContentAlignment(5) -- center text
    self.nameEntry:SetTextColor(COLOR_TEXT)
    self.nameEntry:SetUpdateOnType(true)

    self.canvas = self:Add("DPanel")
    self.canvas:SetSize(self:GetWide() - 220, self:GetTall() - 80)
    self.canvas:SetPos(210, 80)
    self.canvas.Paint = nil

    self.bottomBar = self:Add("DPanel")
    self.bottomBar:Dock(BOTTOM)
    self.bottomBar:SetTall(34)
    self.bottomBar.Paint = nil

    self.entries = {}
end

function PANEL_EDIT:SetPayload(payload)
    local fields = payload.fields or {}
    self._itemID = payload.itemID
    self.modelPanel:SetModel(payload.model or "models/error.mdl")
    self.nameEntry:SetValue(fields.name or "")

    for _, child in ipairs(self.canvas:GetChildren()) do if IsValid(child) then child:Remove() end end
    PopulateFields(self, fields, true)

    local saveBtn = vgui.Create("DButton", self.bottomBar)
    saveBtn:Dock(RIGHT)
    saveBtn:DockMargin(0, 2, 6, 2)
    saveBtn:SetWide(120)
    saveBtn:SetText("Save")
    saveBtn:SetFont(DEFAULT_FONT)
    saveBtn:SetTextColor(COLOR_TEXT)
    saveBtn.Paint = function(self, w, h)
        surface.SetDrawColor(255, 255, 255, 240)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    saveBtn.DoClick = function()
        local newData = {}

        for k, entry in pairs(self.entries) do
            local v = entry:GetValue() or ""
            if k == "weight" then v = v:gsub("%s*kg$", "") end
            newData[k] = tostring(v)
        end

        -- include editable heading name
        if IsValid(self.nameEntry) then
            newData.name = self.nameEntry:GetValue() or ""
        end

        netstream.Start("ixSubmitIDData", {
            itemID = self._itemID,
            fields = newData
        })
        self:Close()
    end
end

function PANEL_EDIT:OnRemove()
    gui.EnableScreenClicker(false)
end

vgui.Register("ixIdentificationEditPanel", PANEL_EDIT, "DFrame")

-- =========================
-- VIEW PANEL
-- =========================
local PANEL_VIEW = {}
function PANEL_VIEW:Init()
    self:SetSize(800, 400)
    self:Center()
    self:SetTitle("")
    self:MakePopup()
    self:ShowCloseButton(false)
    gui.EnableScreenClicker(true)

    self.Paint = PaintBackground

    -- Close button (top‑right)
    self.closeButton = self:Add("DButton")
    self.closeButton:SetSize(30, 30)
    self.closeButton:SetPos(self:GetWide() - 35, 5)
    self.closeButton:SetText("X")
    self.closeButton:SetFont(DEFAULT_FONT)
    self.closeButton:SetTextColor(COLOR_TEXT)
    self.closeButton.Paint = function() end
    self.closeButton.DoClick = function() self:Close() end

    self.modelPanel = self:Add("DModelPanel")
    self.modelPanel:SetSize(180, 180)
    self.modelPanel:SetPos(20, 40)
    self.modelPanel:SetFOV(20)
    self.modelPanel:SetCamPos(Vector(50, 0, 55))
    self.modelPanel:SetLookAt(Vector(0, 0, 65))
    self.modelPanel.LayoutEntity = function(_, ent) if IsValid(ent) then ent:SetAngles(Angle(0, 0, 0)) end end
    self.modelPanel:SetMouseInputEnabled(false)

    self.nameLabel = self:Add("DLabel")
    self.nameLabel:SetSize(self.modelPanel:GetWide(), 30)
    self.nameLabel:SetPos(20, 225)
    self.nameLabel:SetFont(HEADER_FONT)
    self.nameLabel:SetContentAlignment(5)
    self.nameLabel:SetTextColor(COLOR_TEXT)

    self.canvas = self:Add("DPanel")
    self.canvas:SetSize(self:GetWide() - 220, self:GetTall() - 80)
    self.canvas:SetPos(210, 80)
    self.canvas.Paint = nil

    self.bottomBar = self:Add("DPanel")
    self.bottomBar:Dock(BOTTOM)
    self.bottomBar:SetTall(34)
    self.bottomBar.Paint = nil
end

function PANEL_VIEW:SetPayload(payload)
    local fields = payload.fields or {}
    self.modelPanel:SetModel(payload.model or "models/error.mdl")
    self.nameLabel:SetText(fields.name or "Identification")

    for _, child in ipairs(self.canvas:GetChildren()) do
        if IsValid(child) then child:Remove() end
    end

    PopulateFields(self, fields, false)
end

function PANEL_VIEW:OnRemove()
    gui.EnableScreenClicker(false)
end

vgui.Register("ixIdentificationViewPanel", PANEL_VIEW, "DFrame")

-- =========================
-- NETSTREAM HOOKS
-- =========================
netstream.Hook("ixEditID", function(payload)
    local pnl = vgui.Create("ixIdentificationEditPanel")
    pnl:SetPayload(payload or {})
end)

netstream.Hook("ixViewID", function(payload)
    local pnl = vgui.Create("ixIdentificationViewPanel")
    pnl:SetPayload(payload or {})
end)
