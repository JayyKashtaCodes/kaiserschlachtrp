local PLUGIN = PLUGIN or {}

PLUGIN.name = "Chat Icons"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Adds chat icons based on user group."

-- SteamID64-specific icon overrides
local steamIDIconOverrides = {
    ["76561198085437701"] = "icon16/jimmy_carrey.png", -- Dzhey Kashta
}

-- Returns the appropriate icon path for a speaker
local function GetUserGroupIcon(speaker)
    if (not IsValid(speaker)) then return "icon16/user.png" end

    local steamID = speaker:SteamID64()
    if steamIDIconOverrides[steamID] then
        return steamIDIconOverrides[steamID]
    end

    -- Order matters: highest ranks first
    local rankChecks = {
        { check = function(s) return s:IsGA() end,           icon = "icon16/key.png" },           -- GA (Owner, CM, superadmin) = key
        { check = function(s) return s:IsUA() end,           icon = "icon16/briefcase.png" },     -- UA (Managers, Devs, GA) = briefcase
        { check = function(s) return s:IsUStaff() end,       icon = "icon16/shield_add.png" },    -- Upper Staff = shield_add
        { check = function(s) return s:IsStaff() end,        icon = "icon16/shield.png" },        -- All Staff = shield
        { check = function(s) return s:IsDonatorPlus() end,  icon = "icon16/heart_add.png" },     -- Donator+ = heart_add
        { check = function(s) return s:IsDonator() end,      icon = "icon16/heart.png" }          -- Donator = heart
    }

    for _, data in ipairs(rankChecks) do
        if data.check(speaker) then
            return data.icon
        end
    end

    return "icon16/status_online.png"
end

function PLUGIN:InitializedPlugins()
    if SERVER then
        --print("[CHATICONS] OOC/LOOC Override Triggered.")
    end
    ix.chat.classes["ooc"] = nil
    ix.chat.classes["looc"] = nil

    -- OOC Chat
    ix.chat.Register("ooc", {
        CanSay = function(self, speaker, text)
            if (!ix.config.Get("allowGlobalOOC")) then
                speaker:NotifyLocalized("Global OOC is disabled on this server.")
                return false
            end

            local delay = ix.config.Get("oocDelay", 10)

            if (delay > 0 and speaker.ixLastOOC) then
                local lastOOC = CurTime() - speaker.ixLastOOC

                if (lastOOC <= delay and !CAMI.PlayerHasAccess(speaker, "Helix - Bypass OOC Timer", nil)) then
                    speaker:NotifyLocalized("oocDelay", delay - math.ceil(lastOOC))
                    return false
                end
            end

            speaker.ixLastOOC = CurTime()
        end,

        OnChatAdd = function(self, speaker, text)
            if (!IsValid(speaker)) then return end

            local iconPath = hook.Run("GetPlayerIcon", speaker) or GetUserGroupIcon(speaker)
            local iconMaterial = Material(iconPath)

            chat.AddText(iconMaterial, Color(255, 50, 50), "[OOC] ", ix.config.Get("chatColor"), speaker:Name(), color_white, ": " .. text)
        end,

        prefix = {"//", "/OOC"},
        description = "@cmdOOC",
        noSpaceAfter = true
    })

    -- LOOC Chat
    ix.chat.Register("looc", {
        CanSay = function(self, speaker, text)
            local delay = ix.config.Get("loocDelay", 0)

            if (delay > 0 and speaker.ixLastLOOC) then
                local lastLOOC = CurTime() - speaker.ixLastLOOC

                if (lastLOOC <= delay and !CAMI.PlayerHasAccess(speaker, "Helix - Bypass OOC Timer", nil)) then
                    speaker:NotifyLocalized("loocDelay", delay - math.ceil(lastLOOC))
                    return false
                end
            end

            speaker.ixLastLOOC = CurTime()
        end,

        OnChatAdd = function(self, speaker, text)
            if (!IsValid(speaker)) then return end

            local iconPath = hook.Run("GetPlayerIcon", speaker) or GetUserGroupIcon(speaker)
            local iconMaterial = Material(iconPath)

            chat.AddText(iconMaterial, Color(255, 50, 50), "[LOOC] ", ix.config.Get("chatColor"), speaker:Name(), color_white, ": " .. text)
        end,

        CanHear = ix.config.Get("chatRange", 280),
        prefix = {".//", "[[", "/LOOC"},
        description = "@cmdLOOC",
        noSpaceAfter = true
    })
end
