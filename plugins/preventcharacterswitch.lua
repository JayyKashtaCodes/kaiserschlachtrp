local PLUGIN = PLUGIN or {}
PLUGIN.name = "Prevent Damaged Character Switch"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Prevent players from switching characters after being damaged."

function PLUGIN:CanPlayerUseCharacter(client, character)
    if client.LastDamaged and client.LastDamaged > CurTime() - 180 and character:GetFaction() != FACTION_STAFF and client:GetCharacter() then
        return false, "You took or dealt damage too recently to switch characters!"
    end
end

function PLUGIN:PlayerDisconnected(ply)
    local character = ply:GetCharacter()
    if ply.LastDamaged and ply.LastDamaged > CurTime() - 180 and character:GetFaction() != FACTION_STAFF and character then
        print(ply:Nick() .. " disconnected from the server whilst a damage cooldown was active. [SteamID: " .. ply:SteamID() .. "]")
    end
end

function PLUGIN:EntityTakeDamage(ent, dmg)
    if not IsValid(ent) or not ent:IsPlayer() then return end

    local attacker = dmg:GetAttacker()

    if not dmg:IsFallDamage() and IsValid(attacker) and attacker:IsPlayer() and attacker != ent and ent:Team() != FACTION_STAFF then
        ent.LastDamaged = CurTime()
        attacker.LastDamaged = CurTime()
    end
end
