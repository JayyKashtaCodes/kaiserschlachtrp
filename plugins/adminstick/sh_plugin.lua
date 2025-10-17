local PLUGIN = PLUGIN

PLUGIN.name = "Administrative Stick"
PLUGIN.author = "Dzhey Kashta, Doopie | Inspired by EmanSza, berko - NS"
PLUGIN.description = "Admin Stick."

ix.util.Include("cl_plugin.lua")

local RankColors = {
    ["Trial Moderator"]          = HSVToColor(30, 1, 1),    -- Orange
    ["Moderator"]                = HSVToColor(240, 1, 1),   -- Blue
    ["Senior Moderator"]         = HSVToColor(220, 1, 1),   -- Light Blue
    ["Trial Administrator"]      = HSVToColor(60, 1, 1),    -- Yellow
    ["Administrator"]            = HSVToColor(120, 1, 1),   -- Green
    ["Senior Administrator"]     = HSVToColor(100, 1, 1),   -- Darker Green
    ["Head Administrator"]       = HSVToColor(80, 1, 1),    -- Teal
    ["Supervisor Administrator"] = HSVToColor(50, 1, 1),    -- Gold
    ["Server Developer"]         = HSVToColor(300, 1, 1),   -- Purple
    ["Server Manager"]           = HSVToColor(280, 1, 1)    -- Violet
}

function PLUGIN:GetRankColor(ply)
    if (ply:IsGA() or ply:IsUA()) then
        return true, nil -- RGB
    end
    
    return false, RankColors[ply:GetUserGroup()] or Color(255, 255, 255)
end

if SERVER then
    function PLUGIN:GiveStick(ply)
        if not IsValid(ply) then return end

        if ply:HasWeapon("ix_adminstick") then
            ply:StripWeapon("ix_adminstick")
        end

        if ply:IsStaff() then
            ply:Give("ix_adminstick")
            local weapon = ply:GetWeapon("ix_adminstick")
            if IsValid(weapon) then
                local isRGB, colour = self:GetRankColor(ply)
                if isRGB then
                    weapon.RGB = true
                else
                    weapon:SetColor(colour)
                end
            end
        end
    end

    function PLUGIN:PostPlayerLoadout(ply, character, lastChar)
        self:GiveStick(ply)
    end
end
