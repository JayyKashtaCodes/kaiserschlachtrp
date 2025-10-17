local PLUGIN = PLUGIN

PLUGIN.name = "Multi Core Popup"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Multi Core Popup."

ix.lang.AddTable("english", {
    optEnableMultiCore = "Enable MultiCore",
})

--  Persist setting via character data
ix.option.Add("enableMultiCore", ix.type.bool, true, {
    category = "Performance",
    description = "Enable or disable Multi Core support.",
    OnChanged = function(oldValue, newValue)
        -- Apply MultiCore settings client-side
        RunConsoleCommand("gmod_mcore_test", newValue and "1" or "0")
        RunConsoleCommand("cl_threaded_bone_setup", newValue and "1" or "0")
        RunConsoleCommand("mat_queue_mode", newValue and "2" or "-1")

        -- Send to server to persist
        net.Start("SetMultiCorePreference")
        net.WriteBool(newValue)
        net.SendToServer()
    end
})

hook.Add("PlayerLoadedCharacter", "HandleMultiCoreLogic", function(client, character, currentChar)
    if not IsValid(client) or not character then return end

    local pref = character:GetData("HasMultiCoreEnabled", nil)

    if pref ~= nil then
        net.Start("SyncMultiCoreOption")
        net.WriteBool(pref)
        net.Send(client)
    else
        local currentValue = client:GetInfoNum("gmod_mcore_test", 0)

        net.Start("SyncMultiCoreOption")
        net.WriteBool(currentValue == 1)
        net.Send(client)

        local dontShowPopup = character:GetData("DontShowMCorePopup", false)
        if not dontShowPopup and currentValue == 0 then
            net.Start("ShowMCorePopup")
            net.Send(client)
        end
    end
end)

if SERVER then
    util.AddNetworkString("ShowMCorePopup")
    util.AddNetworkString("SyncMultiCoreOption")
    util.AddNetworkString("SetDontShowMCorePopup")
    util.AddNetworkString("SetMultiCorePreference")

    net.Receive("SetDontShowMCorePopup", function(_, client)
        local character = client:GetCharacter()
        if character then
            character:SetData("DontShowMCorePopup", true)
        end
    end)

    net.Receive("SetMultiCorePreference", function(_, client)
        local character = client:GetCharacter()
        local preference = net.ReadBool()

        if character then
            character:SetData("HasMultiCoreEnabled", preference)
        end
    end)

else
    net.Receive("SyncMultiCoreOption", function()
        local enableMultiCore = net.ReadBool()
        ix.option.Set("enableMultiCore", enableMultiCore)
    end)

    net.Receive("ShowMCorePopup", function()
        local frame = vgui.Create("DFrame")
        frame:SetTitle("")
        frame:SetSize(350, 300)
        frame:Center()
        frame:MakePopup()
        frame:ShowCloseButton(false)

        frame.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(Material("vgui/scoreboard/scoreback"))
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local questionLabel = vgui.Create("DLabel", frame)
        questionLabel:SetText("Do you want to enable Multi Core?\nYou should use x64 beta for the Multi Core.")
        questionLabel:SetFont("VintageFont15")
        questionLabel:SetSize(300, 50)
        questionLabel:SetWrap(true)
        questionLabel:SetPos(25, 20)

        local dontShowCheckbox = vgui.Create("DCheckBoxLabel", frame)
        dontShowCheckbox:SetText("Don't show this popup again")
        dontShowCheckbox:SetFont("VintageFont11")
        dontShowCheckbox:SetPos(25, 170)
        dontShowCheckbox:SetValue(0)
        dontShowCheckbox:SizeToContents()

        local yesButton = vgui.Create("DButton", frame)
        yesButton:SetText("Yes")
        yesButton:SetSize(100, 30)
        yesButton:SetPos(25, 120)
        yesButton:SetFont("VintageFont12")
        yesButton.DoClick = function()
            ix.option.Set("enableMultiCore", true)

            net.Start("SetMultiCorePreference")
            net.WriteBool(true)
            net.SendToServer()

            if dontShowCheckbox:GetChecked() then
                net.Start("SetDontShowMCorePopup")
                net.SendToServer()
            end

            frame:Close()
        end

        local noButton = vgui.Create("DButton", frame)
        noButton:SetText("No")
        noButton:SetSize(100, 30)
        noButton:SetPos(125, 120)
        noButton:SetFont("VintageFont12")
        noButton.DoClick = function()
            ix.option.Set("enableMultiCore", false)

            net.Start("SetMultiCorePreference")
            net.WriteBool(false)
            net.SendToServer()

            if dontShowCheckbox:GetChecked() then
                net.Start("SetDontShowMCorePopup")
                net.SendToServer()
            end

            frame:Close()
        end
    end)
end
