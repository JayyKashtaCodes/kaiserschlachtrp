local PLUGIN = PLUGIN or {}
local tiePlugin = ix.plugin.list["tyingoverhauled"]

PLUGIN.name = "Jail System"
PLUGIN.description = "Arrest, sentencing and custody."
PLUGIN.author = "Dzhey Kashta"

ix.util.Include("sv_plugin.lua", "server")
ix.util.Include("sv_networking.lua", "server")
ix.util.Include("sv_sql.lua", "server")
ix.util.Include("cl_plugin.lua", "client")

-- -------------------------
-- Helpers
-- -------------------------
local function getChar(ply)
    return IsValid(ply) and ply.GetCharacter and ply:GetCharacter() or nil
end

function PLUGIN:IsRestrained(ply)
    local char = getChar(ply)
    return char and char:GetData("restricted") == true or false
end

function PLUGIN:GetRestraintType(ply)
    local char = getChar(ply)
    return char and char:GetData("restraintType") or nil
end

function PLUGIN:SyncRestraints(ply)
    if IsValid(ply) then
        ply:SetNetVar("restricted", self:IsRestrained(ply) or nil)
        ply:SetNetVar("restraintType", self:GetRestraintType(ply) or "")
    end
end

-- state=true + type ("cuffs"/"ties")
function PLUGIN:SetRestricted(ply, state, restraintType)
    local char = getChar(ply)
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

-- Apply/Restore Movement
function PLUGIN:SetRestraintMovement(ply, restricted)
    local char = getChar(ply)
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

-- Generic applying of any restraint type
function PLUGIN:PerformRestraintAction(ply, target, restraintType, duration, soundPath, onSuccess, onFail)
    self:SetRestraintMovement(target, true)

    ply:SetAction("Applying " .. restraintType .. "...", duration)

    if soundPath then
        sound.Play(soundPath, target:GetPos(), 75, 100, 1)
    end

    ply:DoStaredAction(target,
        function()
            self:SetRestricted(target, true, restraintType)
            target:SelectWeapon("ix_hands")
            if isfunction(onSuccess) then onSuccess() end
        end,
        duration,
        function()
            if isfunction(onFail) then onFail() end
        end
    )
end

-- -------------------------
-- Jail System Core (CharacterData only)
-- -------------------------

-- Jail a character for a set number of seconds
function PLUGIN:JailCharacter(char, seconds, reason, officer)
    if not char then return end

    char:SetData("JailTime", seconds)
    char:SetData("JailStartTime", os.time())
    char:SetData("JailReason", reason or "N/A")
    char:SetData("JailOfficer", officer or "N/A")

    local ply = char:GetPlayer()
    if IsValid(ply) then
        self:SetRestricted(ply, true, "cuffs")
        -- TODO: Teleport to cell position here
        ply:SetNetVar("JailTime", seconds)
        ply:SetNetVar("JailStartTime", os.time())
    end
end

-- Release a character from jail
function PLUGIN:ReleaseFromJail(target)
    local char = IsEntity(target) and target:GetCharacter() or target
    if not char then return end

    char:SetData("JailTime", 0)
    char:SetData("JailStartTime", 0)
    char:SetData("JailReason", nil)
    char:SetData("JailOfficer", nil)

    local ply = char:GetPlayer()
    if IsValid(ply) then
        self:SetRestricted(ply, false)
        ply:SetNetVar("JailTime", 0)
        ply:SetNetVar("JailStartTime", 0)
        -- TODO: Teleport to release location here
    end
end

-- Active jail checks (online only)
function PLUGIN:GetActiveJails()
    local results = {}
    for _, ply in ipairs(player.GetAll()) do
        local char = ply:GetCharacter()
        if char and char:GetData("JailTime", 0) > 0 then
            local start = char:GetData("JailStartTime", 0)
            local remaining = math.max(0, char:GetData("JailTime") - (os.time() - start))
            if remaining > 0 then
                table.insert(results, {
                    name = char:GetName(),
                    reason = char:GetData("JailReason") or "N/A",
                    officer = char:GetData("JailOfficer") or "N/A",
                    remaining = remaining
                })
            end
        end
    end
    return results
end

-- Periodic enforcement
function PLUGIN:Think()
    for _, ply in ipairs(player.GetAll()) do
        local char = ply:GetCharacter()
        if char then
            local jailTime = char:GetData("JailTime", 0)
            if jailTime > 0 then
                local start = char:GetData("JailStartTime", 0)
                if os.time() >= start + jailTime then
                    self:ReleaseFromJail(ply)
                end
            end
        end
    end
end

-- Escape Commands
ix.command.Add("AddEscapeTrigger", {
    adminOnly = true,
    arguments = {},
    OnRun = function(self, client)
        if !client:IsOwner() then
            client:Notify("You cannot use that command.")
        end

        local ent = ents.Create("ix_escapeblock")
        ent:SetPos(client:GetPos())
        ent:SetAngles(client:GetAngles())
        ent:Spawn()
        PLUGIN:SaveEscapeTriggers()
        return "Created escape trigger."
    end
})

ix.command.Add("RemoveEscapeTrigger", {
    adminOnly = true,
    arguments = {},
    OnRun = function(self, client)
        if !client:IsOwner() then
            client:Notify("You cannot use that command.")
        end

        local removed = 0
        local plyPos = client:GetPos()

        -- Iterate over all escape triggers
        for _, ent in ipairs(ents.FindByClass("ix_escapeblock")) do
            if plyPos:DistToSqr(ent:GetPos()) < (64 ^ 2) then
                ent:Remove()
                removed = removed + 1
            end
        end

        if removed > 0 then
            PLUGIN:SaveEscapeTriggers()
            return "Removed " .. removed .. " escape trigger(s) at your location."
        else
            return "No escape trigger found where you are standing."
        end
    end
})


ix.command.Add("RemoveAllEscapeTriggers", {
    adminOnly = true,
    OnRun = function(self, client)
        if !client:IsOwner() then
            client:Notify("You cannot use that command.")
        end

        for _, ent in ipairs(ents.FindByClass("ix_escapeblock")) do
            ent:Remove()
        end

        PLUGIN:SaveEscapeTriggers()
        return "All escape triggers removed."
    end
})
