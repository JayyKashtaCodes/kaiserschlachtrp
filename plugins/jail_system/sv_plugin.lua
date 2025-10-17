local PLUGIN = PLUGIN
local tiePlugin = ix.plugin.list["tyingoverhauled"]

-----------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------

function PLUGIN.InRange(a, b, dist)
    if not (IsValid(a) and IsValid(b)) then return false end
    dist = dist or 100
    return a:GetPos():DistToSqr(b:GetPos()) <= dist * dist
end

function PLUGIN.GiveRestraintItem(client, uniqueID)
    if not (IsValid(client) and client:IsPlayer()) then return end
    local char = client:GetCharacter()
    if not char then return end

    local inv = char:GetInventory()
    if not inv then return end

    local ok = inv:Add(uniqueID, 1)
    local def = ix.item.list[uniqueID]

    if ok then
        if def then client:ChatPrint(("Received %s."):format(def.name)) end
    else
        local dropPos = client:GetShootPos() + client:GetAimVector() * 16
        ix.item.Spawn(uniqueID, dropPos)
        if def then client:ChatPrint(("Inventory full. Dropped %s."):format(def.name)) end
    end
end

-----------------------------------------------------------------
-- Restrained state
-----------------------------------------------------------------
function PLUGIN:IsRestrained(ply)
    local char = IsValid(ply) and ply:GetCharacter()
    return char and char:GetData("restricted") == true or false
end

function PLUGIN:GetRestraintType(ply)
    local char = IsValid(ply) and ply:GetCharacter()
    return char and char:GetData("restraintType") or ""
end

function PLUGIN:SyncRestraints(ply)
    if IsValid(ply) then
        ply:SetNetVar("restricted", self:IsRestrained(ply) or nil)
        ply:SetNetVar("restraintType", self:GetRestraintType(ply) or "")
    end
end

-- state=true + optional restraintType ("cuffs"/"ties")
function PLUGIN:SetRestricted(ply, state, restraintType)
    local char = IsValid(ply) and ply:GetCharacter()
    if not char then return end

    if state then
        char:SetData("restricted", true)
        if restraintType then
            char:SetData("restraintType", restraintType)
        end
    else
        char:SetData("restricted", nil)
        char:SetData("restraintType", nil)
    end

    self:SyncRestraints(ply)
    self:SetRestraintMovement(ply, state)
end

function PLUGIN:SetRestraintMovement(ply, restricted)
    local char = IsValid(ply) and ply:GetCharacter()
    local stm = (char and char:GetAttribute("stm", 0)) or 0

    if restricted then
        ply:SetWalkSpeed((ix.config.Get("walkSpeed") + stm) * 0.5)
        ply:SetRunSpeed((ix.config.Get("runSpeed") + stm) * 0.5)
        ply:SetJumpPower(0)
    else
        ply:SetWalkSpeed(ix.config.Get("walkSpeed") + stm)
        ply:SetRunSpeed(ix.config.Get("runSpeed") + stm)
        ply:SetJumpPower(160)
    end
end

function PLUGIN:IsAuthorizedJailer(ply)
    return IsValid(ply) and (ply:Team() == FACTION_STAFF or ply:Team() == FACTION_INNERN)
end

-----------------------------------------------------------------
-- Hooks
-----------------------------------------------------------------
function PLUGIN:PlayerUse(ply, ent)
    if not (IsValid(ply) and IsValid(ent) and ply:IsPlayer() and ent:IsPlayer()) then return end
    if not self.InRange(ply, ent, 100) then return end

    if self:IsRestrained(ent) then
        net.Start("OpenCustodyMenu")
            net.WriteEntity(ent)
            net.WriteBool(true)
            net.WriteString(self:GetRestraintType(ent) or "")
        net.Send(ply)
        return false
    end
end

function PLUGIN:PlayerLoadedCharacter(ply, character)
    -- Migration from old vars
    if character:GetData("tied") then
        character:SetData("restricted", true)
        character:SetData("restraintType", "ties")
        character:SetData("tied", nil)
    elseif character:GetData("handcuffed") then
        character:SetData("restricted", true)
        character:SetData("restraintType", "cuffs")
        character:SetData("handcuffed", nil)
    end

    self:SyncRestraints(ply)
    self:SetRestraintMovement(ply, self:IsRestrained(ply))

    -- Jail restore from charData (connected‑only logic)
    local jail = character:GetData("activeJail")
    if jail and jail.time and jail.time > 0 then
        local elapsed = math.max(0, os.time() - (jail.start or os.time()))
        local remaining = math.max(0, jail.time - elapsed)
        if remaining > 0 then
            ply:SetNetVar("JailTime", remaining)
            ply:SetNetVar("JailReason", jail.reason or "")
            ply:SetNetVar("JailJudge", jail.judge or "")
            ply:SetNetVar("JailStartTime", os.time())
            local prisonerClass = ix.class.Get(CLASS_PRISONER)
            if prisonerClass then
                if ply:Team() ~= prisonerClass.faction then
                    char:SetFaction(prisonerClass.faction)
                end
                local oldClass = char:GetClass()
                char:SetClass(prisonerClass.index or CLASS_PRISONER)
                hook.Run("PlayerJoinedClass", ply, prisonerClass.index or CLASS_PRISONER, oldClass)
            else
                ply:Notify("Prisoner class not found.")
            end

            timer.Create("Release_" .. ply:SteamID(), remaining, 1, function()
                if IsValid(ply) then self:EndJailSentence(ply, "Completed") end
            end)
        else
            character:SetData("activeJail", nil)
        end
    end
end

function PLUGIN:OnCharacterDisconnect(client, character)
    if not character then return end
    local jailTime = client:GetNetVar("JailTime", 0)
    if jailTime > 0 then
        local elapsed = math.max(0, os.time() - (client:GetNetVar("JailStartTime") or os.time()))
        character:SetData("activeJail", {
            time = math.max(0, jailTime - elapsed),
            reason = client:GetNetVar("JailReason", ""),
            judge = client:GetNetVar("JailJudge", ""),
            start = os.time()
        })
    else
        character:SetData("activeJail", nil)
    end
end

-- RELEASE + ARCHIVE --------------------------------------------
function PLUGIN:EndJailSentence(ply, reason)
    local char = ply:GetCharacter()
    local now = os.time()

    -- Pull from NetVars for archive
    local startTime  = ply:GetNetVar("JailStartTime", now)
    local jailReason = ply:GetNetVar("JailReason", "")
    local jailJudge  = ply:GetNetVar("JailJudge", "")
    local steamID    = ply:SteamID()
    local name       = char and char:GetName() or ply:Nick()

    -- Pull from charData for original sentence length (in seconds)
    local activeData      = char and char:GetData("activeJail", {}) or {}
    local sentenceLength  = tonumber(activeData.originalSentence or activeData.time or 0) or 0

    -- Archive history, now including sentenceLength
    self:AddJailHistory(
        steamID,
        name,
        jailReason,
        jailJudge,
        startTime,
        now,
        reason or "Completed",
        sentenceLength
    )

    -- Clear charData
    if char then
        char:SetData("activeJail", nil)
    end

    -- Reset to citizen class
    local citizenClass = ix.class.Get(CLASS_CITIZEN)
    if citizenClass then
        if ply:Team() ~= citizenClass.faction then
            char:SetFaction(citizenClass.faction)
        end
        local oldClass = char:GetClass()
        char:SetClass(citizenClass.index or CLASS_CITIZEN)
        hook.Run("PlayerJoinedClass", ply, citizenClass.index or CLASS_CITIZEN, oldClass)
    else
        ply:Notify("Citizen class not found.")
    end

    -- Clear NetVars
    for _, key in ipairs({"JailTime", "JailReason", "JailJudge", "JailStartTime"}) do
        ply:SetNetVar(key, nil)
    end

    -- Kill release timer
    local tID = "Release_" .. steamID
    if timer.Exists(tID) then timer.Remove(tID) end

    ply:ChatPrint("Released from jail: " .. (reason or "Completed"))
    if not reason == "ESCAPED" then
        ply:Spawn()
    end
end

-- ESCAPE --------------------------------------------
PLUGIN.StoredEscapes = PLUGIN.StoredEscapes or {}

-- Save on shutdown / map cleanup
function PLUGIN:SaveEscapeTriggers()
    local data = {}
    for _, ent in ipairs(ents.FindByClass("ix_escapeblock")) do
        data[#data+1] = {
            pos = ent:GetPos(),
            ang = ent:GetAngles()
        }
    end
    ix.data.Set("escapeTriggers", data)
end

-- Load on init
function PLUGIN:LoadEscapeTriggers()
    local data = ix.data.Get("escapeTriggers", {})
    for _, v in ipairs(data) do
        local ent = ents.Create("ix_escapeblock")
        ent:SetPos(v.pos)
        ent:SetAngles(v.ang)
        ent:Spawn()
    end
end

-- Hook into IX lifecycle
function PLUGIN:SaveData()
    self:SaveEscapeTriggers()
end
function PLUGIN:LoadData()
    self:LoadEscapeTriggers()
end
