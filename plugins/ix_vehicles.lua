local PLUGIN = PLUGIN or {}

PLUGIN.name = "KSR Vehicle System"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Enforces spawn limits and manages vehicle spawning globally and per-role."

PLUGIN.vehicleWhitelist = {
    ["gmod_sent_vehicle_fphysics_base"] = true
}

ix.config.Add("vehicLimitGA", 10, nil, nil, {data = {min = 1, max = 20}, category = PLUGIN.name})
ix.config.Add("vehicLimitUA", 5, nil, nil, {data = {min = 1, max = 10}, category = PLUGIN.name})
ix.config.Add("vehicLimitUStaff", 5, nil, nil, {data = {min = 1, max = 10}, category = PLUGIN.name})
ix.config.Add("vehicLimitStaff", 3, nil, nil, {data = {min = 1, max = 10}, category = PLUGIN.name})
ix.config.Add("vehicLimitDonatorPlus", 2, nil, nil, {data = {min = 1, max = 10}, category = PLUGIN.name})
ix.config.Add("vehicLimitDefault", 1, nil, nil, {data = {min = 1, max = 10}, category = PLUGIN.name})
ix.config.Add("vehicLimitGlobal", 30, nil, nil, {data = {min = 1, max = 100}, category = PLUGIN.name})

ix.command.Add("EnableVehicleSpawning", {
    description = "Enable vehicle spawning on the server.",
    adminOnly = true,
    OnRun = function(client)
        RunConsoleCommand("ksr_vehicle_spawning", "1")
        for _, v in ipairs(player.GetAll()) do
            v:Notify("vehicle spawning enabled.")
        end
    end
})

ix.command.Add("DisableVehicleSpawning", {
    description = "Disable vehicle spawning and remove active vehicles.",
    adminOnly = true,
    OnRun = function(client)
        RunConsoleCommand("ksr_vehicle_spawning", "0")

        local removed = 0
        for _, ent in ipairs(PLUGIN.vehicles) do
            if IsValid(ent) then
                ent:Remove()
                removed = removed + 1
            end
        end

        PLUGIN.vehicles = {}
        for _, v in ipairs(player.GetAll()) do
            v:Notify("vehicle spawning disabled. Removed " .. removed .. " vehicle(s).")
        end
    end
})

if SERVER then
    PLUGIN.vehicles = {}

    CreateConVar("ksr_vehicle_spawning", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Toggle vehicle spawning on the server.")

    local function getLimitFor(client)
        local limits = {}

        if client:IsGA() then table.insert(limits, ix.config.Get("vehicLimitGA")) end
        if client:IsUA() then table.insert(limits, ix.config.Get("vehicLimitUA")) end
        if client:IsUStaff() then table.insert(limits, ix.config.Get("vehicLimitUStaff")) end
        if client:IsStaff() then table.insert(limits, ix.config.Get("vehicLimitStaff")) end
        if client:IsDonatorPlus() then table.insert(limits, ix.config.Get("vehicLimitDonatorPlus")) end

        table.insert(limits, ix.config.Get("vehicLimitDefault"))

        return math.max(unpack(limits))
    end

    function PLUGIN:GetVehicleCount(client)
        local count = 0
        for _, ent in ipairs(self.vehicles) do
            if IsValid(ent) and ent:CPPIGetOwner() == client then
                count = count + 1
            end
        end
        return count
    end

    function PLUGIN:CanSpawnVehicle(client)
        if not GetConVar("ksr_vehicle_spawning"):GetBool() then
            client:Notify("Vehicle spawning is currently disabled by an administrator.")
            return false
        end

        local clientLimitReached = self:GetVehicleCount(client) >= getLimitFor(client)
        local globalLimitReached = #self.vehicles >= ix.config.Get("vehicLimitGlobal")

        if clientLimitReached then
            client:Notify("You've reached your personal vehicle limit.")
            return false
        end

        if globalLimitReached then
            client:Notify("The server has reached the global vehicle limit.")
            return false
        end

        return true
    end

    function PLUGIN:PlayerSpawnedVehicle(client, ent)
        -- Check if vehicle spawning is allowed
        if not self:CanSpawnVehicle(client) then
            ent:Remove()
            return
        end

        -- Block chairs by classname or entity class inheritance
        if ent:GetClass():find("chair") or ent:GetClass() == "prop_vehicle_prisoner_pod" then
            client:Notify("Chair vehicles are not permitted.")
            ent:Remove()
            return
        end

        -- Enforce whitelist
        if not self.vehicleWhitelist[ent:GetClass()] then
            client:Notify("This vehicle is not whitelisted for spawning.")
            ent:Remove()
            return
        end

        -- Add to vehicle pool
        table.insert(self.vehicles, ent)

        local remaining = getLimitFor(client) - self:GetVehicleCount(client)
        client:Notify("Vehicle spawned. You have " .. remaining .. " remaining.")
    end

    function PLUGIN:EntityRemoved(ent)
        timer.Simple(0, function()
            table.RemoveByValue(self.vehicles, ent)
        end)
    end
end
