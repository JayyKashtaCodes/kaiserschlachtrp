local PLUGIN = PLUGIN

PLUGIN.name = "Typing Indicator"
PLUGIN.description = "Shows an indicator when someone is typing."
PLUGIN.author = "`impulse"
PLUGIN.animationTime = 0.5

if ( SERVER ) then
    ix.plugin.SetUnloaded("typing", true)
elseif ( CLIENT ) then
    if ( IsValid(ix.gui.pluginManager) ) then
        ix.gui.pluginManager:UpdatePlugin("typing", false)
    end
end

if (CLIENT) then
    local standingOffset = Vector(0, 0, 72)
    local crouchingOffset = Vector(0, 0, 38)
    local boneOffset = Vector(0, 0, 10)
    local textColor = Color(250, 250, 250)
    local shadowColor = Color(66, 66, 66)
    local currentClass = ""
    local lastSendClass = ""

    local symbolPattern = "[~`!@#$%%%^&*()_%+%-={}%[%]|;:'\",%./<>?]"

    function PLUGIN:LoadFonts(font, genericFont)
        surface.CreateFont("ixTypingIndicator", {
            font = genericFont,
            size = 128,
            extended = true,
            weight = 1000
        })
    end

    function PLUGIN:ChatTextChanged(text)
        if not IsValid(LocalPlayer()) then return end
        local character = LocalPlayer():GetCharacter()
        if not character then return end

        local newClass = ""
        if text ~= "" then
            newClass = hook.Run("GetTypingIndicator", character, text) or ""
        end

        -- Only send if the class actually changed
        if newClass ~= lastSendClass then
            lastSendClass = newClass
            net.Start("ixTypeClassSend")
                net.WriteString(newClass)
            net.SendToServer()
        end
    end

    function PLUGIN:FinishChat()
        if lastSendClass ~= "" then
            lastSendClass = ""
            net.Start("ixTypeClassSend")
                net.WriteString("")
            net.SendToServer()
        end
    end

    -- rest of your GetTypingIndicator, GetTypingIndicatorPosition, PostDrawTranslucentRenderables unchanged...

    net.Receive("ixTypeClass", function()
        local client = net.ReadEntity()
        if not IsValid(client) or client == LocalPlayer() then return end

        local newClass = net.ReadString()
        local chatClass = ix.chat.classes[newClass]
        local text, range

        if chatClass then
            text = L(chatClass.indicator or "chatTyping")
            range = chatClass.range or math.pow(ix.config.Get("chatRange", 280), 2)
        elseif (newClass and newClass:sub(1, 1) == "@") then
            text = L(newClass:sub(2))
            range = math.pow(ix.config.Get("chatRange", 280), 2)
        end

        if ix.option.Get("disableAnimations", false) then
            client.ixChatClassText = text
            client.ixChatClassRange = range
        else
            client.ixChatClassAnimation = tonumber(client.ixChatClassAnimation) or 0
            if text and not client.ixChatStarted then
                client.ixChatClassTween = ix.tween.new(PLUGIN.animationTime, client, {ixChatClassAnimation = 1}, "outCubic")
                client.ixChatClassText = text
                client.ixChatClassRange = range
                client.ixChatStarted = true
            elseif not text and client.ixChatStarted then
                client.ixChatClassTween = ix.tween.new(PLUGIN.animationTime, client, {ixChatClassAnimation = 0}, "inCubic")
                client.ixChatStarted = nil
            end
        end
    end)
else
    util.AddNetworkString("ixTypeClass")
    util.AddNetworkString("ixTypeClassSend")

    net.Receive("ixTypeClassSend", function(_, client)
        if (client.ixNextTypeClass or 0) > RealTime() then return end
        local newClass = net.ReadString()

        net.Start("ixTypeClass")
            net.WriteEntity(client)
            net.WriteString(newClass)
        if newClass == "" then
            net.Broadcast()
        else
            net.SendPVS(client:GetPos())
        end

        client.ixNextTypeClass = RealTime() + 0.2
    end)
end
