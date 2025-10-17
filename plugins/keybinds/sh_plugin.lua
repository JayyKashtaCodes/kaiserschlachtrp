local PLUGIN = PLUGIN or {}

PLUGIN.name = "Hot Keys"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Adds hotkeys"

ix.util.Include("cl_hooks.lua", "client")
ix.util.Include("sv_hooks.lua", "server")

hook.Add("CreateMenuButtons", "ixInventory", function(tabs)
    return
end)