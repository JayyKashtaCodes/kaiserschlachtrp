local PLUGIN = PLUGIN

ITEM.name = "Personal Documents"
ITEM.uniqueID = "personal_documents"
ITEM.description = "Personal Identity Documents."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Identification"
ITEM.bDropOnDeath = false
ITEM.CanDrop = false

function ITEM:CanDrop(client)
    return false
end

local function ForceShowID(officer, target)
    if not (IsValid(officer) and officer:IsPlayer()) then return end
    if not (IsValid(target) and target:GetCharacter()) then
        officer:Notify("Invalid target.")
        return
    end

    local idItem = target:GetCharacter():GetInventory():HasItem("personal_documents")
    if not idItem then
        officer:Notify(target:Name() .. " has no ID card.")
        return
    end

    local payload = BuildIDPayload(target)
    if not payload then
        officer:Notify("No personal identification data available.")
        return
    end

    netstream.Start(officer, "ixViewPersonalDocuments", payload)

    officer:Notify("You review " .. target:Name() .. "'s ID.")
    target:Notify(officer:Name() .. " has reviewed your ID.")
end

-- Helper function to build identification payload
-- This is used to create a consistent payload for both self-viewing and showing to others
local function BuildIDPayload(owner)
    local char = owner:GetCharacter()
    if not char then return nil end

    local idData = table.Copy(char:GetData("identification", {}))

    -- Rank
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
    idData.rank = rankName

    -- Job
    local factionData = ix.faction.Get(char:GetFaction())
    local classData   = ix.class.Get(classID)
    idData.job = ("%s, %s"):format(
        factionData and factionData.name or "Unknown Faction",
        classData and classData.name or "Unknown Class"
    )

    -- Always include the current model
    return {
        name = char:GetName(),
        identification = idData,
        model = char:GetModel() or "models/error.mdl"
    }
end

ITEM.functions.ViewInfo = {
    OnRun = function(itemTable)
        local player = itemTable.player
        local payload = BuildIDPayload(player)
        if not payload then
            player:Notify("No personal identification data available.")
            return false
        end
        netstream.Start(player, "ixViewPersonalDocuments", payload)
        return false
    end
}

ITEM.functions.ShowToTarget = {
    name = "Show Papers",
    OnRun = function(itemTable)
        local player = itemTable.player
        local trace  = player:GetEyeTrace()
        local target = trace.Entity

        if not IsValid(target) or not target:IsPlayer() or target:GetPos():Distance(player:GetPos()) > 100 then
            player:Notify("You're not looking at a valid player.")
            return false
        end
        if target.nextPaperOpen and target.nextPaperOpen > CurTime() then
            player:Notify("They're already viewing papers.")
            return false
        end
        target.nextPaperOpen = CurTime() + 5

        local payload = BuildIDPayload(player)
        if not payload then
            player:Notify("No personal identification data available.")
            return false
        end

        netstream.Start(target, "ixViewPersonalDocuments", payload)
        player:Notify("You showed your papers to " .. target:Nick() .. ".")
        return false
    end
}

ITEM.functions.ForceShow = {
    OnRun = function(item)
        local owner = item:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then return false end

        local ply = item.player
        if (ply == owner) then
            ply:Notify("You cannot force view your own documents.")
            return false
        end
        ForceShowID(ply, owner)

        return false
    end
}

ITEM.functions.drop = {
    OnRun = function(itemTable)
        return false
    end
}
