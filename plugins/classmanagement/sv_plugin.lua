local PLUGIN = PLUGIN

function PLUGIN:SendClassRoster(client)
    local rosterData = {}

    for _, ply in ipairs(player.GetAll()) do
        local char = ply:GetCharacter()
        if not char then continue end

        local classID = char:GetClass()
        local rankUID = char:GetData("rankUID", 0)

        table.insert(rosterData, {
            name = ply:Nick(),
            steamID = ply:SteamID(),
            classID = classID,
            rankUID = rankUID
        })
    end

    net.Start("ixClassRosterSync")
        net.WriteUInt(#rosterData, 8)
        for _, entry in ipairs(rosterData) do
            net.WriteString(entry.name)
            net.WriteString(entry.steamID)
            net.WriteUInt(entry.classID, 8)
            net.WriteUInt(math.Clamp(entry.rankUID or 0, 0, 255), 8)
        end
    net.Send(client)
end

-- Salary Payout Logic
function PLUGIN:PaySalaries()
    for _, ply in ipairs(player.GetAll()) do
        local char = ply:GetCharacter()
        if not char then continue end

        local classID = char:GetClass()
        if not self:IsManagedClass(classID) then continue end

        local rankUID = char:GetData("rankUID", 1)
        local salaryDollars = tonumber(self:GetRankSalary(classID, rankUID)) or 0

        if salaryDollars > 0 then
            -- Notify in dollars (human-friendly)
            ply:Notify("[Salary Payment]: " .. ix.currency.Get(salaryDollars))

            -- Accrue in cents (precision-safe)
            local currentCents = tonumber(char:GetData("salaryBuffer", 0)) or 0
            char:SetData("salaryBuffer", currentCents + ix.currency.ToCents(salaryDollars), 0)
        end
    end
end

function PLUGIN:InitializedConfig()
    timer.Create("ixSalaryDispenser", ix.config.Get("salaryPayTimer"), 0, function()
        self:PaySalaries()
    end)
end

-- Character Load Hook
function PLUGIN:CharacterLoaded(character)
    local classID = character:GetClass()
    local rankUID = character:GetData("rankUID")
    if not self:IsManagedClass(classID) or rankUID == nil then return end
    
    local rankName = self:GetRankFromUID(classID, rankUID)
    --print("[CLASS RANK] " .. character:GetName() .. " loaded with rank: " .. rankName)
end
