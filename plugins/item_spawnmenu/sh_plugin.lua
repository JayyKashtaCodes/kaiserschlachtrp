PLUGIN.name = "Item Spawnmenu Tab"
PLUGIN.description = "Does what it says."
PLUGIN.author = "DoopieWop"

CAMI.RegisterPrivilege({
	Name = "Item Spawnmenu - Use Menu",
	MinAccess = "admin"
})

ix.util.Include("cl_hooks.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_plugin.lua")