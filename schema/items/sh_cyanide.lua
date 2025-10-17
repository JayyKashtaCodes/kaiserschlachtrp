ITEM.name = "Cyanide Pill"
ITEM.description = "Perma-Kill yourself to escape."
ITEM.price = 2000
ITEM.model = "models/jellik/poisonpill.mdl"
ITEM.category = "Medical"
ITEM.bDropOnDeath = true

ITEM.functions.Apply = {
    name = "Swallow Capsule",
    icon = "icon16/pill.png",
    OnRun = function(itemTable)
        local player = itemTable.player
        if not player then
            return false
        end

        if IsValid(player) and player:GetCharacter() then
            local char = player:GetCharacter()
            char:SetData("pkactive", true)
            char:SetData("ixHigh", true)
            player:Notify("You took Cyanide...")
            ix.chat.Send(player, "me", "Begins frothing at the mouth, their eyes bloodshot.")

            local totalDuration = 10
            local damageAmount = 10
            local interval = 1
            local repetitions = totalDuration / interval
            local timerName = "DamageOverTime_" .. player:UniqueID()

            if timer.Exists(timerName) then
                timer.Remove(timerName)
            end

            timer.Create(timerName, interval, repetitions, function()
                if IsValid(player) and player:GetCharacter() and player:Health() > 0 then
                    local newHealth = math.max(player:Health() - damageAmount, 0)
                    player:SetHealth(newHealth)
                    player:EmitSound("player/male/pain"..math.random(1,9).."\\.wav", 75)

                    if newHealth <= 0 then
                        timer.Remove(timerName)
                        char:SetData("ixHigh", nil)
                        char:SetData("ixHighTimer", nil)
                        player:Kill()
                    end
                end
            end)
        end

        return true
    end
}