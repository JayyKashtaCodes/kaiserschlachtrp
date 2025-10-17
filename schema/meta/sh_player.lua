local PLAYER = FindMetaTable("Player")

function PLAYER:IsGA()
    local group = self:GetUserGroup()

    return group == "Community Manager"
        or group == "Owner"
        or group == "superadmin"
end

function PLAYER:IsUA()
    local group = self:GetUserGroup()

    return group == "Head Administrator"
        or group == "Supervisor Administrator"
        or group == "Server Developer"
        or group == "Server Manager"
        or group == "Community Manager"
        or group == "Owner"
        or group == "superadmin"
end

function PLAYER:IsUStaff()
    local group = self:GetUserGroup()

    return group == "Trial Administrator"
        or group == "Administrator"
        or group == "Senior Administrator"
        or group == "Head Administrator"
        or group == "Supervisor Administrator"
        or group == "Server Developer"
        or group == "Server Manager"
        or group == "Community Manager"
        or group == "Owner"
        or group == "superadmin"
end

function PLAYER:IsStaff()
    local group = self:GetUserGroup()

    return group == "Trial Moderator"
        or group == "Moderator"
        or group == "Senior Moderator"
        or group == "Trial Administrator"
        or group == "Administrator"
        or group == "Senior Administrator"
        or group == "Head Administrator"
        or group == "Supervisor Administrator"
        or group == "Server Developer"
        or group == "Server Manager"
        or group == "Community Manager"
        or group == "Owner"
        or group == "superadmin"
end

function PLAYER:IsDonatorPlus()
    local group = self:GetUserGroup()
    return group == "VIP+"
        or group == "Trial Moderator"
        or group == "Moderator"
        or group == "Senior Moderator"
        or group == "Trial Administrator"
        or group == "Administrator"
        or group == "Senior Administrator"
        or group == "Server Developer"
        or group == "Server Manager"
        or group == "Community Manager"
        or group == "Owner"
        or group == "superadmin"
end

function PLAYER:IsDonator()
    local group = self:GetUserGroup()
    return group == "VIP"
        or group == "VIP+"
        or group == "Trial Moderator"
        or group == "Moderator"
        or group == "Senior Moderator"
        or group == "Trial Administrator"
        or group == "Administrator"
        or group == "Senior Administrator"
        or group == "Server Developer"
        or group == "Server Manager"
        or group == "Community Manager"
        or group == "Owner"
        or group == "superadmin"
end