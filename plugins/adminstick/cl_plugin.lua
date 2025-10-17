local PLUGIN = PLUGIN

AdminStick = AdminStick or {}

local function OpenNameUI(target)
    AdminStick.IsOpen = true

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Change Name")
    frame:SetSize(300, 110)
    frame:Center()

    function frame:OnClose()
        frame:Remove()
        AdminStick.IsOpen = false
    end

    local edit = vgui.Create("DTextEntry", frame)
    edit:Dock(FILL)
    edit:SetPlaceholderText(target:Name())

    local button = vgui.Create("DButton", frame)
    button:Dock(BOTTOM)
    button:SetText("Copy Name to Clipboard")
    function button:DoClick()
        SetClipboardText(target:Name())
        button:SetText("Copied '" .. target:Name() .. "'s' name to Clipboard")
        surface.PlaySound("buttons/lightswitch2.wav")

        timer.Simple(2, function()
            button:SetText("Copy Name to Clipboard")
        end)
    end

    local button1 = vgui.Create("DButton", frame)
    button1:Dock(BOTTOM)
    button1:SetText("Change")
    function button1:DoClick()
        ix.command.Send("CharsetName", target:Name(), edit:GetValue())
        AdminStick.IsOpen = false
    end

    frame:MakePopup()
end

local function OpenPlayerModelUI(target)
    AdminStick.IsOpen = true

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Change Playermodel")
    frame:SetSize(450, 300)
    frame:Center()

    function frame:OnClose()
        frame:Remove()
        AdminStick.IsOpen = false
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    local wrapper = vgui.Create("DIconLayout", scroll)
    wrapper:Dock(FILL)

    local edit = vgui.Create("DTextEntry", frame)
    edit:Dock(BOTTOM)
    edit:SetPlaceholderText("Model Path")

    local button = vgui.Create("DButton", frame)
    button:SetText("Change")
    button:Dock(TOP)
    function button:DoClick()
        ix.command.Send("CharsetModel", target:Name(), edit:GetValue())
        AdminStick.IsOpen = false
    end

    for name, model in SortedPairs(player_manager.AllValidModels()) do
        local icon = wrapper:Add("SpawnIcon")
        icon:SetModel(model)
        icon:SetSize(64, 64)
        icon:SetTooltip(name)
        icon.playermodel = name
        icon.model_path = model

        icon.DoClick = function(self)
            edit:SetValue(self.model_path)
        end
    end

    frame:MakePopup()
end

local function OpenReasonUI(target, cmd, time)
    AdminStick.IsOpen = true

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Reason for " .. cmd)
    frame:SetSize(300, 150)
    frame:Center()

    function frame:OnClose()
        frame:Remove()
        AdminStick.IsOpen = false
    end

    local edit = vgui.Create("DTextEntry", frame)
    edit:Dock(FILL)
    edit:SetMultiline(true)
    edit:SetPlaceholderText("Reason")

    local timeedit
    if cmd == "gag" or cmd == "ban" then
        local time = vgui.Create("DNumSlider", frame)
        time:Dock(TOP)
        time:SetText(cmd == "gag" and "Length (minutes)" or "Length (days)")
        time:SetMin(0)
        time:SetMax(365)
        time:SetDecimals(0)
        timeedit = time
    end

    local button = vgui.Create("DButton", frame)
    button:Dock(BOTTOM)
    button:SetText("Change")
    function button:DoClick()
        local txt = edit:GetValue()
        if cmd == "gag" then
            RunConsoleCommand("sam", cmd, target:Name(), timeedit:GetValue(), txt)
        elseif cmd == "ban" then
            RunConsoleCommand("sam", cmd, target:Name(), timeedit:GetValue() * 64 * 24, txt)
        else
            RunConsoleCommand("sam", cmd, target:Name(), txt)
        end
        frame:Remove()
        AdminStick.IsOpen = false
    end

    frame:MakePopup()
end

function AdminStick:OpenAdminStickUI(isright, target)
    isright = isright or false
    if isright then target = LocalPlayer() end
    AdminStick.IsOpen = true
    AdminStick.AdminMenu = DermaMenu()
    local AdminMenu = AdminStick.AdminMenu

    local function AddCopyOption(text, value)
        local option = AdminMenu:AddOption(text .. value .. " (left click to copy)", function() 
            SetClipboardText(value)
            AdminStick.IsOpen = false
        end)
        option:SetIcon("icon16/information.png")
    end

    AddCopyOption("Name: ", target:Name())
    local characterID = target:GetCharacter() and target:GetCharacter():GetID() or "N/A"
    AddCopyOption("CharID: ", characterID)
    AddCopyOption("SteamID: ", target:SteamID())
    AddCopyOption("SteamID64: ", target:SteamID64())
    AddCopyOption("Character Money: ", target:GetCharacter():GetMoney())

    AdminMenu:AddSpacer()
    
    local function CheckWhitelist(target)
        local status = {}
        local char = target:GetCharacter()
        if char then
            local player = char:GetPlayer()
            for _, v in pairs(ix.faction.teams) do
                status[v.name] = player:HasWhitelist(v.index)
            end
        end
        return status
    end
    
    for _, fac in pairs(ix.faction.teams) do
        if fac.index == target:GetCharacter():GetFaction() then
            local faction = AdminMenu:AddSubMenu("Set Faction (" .. fac.name .. ")")
            for _, v in pairs(ix.faction.teams) do
                faction:AddOption(v.name, function()
                    ix.command.Send("PlyTransfer", target:Name(), v.name)
                    AdminStick.IsOpen = false
                end)
            end
    
            local wfaction = AdminMenu:AddSubMenu("Set Faction Whitelist")
            local whitelistStatus = CheckWhitelist(target)
            for _, v in pairs(ix.faction.teams) do
                local optionText = v.name .. (whitelistStatus[v.name] and " ✓" or " X")
                wfaction:AddOption(optionText, function()
                    if whitelistStatus[v.name] then
                        ix.command.Send("PlyUnwhitelist", target:Name(), v.name)
                    else
                        ix.command.Send("PlyWhitelist", target:Name(), v.name)
                    end
                    whitelistStatus[v.name] = not whitelistStatus[v.name]
                    AdminStick.IsOpen = false
                    AdminMenu:Remove()
                    AdminStick:OpenAdminStickUI(isright, target)
                end)
            end
        end
    end     

    local class = AdminMenu:AddSubMenu("Set Class")

    local char = target:GetCharacter()
    local currentClass = char and char:GetClass()
    local currentFaction = char and char:GetFaction()

    for _, v in pairs(ix.class.list) do
        if v.faction == currentFaction then
            local optionText = v.name .. (v.index == currentClass and " ✓" or " X")
            class:AddOption(optionText, function()
                ix.command.Send("CharSetClass", target:Name(), v.name)
                AdminStick.IsOpen = false
            end)
        end
    end

    local administration = AdminMenu:AddSubMenu("Administration")
    local character = AdminMenu:AddSubMenu("Character")
    local teleportation = AdminMenu:AddSubMenu("Teleportation")
    local utility = AdminMenu:AddSubMenu("Utility")

    character:AddOption("Change Name", function() 
        OpenNameUI(target)
    end)

    character:AddOption("Change Playermodel", function() 
        OpenPlayerModelUI(target)
    end)

    if target:IsFrozen() then
        administration:AddOption("Unfreeze", function() 
            RunConsoleCommand("sam", "unfreeze", target:Name())
            AdminStick.IsOpen = false
        end)
    else
        administration:AddOption("Freeze", function() 
            RunConsoleCommand("sam", "freeze", target:Name())
            AdminStick.IsOpen = false
        end)
    end

    administration:AddOption("Jail", function() 
        RunConsoleCommand("sam", "jail", target:Name())
        AdminStick.IsOpen = false
    end)

    administration:AddOption("Unjail", function() 
        RunConsoleCommand("sam", "unjail", target:Name())
        AdminStick.IsOpen = false
    end)

    administration:AddOption("Ban", function()
        OpenReasonUI(target, "ban", 0)
    end)

    administration:AddOption("Kick", function() 
        OpenReasonUI(target, "kick", 0)
    end)

    utility:AddOption("Clear Decals", function() 
        ix.command.Send("ClearDecals")
        AdminStick.IsOpen = false
    end)    

    teleportation:AddOption("Bring", function() 
        RunConsoleCommand("sam", "bring", target:Name())
        AdminStick.IsOpen = false
    end)

    teleportation:AddOption("Return", function() 
        RunConsoleCommand("sam", "return", target:Name())
        AdminStick.IsOpen = false
    end)

    teleportation:AddOption("Goto", function() 
        RunConsoleCommand("sam", "goto", target:Name())
        AdminStick.IsOpen = false
    end)

    local permakillMenu = AdminMenu:AddSubMenu("Permakill")
    local function CheckPKActive(target)
        local char = target:GetCharacter()
        if char then
            return char:GetData("pkactive", false)
        end
        return false
    end    

    local pkActiveStatus = CheckPKActive(target)
    local permakillOptionText = "Toggle Permakill " .. (pkActiveStatus and "✓" or "X")

    permakillMenu:AddOption(permakillOptionText, function()
        ix.command.Send("PKActive", target:Name())
        AdminStick.IsOpen = false
    end)

    administration:AddOption("Gag", function()
        OpenReasonUI(target, "gag", 0)
    end)

    administration:AddOption("Ungag", function() 
        RunConsoleCommand("sam", "ungag", target:Name())
        AdminStick.IsOpen = false
    end)

    utility:AddOption("Stop Sound", function() 
        RunConsoleCommand("sam", "stopsound", target:Name())
        AdminStick.IsOpen = false
    end)

    utility:AddOption("Time", function() 
        RunConsoleCommand("sam", "time", target:Name())
        AdminStick.IsOpen = false
    end)

    function AdminMenu:OnClose()
        AdminStick.IsOpen = false
    end

    AdminMenu:Open()
    AdminMenu:Center()
end

local function DrawFilledCircle(x, y, radius, seg, r, g, b, a)
    local cir = {}
    table.insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })

    for i = 0, seg do
        local ang = math.rad((i / seg) * -360)
        table.insert(cir, {
            x = x + math.sin(ang) * radius,
            y = y + math.cos(ang) * radius,
            u = math.sin(ang) / 2 + 0.5,
            v = math.cos(ang) / 2 + 0.5
        })
    end

    draw.NoTexture()
    surface.SetDrawColor(r, g, b, a)
    surface.DrawPoly(cir)
end

-- Draw a circle around staff with the admin stick out
function PLUGIN:PostDrawTranslucentRenderables()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        if not ply:IsStaff() then continue end

        -- Skip if invisible
        if ply:GetNoDraw() then continue end
        local colPly = ply:GetColor()
        if colPly.a == 0 then continue end
        if ply:GetNWBool("invisible", false) then continue end -- for cloak mods

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "ix_adminstick" then continue end

        -- Get rank colour
        local isRGB, col = PLUGIN:GetRankColor(ply)
        if isRGB then
            local hue = (CurTime() * 100) % 360
            col = HSVToColor(hue, 1, 1)
        end

        -- Draw circle at player's feet
        local pos = ply:GetPos()
        pos.z = pos.z + 1

        cam.Start3D2D(pos, Angle(0, 90, 0), 0.25)
            surface.SetDrawColor(col.r, col.g, col.b, 200)
            draw.NoTexture()
            local radius = 100
            if ply:IsGA() then
                radius = 200
            end
            if ply:IsUA() then
                radius = 150
            end
            if ply:IsUStaff() then
                radius = 125
            end
            DrawFilledCircle(0, 0, radius, 48, col.r, col.g, col.b, 200)
        cam.End3D2D()
    end
end
