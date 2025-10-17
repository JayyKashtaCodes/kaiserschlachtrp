local PLUGIN = PLUGIN

ITEM.name = "Rope"
ITEM.description = "A rope used to restrict people."
ITEM.price = 8
ITEM.model = "models/items/crossbowrounds.mdl"
ITEM.category = "Criminal"
ITEM.bDropOnDeath = true

ITEM.functions.Use = {
    OnRun = function(itemTable)
        local client = itemTable.player
        if not IsValid(client) then return false end

        local traceData = {
            start = client:GetShootPos(),
            endpos = client:GetShootPos() + client:GetAimVector() * 96,
            filter = client
        }
        local target = util.TraceLine(traceData).Entity

        if IsValid(target)
        and target:IsPlayer()
        and target:GetCharacter()
        and not PLUGIN:IsRestrained(target)
        and target:Team() ~= FACTION_STAFF then

            if client:GetNetVar("tying", false) then
                if PLUGIN.CancelActions then
                    PLUGIN:CancelActions(client, target)
                end
                return false
            end

            itemTable.bBeingUsed = true

            client:SetAction("Tying...", 5)
            local snd = CreateSound(target, "sfx/tying.wav"); snd:Play()

            client:DoStaredAction(target, function()
                snd:Stop()
                PLUGIN:SetRestricted(target, true, "ties")
                client:ChatPrint("You have tied someone.")
                target:ChatPrint("You have been tied.")
                itemTable.bBeingUsed = false
                itemTable:Remove()
            end, 5, function()
                snd:Stop()
                if PLUGIN.CancelActions then
                    PLUGIN:CancelActions(client, target)
                end
                itemTable.bBeingUsed = false
            end)

        else
            client:ChatPrint("You cannot tie a staff member or the target is not valid.")
        end

        return false
    end,

    OnCanRun = function(itemTable)
        return not IsValid(itemTable.entity) and not itemTable.bBeingUsed
    end
}

function ITEM:CanTransfer(inventory, newInventory)
    return not self.bBeingUsed
end
