local PLUGIN = PLUGIN
PLUGIN.name = "Cigarettes"
PLUGIN.author = "JohnyReaper"
PLUGIN.desc = "Let's smoke."

ALWAYS_RAISED["weapon_ciga"] = true
ALWAYS_RAISED["weapon_ciga_cheap"] = true
ALWAYS_RAISED["weapon_ciga_blat"] = true
ALWAYS_RAISED["weapon_cigar"] = true

function PLUGIN:PlayerLoadedCharacter(client, newChar, prevChar)
    -- Clean up old cig timers
    if (prevChar) then
        if (prevChar.HasCig) then
            if (timer.Exists("ligcig_"..prevChar:GetID())) then
                timer.Remove("ligcig_"..prevChar:GetID())
            end
            prevChar.HasCig = false
        end
    end

    -- Give permanent cigar to DonatorPlus players
    if client:IsDonatorPlus() then
        -- Delay slightly to ensure loadout is complete
        timer.Simple(0.1, function()
            if IsValid(client) and client:Alive() then
                if not client:HasWeapon("weapon_cigar") then
                    client:Give("weapon_cigar")
                end
            end
        end)
    end
end
