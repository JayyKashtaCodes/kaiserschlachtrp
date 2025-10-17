local PLUGIN = PLUGIN
local tiePlugin = ix.plugin.list["tyingoverhauled"]

-----------------------------------------------------------------
-- Network strings
-----------------------------------------------------------------
util.AddNetworkString("JailPlayer")
util.AddNetworkString("ReleasePlayer")

util.AddNetworkString("RequestJailHistory")
util.AddNetworkString("ReceiveJailHistory")

util.AddNetworkString("OpenActiveJailMenu")
util.AddNetworkString("RequestActiveJails")
util.AddNetworkString("SendActiveJails")

util.AddNetworkString("SearchInventoryRequest")
util.AddNetworkString("OpenInventoryUI")
util.AddNetworkString("UncuffPlayer")
util.AddNetworkString("UntiePlayer")
util.AddNetworkString("UnblindfoldPlayer")
util.AddNetworkString("UngagPlayer")
util.AddNetworkString("OpenCustodyMenu")

-- Map restraintType → actual item uniqueID
local RESTRAINT_ITEM_MAP = {
    cuffs = "handcuffs",
    ties  = "rope"
}

-----------------------------------------------------------------
-- Jail sentencing
-----------------------------------------------------------------
net.Receive("JailPlayer", function(_, actor)
    local target = net.ReadEntity()
    local jailMinutes = net.ReadInt(32)
    local reason = net.ReadString()
    local judge  = net.ReadString()

    if not (IsValid(target) and target:IsPlayer()) then return end
    if not PLUGIN:IsAuthorizedJailer(actor) then return end
    if target:Team() == FACTION_PRISONER then 
        actor:Notify("You can't Jail someone who is already Jailed.")
        return 
    end
    if not jailMinutes or jailMinutes < 1 or jailMinutes > 120 then
        actor:ChatPrint("Invalid jail time. Must be between 1 and 120 minutes.")
        return
    end

    local seconds = jailMinutes * 60
    local char = target:GetCharacter()
    local now = os.time()

    if char then
        char:SetData("activeJail", {
            time   = seconds,
            timesentenced = seconds,
            reason = reason or "",
            judge  = judge or "",
            start  = now
        })
        char:SetFaction(FACTION_PRISONER)

        local prisonerClass = ix.class.Get(CLASS_PRISONER)
        if not prisonerClass then
            actor:Notify("Prisoner class not found.")
            return
        end

        local oldClass = char:GetClass()
        char:SetClass(prisonerClass.index or CLASS_PRISONER)
        hook.Run("PlayerJoinedClass", target, prisonerClass.index or CLASS_PRISONER, oldClass)
        char:Save()
    end

    -- NetVars for HUD / UI
    target:SetNetVar("JailTime", seconds)
    target:SetNetVar("JailReason", reason or "")
    target:SetNetVar("JailJudge", judge or "")
    target:SetNetVar("JailStartTime", now)

    -- Release timer
    local tID = "Release_" .. target:SteamID()
    if timer.Exists(tID) then timer.Remove(tID) end
    timer.Create(tID, seconds, 1, function()
        if IsValid(target) then
            PLUGIN:EndJailSentence(target, "Completed")
        end
    end)
    target:Notify("You have been Jailed.")
    actor:Notify("You Jailed " .. char:GetName() .. ".")
end)

-----------------------------------------------------------------
-- History queries
-----------------------------------------------------------------
net.Receive("RequestJailHistory", function(_, ply)
    if not PLUGIN:IsAuthorizedJailer(ply) then return end
    --print("[Server] Request received from", IsValid(ply) and ply:Nick() or "nil")

    local query = mysql:Select("ix_jail_history")
    query:OrderByDesc("releaseTime")
    query:Limit(100)
    query:Callback(function(data)
        --print("[Server] Sending", istable(data) and #data or 0, "records back")
        net.Start("ReceiveJailHistory")
            net.WriteTable(data or {})
        net.Send(ply)
    end)
    query:Execute()
end)

-----------------------------------------------------------------
-- Active jail list (connected players only)
-- We’ll keep an indexed list in memory for quick “release by index”
-----------------------------------------------------------------
local lastActiveList = {}

net.Receive("RequestActiveJails", function(_, ply)
    if not PLUGIN:IsAuthorizedJailer(ply) then return end

    lastActiveList = {}
    for _, target in ipairs(player.GetAll()) do
        local char = target:GetCharacter()
        if char and target:GetNetVar("JailTime", 0) > 0 then
            local startTime = target:GetNetVar("JailStartTime", 0)
            local jailTime  = target:GetNetVar("JailTime", 0)
            local elapsed   = math.max(0, os.time() - startTime)
            local remaining = math.max(0, jailTime - elapsed)

            table.insert(lastActiveList, {
                ply           = target, -- actual player object
                characterName = char:GetName() or target:Nick(),
                reason        = target:GetNetVar("JailReason", ""),
                judge         = target:GetNetVar("JailJudge", ""),
                startTime     = startTime,
                jailTime      = jailTime,
                remaining     = remaining
            })
        end
    end

    net.Start("SendActiveJails")
        net.WriteUInt(#lastActiveList, 12)
        for _, row in ipairs(lastActiveList) do
            net.WriteString("") -- dummy SteamID slot, kept for net order compatibility
            net.WriteString(row.characterName)
            net.WriteString(row.reason)
            net.WriteString(row.judge)
            net.WriteUInt(row.startTime, 32)
            net.WriteUInt(row.jailTime, 32)
            net.WriteUInt(row.remaining, 32)
        end
    net.Send(ply)
end)

-----------------------------------------------------------------
-- ReleasePlayer now uses row index from lastActiveList
-----------------------------------------------------------------
net.Receive("ReleasePlayer", function(_, actor)
    local index = net.ReadUInt(12)
    local reason = net.ReadString()

    if not PLUGIN:IsAuthorizedJailer(actor) then return end
    local entry = lastActiveList[index]
    if not entry or not IsValid(entry.ply) or not entry.ply:IsPlayer() then return end

    if entry.ply:GetNetVar("JailTime", 0) <= 0 then return end

    PLUGIN:EndJailSentence(entry.ply, reason or "Released early")

    entry.ply:Notify("You have been Released by " .. actor:GetCharacter():GetName() .. ".")
    actor:Notify("You have Released " .. entry.ply:GetCharacter():GetName() .. ".")
end)

-----------------------------------------------------------------
-- Full release helpers
-----------------------------------------------------------------
local function FullyRelease(actor, target, msgActor, msgTarget)
    if not (IsValid(target) and target:IsPlayer()) then return end
    if not PLUGIN.InRange(actor, target, 100) then return end

    local char = target:GetCharacter()
    local restraintType = PLUGIN:GetRestraintType(target)
    local itemID = restraintType and RESTRAINT_ITEM_MAP[restraintType]

    -- Remove primary restraint
    PLUGIN:SetRestricted(target, false)
    if itemID then
        PLUGIN.GiveRestraintItem(actor, itemID)
    end
    if msgActor then actor:ChatPrint(msgActor:format(target:Nick())) end
    if msgTarget then target:ChatPrint(msgTarget) end

    -- Also remove blindfold/gag if present
    if char then
        if char.IsBlindfolded and char:IsBlindfolded() then
            char:SetBlindfolded(false)
            PLUGIN.GiveRestraintItem(actor, "blindfold")
            actor:NotifyLocalized("You have removed the blindfold from " .. target:Name() .. ".")
            target:NotifyLocalized("Your blindfold has been removed.")
        end
        if char.IsGagged and char:IsGagged() then
            char:SetGagged(false)
            PLUGIN.GiveRestraintItem(actor, "gag")
            actor:NotifyLocalized("You have removed the gag from " .. target:Name() .. ".")
            target:NotifyLocalized("Your gag has been removed.")
        end
        char:Save()
    end
end

-----------------------------------------------------------------
-- Net handlers for restraint removal
-----------------------------------------------------------------
net.Receive("UncuffPlayer", function(_, actor)
    local target = net.ReadEntity()
    if PLUGIN:GetRestraintType(target) ~= "cuffs" then return end

    actor:SetAction("Uncuffing...", 5)
    target:ChatPrint("Your handcuffs are being removed.")

    local snd = CreateSound(target, "sfx/cuffing.wav"); snd:Play()
    actor:DoStaredAction(target, function()
        snd:Stop()
        FullyRelease(actor, target, "You unhandcuffed %s", "Your handcuffs have been removed.")
    end, 5, function()
        snd:Stop()
        actor:ChatPrint("Uncuffing failed due to interruption.")
    end)
end)

net.Receive("UntiePlayer", function(_, actor)
    local target = net.ReadEntity()
    if PLUGIN:GetRestraintType(target) ~= "ties" then return end

    actor:SetAction("Untying...", 3)
    target:ChatPrint("Your restraints are being removed.")

    local snd = CreateSound(target, "sfx/tying.wav"); snd:Play()
    actor:DoStaredAction(target, function()
        snd:Stop()
        FullyRelease(actor, target, "You untied %s", "Your restraints have been removed.")
    end, 3, function()
        snd:Stop()
        actor:ChatPrint("Untying failed due to interruption.")
    end)
end)

net.Receive("UnblindfoldPlayer", function(_, actor)
    local target = net.ReadEntity()
    if not PLUGIN.InRange(actor, target, 100) then return end

    local char = target:GetCharacter()
    if char and char.IsBlindfolded and char:IsBlindfolded() then
        char:SetBlindfolded(false)
        PLUGIN.GiveRestraintItem(actor, "blindfold")
        actor:NotifyLocalized("You have removed the blindfold from " .. target:Name() .. ".")
        target:NotifyLocalized("Your blindfold has been removed.")
        char:Save()
    end
end)

net.Receive("UngagPlayer", function(_, actor)
    local target = net.ReadEntity()
    if not PLUGIN.InRange(actor, target, 100) then return end

    local char = target:GetCharacter()
    if char and char.IsGagged and char:IsGagged() then
        char:SetGagged(false)
        PLUGIN.GiveRestraintItem(actor, "gag")
        actor:NotifyLocalized("You have removed the gag from " .. target:Name() .. ".")
        target:NotifyLocalized("Your gag has been removed.")
        char:Save()
    end
end)
