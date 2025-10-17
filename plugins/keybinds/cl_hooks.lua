local PLUGIN = PLUGIN

-- Cooldown timers to prevent input spamming
local nextToggleInventoryTime = 0
local nextToggleThirdPersonTime = 0

-- Third-person mode toggle state
local thirdPersonEnabled = false

-- Toggle third-person camera mode
local function ToggleThirdPerson()
    thirdPersonEnabled = not thirdPersonEnabled
    ix.option.Set("thirdpersonEnabled", thirdPersonEnabled)
end

-- Toggle custom inventory panel
local function ToggleInventory()
    local existingPanel = ix.gui.inventory

    -- Close panel if it's open
    if IsValid(existingPanel) then
        existingPanel:Remove()
        ix.gui.inventory = nil
        return
    end

    local client = LocalPlayer()
    if not IsValid(client) then return end

    if client:GetNetVar("handcuffed", false) or client:GetNetVar("tied", false) then
        chat.AddText(Color(255, 100, 100), "[Inventory] You can't open your inventory while restrained.")
        return
    end

    local character = client:GetCharacter()
    if not character then
        chat.AddText(Color(255, 100, 100), "[Inventory] Character not loaded yet.")
        return
    end

    local inventory = character:GetInventory()
    if not inventory then
        chat.AddText(Color(255, 100, 100), "[Inventory] Inventory not available yet.")
        return
    end

    -- Create inventory panel
    local inventoryPanel = vgui.Create("ixInventory")
    if not IsValid(inventoryPanel) then
        chat.AddText(Color(255, 0, 0), "Inventory panel 'ixInventory' is missing or not registered.")
        return
    end

    inventoryPanel:SetTitle("Inventory")
    inventoryPanel:SetSize(ScrW() * 0.5, ScrH() * 0.5)
    inventoryPanel:Center()
    inventoryPanel:MakePopup()
    inventoryPanel:SetKeyboardInputEnabled(false)
    inventoryPanel:ShowCloseButton(true)
    inventoryPanel:SetInventory(inventory)

    ix.gui.inventory = inventoryPanel
end

-- Input handler
function PLUGIN:PlayerButtonDown(ply, key)
    if not IsFirstTimePredicted() then return end
    if ply != LocalPlayer() then return end

    -- Third-person toggle (F4 key)
    if key == KEY_F4 and CurTime() > nextToggleThirdPersonTime then
        ToggleThirdPerson()
        nextToggleThirdPersonTime = CurTime() + 0.5
    end

    -- Inventory toggle (I key)
    if key == KEY_I and CurTime() > nextToggleInventoryTime then
        ToggleInventory()
        nextToggleInventoryTime = CurTime() + 0.2
    end
end
