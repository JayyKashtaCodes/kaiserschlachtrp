local PLUGIN = PLUGIN
local custodyMenuFrame = nil

-- Helper to close the custody menu
local function CloseCustodyMenu()
    if IsValid(custodyMenuFrame) then
        custodyMenuFrame:Close()
        custodyMenuFrame = nil
    end
end

-- Tooltip: show if restrained
function PLUGIN:PopulateCharacterInfo(client, character, tooltip)
    if client:GetNetVar("restricted", false) then
        local panel = tooltip:AddRowAfter("description", "restricted")
        panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
        panel:SetText(L("This character is restrained"))
        panel:SizeToContents()
    end
end

-- Jail Timer HUD
hook.Add("HUDPaint", "JailTimerHUD", function()
    local ply = LocalPlayer()
    local jailTime = ply:GetNetVar("JailTime", 0)
    if jailTime <= 0 then return end

    local start = ply:GetNetVar("JailStartTime", 0)
    local elapsed = math.max(0, os.time() - start)

    local remaining = math.max(0, jailTime - elapsed)

    draw.SimpleText(
        "Time Remaining: " .. string.ToMinutesSeconds(remaining),
        "DermaLarge",
        ScrW() / 2, 20,
        Color(255, 0, 0),
        TEXT_ALIGN_CENTER
    )
end)


-- Open Inventory UI after search request
net.Receive("OpenInventoryUI", function()
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end

    local char = target:GetCharacter()
    if not char then return end

    local inv = char:GetInventory()
    if not inv then return end

    ix.storage.Open(LocalPlayer(), inv, {
        entity = target,
        name = target:Nick(),
        searchText = "Searching Inventory",
        searchTime = ix.config.Get("inventorySearchTime", 2)
    })
end)

-- Receive + Display Custody Menu
net.Receive("OpenCustodyMenu", function()
    local target = net.ReadEntity()
    local isRestricted = net.ReadBool()
    local restraintType = net.ReadString() or "" -- "cuffs" / "ties" / ""

    if not IsValid(target) then return end
    CloseCustodyMenu()

    custodyMenuFrame = vgui.Create("DFrame")
    local frame = custodyMenuFrame
    frame:SetTitle("Custody Actions")
    frame:SetSize(220, 160)
    frame:Center()
    frame:MakePopup()

    -- Search inventory
    local searchBtn = frame:Add("DButton")
    searchBtn:Dock(TOP)
    searchBtn:SetText("Search Inventory")
    searchBtn.DoClick = function()
        net.Start("SearchInventoryRequest")
            net.WriteEntity(target)
        net.SendToServer()
        CloseCustodyMenu()
    end

    -- Optional: blindfold removal
    local char = target:GetCharacter()

    if char and char.IsBlindfolded and char:IsBlindfolded() then
        local unblindBtn = frame:Add("DButton")
        unblindBtn:Dock(TOP)
        unblindBtn:SetText("Remove Blindfold")
        unblindBtn.DoClick = function()
            net.Start("UnblindfoldPlayer")
                net.WriteEntity(target)
            net.SendToServer()
            CloseCustodyMenu()
        end
    end

    -- Optional: gag removal
    if char and char.IsGagged and char:IsGagged() then
        local ungagBtn = frame:Add("DButton")
        ungagBtn:Dock(TOP)
        ungagBtn:SetText("Remove Gag")
        ungagBtn.DoClick = function()
            net.Start("UngagPlayer")
                net.WriteEntity(target)
            net.SendToServer()
            CloseCustodyMenu()
        end
    end

    -- Release button if restricted
    if isRestricted then
        local releaseBtn = frame:Add("DButton")
        releaseBtn:Dock(TOP)

        if restraintType == "cuffs" then
            releaseBtn:SetText("Uncuff (5s)")
            releaseBtn.DoClick = function()
                net.Start("UncuffPlayer")
                    net.WriteEntity(target)
                net.SendToServer()
                CloseCustodyMenu()
            end
        elseif restraintType == "ties" then
            releaseBtn:SetText("Untie (3s)")
            releaseBtn.DoClick = function()
                net.Start("UntiePlayer")
                    net.WriteEntity(target)
                net.SendToServer()
                CloseCustodyMenu()
            end
        else
            -- Fallback if type is missing/unknown
            releaseBtn:SetText("Release Restraints")
            releaseBtn.DoClick = function()
                net.Start("UncuffPlayer")
                    net.WriteEntity(target)
                net.SendToServer()
                CloseCustodyMenu()
            end
        end
    end
end)
