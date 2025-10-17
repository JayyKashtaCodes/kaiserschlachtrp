ITEM.name = "Shareable Docs"
ITEM.description = "Documents (GoogleDocs) you can share."
ITEM.price = 4
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Literature"
ITEM.bDropOnDeath = true

-- Ensure the Google Docs link ends with "/preview"
local function EnsurePreviewLink(link)
    if not link:match("/preview$") then
        return link .. "/preview"
    end
    return link
end

-- Initialize the default link with sanitization
ITEM.GoogleDocLink = EnsurePreviewLink(ITEM.GoogleDocLink or "https://docs.google.com/document/d/15JRYk57tIT2rotvOMxA_SH2igaz3KcMJ_uTlAD7Qz6Y")

if SERVER then
    util.AddNetworkString("MyShowGoogleDoc")
    util.AddNetworkString("MySetGoogleDocLink")
    util.AddNetworkString("UpdateGoogleDocLink")

    -- Function to find a player in front of the current player
    function ITEM:GetPlayerInFront(ply)
        local trace = {}
        trace.start = ply:GetShootPos()
        trace.endpos = trace.start + ply:GetForward() * 100
        trace.filter = function(ent) return ent:IsPlayer() and ent ~= ply end
        local traceResult = util.TraceLine(trace)

        if traceResult.Hit and traceResult.HitEntity:IsPlayer() then
            return traceResult.HitEntity
        end

        return nil
    end
end

if CLIENT then
    -- Creates a popup to display the Google Doc
    local function CreateGoogleDocPopup(link)
        local frame = vgui.Create("DFrame")
        frame:SetTitle("Shareable Documents")
        frame:SetSize(600, 400)
        frame:Center()
        frame:SetVisible(true)
        frame:MakePopup()
        frame:SetSizable(true)
    
        local loading = vgui.Create("DLabel", frame)
        loading:SetText("Loading...")
        loading:SetPos(270, 190)
        loading:SizeToContents()
    
        local html = vgui.Create("DHTML", frame)
        html:SetPos(10, 40)
        html:SetVisible(false) -- Hide the iframe initially
    
        timer.Simple(1, function()
            html:SetHTML("<iframe src='" .. link .. "' width='100%' height='100%'></iframe>")
            html:SetVisible(true) -- Show the iframe after loading
            loading:Remove() -- Remove the loading indicator
        end)
    
        frame.PerformLayout = function(self)
            html:SetSize(self:GetWide() - 20, self:GetTall() - 50)
            self.btnClose:SetPos(self:GetWide() - 35, 0)
        end
    end    

    -- Receive and handle requests to show a document
    net.Receive("MyShowGoogleDoc", function()
        local link = net.ReadString()
        CreateGoogleDocPopup(link)
    end)

    -- Receive and handle link update requests
    net.Receive("MySetGoogleDocLink", function()
        local currentLink = net.ReadString()

        local frame = vgui.Create("DFrame")
        frame:SetTitle("Set Google Docs Link")
        frame:SetSize(300, 100)
        frame:Center()
        frame:SetVisible(true)
        frame:MakePopup()

        local label = vgui.Create("DLabel", frame)
        label:SetText("Enter new link:")
        label:SetPos(10, 30)
        label:SizeToContents()

        local entry = vgui.Create("DTextEntry", frame)
        entry:SetPos(10, 50)
        entry:SetSize(280, 20)
        entry:SetText(currentLink)

        local button = vgui.Create("DButton", frame)
        button:SetText("Update")
        button:SetPos(10, 75)
        button:SetSize(80, 20)
        button.DoClick = function()
            local newLink = entry:GetValue()

            if newLink ~= currentLink and newLink:match("^https://docs.google.com/document/") then
                net.Start("UpdateGoogleDocLink")
                net.WriteString(newLink)
                net.SendToServer()
                frame:Remove()
            elseif newLink == currentLink then
                LocalPlayer():Notify("The link is unchanged. No updates made.")
            else
                LocalPlayer():Notify("Invalid link. Please enter a valid Google Docs link.")
            end
        end
    end)

    -- Receive updates about the Google Doc link
    net.Receive("UpdateGoogleDocLink", function()
        local newLink = net.ReadString()
        LocalPlayer():Notify("Google Docs link updated to: " .. newLink)
    end)
end

-- Show document to a target player
ITEM.functions.Show = {
    name = "Show Document",
    OnRun = function(itemTable)
        local ply = itemTable.player
        local targetPlayer = nil

        if itemTable.entity then
            targetPlayer = itemTable.entity:GetPlayerInFront(ply)
        else
            local trace = {}
            trace.start = ply:GetShootPos()
            trace.endpos = trace.start + ply:GetAimVector() * 100
            trace.filter = ply
            local traceResult = util.TraceLine(trace)

            if traceResult.Hit and IsValid(traceResult.HitEntity) and traceResult.HitEntity:IsPlayer() then
                targetPlayer = traceResult.HitEntity
            end
        end

        if targetPlayer then
            net.Start("MyShowGoogleDoc")
            net.WriteString(itemTable.GoogleDocLink)
            net.Send(targetPlayer)

            ply:Notify("You showed the document to " .. targetPlayer:GetName() .. ".")
            targetPlayer:Notify(ply:GetName() .. " showed you a document.")
        else
            ply:Notify("No player found in front of you to show to.")
        end
        return false
    end
}

-- Open and read the document
ITEM.functions.Read = {
    name = "Read Document",
    OnRun = function(itemTable)
        local ply = itemTable.player
        net.Start("MyShowGoogleDoc")
        net.WriteString(itemTable.GoogleDocLink)
        net.Send(ply)
        return false
    end
}

-- Set a new Google Docs link
ITEM.functions["Set Link"] = {
    name = "Set Google Docs Link",
    OnRun = function(itemTable)
        local ply = itemTable.player
        local currentLink = itemTable.GoogleDocLink

        -- Trigger the client to display the link-setting frame
        net.Start("MySetGoogleDocLink")
        net.WriteString(currentLink)
        net.Send(ply)

        -- Handle link updates asynchronously
        net.Receive("UpdateGoogleDocLink", function(len, ply)
            local newLink = net.ReadString()
            local sanitizedLink = EnsurePreviewLink(newLink) -- Correct the link

            -- Update the GoogleDocLink to the corrected version
            ITEM.GoogleDocLink = sanitizedLink

            ply:Notify("Google Docs link updated to: " .. sanitizedLink)
        end)

        return false
    end
}
