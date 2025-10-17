local PLUGIN = PLUGIN
local ringingSounds = {} -- [entIndex] = soundObj

-- Helper: get or create the telephone panel
local function GetOrCreateTelephonePanel()
    if not IsValid(ix.telephonePanel) then
        ix.telephonePanel = vgui.Create("ixTelephone")
    end
    return ix.telephonePanel
end

-- Call successfully started
net.Receive("ixTelephone_CallStarted", function()
    surface.PlaySound("buttons/button9.wav")

    local fromNumber = net.ReadString()
    local toNumber   = net.ReadString()

    -- Stop any ringing that might still be playing for this call
    for _, snd in pairs(ringingSounds) do
        if snd.Stop then snd:Stop() end
    end
    ringingSounds = {}

    local panel = GetOrCreateTelephonePanel()
    panel:SetTelephoneNumber(fromNumber)
    panel:SetInCall(true)
    panel:SetConnectedTo(toNumber)
end)

-- Call failed
net.Receive("ixTelephone_CallFailed", function()
    surface.PlaySound("buttons/button10.wav")

    local reason = net.ReadString() or "Call failed."
    notification.AddLegacy(reason, NOTIFY_ERROR, 3)

    -- Stop all ringing just in case
    for _, snd in pairs(ringingSounds) do
        if snd.Stop then snd:Stop() end
    end
    ringingSounds = {}
end)

-- Call ended
net.Receive("ixTelephone_CallEnded", function()
    surface.PlaySound("sfx/hangup.mp3")

    if IsValid(ix.telephonePanel) then
        ix.telephonePanel:OnCallEnded()
        ix.telephonePanel:Remove()
        ix.telephonePanel = nil
    end

    -- Stop ringing
    for _, snd in pairs(ringingSounds) do
        if snd.Stop then snd:Stop() end
    end
    ringingSounds = {}
end)

-- Incoming call (single source of panel for callee)
net.Receive("ixTelephone_IncomingCall", function()
    --surface.PlaySound("ambient/alarms/klaxon1.wav") -- personal alert for callee

    local fromNumber = net.ReadString()
    local toNumber   = net.ReadString()

    local panel = GetOrCreateTelephonePanel()
    panel:SetTelephoneNumber(fromNumber) -- show caller ID
    panel:SetIncomingCall(true)
    panel:SetIncomingFrom(fromNumber)
end)

-- Open panel (for caller dial mode or manual use)
net.Receive("ixTelephone_OpenPanel", function()
    local number     = net.ReadString()
    local isIncoming = net.ReadBool()

    local panel = GetOrCreateTelephonePanel()
    panel:SetTelephoneNumber(number)

    if isIncoming then
        panel:SetIncomingCall(true)
    end
end)

-- 3D world ring handler
-- Server sends: entity index of the ringing phone, bool shouldRing (true/nil=start, false=stop)
net.Receive("ixTelephone_PlayRing", function()
    local entIndex   = net.ReadUInt(16)
    local shouldRing = net.ReadBool()
    if shouldRing == nil then shouldRing = true end

    local phoneEnt = Entity(entIndex)
    if not IsValid(phoneEnt) then return end

    if shouldRing then
        -- Start or restart ring
        if not ringingSounds[entIndex] then
            local snd = CreateSound(phoneEnt, "sfx/ringing.mp3")
            ringingSounds[entIndex] = snd
            snd:PlayEx(1, 100) -- volume, pitch
        end
    else
        -- Stop ring
        local snd = ringingSounds[entIndex]
        if snd and snd.Stop then
            snd:Stop()
            ringingSounds[entIndex] = nil
        end
    end
end)
