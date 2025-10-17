local PLUGIN = PLUGIN

ITEM.name = "Handcuffs"
ITEM.description = "Policing Handcuffs."
ITEM.price = 8
ITEM.model = "models/items/crossbowrounds.mdl"
ITEM.category = "Police"
ITEM.factions = {FACTION_INNERN, FACTION_ARMY}
ITEM.bDropOnDeath = false

ITEM.functions.Use = {
    OnRun = function(itemTable)
        local client = itemTable.player
        if not IsValid(client) then return false end

        -- Trace for target within ~96 units
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

            if client:GetNetVar("handcuffing", false) then
                if PLUGIN.CancelActions then
                    PLUGIN:CancelActions(client, target)
                end
                return false
            end

            itemTable.bBeingUsed = true

            -- Play cuffing action
            client:SetAction("Handcuffing...", 3)
            local snd = CreateSound(target, "sfx/cuffing.wav"); snd:Play()

            client:DoStaredAction(target, function()
                snd:Stop()
                PLUGIN:SetRestricted(target, true, "cuffs")
                client:ChatPrint("You have handcuffed someone.")
                target:ChatPrint("You have been handcuffed.")
                itemTable.bBeingUsed = false
                itemTable:Remove()
            end, 3, function()
                snd:Stop()
                if PLUGIN.CancelActions then
                    PLUGIN:CancelActions(client, target)
                end
                itemTable.bBeingUsed = false
            end)

        else
            client:ChatPrint("You cannot handcuff a staff member or the target is not valid.")
        end

        -- return false to prevent automatic item removal unless we explicitly remove it on success
        return false
    end,

    OnCanRun = function(itemTable)
        return not IsValid(itemTable.entity) and not itemTable.bBeingUsed
    end
}

function ITEM:CanTransfer(inventory, newInventory)
    return not self.bBeingUsed
end
