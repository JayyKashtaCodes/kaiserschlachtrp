local PLUGIN = PLUGIN

PLUGIN.name = "DarkRP compatibility"
PLUGIN.author = "JohnyReaper, Dzhey Kashta"
PLUGIN.description = "Adds DarkRP compatibility"

DarkRP = DarkRP or {}
RPExtraTeams = RPExtraTeams or {}

local plyMeta = FindMetaTable("Player")
local entMeta = FindMetaTable("Entity")

if SERVER then
    -- Populate RPExtraTeams after all factions are loaded
    function PLUGIN:InitPostEntity()
        timer.Simple(0, function()
            if not ix or not ix.faction or not ix.faction.GetAll then
                return -- safety check
            end

            RPExtraTeams = RPExtraTeams or {}
            local index = 1

            for _, faction in pairs(ix.faction.GetAll()) do
                local name = tostring(faction.name or ("Faction " .. index))
                local ident = string.Replace(string.lower(tostring(faction.uniqueID or faction.name or ("faction" .. index))), " ", "_")

                RPExtraTeams[index] = {
                    team = index,
                    name = name,
                    command = ident,
                    OPENPERMISSIONS_IDENTIFIER = ident,
                    color = faction.color or Color(255, 255, 255)
                }

                index = index + 1
            end

            -- Final pass: ensure no nils in any Blogs‑critical fields
            for k, job in pairs(RPExtraTeams) do
                job.name = tostring(job.name or ("Job " .. k))
                job.command = tostring(job.command or ("job_" .. k))
                job.OPENPERMISSIONS_IDENTIFIER = tostring(job.OPENPERMISSIONS_IDENTIFIER or ("job_" .. k))
            end
        end)
    end

    function DarkRP.isEmpty(vector, ignore)
        ignore = ignore or {}
        local point = util.PointContents(vector)
        local a = point ~= CONTENTS_SOLID
            and point ~= CONTENTS_MOVEABLE
            and point ~= CONTENTS_LADDER
            and point ~= CONTENTS_PLAYERCLIP
            and point ~= CONTENTS_MONSTERCLIP
        if not a then return false end

        for _, v in ipairs(ents.FindInSphere(vector, 35)) do
            if (v:IsNPC() or v:IsPlayer() or v:GetClass() == "prop_physics" or v.NotEmptyPos) and not table.HasValue(ignore, v) then
                return false
            end
        end

        return true
    end

    function DarkRP.findEmptyPos(pos, ignore, distance, step, area)
        if DarkRP.isEmpty(pos, ignore) and DarkRP.isEmpty(pos + area, ignore) then
            return pos
        end

        for j = step, distance, step do
            for i = -1, 1, 2 do
                local k = j * i
                if DarkRP.isEmpty(pos + Vector(k, 0, 0), ignore) and DarkRP.isEmpty(pos + Vector(k, 0, 0) + area, ignore) then
                    return pos + Vector(k, 0, 0)
                end
                if DarkRP.isEmpty(pos + Vector(0, k, 0), ignore) and DarkRP.isEmpty(pos + Vector(0, k, 0) + area, ignore) then
                    return pos + Vector(0, k, 0)
                end
                if DarkRP.isEmpty(pos + Vector(0, 0, k), ignore) and DarkRP.isEmpty(pos + Vector(0, 0, k) + area, ignore) then
                    return pos + Vector(0, 0, k)
                end
            end
        end

        return pos
    end

    function DarkRP.notify(pPlayer, msgtype, time, msg)
        pPlayer:Notify(msg)
    end

    function plyMeta:addMoney(amount)
        local char = self:GetCharacter()
        if char then
            char:SetMoney(char:GetMoney() + amount)
        end
    end
end

if CLIENT then
    local function charWrap(text, remainingWidth, maxWidth)
        local totalWidth = 0
        text = text:gsub(".", function(char)
            totalWidth = totalWidth + surface.GetTextSize(char)
            if totalWidth >= remainingWidth then
                totalWidth = surface.GetTextSize(char)
                remainingWidth = maxWidth
                return "\n" .. char
            end
            return char
        end)
        return text, totalWidth
    end

    function DarkRP.textWrap(text, font, maxWidth)
        local totalWidth = 0
        surface.SetFont(font)
        local spaceWidth = surface.GetTextSize(" ")
        text = text:gsub("(%s?[%S]+)", function(word)
            local char = string.sub(word, 1, 1)
            if char == "\n" or char == "\t" then
                totalWidth = 0
            end
            local wordlen = surface.GetTextSize(word)
            totalWidth = totalWidth + wordlen
            if wordlen >= maxWidth then
                local splitWord, splitPoint = charWrap(word, maxWidth - (totalWidth - wordlen), maxWidth)
                totalWidth = splitPoint
                return splitWord
            elseif totalWidth < maxWidth then
                return word
            end
            if char == " " then
                totalWidth = wordlen - spaceWidth
                return "\n" .. string.sub(word, 2)
            end
            totalWidth = wordlen
            return "\n" .. word
        end)
        return text
    end
end

function plyMeta:canAfford(amount)
    local char = self:GetCharacter()
    return char and char:GetMoney() >= amount or false
end

function DarkRP.formatMoney(amount)
    return ix.currency.Get(amount)
end
