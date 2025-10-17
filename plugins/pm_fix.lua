local PLUGIN = PLUGIN

PLUGIN.name = "T-Pose Fix"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Fixes T-poses by assigning proper animation classes, hands, and player model registration."

ix.anim = ix.anim

local defaultHands = "models/weapons/c_arms_citizen.mdl"

local folderPaths = {
    "models/fearless",
    "models/1910rp",
    "models/coatksr",
    "models/iamhaed/ksr/newsuit",
    "models/sarcastic/heer/cavalry/hussars/en",
    "models/sarcastic/heer/cavalry/hussars/nco",
    "models/sarcastic/heer/cavalry/hussars/co",
    "models/sarcastic/heer/cavalry/hussars/go",
    "models/sarcastic/heer/infantry/grenadiers/en",
    "models/sarcastic/heer/infantry/grenadiers/nco",
    "models/sarcastic/heer/infantry/grenadiers/co",
    "models/sarcastic/heer/infantry/generals/go",
    "models/sarcastic/heer/medical/co",
    "models/sarcastic/heer/medical/go",
    "models/iamhaed/ksr/secret",
    "models/sarcastic/heer/stab/co",
    "models/ksr/policesr"
}

for _, folderPath in ipairs(folderPaths) do
    for _, fileName in ipairs(file.Find(folderPath .. "/*.mdl", "GAME")) do
        local modelPath = folderPath .. "/" .. fileName
        local modelId = string.Replace(fileName, ".mdl", ""):lower()

        ix.anim.SetModelClass(modelPath, "player")

        player_manager.AddValidModel(modelId, modelPath)

        local handModel = string.Replace(modelPath, ".mdl", "_arms.mdl")
        if file.Exists(handModel, "GAME") then
            player_manager.AddValidHands(modelPath, handModel, 0, "00000000")
        else
            player_manager.AddValidHands(modelPath, defaultHands, 0, "00000000")
        end

        if (SERVER) then
            --print("[T-Pose Fix] Registered: " .. modelPath)
        end
    end
end
