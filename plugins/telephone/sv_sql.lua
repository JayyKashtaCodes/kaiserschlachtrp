local PLUGIN = PLUGIN

-- Create the table when the server starts
function PLUGIN:DatabaseConnected()
    local query = mysql:Create("ix_telephones")
    query:Create("id", "INT(11) UNSIGNED NOT NULL")
    query:Create("number", "VARCHAR(16) NOT NULL UNIQUE")
    query:Create("pos_x", "FLOAT NOT NULL")
    query:Create("pos_y", "FLOAT NOT NULL")
    query:Create("pos_z", "FLOAT NOT NULL")
    query:Create("ang_p", "FLOAT NOT NULL DEFAULT 0")
    query:Create("ang_y", "FLOAT NOT NULL DEFAULT 0")
    query:Create("ang_r", "FLOAT NOT NULL DEFAULT 0")
    query:PrimaryKey("id")
    query:Execute()

    print("[Telephones] ix_telephones table initialised via MySQL")
end

-- Load saved telephones into the map after entities are initialized
function PLUGIN:InitPostEntity()
    -- Ensure table exists / is up to date
    self:DatabaseConnected()

    timer.Simple(1, function()
        local query = mysql:Select("ix_telephones")
        query:Select("id")
        query:Select("number")
        query:Select("pos_x")
        query:Select("pos_y")
        query:Select("pos_z")
        query:Select("ang_p")
        query:Select("ang_y")
        query:Select("ang_r")
        query:Callback(function(rows)
            if not istable(rows) or #rows == 0 then
                print("[Telephones] No saved telephones found.")
                return
            end

            for _, row in ipairs(rows) do
                local ent = ents.Create("ix_telephone")
                if not IsValid(ent) then continue end

                ent:SetPos(Vector(
                    tonumber(row.pos_x) or 0,
                    tonumber(row.pos_y) or 0,
                    tonumber(row.pos_z) or 0
                ))

                ent:SetAngles(Angle(
                    tonumber(row.ang_p) or 0,
                    tonumber(row.ang_y) or 0,
                    tonumber(row.ang_r) or 0
                ))

                ent.number = row.number
                ent.dbID = tonumber(row.id)
                ent.fromDatabase = true

                ent:Spawn()
                ent:Activate()

                self:RegisterTelephone(ent.number, ent)
            end

            print(("[Telephones] Loaded %d telephones from database."):format(#rows))
        end)
        query:Execute()
    end)
end

-- Find the next available ID
function PLUGIN:GetNextAvailableID(callback)
    local query = mysql:Select("ix_telephones")
    query:Select("id")
    query:Callback(function(results)
        local used = {}
        for _, row in ipairs(results) do
            local id = tonumber(row.id)
            if id then used[id] = true end
        end

        for i = 1, #results + 1 do
            if not used[i] then
                callback(i)
                return
            end
        end
    end)
    query:Execute()
end

-- Save or update a telephone entry
function PLUGIN:SaveTelephone(entity)
    if not IsValid(entity) then return end

    local pos = entity:GetPos()
    local ang = entity:GetAngles()

    if entity.dbID then
        -- UPDATE existing row
        local query = mysql:Update("ix_telephones")
        query:Update("number", entity.number)
        query:Update("pos_x", pos.x)
        query:Update("pos_y", pos.y)
        query:Update("pos_z", pos.z)
        query:Update("ang_p", ang.p)
        query:Update("ang_y", ang.y)
        query:Update("ang_r", ang.r)
        query:Where("id", entity.dbID)
        query:Execute()
    else
        -- INSERT new row
        self:GetNextAvailableID(function(nextID)
            local query = mysql:Insert("ix_telephones")
            query:Insert("id", nextID)
            query:Insert("number", entity.number)
            query:Insert("pos_x", pos.x)
            query:Insert("pos_y", pos.y)
            query:Insert("pos_z", pos.z)
            query:Insert("ang_p", ang.p)
            query:Insert("ang_y", ang.y)
            query:Insert("ang_r", ang.r)
            query:Execute()

            entity.dbID = nextID
        end)
    end
end

-- Delete a telephone entry
function PLUGIN:DeleteTelephone(ent)
    if not IsValid(ent) or not ent.dbID then return end

    local deleteQuery = mysql:Delete("ix_telephones")
    deleteQuery:Where("id", ent.dbID)
    deleteQuery:Execute()
end
