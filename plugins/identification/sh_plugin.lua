local PLUGIN = PLUGIN or {}

PLUGIN.name = "Identification"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Identification Document."

ix.util.Include("sv_plugin.lua", "server")

-- Allowed identification fields (persisted)
PLUGIN.ALLOWED_IDENT_FIELDS = {
    dob = true, pob = true, blood = true, ethnicity = true,
    height = true, weight = true, hairColour = true, eyeColour = true
}

if CLIENT then
    PLUGIN.backgroundMaterial = Material("vgui/scoreboard/scoreback.vmt")
end

-- Resolve rank via Class Rank plugin or fallback
local function ResolveRankName(char)
    if not char then return "Unranked", 0, 0 end
    local classID = char:GetClass()
    local rankUID = char:GetData("rankUID", 0)
    local rankName = "Unranked"

    if ix.classrank and isfunction(ix.classrank.GetName) then
        rankName = ix.classrank.GetName(classID, rankUID) or "Unranked"
    else
        for _, plug in pairs(ix.plugin.list or {}) do
            if isfunction(plug.GetRankFromUID) then
                rankName = plug:GetRankFromUID(classID, rankUID) or "Unranked"
                break
            end
        end
    end

    return rankName, rankUID, classID
end

-- Resolve job as "FactionName, ClassName" but split with newline
local function ResolveJob(char)
    if not char then return "Unknown Faction, Unknown Class" end
    local factionData = ix.faction.Get(char:GetFaction())
    local classData   = ix.class.Get(char:GetClass())
    local factionName = factionData and factionData.name or "Unknown Faction"
    local className   = classData and classData.name or "Unknown Class"
    return ("%s, %s"):format(factionName, className)
end

-- Server-side build of ID payload (rank, job injected)
function PLUGIN:BuildIdentificationPayload(owner)
    if not IsValid(owner) then return end
    local char = owner:GetCharacter()
    if not char then return end

    local identificationData = char:GetData("identification", {})
    local rankName = ResolveRankName(char)
    local jobName  = ResolveJob(char)

    local idCopy = {}
    for k, v in pairs(identificationData) do
        idCopy[k] = v
    end

    idCopy.rank = rankName
    idCopy.job  = jobName

    return {
        name = char:GetName() or owner:Nick(),
        identification = idCopy
    }
end

-- Delegate OpenPersonalDocuments to the central sender
function PLUGIN:OpenPersonalDocuments(viewer, owner)
    if SERVER then
        self:SendPersonalDocuments(viewer, owner)
    end
end

-- Command: Edit your own identification
local IDENTITY_FIELDS = {
    "dob", "pob", "blood", "ethnicity", "height", "weight", "hairColour", "eyeColour"
}

-- Command: Edit only missing fields
ix.command.Add("EditMissingIdentityDocs", {
    description = "Opens the identification window to fill in missing details only.",
    adminOnly = false,
    arguments = {},
    OnRun = function(self, client)
        local character = client:GetCharacter()
        if not character then
            client:Notify("You do not have a valid character!")
            return
        end

        local missing = {}
        local ident = character:GetData("identification", {})

        for _, field in ipairs(IDENTITY_FIELDS) do
            local val = ident[field]
            if not val or val == "" then
                table.insert(missing, field)
            end
        end

        if #missing > 0 then
            netstream.Start(client, "ixOpenIdentificationWindow", missing)
        else
            client:Notify("All identification details are already filled in!")
        end
    end
})

-- Command: Edit all fields regardless of current values
ix.command.Add("EditAllIdentityDocs", {
    description = "Opens the identification window to edit all details, even if already set.",
    adminOnly = false,
    arguments = {},
    OnRun = function(self, client)
        local character = client:GetCharacter()
        if not character then
            client:Notify("You do not have a valid character!")
            return
        end

        local ident = character:GetData("identification", {})
        local dataToSend = {}

        -- Build key/value table with current values (or empty string if none)
        for _, field in ipairs(IDENTITY_FIELDS) do
            dataToSend[field] = ident[field] or ""
        end

        -- Send the full dataset to the UI
        netstream.Start(client, "ixOpenIdentificationWindow", dataToSend)
    end
})
