local PLUGIN = PLUGIN

-- Whitelist of fields the fake ID item allows
local FAKE_ID_ALLOWED = {
    name=true, dob=true, pob=true, blood=true, ethnicity=true,
    height=true, weight=true, hairColour=true, eyeColour=true,
    rank=true, job=true
}

local EXPECTED_ITEM_UID = "fake_id"

-- Save fake ID changes from client
netstream.Hook("ixSubmitIDData", function(ply, payload)
    if not IsValid(ply) or not istable(payload) then return end

    local itemID = tonumber(payload.itemID) or payload.itemID
    if not itemID then
        ply:Notify("No item ID provided.")
        return
    end

    local item = ix.item.instances[itemID]
    if not item then
        ply:Notify("ID item not found.")
        return
    end

    if item.uniqueID ~= EXPECTED_ITEM_UID then
        ply:Notify("Wrong item type.")
        return
    end

    local fields = istable(payload.fields) and payload.fields or {}

    -- Sanitize and clamp
    local cleaned = {}
    for k, v in pairs(fields) do
        if FAKE_ID_ALLOWED[k] then
            v = tostring(v or ""):Trim()
            if k == "name" then v = v:sub(1, 64) end
            if k == "job" then v = v:sub(1, 96) end
            cleaned[k] = v
        end
    end

    -- Sanitize and clamp
    local cleaned = {}
    for k, v in pairs(fields) do
        if FAKE_ID_ALLOWED[k] then
            v = tostring(v or ""):Trim()
            if k == "name" then v = v:sub(1, 64) end
            if k == "job" then v = v:sub(1, 96) end
            cleaned[k] = v
        end
    end

    -- Store ONLY the fields table
    item:SetData("fields", cleaned, false, false)

    -- Push update to owner immediately
    if item:HasPlayerOwner() and IsValid(item.player) then
        item:Sync(item.player)
    end

    ply:Notify("ID updated.")
end)

-- Permission check for editing others' identification
function PLUGIN:CanEditOthersIdentification(editor, targetChar)
    if not IsValid(editor) then return false end
    local editorChar = editor:GetCharacter()
    if not editorChar then return false end

    local requiredFlag = ix.config.Get("identityEditFlag", "I")
    if hook.Run("CanEditIdentification", editor, targetChar) == true then return true end
    if editor:IsStaff() then return true end
    if isfunction(editorChar.HasFlags) then
        return editorChar:HasFlags(requiredFlag)
    end

    return false
end

function PLUGIN:PlayerLoadedCharacter(client, character, prevCharacter)
    if not IsValid(client) or not character then return end

    -- Check identification completeness
    local identificationData = character:GetData("identification", {})
    local requiredFields = {
        "dob", "pob", "blood", "ethnicity", "height", "weight", "hairColour", "eyeColour"
    }

    local missingFields = {}
    for _, field in ipairs(requiredFields) do
        local value = identificationData[field]
        if not value or value == "" then
            table.insert(missingFields, field)
        end
    end

    if #missingFields > 0 then
        client:Notify("Please complete your identification details.")
        netstream.Start(client, "ixOpenIdentificationWindow", missingFields)
    end

    -- Ensure the player has the ID item
    local inventory = character:GetInventory()
    if not inventory then return end

    local hasDocuments = false
    for _, item in pairs(inventory:GetItems()) do
        if item.uniqueID == "personal_documents" then
            hasDocuments = true
            break
        end
    end

    if not hasDocuments then
        inventory:Add("personal_documents", 1)
    end
end

-- Save own identification (character data, not the fake ID item)
netstream.Hook("ixSubmitIdentificationData", function(client, payload)
    local character = IsValid(client) and client:GetCharacter()
    if not character then
        print("[Identification] Error: No character found for client!")
        return
    end

    if not payload or type(payload) ~= "table" or type(payload.identification) ~= "table" then
        print("[Identification] Error: Invalid payload structure!")
        return
    end

    local identificationData = character:GetData("identification") or {}
    for k, v in pairs(payload.identification) do
        if PLUGIN.ALLOWED_IDENT_FIELDS and PLUGIN.ALLOWED_IDENT_FIELDS[k] then
            identificationData[k] = v
        end
    end

    character:SetData("identification", identificationData, true)
    if isfunction(character.Save) then character:Save() end

    print(("[Identification] Saved identification data for %s: %s")
        :format(character:GetID(), util.TableToJSON(character:GetData("identification"))))
end)

-- Save changes to another character's identification
netstream.Hook("ixSubmitIdentificationDataForTarget", function(editor, payload)
    if not IsValid(editor) then return end

    if type(payload) ~= "table" or type(payload.identification) ~= "table" or not payload.targetCharID then
        print("[Identification] Error: Invalid editor payload.")
        return
    end

    local targetChar = ix.char.loaded and ix.char.loaded[payload.targetCharID]
    if not targetChar then
        editor:Notify("Target character is not available.")
        return
    end

    if not PLUGIN:CanEditOthersIdentification(editor, targetChar) then
        editor:Notify("You do not have permission to edit this character.")
        return
    end

    local identificationData = targetChar:GetData("identification") or {}
    for k, v in pairs(payload.identification) do
        if PLUGIN.ALLOWED_IDENT_FIELDS and PLUGIN.ALLOWED_IDENT_FIELDS[k] then
            identificationData[k] = v
        end
    end

    targetChar:SetData("identification", identificationData, true)
    if isfunction(targetChar.Save) then targetChar:Save() end

    local editorChar = editor:GetCharacter()
    local editorName = (editorChar and editorChar:GetName()) or editor:Nick() or "Unknown"

    local targetPly = targetChar:GetPlayer()
    if IsValid(targetPly) then
        targetPly:Notify("Your identification was updated by "..editorName..".")
    end
    editor:Notify("Saved identification for "..targetChar:GetName()..".")

    print(("[Identification] %s (%s) edited identification for charID %s: %s")
        :format(editorName, IsValid(editor) and editor:SteamID() or "N/A",
            tostring(targetChar:GetID()),
            util.TableToJSON(identificationData)))
end)

-- Centralised sender
function PLUGIN:SendPersonalDocuments(viewer, owner)
    if not IsValid(viewer) or not IsValid(owner) then return end

    local payload = self:BuildIdentificationPayload(owner)
    if not payload then return end

    local char = owner:GetCharacter()
    payload.model = char and char:GetModel() or ""

    print(("[Identification] Sending personal docs: model=%s to viewer=%s for owner=%s")
        :format(payload.model or "nil", viewer:Name(), owner:Name()))

    netstream.Start(viewer, "ixViewPersonalDocuments", payload)
end

netstream.Hook("ixRequestPersonalDocuments", function(client, data)
    local target = client
    if istable(data) and IsValid(data.ent) and data.ent:IsPlayer() then
        target = data.ent
    end

    PLUGIN:SendPersonalDocuments(client, target)
end)
