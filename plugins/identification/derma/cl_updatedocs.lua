netstream.Hook("ixOpenIdentificationWindow", function(incoming)
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 650)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame.Paint = function(self, w, h)
        surface.SetDrawColor(30, 30, 30, 255)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    local scrollPanel = vgui.Create("DScrollPanel", frame)
    scrollPanel:Dock(FILL)

    -- Canonical order for consistent layout
    local CANON_ORDER = {
        "dob", "pob", "blood", "ethnicity", "eyeColour", "hairColour", "height", "weight"
    }

    -- Options and headings
    local options = {
        blood = {"A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"},
        eyeColour = {"Brown", "Blue", "Grey", "Green", "Hazel"},
        hairColour = {"Dark Brown", "Medium Brown", "Light Brown", "Blonde", "Black", "Auburn"},
        ethnicity = {
            "German","Polish","Kashubian","Sorbian","Jewish","Danish",
            "Lithuanian","Russian","Czech","Italian","French","Austrian","Hungarian"
        }
    }

    local headings = {
        dob = "Date of Birth (YYYY/MM/DD)",
        pob = "Place of Birth (Township, Region, Country)",
        blood = "Blood Type",
        ethnicity = "Ethnicity",
        eyeColour = "Eye Colour",
        hairColour = "Hair Colour",
        height = "Height (5'11\")",
        weight = "Weight (kg)"
    }

    -- Normalize payload:
    -- Supports:
    -- 1) { "dob", "pob", ... }                          -- array of fields (missing-only)
    -- 2) { dob = "1890/03/12", ... }                    -- key/value table (all fields)
    -- 3) { order = {...}, values = {field = value,...} } -- unified payload
    local fields = {}
    local values = {}

    if type(incoming) ~= "table" then
        -- Fallback: default to full form empty
        fields = CANON_ORDER
        values = {}
    elseif incoming.order and incoming.values then
        fields = incoming.order
        values = incoming.values
    elseif incoming[1] ~= nil then
        -- Looks like an array (missing fields)
        fields = incoming
        values = {}
    else
        -- Key/value map of fields -> current values
        values = incoming
        -- Build field order from canonical list first, then any extras
        for _, f in ipairs(CANON_ORDER) do
            if values[f] ~= nil then table.insert(fields, f) end
        end
        for f, _ in pairs(values) do
            local exists = false
            for _, v in ipairs(fields) do if v == f then exists = true break end end
            if not exists then table.insert(fields, f) end
        end
        if #fields == 0 then fields = CANON_ORDER end
    end

    local payload = { identification = {} }
    local inputValues = {}

    -- Field builder
    local function addField(fieldName, fieldType, additionalOptions, defaultValue)
        defaultValue = defaultValue or ""
        inputValues[fieldName] = defaultValue

        local panel = vgui.Create("DPanel", scrollPanel)
        panel:Dock(TOP)
        panel:DockMargin(5, 5, 5, 5)
        panel:SetTall(40)
        panel.Paint = nil

        local label = vgui.Create("DLabel", panel)
        label:SetText(headings[fieldName] or string.upper(fieldName))
        label:Dock(LEFT)
        label:SetWide(100)
        label:SetTextColor(Color(200, 200, 200))

        if fieldType == "combo" then
            local comboBox = vgui.Create("DComboBox", panel)
            comboBox:Dock(FILL)

            local defaultIndex
            for i, option in ipairs(additionalOptions or {}) do
                comboBox:AddChoice(option)
                if option == defaultValue then
                    defaultIndex = i
                end
            end

            if defaultIndex then
                comboBox:ChooseOptionID(defaultIndex)
            elseif defaultValue ~= "" then
                -- If value isn't in options, still show it
                comboBox:SetValue(defaultValue)
            end

            comboBox.OnSelect = function(_, _, value)
                inputValues[fieldName] = value
            end

            comboBox.Paint = function(self, w, h)
                surface.SetDrawColor(50, 50, 50, 255)
                surface.DrawRect(0, 0, w, h)
                self:DrawTextEntryText(color_white, Color(70, 150, 200, 255), color_white)
            end
        else
            local entry = vgui.Create("DTextEntry", panel)
            entry:Dock(FILL)
            entry:SetValue(defaultValue)
            entry.OnValueChange = function(self, val)
                inputValues[fieldName] = val
            end
            entry.OnLoseFocus = function(self)
                inputValues[fieldName] = self:GetValue()
            end

            if fieldType == "dob" then
                entry:SetPlaceholderText("YYYY/MM/DD")
            elseif fieldType == "pob" then
                entry:SetPlaceholderText("Township, Region, Country")
            end
        end
    end

    -- Create fields in the chosen order, prefilling with current values when present
    for _, field in ipairs(fields) do
        local default = values[field] or ""
        if options[field] then
            addField(field, "combo", options[field], default)
        elseif field == "dob" or field == "pob" then
            addField(field, field, nil, default)
        else
            addField(field, "text", nil, default)
        end
    end

    -- Submit button + validation
    local submitButton = vgui.Create("DButton", frame)
    submitButton:SetText("Submit")
    submitButton:Dock(BOTTOM)
    submitButton:DockMargin(5, 5, 5, 5)
    submitButton.DoClick = function()
        local missingData = {}

        local function isValid(field, value)
            if not value or value == "" then return false end
            if field == "dob" then
                return string.match(value, "^%d%d%d%d/%d%d/%d%d$") ~= nil
            elseif field == "weight" then
                return tonumber(value) and tonumber(value) > 0
            elseif field == "height" then
                return tonumber(value) or string.match(value, "^%d+'%d*\"?$") ~= nil
            end
            return true
        end

        for _, field in ipairs(fields) do
            if not isValid(field, inputValues[field]) then
                table.insert(missingData, field)
            end
        end

        if #missingData > 0 then
            local errorMessage = "Please fill in or correct the following fields:\n"
            for _, field in ipairs(missingData) do
                errorMessage = errorMessage .. "- " .. (headings[field] or string.upper(field)) .. "\n"
            end
            LocalPlayer():ChatPrint(errorMessage)
            return
        end

        for field, value in pairs(inputValues) do
            payload.identification[field] = value
        end

        netstream.Start("ixSubmitIdentificationData", payload)
        frame:Close()
    end
end)
