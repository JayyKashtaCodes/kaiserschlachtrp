local PLUGIN = PLUGIN

PLUGIN.classGroups = {
    ["Innern"] = {
        class = {CLASS_SHU, CLASS_GP, CLASS_IM, CLASS_KPA, CLASS_HOUSE, CLASS_STAFF}
    },
    ["Government"] = {
        class = {
            CLASS_BUND, CLASS_COLON, CLASS_DKP, CLASS_HOUSE,
            CLASS_DZP, CLASS_FOREIGN, CLASS_JUST, CLASS_KAB, CLASS_KFA,
            CLASS_MARINE, CLASS_MAW, CLASS_NLP, CLASS_REICH, CLASS_SPD, CLASS_STAFF
        }
    },
    ["Army"] = {
        class = {CLASS_GEN, CLASS_ARMYJUS, CLASS_ARMYMED, CLASS_GARDE, CLASS_HUSAR, CLASS_HOUSE, CLASS_STAFF}
    }, 
    ["Gerichtsgebäude"] = { ---- this should be removed
        class = {
            CLASS_SJUST,
            CLASS_AMTSGER,
            CLASS_LANDGER,
            CLASS_OBLANDGER,
            CLASS_KAMGER,
            CLASS_REICHGER,
            CLASS_GEN,
            CLASS_ARMYJUS,
            CLASS_ARMYMED,
            CLASS_GARDE,
            CLASS_HUSAR,
            CLASS_SHU,
            CLASS_GP,
            CLASS_IM,
            CLASS_KPA,
            CLASS_HOUSE,
            CLASS_STAFF
        }
    },
    ["Polizeiwache"] = { ---- so should this
        class = {CLASS_SHU, CLASS_GP, CLASS_IM, CLASS_KPA, CLASS_ARMYJUS, CLASS_HOUSE, CLASS_STAFF}
    }, 
    ["Polizeipräsidium_Berlin"] = { ---- replacement 
        class = {CLASS_SHU, CLASS_GP, CLASS_IM, CLASS_KPA, CLASS_ARMYJUS, CLASS_HOUSE, CLASS_STAFF}
    },
    ["Preußisches_Innenministerium"] = {
        class = {CLASS_IM, CLASS_PIM, CLASS_POLPRAS, CLASS_SHU, CLASS_KPA, CLASS_GP, CLASS_STAFF}
    },
    ["Landgericht_Berlin"] = { ---- replacement
        class = {
            CLASS_SJUST,
            CLASS_AMTSGER,
            CLASS_LANDGER,
            CLASS_OBLANDGER,
            CLASS_KAMGER,
            CLASS_REICHGER,
            CLASS_GEN,
            CLASS_ARMYJUS,
            CLASS_ARMYMED,
            CLASS_GARDE,
            CLASS_HUSAR,
            CLASS_SHU,
            CLASS_GP,
            CLASS_IM,
            CLASS_KPA,
            CLASS_HOUSE,
            CLASS_STAFF}
    },
    ["Reichstag"] = {
        class = {CLASS_REICH, CLASS_BUND, CLASS_STAFF}
    },
    ["Große_Hauptquartier"] = {
        class = {CLASS_GEN, CLASS_HUSAR, CLASS_GARDE, CLASS_ARMYMED, CLASS_ARMYJUS, CLASS_STAFF}
    },
    ["Reichskanzlei"] = {
        class = {CLASS_REICHKAN, CLASS_KAB, CLASS_FOREIGN, CLASS_KFA, CLASS_COLON, CLASS_MARINE, CLASS_MAW, CLASS_SFOREIGN, CLASS_SKFA, CLASS_SMARINE, CLASS_STAFF}
    },
    ["Berliner_Schloss"] = {
        class = {CLASS_HOUSE, CLASS_GARDE, CLASS_KAB, CLASS_STAFF}
    },
    ["Berliner_Krankenhaus"] = {
        class = {CLASS_ARMYMED, CLASS_SMARINE, CLASS_STAFF}
    },
}