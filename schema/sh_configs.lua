local Schema = Schema
---------------------------------------------------------------------------------------------------------------------------------
--[[ Stop Intro ]]--
ix.config.Set("intro", false)
ix.config.SetDefault("intro", false)
ix.config.SetDefault("maxAttributes", 60)
ix.config.Add("minNameLength", 2, "The minimum number of characters in a name.", nil, {data = {min = 2, max = 32}, category = "characters"})
--[[ END ]]--
---------------------------------------------------------------------------------------------------------------------------------
--[[ Doorkick Respawn ]]--
ix.config.Add("Door Kick Respawn", 60, "How long it takes for the door to respawn", nil, {
    data = { min = 1, max = 600 },
    category = "Door Kick"
})
--[[ END ]]--
---------------------------------------------------------------------------------------------------------------------------------
--[[ Inventory ]]--
ix.config.SetDefault( "inventoryHeight", 7 )
ix.config.SetDefault( "inventoryWidth", 5 )
--[[ END ]]--
---------------------------------------------------------------------------------------------------------------------------------
--[[ Voice ]]--
ix.config.SetDefault( "allowVoice", true )
--[[ END ]]--
---------------------------------------------------------------------------------------------------------------------------------