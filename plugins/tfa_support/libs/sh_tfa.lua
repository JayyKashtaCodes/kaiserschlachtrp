
local PLUGIN = PLUGIN

ix.tfa = {}
ix.tfa.attachments = {}
ix.tfa.grenades = {}
ix.tfa.freeAttachments = {}

ix.tfa.excludedWeapons = ix.tfa.excludedWeapons or {}

table.Merge(ix.tfa.excludedWeapons, {
    ["tfa_nmrih_fubar"] = true,
    ["tfa_nmrih_pickaxe"] = true,
    ["tfa_nmrih_hatchet"] = true,
    ["tfa_nmrih_fireaxe"] = true,
    ["tfa_nmrih_chainsaw"] = true,
    ["tfa_nmrih_fists"] = true,
    ["tfa_nmrih_asaw"] = true,
    ["tfa_nmrih_spade"] = true,
})


if SERVER then
    -- set up a weapon's attachments on equip, based on it's default value or data
    function ix.tfa.InitWeapon(client, weapon, item)
        if !IsValid(client) or !IsValid(weapon) or !item then return end

        local atts = item:GetAttachments()
        for k, _ in pairs(atts) do
            weapon:Attach(k, true)
        end

        if item.isGrenade then
            weapon:SetClip1(1)
        else
            weapon:SetClip1(item:GetData("ammo", 0))
        end
    end
end

-- generates attachment items automatically
function ix.tfa.GenerateAttachments()
    if ix.tfa.attachmentsGenerated then return end

    for attID, attTable in pairs(TFA.Attachments.Atts) do
        if !ix.tfa.IsFreeAttachment(attID) then
            if !ix.tfa.attachments[attID] then
                local ITEM = ix.item.Register(attID, "base_tfa_attachments", false, nil, true)
                ITEM.name = attTable.Name
                ITEM.description = "An attachment, used to modify weapons."
                ITEM.att = attID
                ITEM.isGenerated = true

                ix.tfa.attachments[ITEM.att] = attID
            end
        end
    end

    ix.tfa.attachmentsGenerated = true
end

-- generates weapon items automatically
function ix.tfa.GenerateWeapons()
    if ix.tfa.weaponsGenerated then return end

    local holsterPresets = {
        Throwable = {
            pos = Vector(4, 4, 0),
            ang = Angle(15, 0, 270),
            bone = "ValveBiped.Bip01_Pelvis"
        },
        Melee = {
            pos = Vector(7, 0, -2),
            ang = Angle(0, 180, -90),
            bone = "ValveBiped.Bip01_Spine"
        },
        Secondary = {
            pos = Vector(7, -2, 2),
            ang = Angle(0, -90, 0),
            bone = "ValveBiped.Bip01_Pelvis"
        },
        Primary = {
            pos = Vector(5, 5, 0),
            ang = Angle(0, 0, 0),
            bone = "ValveBiped.Bip01_Spine"
        }
    }

    for _, v in ipairs(weapons.GetList()) do
        if ix.tfa.excludedWeapons[v.ClassName] then continue end
        if not v.PrintName or not v.Base or not string.find(v.Base, "tfa_") then continue end
        if string.find(v.ClassName, "base") then continue end

        local ITEM = ix.item.Register(v.ClassName, "base_tfa_weapons", false, nil, true)
        ITEM.name = v.PrintName
        ITEM.description = v.Description or nil
        ITEM.model = v.WorldModel
        ITEM.class = v.ClassName
        ITEM.isGenerated = true

        local class
        if v.Type then
            class = v.Type:lower():gsub("%s+", "")
        end

        if v.IsGrenade or (class and string.find(class, "grenade") and not string.find(class, "launch")) or (class and string.find(class, "throw")) then
            ITEM.weaponCategory = "Throwable"
            ITEM.width = 1
            ITEM.height = 1
            ITEM.isGrenade = true
            ix.tfa.grenades[v.ClassName] = true
        elseif string.find(v.Base, "melee") or (class and string.find(class, "melee")) or (v.HoldType and (v.HoldType == "melee") or (v.HoldType == "knife")) then
            ITEM.weaponCategory = "Melee"
            ITEM.width = 1
            ITEM.height = 2
        elseif v.HoldType and (v.HoldType == "pistol" or v.HoldType == "revolver") then
            ITEM.weaponCategory = "Secondary"
            ITEM.width = 2
            ITEM.height = 1
        else
            ITEM.weaponCategory = "Primary"
            ITEM.width = 3
            ITEM.height = 1

            if class and string.find(class, "shotgun") then
                ITEM.width = 3
                ITEM.height = 2
            elseif class and (string.find(class, "sniper") or string.find(class, "marksman")) then
                ITEM.width = 4
                ITEM.height = 2
            elseif class and (string.find(class, "smg") or string.find(class, "sub")) then
                ITEM.width = 3
                ITEM.height = 2
            elseif class and (string.find(class, "lmg") or string.find(class, "machinegun") or string.find(class, "hmg")) then
                ITEM.width = 4
                ITEM.height = 2
            else
                ITEM.width = 3
                ITEM.height = 2
            end
        end

        if ITEM.weaponCategory == "Throwable" then
            ITEM.category = "TFA - Grenades"
        elseif ITEM.weaponCategory == "Melee" then
            ITEM.category = "TFA - Melee"
        elseif ITEM.weaponCategory == "Secondary" then
            ITEM.category = "TFA - Secondary"
        else
            ITEM.category = "TFA - Primary"
        end

        local override = ix.tfa.weaponOverrides[v.ClassName:lower()]
        if override then
            ITEM.width = override.width or ITEM.width
            ITEM.height = override.height or ITEM.height
            ITEM.weaponCategory = override.category or ITEM.weaponCategory
        end

        -- Inject holster visual config (override takes priority)
        local holsterInfo = override and override.holster or holsterPresets[ITEM.weaponCategory]
        if holsterInfo then
            ITEM.holsterDrawInfo = {
                pos = holsterInfo.pos,
                ang = holsterInfo.ang,
                bone = holsterInfo.bone,
                model = v.WorldModel
            }

            HOLSTER_DRAWINFO = HOLSTER_DRAWINFO or {}
            HOLSTER_DRAWINFO[v.ClassName:lower()] = ITEM.holsterDrawInfo
        end
    end

    ix.tfa.weaponsGenerated = true
end

-- returns the item id for the passed attachment id
function ix.tfa.GetItemForAttachment(att)
    return ix.tfa.attachments[att]
end

function ix.tfa.IsFreeAttachment(att)
    return ix.tfa.freeAttachments[att]
end

function ix.tfa.MakeFreeAttachment(att)
    ix.tfa.freeAttachments[att] = true
end