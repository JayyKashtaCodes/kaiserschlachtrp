local PLUGIN = PLUGIN or {}

PLUGIN.name = "Telephone System"
PLUGIN.description = "A system for managing telephone interactions."
PLUGIN.author = "Dzhey Kashta"

-- Emergency routing
PLUGIN.emergencyNumbers = {
    ["112"] = "police",
    ["113"] = "hospital"
}

-- Telephone registry
PLUGIN.telephones = {} -- [number] = entity

-- Active calls map: [callerNumber] = receiverNumber
PLUGIN.activeCalls = {}

-- Call state per phone number: [phoneNumber] = { incomingFrom = number, isActive = bool }
PLUGIN.callState = {}

-- Networking setup
ix.util.Include("sv_networking.lua", "server")
ix.util.Include("sv_sql.lua", "server")
ix.util.Include("cl_networking.lua", "client")

function PLUGIN:IsValidTelephoneNumber(number)
    if not isstring(number) then return false end

    if self.emergencyNumbers and self.emergencyNumbers[number] then
        return true
    end

    return number:match("^%d+$") and (#number >= 4 and #number <= 5)
end

-- Generate new phone number
function PLUGIN:GenerateTelephoneNumber(isEmergency, emergencyType)
    if isEmergency and emergencyType then
        for num, service in pairs(self.emergencyNumbers) do
            if service == emergencyType then
                return num
            end
        end
        return "000"
    end

    local length = math.random(4, 5)
    local number = ""
    for i = 1, length do
        number = number .. math.random(0, 9)
    end
    return number
end

-- Register a phone entity
function PLUGIN:RegisterTelephone(number, entity)
    if not isstring(number) or number == "" then return end
    self.telephones[number] = entity
end

-- Get entity by phone number (purges stale refs)
function PLUGIN:GetTelephoneByNumber(number)
    local ent = self.telephones[number]
    if IsValid(ent) then
        return ent
    else
        self.telephones[number] = nil
    end
end

-- Get phone number from a player if nearby
function PLUGIN:GetNumberFromPlayer(ply)
    for number, ent in pairs(self.telephones) do
        if IsValid(ent) and ply:GetPos():DistToSqr(ent:GetPos()) < 256^2 then
            return number
        end
    end
    return nil
end

-- Check if emergency number
function PLUGIN:IsEmergencyNumber(number)
    return self.emergencyNumbers[number] ~= nil
end

-- Start a call between two numbers
function PLUGIN:StartCall(fromNumber, toNumber)
    if not self.telephones[fromNumber] or not self.telephones[toNumber] then return false end
    self.activeCalls[fromNumber] = toNumber
    self.activeCalls[toNumber] = fromNumber
    return true
end

-- Clear activeCalls, remove stale telephones, clear callState
function PLUGIN:EndCall(number)
    local other = self.activeCalls[number]
    if other then
        self.activeCalls[other] = nil
    end
    self.activeCalls[number] = nil

    if not IsValid(self.telephones[number]) then
        self.telephones[number] = nil
    end
    if other and not IsValid(self.telephones[other]) then
        self.telephones[other] = nil
    end

    for num, state in pairs(self.callState) do
        if state.incomingFrom == number or num == number then
            self.callState[num] = nil
        end
    end
end

-- Accept an incoming call
function PLUGIN:AcceptIncomingCall(ply)
    local myNumber = self:GetNumberFromPlayer(ply)
    if not myNumber then return end

    local state = self.callState[myNumber]
    if not state or not state.incomingFrom then
        net.Start("ixTelephone_CallFailed")
            net.WriteString("No incoming call to accept.")
        net.Send(ply)
        return
    end

    local fromNumber = state.incomingFrom
    if self:StartCall(fromNumber, myNumber) then
        self.callState[myNumber].isActive = true

        -- Notify callee
        net.Start("ixTelephone_CallStarted")
            net.WriteString(fromNumber)
            net.WriteString(myNumber)
        net.Send(ply)

        -- Notify caller
        local callerEnt = self.telephones[fromNumber]
        if IsValid(callerEnt) then
            for _, callerPly in ipairs(ents.FindInSphere(callerEnt:GetPos(), 128)) do
                if callerPly:IsPlayer() then
                    net.Start("ixTelephone_CallStarted")
                        net.WriteString(fromNumber)
                        net.WriteString(myNumber)
                    net.Send(callerPly)
                end
            end
        end
    else
        net.Start("ixTelephone_CallFailed")
            net.WriteString("Could not connect call.")
        net.Send(ply)
    end
end

-- End or deny a call from a player's side
function PLUGIN:DenyOrEndCall(ply)
    local myNumber = self:GetNumberFromPlayer(ply)
    if not myNumber then return end
    local otherNumber = self.activeCalls[myNumber]

    self:EndCall(myNumber)

    -- Release lock for my phone
    self:_ReleasePhoneLockByNumber(myNumber)
    if otherNumber then
        self:_ReleasePhoneLockByNumber(otherNumber)
    end

    net.Start("ixTelephone_CallEnded")
    net.Send(ply)

    if otherNumber then
        local otherEnt = self.telephones[otherNumber]
        if IsValid(otherEnt) then
            for _, otherPly in ipairs(ents.FindInSphere(otherEnt:GetPos(), 128)) do
                if otherPly:IsPlayer() then
                    net.Start("ixTelephone_CallEnded")
                    net.Send(otherPly)
                end
            end
        end
    end
end

-- INTERNAL: release use lock for a number's entity
function PLUGIN:_ReleasePhoneLockByNumber(number)
    local ent = self.telephones[number]
    if IsValid(ent) then
        if IsValid(ent.currentUser) then
            ent.currentUser.ixUsingPhone = nil
        end
        ent.currentUser = nil
    end
end

-- Voice routing: only allow between call partners, full volume
function PLUGIN:PlayerCanHearPlayersVoice(listener, talker)
    local talkerNumber = self:GetNumberFromPlayer(talker)
    if not talkerNumber then return end

    local partnerNumber = self.activeCalls[talkerNumber]
    if not partnerNumber then return end

    local listenerNumber = self:GetNumberFromPlayer(listener)
    if listenerNumber == partnerNumber then
        return true, false
    else
        return false, false
    end
end

if SERVER then
    hook.Add("ShutDown", "ixTelephoneClearCalls", function()
        PLUGIN.activeCalls = {}
        PLUGIN.callState = {}
    end)

    hook.Add("PlayerDisconnected", "ixTelephoneReleaseLock", function(ply)
        local ent = ply.ixUsingPhone
        if IsValid(ent) and ent.currentUser == ply then
            ent.currentUser = nil
            ply.ixUsingPhone = nil
        end
    end)

    hook.Add("PlayerDeath", "ixTelephoneReleaseLock", function(ply)
        local ent = ply.ixUsingPhone
        if IsValid(ent) and ent.currentUser == ply then
            ent.currentUser = nil
            ply.ixUsingPhone = nil
        end
    end)
end
