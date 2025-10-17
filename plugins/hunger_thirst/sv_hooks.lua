local PLUGIN = PLUGIN or {}

PLUGIN.hungerSounds = {
    [1] = 'npc/barnacle/barnacle_digesting1.wav',
    [2] = 'npc/barnacle/barnacle_digesting2.wav'
}

-- Apply drunk effects based on drunkenness level
function PLUGIN:ApplyDrunkEffects(client, drunkenness)
    if drunkenness > 25 then
        -- Apply scaling effects based on drunkenness
        local effectStrength = (drunkenness - 25) / 65 -- Scales from 0 at 25 to 1 at 90

        -- Reduce stamina and endurance based on drunkenness
        local staminaReduction = effectStrength * 0.5 -- Reduce stamina by up to 50%
        client:SetRunSpeed(client:GetRunSpeed() * (1 - staminaReduction))
        client:SetWalkSpeed(client:GetWalkSpeed() * (1 - staminaReduction))
    end
end

-- Make the player unconscious
function PLUGIN:MakePlayerUnconscious(client)
    if not IsValid(client) then return end

    local fadeTime = ix.config.Get("unconsciousDuration", 60)
    local wakeupDrunkenness = ix.config.Get("wakeupDrunkenness", 30)

    client:SetRagdollState(RAGDOLL_KNOCKEDOUT)

    net.Start("ixFadeBlack")
    net.WriteFloat(fadeTime)
    net.Send(client)

    net.Start("ixPassOut")
    net.WriteFloat(fadeTime)
    net.Send(client)

    timer.Simple(fadeTime, function()
        if IsValid(client) then
            client:SetRagdollState(RAGDOLL_NONE)
            client:SetLocalVar("drunkenness", wakeupDrunkenness)
        end
    end)
end

if SERVER then
    util.AddNetworkString("ixFadeBlack")
    util.AddNetworkString("ixPassOut")
else
    function PLUGIN:ReceiveFadeBlack()
        local fadeTime = net.ReadFloat()
        local startTime = CurTime()

        hook.Add("HUDPaint", "ixFadeBlack", function()
            local timeElapsed = CurTime() - startTime
            if timeElapsed < fadeTime then
                surface.SetDrawColor(0, 0, 0, math.Clamp((timeElapsed / fadeTime) * 255, 0, 255))
                surface.DrawRect(0, 0, ScrW(), ScrH())
            else
                hook.Remove("HUDPaint", "ixFadeBlack")
            end
        end)
    end
    net.Receive("ixFadeBlack", function() PLUGIN:ReceiveFadeBlack() end)

    function PLUGIN:ReceivePassOut()
        local fadeTime = net.ReadFloat()
        local startTime = CurTime()

        hook.Add("RenderScreenspaceEffects", "ixPassOutBlur", function()
            DrawMotionBlur(0.95, 0.8, 0.01)
        end)

        hook.Add("HUDPaint", "ixPassOutText", function()
            local timeElapsed = CurTime() - startTime
            if timeElapsed < fadeTime then
                draw.SimpleText("YOU PASSED OUT", "Trebuchet24", ScrW() / 2, ScrH() / 2, Color(255, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                hook.Remove("HUDPaint", "ixPassOutText")
                hook.Remove("RenderScreenspaceEffects", "ixPassOutBlur")
            end
        end)
    end
    net.Receive("ixPassOut", function() PLUGIN:ReceivePassOut() end)
end

function PLUGIN:PlayerLoadedCharacter(client, character)
    if not IsValid(client) or not client:IsPlayer() or not character then return end

    local data = character:GetData("needs")
    if not data or not data.hunger then
        data = {hunger = 100, thirst = 100, drunkenness = 0}
        character:SetData("needs", data) -- Save to DB immediately
    end

    client:SetLocalVar("hunger", math.Clamp(data.hunger, 0, 100))
    client:SetLocalVar("thirst", math.Clamp(data.thirst, 0, 100))
    client:SetLocalVar("drunkenness", math.Clamp(data.drunkenness, 0, 100))

    if data.drunkenness > 25 then
        self:ApplyDrunkEffects(client, data.drunkenness)
    end

    if self:EnableNeedsForCharacter(client, character) then
        self:CreateNeedsTimer(client, character)
    end
end


-- Create needs timer
function PLUGIN:CreateNeedsTimer(client, character)
    local uniqueID = client:AccountID()
    local needsDelay = ix.config.Get("primaryNeedsDelay", 120)
    local timerName = "ixPrimaryNeeds." .. uniqueID

    timer.Create(timerName, needsDelay, 0, function()
        if not IsValid(client) or not character then return end
        if not self:EnableNeedsForCharacter(client, character) then return end

        local filledSlots = math.Round(character:GetInventory():GetFilledSlotCount() / 2)
        local velocity = client:GetVelocity():LengthSqr()
        local hungerConsume = ix.config.Get("hungerConsume", 3) + filledSlots
        local thirstConsume = ix.config.Get("thirstConsume", 2) + filledSlots
        local hunger = client:GetLocalVar("hunger")
        local thirst = client:GetLocalVar("thirst")
        local drunkenness = client:GetLocalVar("drunkenness")

        if velocity > 0 then
            hungerConsume = math.Round(hungerConsume * 1.5)
            thirstConsume = math.Round(thirstConsume * 1.5)
        end

        if hunger <= 10 then
            client:EmitSound(self.hungerSounds[math.random(#self.hungerSounds)])
        end

        if hunger <= 0 and thirst <= 0 then
            client:SetHealth(client:Health() - 2)
        end

        client:Hunger(-hungerConsume)
        client:Thirst(-thirstConsume)

        local drunkennessDecayAmount = ix.config.Get("drunkennessDecayAmount", 1)
        if drunkenness > 0 then
            client:Drunkenness(-drunkennessDecayAmount)
        end

        if drunkenness > 25 then
            self:ApplyDrunkEffects(client, drunkenness)
        end

        if drunkenness >= 100 then
            self:MakePlayerUnconscious(client)
        end
        self:SaveCharacterNeeds(client:GetCharacter())
    end)
end

-- Save character needs
function PLUGIN:SaveCharacterNeeds(character)
    local player = character:GetPlayer()
    if player then
        local hunger = player:GetLocalVar("hunger") or 100
        local thirst = player:GetLocalVar("thirst") or 100
        local drunkenness = player:GetLocalVar("drunkenness") or 0

        character:SetData("needs", {
            hunger = hunger,
            thirst = thirst,
            drunkenness = drunkenness
        })
    end
end

function PLUGIN:PlayerDisconnected(client)
    if IsValid(client) and client:GetCharacter() then
        self:SaveCharacterNeeds(client:GetCharacter())

        local uniqueID = client:AccountID()
        local timerName = "ixPrimaryNeeds." .. uniqueID
        if timer.Exists(timerName) then
            timer.Remove(timerName)
        end
    end
end

function PLUGIN:CharacterPreSave(character)
    self:SaveCharacterNeeds(character)
end

-- Reset needs on player death
function PLUGIN:DoPlayerDeath(client)
    if IsValid(client) and client:GetCharacter() then
        client:SetLocalVar("hunger", 100)
        client:SetLocalVar("thirst", 100)
        client:SetLocalVar("drunkenness", 0)

        self:SaveCharacterNeeds(client:GetCharacter())
    end
end

function PLUGIN:CharacterCreated(client, character)
    character:SetData("needs", {hunger = 100, thirst = 100, drunkenness = 0})
end

-- Check if needs should be enabled for the character
function PLUGIN:EnableNeedsForCharacter(client, character)
    local factionTable = ix.faction.indices[character:GetFaction()] or {}
    return factionTable.includeNeeds ~= false
end

function PLUGIN:ShutDown()
    for _, client in ipairs(player.GetAll()) do
        if client:GetCharacter() then
            self:SaveCharacterNeeds(client:GetCharacter())
        end
    end
end

function PLUGIN:PrePlayerLoadedCharacter(client, oldCharacter, newCharacter)
    if oldCharacter then
        self:SaveCharacterNeeds(oldCharacter)
    end
end