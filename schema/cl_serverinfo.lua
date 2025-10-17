local Schema = Schema

hook.Add("CreateMenuButtons", "SchemaServerMenu", function(tabs)
    tabs["server"] = {
        buttonColor = ix.config.Get("color"),
        bDefault = false,

        -- NOTE: Create is invoked as info:Create(panel), so it must accept (self, container)
        Create = function(self, container)
            if not IsValid(container) then return end

            container:DockPadding(8, 8, 8, 8)

            local function addLabel(text, font, margin)
                local lbl = container:Add("DLabel")
                lbl:SetFont(font)
                lbl:SetText(text)
                lbl:SetWrap(true)
                lbl:SetAutoStretchVertical(true)
                lbl:SetTextColor(color_white)
                lbl:SetExpensiveShadow(1, color_black)
                lbl:Dock(TOP)
                if margin then
                    lbl:DockMargin(0, margin, 0, margin)
                end
                lbl:SizeToContents()
            end

            addLabel(Schema.name or "Unknown Server", "ixTitleFont", 0)
            addLabel(Schema.description or "No description set.", "ixSmallFont", 8)
            addLabel("Author(s): " .. (Schema.author or "N/A"), "ixSmallFont", 4)
            local discordURL = "https://" .. Schema.discord or "https://discord.gg/"
            local discordBtn = container:Add("DButton")
            discordBtn:SetFont("ixSmallFont")
            discordBtn:SetText("Discord: " .. discordURL)
            discordBtn:SetTextColor(Color(100, 149, 237))
            discordBtn:SetExpensiveShadow(1, color_black)
            discordBtn:Dock(TOP)
            discordBtn:DockMargin(0, 4, 0, 0)
            discordBtn:SetTall(20)

            -- Underline on hover
            discordBtn.Paint = function(self, w, h)
                if self:IsHovered() then
                    surface.SetDrawColor(self:GetTextColor())
                    surface.DrawLine(0, h - 2, w, h - 2)
                end
            end

            discordBtn.DoClick = function()
                gui.OpenURL(discordURL)
            end
        end,

        Sections = {
            ["Credits"] = function(container)
                if not IsValid(container) then return end
                container:DockPadding(8, 8, 8, 8)

                local title = container:Add("DLabel")
                title:SetFont("ixTitleFont")
                title:SetText("Server Credits")
                title:SetTextColor(color_white)
                title:SetExpensiveShadow(1, color_black)
                title:Dock(TOP)
                title:DockMargin(0, 0, 0, 8)
                title:SizeToContents()

                for _, text in ipairs(Schema.credits) do
                    local lbl = container:Add("DLabel")
                    lbl:SetFont("ixSmallFont")
                    lbl:SetText("• " .. text)
                    lbl:SetTextColor(color_white)
                    lbl:SetExpensiveShadow(1, color_black)
                    lbl:Dock(TOP)
                    lbl:DockMargin(0, 0, 0, 2)
                    lbl:SizeToContents()
                end
            end,

            ["Development"] = function(container)
                if not IsValid(container) then return end
                container:DockPadding(8, 8, 8, 8)

                local function addLabel(text, font, margin)
                    local lbl = container:Add("DLabel")
                    lbl:SetFont(font)
                    lbl:SetText(text)
                    lbl:SetTextColor(color_white)
                    lbl:SetExpensiveShadow(1, color_black)
                    lbl:Dock(TOP)
                    if margin then
                        lbl:DockMargin(0, margin, 0, margin)
                    end
                    lbl:SizeToContents()
                end

                addLabel("Server Development", "ixTitleFont", 0)
                addLabel("Build: " .. (Schema.build or "N/A"), "ixSmallFont", 4)
                addLabel("Current Version: " .. (Schema.currentVersion or "N/A"), "ixSmallFont", 4)

                if Schema.changelogs then
                    local subHeader = container:Add("DLabel")
                    subHeader:SetFont("ixMediumLightFont")
                    subHeader:SetText("Changelogs")
                    subHeader:SetTextColor(color_white)
                    subHeader:SetExpensiveShadow(1, color_black)
                    subHeader:Dock(TOP)
                    subHeader:DockMargin(0, 8, 0, 4)
                    subHeader:SizeToContents()

                    for version, changes in pairs(Schema.changelogs) do
                        local verLbl = container:Add("DLabel")
                        verLbl:SetFont("ixSmallFont")
                        verLbl:SetText(version)
                        verLbl:SetTextColor(Color(200, 200, 50))
                        verLbl:SetExpensiveShadow(1, color_black)
                        verLbl:Dock(TOP)
                        verLbl:DockMargin(0, 4, 0, 0)
                        verLbl:SizeToContents()

                        for _, change in ipairs(changes) do
                            local changeLbl = container:Add("DLabel")
                            changeLbl:SetFont("ixSmallFont")
                            changeLbl:SetText("  - " .. change)
                            changeLbl:SetTextColor(color_white)
                            changeLbl:SetExpensiveShadow(1, color_black)
                            changeLbl:Dock(TOP)
                            changeLbl:SizeToContents()
                        end
                    end
                end
            end
        }
    }
end)
