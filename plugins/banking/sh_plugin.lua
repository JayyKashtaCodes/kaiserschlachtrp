local PLUGIN = PLUGIN or {}

PLUGIN.name = "Banking"
PLUGIN.author = "DoopieWop"

-- forgive me for the terrible clientside/UI related stuff.
-- thats what happens when you dont know what to do for a UI but then have to go with it anyways
-- DONT BE LIKE ME!!

-- permissions
BANKINGPERM_DEPOSIT_WITHDRAW = 2
BANKINGPERM_SEND = 4
BANKINGPERM_LOG = 8
BANKINGPERM_MANAGE_HOLDERS = 16
BANKINGPERM_OWNER = 32
-- account owner, can do anything, necessary in case two account holders have conflicting interests (aka trying to remove each other)
-- also needed to confirm big actions like closing the account

ix.banking = ix.banking or {}
ix.banking.accountTypes = {}
ix.banking.logTypes = {}
ix.banking.offlineCharacters = ix.banking.offlineCharacters or {}
ix.banking.accounts = ix.banking.accounts or {}
ix.banking.accountsByChar = ix.banking.accountsByChar or {}

-- totally unnecessary but im lazy
-- hardcode the value before this enters prod...
local bDev = false

local cache = 0
function ix.banking.GetBankingPermissionsSum()
    if not bDev then
        return 62 -- all permissions together
    end

    if cache == 0 then
        local sum = 0
        for k, v in pairs(_G) do
            if k:match("^BANKINGPERM_") and isnumber(v) then
                sum = sum + v
            end
        end

        cache = sum
    end
    return cache
end

function ix.banking.RegisterType(type, meta)
    ix.banking.accountTypes[type] = meta
end

function ix.banking.RegisterLogType(logType, format, accentColor)
    ix.banking.logTypes[logType] = {
        format = format,
        accentColor = accentColor or Color(200, 200, 200)
    }
end

function ix.banking.ParseLog(logType, accountID, time, data)
    local logTypeInfo = ix.banking.logTypes[logType]
    if logTypeInfo then
        return logTypeInfo.format(accountID, time, unpack(data))
    end
end

function ix.banking.GetOwnedAccounts(character)
    local id = character:GetID()
    if ix.banking.accountsByChar[id] then
        local accounts = {}
        for k, v in pairs(ix.banking.accountsByChar[id]) do
            if v:GetOwner() == id then
                table.insert(accounts, v)
            end
        end
        return accounts
    end
    return {}
end

ix.util.Include("meta/sh_account.lua")
ix.util.Include("sh_config.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("cl_networking.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sv_networking.lua")
ix.util.Include("sv_plugin.lua")
ix.util.Include("sv_sql.lua")
ix.util.Include("sv_hooks.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/commands", true)