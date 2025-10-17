local PANEL = {}

local matOverlay_Normal = Material("gui/ContentIcon-normal.png")
local matOverlay_Hovered = Material("gui/ContentIcon-hovered.png")

AccessorFunc(PANEL, "m_sMaterial", "Material", FORCE_STRING)
AccessorFunc(PANEL, "m_cColor", "Color", FORCE_COLOR)
AccessorFunc(PANEL, "m_sName", "Name", FORCE_STRING)
AccessorFunc(PANEL, "m_sUniqueID", "UniqueID", FORCE_STRING)
AccessorFunc(PANEL, "m_sModel", "Model", FORCE_STRING)
AccessorFunc(PANEL, "m_iSkin", "SkinID", FORCE_NUMBER)

function PANEL:Init()
    self:SetPaintBackground(false)
	self:SetSize(128, 128)
	self:SetText("")
	self:SetDoubleClickingEnabled(false)

	self.Image = self:Add("DImage")
	self.Image:SetPos(3, 3)
	self.Image:SetSize(128 - 6, 128 - 6)
	self.Image:SetVisible(false)

    self.Icon = self:Add("ModelImage")
    self.Icon:SetPos(3, 3)
	self.Icon:SetSize(128 - 6, 128 - 6)
	self.Icon:SetMouseInputEnabled(false)
	self.Icon:SetKeyboardInputEnabled(false)
	self.Icon:SetVisible(false)

    self.Border = 0
end

function PANEL:SetMaterial(str)
    if not str then return end

    if self:GetModel() then return end

    self.m_sMaterial = str
    self.Image:SetImage(str)
    self.Image:SetVisible(true)
end

function PANEL:SetColor(col)
    if not col then return end

    if not self:GetMaterial() then return end

    self.m_cColor = col
    self.Image:SetColor(col)
end

function PANEL:SetModel(str)
    if not str then return end

    if self:GetMaterial() then return end

    self.m_sModel = str
    self.Icon:SetModel(str, self:GetSkinID() or 0, "000000000")
    self.Icon:SetVisible(true)
end

function PANEL:SetSkinID(int)
    if not int then return end

    if not self:GetModel() then return end

    self.m_iSkin = int
    self.Icon:SetModel(self:GetModel(), int, "000000000")
end

function PANEL:SetName(str)
    if not str then return end

    self.m_sName = str
    self:SetTooltip(str)
end

function PANEL:PaintOver(w, h)
	if self.Depressed && !self.Dragging then
		if self.Border != 8 then
			self.Border = 8
		end
	else
		if self.Border != 0 then
			self.Border = 0
		end
	end

	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	self.Image:PaintAt(3 + self.Border, 3 + self.Border, 128 - 8 - self.Border * 2, 128 - 8 - self.Border * 2)
	--self.Icon:PaintAt(3 + self.Border, 3 + self.Border, 128 - 8 - self.Border * 2, 128 - 8 - self.Border * 2)

	render.PopFilterMin()
	render.PopFilterMag()

	surface.SetDrawColor(color_white)

    local show = true

	if !dragndrop.IsDragging() && (self:IsHovered() or self.Depressed or self:IsChildHovered()) then
		surface.SetMaterial(matOverlay_Hovered)
        show = false
	else
		surface.SetMaterial(matOverlay_Normal)
	end

	surface.DrawTexturedRect(self.Border, self.Border, w-self.Border*2, h-self.Border*2)

    if show then
        local width = w-self.Border*2
        local text = self:GetName()
        local font = "DermaDefault"
        surface.SetFont(font)
        local textWidth = select(1, surface.GetTextSize(text)) + 10
        if (textWidth > width) then
            text = string.sub(text, 1, math.floor(width / textWidth * string.len(text)) - 5) .. "..."
        end

        local texttable = {
            text = text,
            font = "DermaDefault",
            pos = {w / 2, h - 16},
            xalign = TEXT_ALIGN_CENTER,
            yalign = TEXT_ALIGN_CENTER,
            color = color_white
        }

        draw.Text(texttable)
        draw.TextShadow(texttable, 1, 255)
    end
end

function PANEL:OnDepressed()
    self.Icon:SetSize(128 - 6 - 16, 128 - 16 - 8)
    self.Icon:SetPos(3 + 8, 3 + 8)
end

function PANEL:OnReleased()
    self.Icon:SetSize(128 - 6, 128 - 6)
    self.Icon:SetPos(3, 3)
end

function PANEL:DoClick()
    net.Start("ixItemSpawnmenuSpawn")
        net.WriteString(self:GetUniqueID())
    net.SendToServer()
	surface.PlaySound("ui/buttonclickrelease.wav")
end

function PANEL:DoRightClick()
    local menu = DermaMenu()
    menu:AddOption("Copy Item ID to Clipboard", function()
        SetClipboardText(self:GetUniqueID())
    end):SetIcon("icon16/page_copy.png")
    menu:AddOption("Give to Target", function()
        net.Start("ixItemSpawnmenuGive")
            net.WriteString(self:GetUniqueID())
            net.WriteUInt(1, 4)
            net.WriteBool(true)
        net.SendToServer()
    end):SetIcon("icon16/package_add.png")
    menu:AddOption("Give to Self", function()
        net.Start("ixItemSpawnmenuGive")
            net.WriteString(self:GetUniqueID())
            net.WriteUInt(1, 4)
            net.WriteBool(false)
        net.SendToServer()
    end):SetIcon("icon16/add.png")
    -- give 5 to self, 10 to self, 15 to self
    menu:AddOption("Give to Self (x5)", function()
        net.Start("ixItemSpawnmenuGive")
            net.WriteString(self:GetUniqueID())
            net.WriteUInt(5, 4)
            net.WriteBool(false)
        net.SendToServer()
    end):SetIcon("icon16/add.png")
    menu:AddOption("Give to Self (x10)", function()
        net.Start("ixItemSpawnmenuGive")
            net.WriteString(self:GetUniqueID())
            net.WriteUInt(10, 4)
            net.WriteBool(false)
        net.SendToServer()
    end):SetIcon("icon16/add.png")
    menu:AddOption("Give to Self (x15)", function()
        net.Start("ixItemSpawnmenuGive")
            net.WriteString(self:GetUniqueID())
            net.WriteUInt(15, 4)
            net.WriteBool(false)
        net.SendToServer()
    end):SetIcon("icon16/add.png")
    menu:Open()
end

vgui.Register("ixSpawnmenuItemIcon", PANEL, "DButton")