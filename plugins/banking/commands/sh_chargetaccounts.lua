local COMMAND = {}

COMMAND.superAdminOnly = true
COMMAND.description = "@bankingCmdCharGetAccounts"
COMMAND.arguments = {ix.type.character}
COMMAND.OnRun = function(self, client, targetCharacter)
    if not ix.banking.accountsByChar[targetCharacter:GetID()] then
        return "@bankingNotifyCharNoAccounts"
    end

    local data = {}
    local missingNames = {}
    for k, v in pairs(ix.banking.accountsByChar[targetCharacter:GetID()]) do
        local bMissingOwnerName = false
        local ownerID, ownerName = v:GetOwner(), "Missing Name"
        if ownerID then
            if ix.char.loaded[ownerID] then
                ownerName = ix.char.loaded[ownerID]:GetName()
            else
                missingNames[ownerID] = true
            end
        else
            ownerID = 0
            ownerName = "No Owner"
        end

        local accountHolders = {}
        for k, v in pairs(v.accountHolders) do
            local name = "Missing Name"
            if ix.char.loaded[k] then
                name = ix.char.loaded[k]:GetName()
            else
                missingNames[k] = true
            end

            accountHolders[k] = {permissions = v, name = name}
        end

        table.insert(data, {ownerID = ownerID, ownerName = ownerName, id = v:GetID(), name = v:GetName(), money = v:GetMoney(), accountHolders = accountHolders})
    end

    local function sendNet()
        net.Start("ixBankingGetAccounts")
            net.WriteUInt(targetCharacter:GetID(), 32)
            net.WriteUInt(#data, 10)
            for i = 1, #data do
                local entry = data[i]
                net.WriteUInt(entry.ownerID, 32)
                net.WriteString(entry.ownerName)
                net.WriteUInt(entry.id, 32)
                net.WriteString(entry.name)
                net.WriteUInt(entry.money, 32)
                net.WriteTable(entry.accountHolders)
            end
        net.Send(client)
    end

    if table.Count(missingNames) > 0 then
        local query = mysql:Select("ix_characters")
            query:Select("id")
            query:Select("name")
            query:WhereIn("id", table.GetKeys(missingNames))
            query:Callback(function(result)
                if result and #result > 0 then
                    for k, v in ipairs(result) do
                        for k2, v2 in ipairs(data) do
                            if tonumber(v.id) == v2.ownerID then
                                data[k2].ownerName = v.name
                                break
                            elseif v2.accountHolders[tonumber(v.id)] then
                                data[k2].accountHolders[tonumber(v.id)].name = v.name
                                break
                            end
                        end
                    end
                end

                sendNet()
            end)
        query:Execute()
    else
        sendNet()
    end

    return "@bankingNotifyViewConsole"
end

ix.command.Add("CharGetAccounts", COMMAND)