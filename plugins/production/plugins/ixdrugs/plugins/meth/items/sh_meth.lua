-- Item Statistics
ITEM.name = "Methamphetamine"
ITEM.description = "A small syringe filled with meth. It has some nasty side-effects which may include genuine weakness or unnatural overdose."
ITEM.category = "Medical"

-- Item Configuration
ITEM.model = "models/e7/gmod/renderhub/items/syringe/syringe_blood.mdl"
ITEM.skin = 0

-- Item Inventory Size Configuration
ITEM.width = 1
ITEM.height = 1

-- Item Custom Configuration
ITEM.bDropOnDeath = true

-- Item Functions
ITEM.functions.Apply = {
    name = "Inject",
    icon = "icon16/pill.png",
    OnRun = function(itemTable)
        local ply = itemTable.player
        local char = ply:GetCharacter()

        -- Overdose logic
        if (math.random(1, 4) == 4) and (char:GetData("ixHigh")) then
            ix.chat.Send(ply, "me", "falls on the ground and slowly dies due to overdose.", false)
            ply:Notify("You have died of overdose!")
            ply:Kill()
            return false
        end

        -- Injection logic
        ix.chat.Send(ply, "me", "Injects the meth into their own vein.", false)
        ply:Freeze(true)
        ply:SetAction("Injecting Meth...", 3, function()
            local lastHealth = ply:Health()
            ply:Notify("You have injected some meth.")
            ply:Freeze(false)
            ply:SetHealth(ply:Health() + 80)
            ply:EmitSound("vo/npc/male01/pain0" .. math.random(7, 9) .. ".wav", 80)
            ply:ViewPunch(Angle(-10, 0, 0))
            timer.Simple(1, function() ply:EmitSound("vo/npc/male01/yeah02.wav") end)

            -- Apply ixHigh state and start timer
            char:SetData("ixHigh", true)
            char:SetData("ixHighTimer", ix.config.Get("highTime")) -- Set the duration of the effect

            -- Start the timer for persistent effects
            timer.Create("HighEffectTimer_" .. ply:SteamID(), 1, 0, function()
                if not IsValid(ply) or not ply:GetCharacter() then
                    timer.Remove("HighEffectTimer_" .. ply:SteamID())
                    return
                end

                local highTimer = char:GetData("ixHighTimer", 0)
                if highTimer > 0 then
                    char:SetData("ixHighTimer", highTimer - 1) -- Reduce the timer by 1 second
                else
                    -- Remove effects when timer runs out
                    ply:Notify("Your meth has worn off...")
                    ply:SetHealth(lastHealth)
                    ply:TakeDamage(10)
                    ply:ViewPunch(Angle(-10, 0, 0))
                    char:SetData("ixHigh", nil)
                    char:SetData("ixHighTimer", nil)
                    timer.Remove("HighEffectTimer_" .. ply:SteamID())
                end
            end)
        end)

        return true
    end
}
