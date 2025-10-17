local PLUGIN = PLUGIN
ClassManagementUI = ClassManagementUI or {}

-- Populate roster for a given class
function ClassManagementUI.PopulateRoster(roster, classID)
    roster:Clear()

    for _, entry in ipairs(PLUGIN.classRoster or {}) do
        if entry.classID == classID then
            local rankName = PLUGIN:GetRankFromUID(classID, entry.rankUID) or "Unranked"
            local line = roster:AddLine(entry.name, rankName, entry.steamID)
            line.classID = entry.classID
        end
    end

    if roster:GetLines() == 0 then
        roster:AddLine("No players found in this class", "", "")
    end
end

-- Refresh all rosters
function ClassManagementUI.RefreshAllRosters()
    if not IsValid(ClassManagementUI.Frame) then return end

    for _, sheet in ipairs(ClassManagementUI.Frame.sheet.Items or {}) do
        local panel = sheet.Panel
        if IsValid(panel.roster) and panel.classID then
            ClassManagementUI.PopulateRoster(panel.roster, panel.classID)
        end
    end
end

-- Open UI
function ClassManagementUI.Open(perms)
    local clientChar = LocalPlayer():GetCharacter()
    if not clientChar then return end

    local myClassID = clientChar:GetClass()
    local myRankUID = clientChar:GetVar("rankUID", 0)
    local myRankName = PLUGIN:GetRankFromUID(myClassID, myRankUID)

    -- Collect manageable classes
    local managedClasses = {}
    for classID, classData in pairs(ix.class.list) do
        if PLUGIN:IsManagedClass(classID) and (classID == myClassID or PLUGIN:CanManageClass(myClassID, classID)) then
            managedClasses[classID] = classData
        end
    end

    -- Frame
    local frame = vgui.Create("DFrame")
    ClassManagementUI.Frame = frame
    frame.OnRemove = function() ClassManagementUI.Frame = nil end
    frame:SetTitle("Class Management")
    frame:SetSize(750, 500)
    frame:Center()
    frame:MakePopup()

    -- Player Info
    local infoLabel = vgui.Create("DLabel", frame)
    infoLabel:SetText("Your Character: " .. clientChar:GetName() ..
        "\nClass: " .. (ix.class.Get(myClassID).name or "Unknown") ..
        "\nRank: " .. myRankName)
    infoLabel:SetFont("DermaDefaultBold")
    infoLabel:Dock(TOP)
    infoLabel:DockMargin(10, 10, 10, 0)
    infoLabel:SetTall(60)

    -- Tabs
    local sheet = vgui.Create("DPropertySheet", frame)
    frame.sheet = sheet
    sheet:Dock(FILL)
    sheet:DockMargin(10, 10, 10, 10)

    -- Toolbar helper
    local function SmallBtn(parent, label, onclick)
        local b = vgui.Create("DButton", parent)
        b:SetFont("DermaDefault")
        b:SetText(label)
        b:SizeToContentsX(12)
        b:SetTall(24)
        b:Dock(LEFT)
        b:DockMargin(0, 0, 6, 0)
        b.DoClick = onclick
        return b
    end

    for classID, classData in pairs(managedClasses) do
        local panel = vgui.Create("DPanel", sheet)
        panel:Dock(FILL)
        panel.classID = classID

        local roster = vgui.Create("DListView", panel)
        roster:Dock(FILL)
        roster:SetMultiSelect(false) -- SINGLE SELECT
        roster:AddColumn("Name")
        roster:AddColumn("Rank")
        roster:AddColumn("SteamID")
        panel.roster = roster

        ClassManagementUI.PopulateRoster(roster, classID)

        -- Button Panel
        local btnPanel = vgui.Create("DPanel", panel)
        btnPanel:Dock(BOTTOM)
        btnPanel:SetTall(32)
        btnPanel:DockPadding(6, 4, 6, 4)

        -- Invite
        if perms.canInvite then
            SmallBtn(btnPanel, "Invite", function()
                Derma_StringRequest("Invite Player", "Enter the name of the player to invite:", "", function(name)
                    for _, ply in ipairs(player.GetAll()) do
                        if ply:Nick():lower() == name:lower() then
                            net.Start("ixClassInviteSend")
                                net.WriteEntity(ply)
                                net.WriteUInt(classID, 8)
                            net.SendToServer()
                            return
                        end
                    end
                    LocalPlayer():ChatPrint("Player not found.")
                end)
            end)
        end

        -- Transfer
        if perms.canPromote and perms.canInvite then
            SmallBtn(btnPanel, "Transfer", function()
                local selectedLineID = roster:GetSelectedLine()
                if not selectedLineID then return end
                local line = roster:GetLine(selectedLineID)
                local steamID = line:GetColumnText(3)

                local classChoices = {}
                for id, data in pairs(managedClasses) do
                    if id ~= classID then
                        table.insert(classChoices, data.name)
                    end
                end

                if #classChoices == 0 then
                    LocalPlayer():ChatPrint("No other classes available.")
                    return
                end

                Derma_Query("Choose target class:", "Transfer", unpack(classChoices), function(className)
                    local targetClassID
                    for id, data in pairs(managedClasses) do
                        if data.name == className then targetClassID = id break end
                    end
                    if not targetClassID then return end

                    local rankChoices = PLUGIN:GetAssignableRanks(targetClassID, myRankUID)
                    if #rankChoices == 0 then
                        LocalPlayer():ChatPrint("No valid ranks available.")
                        return
                    end

                    Derma_Query("Choose rank in " .. className .. ":", "Transfer", unpack(rankChoices), function(rankName)
                        local rankUID = PLUGIN:GetRankUIDFromName(targetClassID, rankName)
                        if not rankUID then return end

                        -- Send steamID, oldClassID, newClassID, newRankUID (match server handler)
                        net.Start("ixClassTransfer")
                            net.WriteString(steamID)
                            net.WriteUInt(classID, 8)        -- oldClassID (from current tab)
                            net.WriteUInt(targetClassID, 8)  -- newClassID
                            net.WriteUInt(rankUID, 8)        -- newRankUID
                        net.SendToServer()
                    end)
                end)
            end)
        end
        
        -- Promote / Demote
        if perms.canPromote then
            local AUTO_PROMOTE, AUTO_DEMOTE = 255, 254
            local lastClick, COOL_DOWN = 0, 0.5

            SmallBtn(btnPanel, "Promote", function()
                if RealTime() - lastClick < COOL_DOWN then return end
                lastClick = RealTime()

                local selID = roster:GetSelectedLine()
                if not selID then
                    LocalPlayer():ChatPrint("Select someone first.")
                    return
                end

                local line = roster:GetLine(selID)
                local steamID = line:GetColumnText(3)

                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and ply:SteamID() == steamID and ply:GetCharacter() then
                        local classID = ply:GetCharacter():GetClass()
                        net.Start("ixClassTransfer")
                            net.WriteString(steamID)
                            net.WriteUInt(classID, 8)       -- oldClassID
                            net.WriteUInt(classID, 8)       -- newClassID (same class)
                            net.WriteUInt(AUTO_PROMOTE, 8)  -- special flag
                        net.SendToServer()

                        LocalPlayer():ChatPrint("Promotion request sent for " .. ply:Nick())
                        return
                    end
                end

                LocalPlayer():ChatPrint("Target not found.")
            end)

            SmallBtn(btnPanel, "Demote", function()
                if RealTime() - lastClick < COOL_DOWN then return end
                lastClick = RealTime()

                local selID = roster:GetSelectedLine()
                if not selID then
                    LocalPlayer():ChatPrint("Select someone first.")
                    return
                end

                local line = roster:GetLine(selID)
                local steamID = line:GetColumnText(3)

                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and ply:SteamID() == steamID and ply:GetCharacter() then
                        local classID = ply:GetCharacter():GetClass()
                        net.Start("ixClassTransfer")
                            net.WriteString(steamID)
                            net.WriteUInt(classID, 8)      -- oldClassID
                            net.WriteUInt(classID, 8)      -- newClassID (same class)
                            net.WriteUInt(AUTO_DEMOTE, 8)  -- special flag
                        net.SendToServer()

                        LocalPlayer():ChatPrint("Demotion request sent for " .. ply:Nick())
                        return
                    end
                end

                LocalPlayer():ChatPrint("Target not found.")
            end)
        end

        -- Kick
        if perms.canKick then
            SmallBtn(btnPanel, "Kick", function()
                local selID = roster:GetSelectedLine()
                if not selID then return end

                local line = roster:GetLine(selID)
                local steamID = line:GetColumnText(3)
                local classID = line.classID or panel.classID

                net.Start("ixClassKick")
                    net.WriteString(steamID)
                    net.WriteUInt(classID, 8)
                net.SendToServer()
            end)
        end

        -- Refresh
        SmallBtn(btnPanel, "Refresh", function()
            net.Start("ixRequestClassRoster")
            net.SendToServer()
        end)

        -- Add this class tab
        sheet:AddSheet(classData.name, panel, "icon16/group.png")
    end -- end for managedClasses
end -- end Open()
