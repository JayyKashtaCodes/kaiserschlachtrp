local PANEL = {}

function PANEL:Init()
    self:SetTitle("Inventory")
    self:SetSize(ScrW() * 0.6, ScrH() * 0.6)
    self:Center()
    self:MakePopup()
    self:ShowCloseButton(true)

    -- Inventory sub-panel
    self.inventoryPanel = vgui.Create("ixInventory", self)
    self.inventoryPanel:Dock(FILL)
    self.inventoryPanel:ShowCloseButton(false)

    self.debugInventoryID = true
end

function PANEL:SetInventory(inventory)
    if not IsValid(self.inventoryPanel) or not inventory then return end

    self.inventoryPanel:SetInventory(inventory)
    self.inventoryID = inventory:GetID()

    if self.debugInventoryID then
        MsgC(Color(100, 255, 100), "[InventoryWrapper] Bound to inventory ID: ", self.inventoryID, "\n")
    end
end

function PANEL:RefreshInventory()
    if IsValid(self.inventoryPanel) and self.inventoryPanel.GetInventory then
        self.inventoryPanel:RebuildItems()
    end
end

vgui.Register("ixInventoryWrapper", PANEL, "DFrame")
