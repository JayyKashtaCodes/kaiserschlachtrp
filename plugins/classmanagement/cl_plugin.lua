local PLUGIN = PLUGIN

PLUGIN.classRoster = {}

-- Prompt when receiving a class invite
net.Receive("ixClassInvitePrompt", function()
    local inviter   = net.ReadEntity()
    local classID   = net.ReadUInt(8)
    local classData = ix.class.Get(classID)
    local className = classData and classData.name or "Class"

    Derma_Query(
        ("You have been invited by %s to join %s. Accept?")
            :format(IsValid(inviter) and inviter:Nick() or "Someone", className),
        "Class Invitation",
        "Accept", function()
            net.Start("ixClassInviteResponse")
                net.WriteBool(true)
                net.WriteEntity(inviter)
                net.WriteUInt(classID, 8)
            net.SendToServer()
        end,
        "Decline", function()
            net.Start("ixClassInviteResponse")
                net.WriteBool(false)
                net.WriteEntity(inviter)
                net.WriteUInt(classID, 8)
            net.SendToServer()
        end
    )
end)

-- Receive class roster data from server
net.Receive("ixClassRosterSync", function()
    local count = net.ReadUInt(8)
    PLUGIN.classRoster = {}

    for i = 1, count do
        local name     = net.ReadString()
        local steamID  = net.ReadString()
        local classID  = net.ReadUInt(8)
        local rankUID  = net.ReadUInt(8)

        table.insert(PLUGIN.classRoster, {
            name     = name,
            steamID  = steamID,
            classID  = classID,
            rankUID  = rankUID
        })
    end

    -- If UI is open, refresh all rosters
    if ClassManagementUI and isfunction(ClassManagementUI.RefreshAllRosters) then
        ClassManagementUI.RefreshAllRosters()
    end
end)

-- Open Class Management UI
net.Receive("ixOpenClassManagement", function()
    local canInvite  = net.ReadBool()
    local canPromote = net.ReadBool()
    local canKick    = net.ReadBool()

    if IsValid(ClassManagementUI and ClassManagementUI.Frame) then
        ClassManagementUI.Frame:MakePopup()
        return
    end

    if ClassManagementUI and isfunction(ClassManagementUI.Open) then
        timer.Simple(0.1, function()
            ClassManagementUI.Open({
                canInvite  = canInvite,
                canPromote = canPromote,
                canKick    = canKick
            })
        end)
    else
        LocalPlayer():ChatPrint("Class management UI is missing or not loaded.")
    end
end)

-- Updated live rank getter: now uses GetData fallback
function PLUGIN:GetLiveRank(ply)
    if not IsValid(ply) then return 0 end
    local char = ply:GetCharacter()
    if not char then return 0 end
    return char:GetData("rankUID", 0)
end

-- UI helper: refresh all open roster panels
function ClassManagementUI.RefreshAllRosters()
    if not IsValid(ClassManagementUI.Frame) then return end

    for _, sheet in ipairs(ClassManagementUI.Frame.sheet.Items or {}) do
        local panel = sheet.Panel
        if IsValid(panel.roster) and panel.classID then
            ClassManagementUI.PopulateRoster(panel.roster, panel.classID)
        end
    end
end
