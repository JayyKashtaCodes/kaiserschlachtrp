local Schema = Schema or {}
---------------------------------------------------------------------------------------------------------------------------------

Schema.name = "Kaiserschlacht World War 1 Roleplay"
Schema.author = "Dzhey Kashta & Skyrakt"
Schema.description = "Kaiserschlacht Imperial Roleplay Experience."

Schema.discord = "discord.kaiserschlacht.ch"
Schema.build = "Beta"
Schema.currentVersion = "0.1.1"
Schema.changelogs = {
    ["0.0.1"] = {
        "Alpha Release",
    },
    ["0.1.0"] = {
        "Beta Release",
    },
    ["0.1.1"] = {
        "Code Cleaning",
    },
}

Schema.credits = {
    "Lead Developer: Dzhey Kashta",
    "Co‑Developer (Former): DoopieWop",
    "Models: Sarcastic & IAmHead",
    "Historical Research: Skyrakt",
    "Map Design: Skyrakt & Logan"
}

--ix.util.Include( "" )
--ix.util.IncludeDir("")
ix.util.IncludeDir("libs")
ix.util.IncludeDir("libs/thirdparty")

ix.util.IncludeDir("meta")
ix.util.IncludeDir("derma")
ix.util.IncludeDir("languages")

ix.util.IncludeDir("hooks")

ix.util.Include( "sh_configs.lua" )
ix.util.Include( "sh_commands.lua" )
ix.util.Include( "cl_schema.lua" )
ix.util.Include( "sv_schema.lua" )
ix.util.Include( "cl_serverinfo.lua" )
-------------------------------------------
--[[ Currency ]]--
ix.currency.plural = "Mark"
ix.currency.singular = "Goldmark"
ix.currency.symbol = "ℳ"
ix.currency.font = "OpenSansLight25"
--[[ END ]]--
-------------------------------------------
--[[ Change Server Category ]]--
function Schema:GetGameDescription()
    return "WW1 Imperial Germany Roleplay"
end
--[[ END ]]--
-------------------------------------------
--[[ Extra Flags ]]--
--ix.flag.Add("J", "Judge Flag: Assigned to Judges.")
--[[ END ]]--
-------------------------------------------
--[[ Action Block ]]--
function Schema:IsBusy(ply)
    return ply:GetLocalVar("ixBusyAction", false)
end

function Schema:SetBusy(ply, actionName)
    ply:SetLocalVar("ixBusyAction", actionName or false)
end
--[[ END ]]--
-------------------------------------------
--[[ ZeroNumber ]]--
function Schema:ZeroNumber(number, length)
    local amount = math.max(0, length - string.len(number))
    return string.rep("0", amount)..tostring(number)
end
-------------------------------------------
--[[ taken from DarkRP ]]--
local ent = FindMetaTable("Entity")
function ent:IsInRoom(target)
    local tracedata = {}
    tracedata.start = self:GetPos()
    tracedata.endpos = target:GetPos()
    local trace = util.TraceLine(tracedata)

    return not trace.HitWorld
end
--[[ END ]]--
-------------------------------------------
--[[ Character Inventory Death Fix ]]--
function Schema:PrePlayerLoadedCharacter(client, character, currentChar)
    if character then
        local inventory = character:GetInventory()

    	if inventory then
        	inventory:SetShouldSave(true)
    	end
    end
	if currentChar then
        local inventory = currentChar:GetInventory()

    	if inventory then
        	inventory:SetShouldSave(true)
    	end
    end
end
--[[ END ]]--
-------------------------------------------