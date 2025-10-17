local PLUGIN = PLUGIN or {}

PLUGIN.name = "Class Rank Management"
PLUGIN.description = "Allows Class Leaders to manage class ranks across class hierarchies and includes salary payout logic."
PLUGIN.author = "Dzhey Kashta"

-- Include shared rank definitions
local rankData = ix.util.Include("sh_ranks.lua", "shared")
PLUGIN.classRanks = rankData.RANKS
PLUGIN.defaultRanks = rankData.DEFAULT_RANKS

-- Include server/client logic
ix.util.Include("sh_commands.lua", "shared")
ix.util.Include("sv_networking.lua", "server")
ix.util.Include("sv_plugin.lua", "server")
ix.util.Include("cl_plugin.lua", "client")


-- Config: Salary payout interval
ix.config.Add("salaryPayTimer", 300, "Time for Salary Payouts.", nil, {
    data = {min = 60, max = 43200},
    category = PLUGIN.name
})

PLUGIN.managedClasses = {
    CLASS_HOUSE,     -- Imperial German Household
    CLASS_GEN,       -- General Officers
    CLASS_HUSAR,     -- Husaren
    CLASS_GARDE,     -- Garde / Garde-Grenadiers
    CLASS_ARMYMED,   -- Army Medical
    CLASS_ARMYJUS,   -- Army Justice
    CLASS_SHU,       -- Schutzpolizei
    CLASS_KPA,       -- Kriminalpolizeiamt
    CLASS_GP,        -- Geheimpolizei
    CLASS_IM,        -- Interior Ministry
    CLASS_PIM,
    CLASS_POLPRAS,
    CLASS_SFOREIGN,
    CLASS_SKFA,
    CLASS_SMARINE,
    CLASS_SJUST,

    -- Courts & Prosecution Offices
    CLASS_AMTSGER,
    CLASS_AMTSANW,   -- Amtsanwaltschaft
    CLASS_LANDGER,
    CLASS_LANDANW,   -- Staatsanwaltschaft beim Landgericht
    CLASS_OBLANDGER,
    CLASS_OBLANW,    -- Oberstaatsanwaltschaft beim Oberlandesgericht
    CLASS_KAMGER,
    CLASS_KAMANW,    -- Generalstaatsanwaltschaft beim Kammergericht
    CLASS_REICHGER,
    CLASS_REICHANW,  -- Reichsanwaltschaft beim Reichsgericht

    CLASS_SCOLON,
    CLASS_KAB,       -- Imperial Cabinet
    CLASS_BUND,      -- Bundesrat

    -- Bundesrat Standing Committees
    CLASS_AHF,       -- Ausschuss für das Landheer und die Festungen
    CLASS_ASW,       -- Ausschuss für das Seewesen
    CLASS_AZS,       -- Ausschuss für das Zoll- und Steuerwesen
    CLASS_AHV,       -- Ausschuss für Handel und Verkehr
    CLASS_AJW,       -- Ausschuss für Justizwesen
    CLASS_ARW,       -- Ausschuss für Rechnungswesen
    CLASS_AAA,       -- Ausschuss für Auswärtige Angelegenheiten

    CLASS_REICH,     -- Reichstag Leadership
    CLASS_REICHKAN,
    CLASS_FOREIGN,   -- Foreign Office
    CLASS_KFA,       -- Finance Office
    CLASS_MARINE,    -- Naval Office
    CLASS_COLON,     -- Colonial Office
    CLASS_SMAW,
    CLASS_MAW,        -- Labor & Economics

    -- Prussian Ministry of Spiritual,
    --- Educational, and Medical Affairs
    CLASS_SEDU,
    CLASS_MEDU,
    CLASS_GEDU,
    CLASS_UEDU,
    CLASS_SUEDU,
    CLASS_FWU

}

PLUGIN.classManagementMap = {
--- House
    [CLASS_HOUSE] = {
        CLASS_GEN,
        CLASS_HUSAR,
        CLASS_GARDE,
        CLASS_ARMYMED,
        CLASS_ARMYJUS,

        CLASS_SHU,
        CLASS_KPA,
        CLASS_GP,
        CLASS_IM,
        CLASS_PIM,
        CLASS_POLPRAS,

        CLASS_SFOREIGN,
        CLASS_SKFA,
        CLASS_SMARINE,

        CLASS_SJUST,

        CLASS_AMTSGER,
        CLASS_AMTSANW,

        CLASS_LANDGER,
        CLASS_LANDANW,

        CLASS_OBLANDGER,
        CLASS_OBLANW,

        CLASS_KAMGER,
        CLASS_KAMANW,

        CLASS_REICHGER,
        CLASS_REICHANW,

        CLASS_SCOLON,
        CLASS_KAB,
        CLASS_BUND,

        CLASS_AHF,
        CLASS_ASW,
        CLASS_AZS,
        CLASS_AHV,
        CLASS_AJW,
        CLASS_ARW,
        CLASS_AAA,

        CLASS_REICHKAN,
        CLASS_REICH,
        CLASS_FOREIGN,
        CLASS_KFA,
        CLASS_MARINE,
        CLASS_COLON,
        CLASS_SMAW,
        CLASS_MAW,

        CLASS_SEDU,
        CLASS_MEDU,
        CLASS_GEDU,
        CLASS_UEDU,
        CLASS_SUEDU,
        CLASS_FWU
    },
--- Army
    [CLASS_GEN]     = { CLASS_HUSAR, CLASS_GARDE, CLASS_ARMYMED, CLASS_ARMYJUS },
    [CLASS_HUSAR]   = {},
    [CLASS_GARDE]   = {},
    [CLASS_ARMYMED] = {},
    [CLASS_ARMYJUS] = {},
--- Police
    [CLASS_PIM]     = { CLASS_POLPRAS, CLASS_SHU, CLASS_KPA, CLASS_GP, CLASS_IM },
    [CLASS_IM]      = {},
    [CLASS_POLPRAS] = { CLASS_KPA, CLASS_GP, CLASS_SHU },
    [CLASS_SHU]     = {},
    [CLASS_KPA]     = {},
    [CLASS_GP]      = {},
--- Royal Cabinet
    [CLASS_KAB]     = {},
--- Justice
    [CLASS_SJUST] = {
        CLASS_AMTSGER,
        CLASS_AMTSANW,
        CLASS_LANDGER,
        CLASS_LANDANW,
        CLASS_OBLANDGER,
        CLASS_OBLANW,
        CLASS_KAMGER,
        CLASS_KAMANW,
        CLASS_REICHGER,
        CLASS_REICHANW
    },
    [CLASS_AMTSGER]  = {},
    [CLASS_AMTSANW]  = { CLASS_AMTSGER },
    [CLASS_LANDGER]  = { CLASS_AMTSGER },
    [CLASS_LANDANW]  = { CLASS_LANDGER, CLASS_AMTSGER },
    [CLASS_OBLANDGER] = { CLASS_LANDGER, CLASS_AMTSGER },
    [CLASS_OBLANW]    = { CLASS_OBLANDGER, CLASS_LANDGER, CLASS_AMTSGER },
    [CLASS_KAMGER]   = { CLASS_OBLANDGER, CLASS_LANDGER, CLASS_AMTSGER },
    [CLASS_KAMANW]   = { CLASS_KAMGER, CLASS_OBLANDGER, CLASS_LANDGER, CLASS_AMTSGER },
    [CLASS_REICHGER]  = { CLASS_KAMGER, CLASS_OBLANDGER, CLASS_LANDGER, CLASS_AMTSGER },
    [CLASS_REICHANW]  = { CLASS_REICHGER, CLASS_KAMGER, CLASS_OBLANDGER, CLASS_LANDGER, CLASS_AMTSGER },
--- Foreign
    [CLASS_FOREIGN] = {},
    [CLASS_SFOREIGN] = { CLASS_FOREIGN },
--- Finance
    [CLASS_KFA]     = {},
    [CLASS_SKFA]     = { CLASS_KFA },
--- Marine
    [CLASS_MARINE]  = {},
    [CLASS_SMARINE]  = { CLASS_MARINE },
--- Colonial
    [CLASS_SCOLON]   = { CLASS_COLON },
    [CLASS_COLON]   = {},
--- Reich Kanzler
    [CLASS_REICHKAN] = { 
        -- Foreign
        CLASS_FOREIGN,
        CLASS_SFOREIGN,
        -- Finance
        CLASS_SKFA,
        CLASS_KFA,
        -- Marine
        CLASS_SMARINE,
        CLASS_MARINE,
        -- Colonial
        CLASS_SCOLON,
        CLASS_COLON,

        CLASS_SEDU,
        CLASS_MEDU,
        CLASS_GEDU,
        CLASS_UEDU,
        CLASS_SUEDU,
        CLASS_FWU,
        --[[ Justice
        CLASS_SJUST,
        CLASS_AMTSGER,
        CLASS_AMTSANW,
        CLASS_LANDGER,
        CLASS_LANDANW,
        CLASS_OBLANDGER,
        CLASS_OBLANW,
        CLASS_KAMGER,
        CLASS_KAMANW,
        CLASS_REICHGER,
        CLASS_REICHANW,]]--
        -- Kabinet
        CLASS_KAB,
        -- Reichstag
        CLASS_REICH,
        -- Bundestat
        CLASS_BUND,
        CLASS_AHF,
        CLASS_ASW,
        CLASS_AZS,
        CLASS_AHV,
        CLASS_AJW,
        CLASS_ARW,
        CLASS_AAA 
    },
--- Reichstag
    [CLASS_REICH] = {},
--- Bundestat
    [CLASS_BUND] = { 
        CLASS_AHF,
        CLASS_ASW,
        CLASS_AZS,
        CLASS_AHV,
        CLASS_AJW,
        CLASS_ARW,
        CLASS_AAA 
    },
    [CLASS_AHF] = {},
    [CLASS_ASW] = {},
    [CLASS_AZS] = {},
    [CLASS_AHV] = {},
    [CLASS_AJW] = {},
    [CLASS_ARW] = {},
    [CLASS_AAA] = {},
--- ------------------
    [CLASS_SMAW]     = { CLASS_MAW },
    [CLASS_MAW]     = {},
--- ------------------
    [CLASS_SEDU] = {
        CLASS_MEDU,
        CLASS_GEDU,
        CLASS_UEDU,
        CLASS_SUEDU,
        CLASS_FWU
    },
    [CLASS_MEDU] = {},
    [CLASS_GEDU] = {},
    [CLASS_UEDU] = {},
    [CLASS_SUEDU] = {
        CLASS_FWU, 
        CLASS_UEDU
    },
    [CLASS_FWU] = {}
}

-- Utility: is this a managed class?
function PLUGIN:IsManagedClass(classID)
    return classID and table.HasValue(self.managedClasses, classID)
end

-- Utility: can one class manage another?
function PLUGIN:CanManageClass(managerClass, targetClass)
    if managerClass == targetClass then return true end
    local managed = self.classManagementMap[managerClass]
    return managed and table.HasValue(managed, targetClass) or false
end

-- Get all ranks for a class
function PLUGIN:GetClassRanks(classID)
    return self.classRanks[classID] or self.defaultRanks
end

-- Get numeric index of a rankUID in its class
function PLUGIN:GetRankIndex(classID, rankUID)
    if not self:IsManagedClass(classID) then return nil end

    local sortedUIDs = {}
    for _, data in pairs(self:GetClassRanks(classID)) do
        table.insert(sortedUIDs, data.uid)
    end
    table.sort(sortedUIDs)

    for i, uid in ipairs(sortedUIDs) do
        if uid == rankUID then
            return i
        end
    end
end

-- Translate rankUID -> displayName
function PLUGIN:GetRankFromUID(classID, rankUID)
    local data = self:GetRankData(classID, rankUID)
    return data and data.displayName or "Unranked"
end

-- Rank permissions lookup
function PLUGIN:GetRankPermissions(classID, rankUID)
    if not self:IsManagedClass(classID) then return {} end

    for _, data in pairs(self:GetClassRanks(classID)) do
        if data.uid == rankUID then
            return data
        end
    end
    return {}
end

-- Compare two players’ rank for action validity
function PLUGIN:CanAffectTarget(actor, target)
    local actorChar = actor:GetCharacter()
    local targetChar = target:GetCharacter()
    if not actorChar or not targetChar then return false end

    local actorRank  = actorChar:GetData("rankUID", 1)
    local targetRank = targetChar:GetData("rankUID", 1)
    return actorRank > targetRank
end

-- Check if a player can perform a specific action
function PLUGIN:CanPerformAction(ply, action)
    local char = ply:GetCharacter()
    if not char then return false end

    local classID = char:GetClass()
    local rankUID = char:GetData("rankUID", 0)

    local permissions = self:GetRankPermissions(classID, rankUID)
    return permissions[action] == true
end

-- Get rank key from UID
function PLUGIN:GetRankKeyFromUID(classID, rankUID)
    local classRanks = self.classRanks[classID]
    if not classRanks then return end

    for key, data in pairs(classRanks) do
        if data.uid == rankUID then
            return key
        end
    end
end

-- Get full rank data table from UID
function PLUGIN:GetRankData(classID, rankUID)
    local classRanks = self.classRanks[classID]
    if not classRanks then return end

    for _, data in pairs(classRanks) do
        if data.uid == rankUID then
            return data
        end
    end
end

-- Return ordered list of ranks for a class
function PLUGIN:GetOrderedRanks(classID)
    local rawRanks = self.classRanks[classID]
    if not rawRanks then return {} end

    local ordered = {}

    for _, rankData in pairs(rawRanks) do
        table.insert(ordered, rankData)
    end

    table.sort(ordered, function(a, b)
        return a.uid < b.uid
    end)

    return ordered
end

-- Get next rank UID in a class hierarchy
function PLUGIN:GetNextRank(classID, currentUID, direction)
    local ranks = self:GetOrderedRanks(classID)
    if #ranks == 0 then return nil end

    local currentRank = self:GetRankData(classID, currentUID)
    if not currentRank then
        if server then print("Rank not found") end
        return nil
    end

    local currentIndex
    for i, rank in ipairs(ranks) do
        if rank.uid == currentUID then
            currentIndex = i
            break
        end
    end

    if not currentIndex then
        if server then print("Rank Index not found") end
        return nil
    end

    local nextIndex = currentIndex + direction
    if nextIndex < 1 or nextIndex > #ranks then
        return nil
    end

    local nextRank = ranks[nextIndex]
    return nextRank and nextRank.uid or nil
end

-- Get salary tied to a specific rank
function PLUGIN:GetRankSalary(classID, rankUID)
    if not self:IsManagedClass(classID) then return 0 end

    for _, data in pairs(self:GetClassRanks(classID)) do
        if data.uid == rankUID then
            return data.salary or 0
        end
    end
    return 0
end
