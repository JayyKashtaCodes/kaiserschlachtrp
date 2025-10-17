local PLUGIN = PLUGIN

PLUGIN.name = "Ambience Modifier"
PLUGIN.description = "Changes in-game ambient sound."
PLUGIN.author = "Dzhey Kashta"

if (CLIENT) then
    ix.option.Add("ambientEnabled", ix.type.bool, true, {
        category = "Gameplay",
        default = true,
    })

    local volume = 0.04

    local outdoorSound = "ambience/outside_ambience.wav"
    local playerAmbientState = {}
    local playerSoundObjects = {}

    local function IsPlayerOutside(player)
        if not IsValid(player) then return false end
        local traceData = {}
        traceData.start = player:GetPos()
        traceData.endpos = traceData.start + Vector(0, 0, 1000)
        traceData.filter = player

        local trace = util.TraceLine(traceData)
        return not trace.Hit or trace.HitSky
    end

    local function ChangeAmbientSound(player, soundPath)
        local playerID = player:SteamID()
        if not playerSoundObjects[playerID] then
            playerSoundObjects[playerID] = CreateSound(player, soundPath)
        end

        if not playerSoundObjects[playerID]:IsPlaying() then
            playerSoundObjects[playerID]:Play()
            playerSoundObjects[playerID]:ChangeVolume(volume, 0)
            playerSoundObjects[playerID]:SetSoundLevel(0)
        end
    end


    local function StopAmbientSound(player)
        local playerID = player:SteamID()
        if playerSoundObjects[playerID] then
            if playerSoundObjects[playerID]:IsPlaying() then
                playerSoundObjects[playerID]:Stop()
            end
            playerSoundObjects[playerID] = nil
        end
    end

    function PLUGIN:Think()
        if ix.option.Get("ambientEnabled", true) then
            for _, player in ipairs(player.GetAll()) do
                if not IsValid(player) then continue end

                local isOutside = IsPlayerOutside(player)
                local playerID = player:SteamID()

                if playerAmbientState[playerID] == nil then
                    playerAmbientState[playerID] = not isOutside
                end

                if isOutside and not playerAmbientState[playerID] then
                    ChangeAmbientSound(player, outdoorSound)
                    playerAmbientState[playerID] = true
                elseif not isOutside and playerAmbientState[playerID] then
                    StopAmbientSound(player)
                    playerAmbientState[playerID] = false
                end
            end
        end
    end
end
