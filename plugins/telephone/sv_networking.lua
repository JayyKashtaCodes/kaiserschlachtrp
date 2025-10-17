local PLUGIN = PLUGIN

-- Server → Client events
util.AddNetworkString("ixTelephone_CallStarted")
util.AddNetworkString("ixTelephone_CallEnded")
util.AddNetworkString("ixTelephone_CallFailed")
util.AddNetworkString("ixTelephone_OpenPanel")    -- only sent when a player presses USE
util.AddNetworkString("ixTelephone_PlayRing")     -- 3D world ring sound at phone entity

-- Client → Server intents
util.AddNetworkString("ixTelephone_ReleaseUse")
util.AddNetworkString("ixTelephone_Dial")
util.AddNetworkString("ixTelephone_Accept")
util.AddNetworkString("ixTelephone_End")
util.AddNetworkString("ixTelephone_SetEmergency")

net.Receive("ixTelephone_SetEmergency", function(_, client)
    if not client:IsUA() then return end
    local ent = net.ReadEntity()
    local num = net.ReadString()
    if not IsValid(ent) or ent:GetClass() ~= "ix_telephone" then return end
    ent:SetEmergencyNumber(num)
end)

-- Caller initiates a dial
net.Receive("ixTelephone_Dial", function(_, client)
    local fromNumber = net.ReadString()
    local toNumber   = net.ReadString()

    if not fromNumber or not toNumber then
        net.Start("ixTelephone_CallFailed")
            net.WriteString("Invalid phone number format.")
        net.Send(client)
        return
    end

    -- Emergency call shortcut
    if PLUGIN:IsEmergencyNumber(toNumber) then
        net.Start("ixTelephone_CallStarted")
            net.WriteString(fromNumber)
            net.WriteString(toNumber)
        net.Send(client)
        return
    end

    local fromPhone = PLUGIN:GetTelephoneByNumber(fromNumber)
    local toPhone   = PLUGIN:GetTelephoneByNumber(toNumber)

    if not IsValid(fromPhone) or not IsValid(toPhone) then
        net.Start("ixTelephone_CallFailed")
            net.WriteString("One or both phone entities are invalid.")
        net.Send(client)
        return
    end

    if PLUGIN.activeCalls[fromNumber] or PLUGIN.activeCalls[toNumber] then
        net.Start("ixTelephone_CallFailed")
            net.WriteString("One of the lines is currently busy.")
        net.Send(client)
        return
    end

    -- Mark incoming call state on the callee's number
    PLUGIN.callState[toNumber] = {
        incomingFrom = fromNumber,
        isActive = false
    }

    -- Ring the physical phone in 3D for nearby players
    net.Start("ixTelephone_PlayRing")
        net.WriteUInt(toPhone:EntIndex(), 16)
        net.WriteBool(true) -- start ring
    net.SendPVS(toPhone:GetPos())

    -- Caller’s own panel in “dialling” mode (because they just picked up to dial)
    net.Start("ixTelephone_OpenPanel")
        net.WriteString(toNumber)
        net.WriteBool(false) -- not incoming
    net.Send(client)
end)

-- Callee accepts
net.Receive("ixTelephone_Accept", function(_, client)
    local myNumber = PLUGIN:GetNumberFromPlayer(client)
    local phoneEnt = PLUGIN.telephones[myNumber]

    if IsValid(phoneEnt) then
        -- stop ringing for everyone near this phone
        net.Start("ixTelephone_PlayRing")
            net.WriteUInt(phoneEnt:EntIndex(), 16)
            net.WriteBool(false)
        net.SendPVS(phoneEnt:GetPos())
    end

    PLUGIN:AcceptIncomingCall(client)
    PLUGIN.callState[myNumber] = nil
end)

-- Client panel closed: release lock for the user's current phone
net.Receive("ixTelephone_ReleaseUse", function(_, client)
    local ent = client.ixUsingPhone
    if IsValid(ent) and ent.currentUser == client then
        ent.currentUser = nil
        client.ixUsingPhone = nil
    end
end)

-- Either side hangs up / declines
net.Receive("ixTelephone_End", function(_, client)
    local myNumber = PLUGIN:GetNumberFromPlayer(client)
    local phoneEnt = PLUGIN.telephones[myNumber]

    if IsValid(phoneEnt) then
        net.Start("ixTelephone_PlayRing")
            net.WriteUInt(phoneEnt:EntIndex(), 16)
            net.WriteBool(false)
        net.SendPVS(phoneEnt:GetPos())
    end

    PLUGIN:DenyOrEndCall(client)
    PLUGIN.callState[myNumber] = nil
end)
