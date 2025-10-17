--/!/ FORMATTED RANKS FILE (WWI Imperial German) /!/--
-- This file follows the exact structure shown in your screenshots:
--   local PLUGIN = PLUGIN
--   local DEFAULT_RANKS = { ... }
--   local RANKS = { [CLASS_*] = { ["rankkey"] = { uid=, canInvite=, canPromote=, canKick=, displayName=, salary= }}}
--   return { RANKS = RANKS, DEFAULT_RANKS = DEFAULT_RANKS }
-- No helper functions, no class constant declarations here (assumed defined elsewhere).

local PLUGIN = PLUGIN

------------------------------------------------------------
-- DEFAULT RANKS (fallback)
------------------------------------------------------------
local DEFAULT_RANKS = {
    ["Recruit"] = {
        uid = 1,
        canInvite = false,
        canPromote = false,
        canKick = false,
        displayName = "Recruit",
        salary = 2.00
    },
    ["Soldier"] = {
        uid = 2,
        canInvite = true,
        canPromote = false,
        canKick = false,
        displayName = "Soldier",
        salary = 3.00
    },
    ["Commander"] = {
        uid = 3,
        canInvite = true,
        canPromote = true,
        canKick = true,
        displayName = "Commander",
        salary = 6.00
    },
    ["Leader"] = {
        uid = 4,
        canInvite = true,
        canPromote = true,
        canKick = true,
        displayName = "Leader",
        salary = 8.00
    }
}
------------------------------------------------------------
-- RANKS BY CLASS
------------------------------------------------------------
local RANKS = {
    --------------------------------------------------------
    -- Army: General Officers
    --------------------------------------------------------
    [CLASS_HOUSE] = {
        ["crownprince"] = { uid = 1, canInvite = true, canPromote = true, canKick = true, displayName = "Kronprinz", salary = 18.75 },
        ["german_crownprince"] = { uid = 2, canInvite = true, canPromote = true, canKick = true, displayName = "Deutscher Kronprinz", salary = 19.50 },
        ["kaiser"] = { uid = 3, canInvite = true, canPromote = true, canKick = true, displayName = "Der Kaiser und Oberster Kriegsherr", salary = 21.25 }
    },

    --------------------------------------------------------
    -- Army: General Officers
    --------------------------------------------------------
    [CLASS_GEN] = {
        ["generalmajor"]         = { uid = 1, canInvite = true, canPromote = true, canKick = true, displayName = "Generalmajor", salary = 11.00 },
        ["generalleutnant"]      = { uid = 2, canInvite = true, canPromote = true, canKick = true, displayName = "Generalleutnant", salary = 12.00 },
        ["generalderinfanterie"] = { uid = 3, canInvite = true, canPromote = true, canKick = true, displayName = "General der Infanterie", salary = 14.00 },
        ["generalkavallerie"]    = { uid = 4, canInvite = true, canPromote = true, canKick = true, displayName = "General der Kavallerie", salary = 14.00 },
        ["generalderartillerie"] = { uid = 5, canInvite = true, canPromote = true, canKick = true, displayName = "General der Artillerie", salary = 14.00 },
        ["generaloberst"]        = { uid = 6, canInvite = true, canPromote = true, canKick = true, displayName = "Generaloberst", salary = 16.00 },
        ["generalfeldmarschall"] = { uid = 7, canInvite = true, canPromote = true, canKick = true, displayName = "Generalfeldmarschall", salary = 18.00 }
    },

    --------------------------------------------------------
    -- Army: Husaren
    --------------------------------------------------------
    [CLASS_HUSAR] = {
        ["rekrut"]        = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Rekrut", salary = 1.00 },
        ["husar"]         = { uid = 2, canInvite = false, canPromote = false, canKick = false, displayName = "Husar", salary = 2.00 },
        ["oberhusar"]     = { uid = 3, canInvite = true, canPromote = false, canKick = false, displayName = "Oberhusar", salary = 3.00 },
        ["wachmeister"]   = { uid = 4, canInvite = true, canPromote = true, canKick = false, displayName = "Wachtmeister", salary = 4.00 },
        ["feldwebel"]     = { uid = 5, canInvite = true, canPromote = true, canKick = true, displayName = "Feldwebel", salary = 5.00 },
        ["leutnant"]      = { uid = 6, canInvite = true, canPromote = true, canKick = true, displayName = "Leutnant der Husaren", salary = 6.00 },
        ["oberleutnant"]  = { uid = 7, canInvite = true, canPromote = true, canKick = true, displayName = "Oberleutnant der Husaren", salary = 7.00 },
        ["rittmeister"]   = { uid = 8, canInvite = true, canPromote = true, canKick = true, displayName = "Rittmeister", salary = 8.00 },
        ["major"]         = { uid = 9, canInvite = true, canPromote = true, canKick = true, displayName = "Major der Kavallerie", salary = 9.00 },
        ["oberst"]        = { uid = 10, canInvite = true, canPromote = true, canKick = true, displayName = "Oberst der Husaren", salary = 10.00 }
    },

    --------------------------------------------------------
    -- Army: Garde / Garde-Grenadiers
    --------------------------------------------------------
    [CLASS_GARDE] = {
        ["rekrut"]        = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Garde-Grenadier (Rekrut)", salary = 1.25 },
        ["grenadier"]     = { uid = 2, canInvite = false, canPromote = false, canKick = false, displayName = "Garde-Grenadier", salary = 1.75 },
        ["obergfreiter"]  = { uid = 3, canInvite = false, canPromote = false, canKick = false, displayName = "Obergefreiter", salary = 2.25 },
        ["unteroffizier"] = { uid = 4, canInvite = true, canPromote = false, canKick = false, displayName = "Unteroffizier", salary = 3.50 },
        ["sergeant"]      = { uid = 5, canInvite = true, canPromote = true, canKick = false, displayName = "Sergeant", salary = 4.50 },
        ["feldwebel"]     = { uid = 6, canInvite = true, canPromote = true, canKick = true, displayName = "Feldwebel", salary = 5.50 },
        ["leutnant"]      = { uid = 7, canInvite = true, canPromote = true, canKick = true, displayName = "Leutnant", salary = 6.50 },
        ["oberleutnant"]  = { uid = 8, canInvite = true, canPromote = true, canKick = true, displayName = "Oberleutnant", salary = 7.50 },
        ["hauptmann"]     = { uid = 9, canInvite = true, canPromote = true, canKick = true, displayName = "Hauptmann", salary = 8.50 },
        ["major"]         = { uid = 10, canInvite = true, canPromote = true, canKick = true, displayName = "Major", salary = 9.50 },
        ["oberst"]        = { uid = 11, canInvite = true, canPromote = true, canKick = true, displayName = "Oberst", salary = 10.50 }
    },

    --------------------------------------------------------
    -- Army: Medical Service
    --------------------------------------------------------
    [CLASS_ARMYMED] = {
        ["sanitaetsdienst"]       = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Sanitätsdienst", salary = 2.00 },
        ["sanitaetsgefreiter"]    = { uid = 2, canInvite = false, canPromote = false, canKick = false, displayName = "Sanitätsgefreiter", salary = 2.50 },
        ["sanitaetsunteroffizier"]= { uid = 3, canInvite = true, canPromote = false, canKick = false, displayName = "Sanitätsunteroffizier", salary = 3.75 },
        ["sanitaetsfeldwebel"]    = { uid = 4, canInvite = true, canPromote = true, canKick = false, displayName = "Sanitätsfeldwebel", salary = 4.75 },
        ["assistenzarzt"]         = { uid = 5, canInvite = true, canPromote = true, canKick = true, displayName = "Assistenzarzt", salary = 6.50 },
        ["stabsarzt"]             = { uid = 6, canInvite = true, canPromote = true, canKick = true, displayName = "Stabsarzt", salary = 8.00 },
        ["oberstabsarzt"]         = { uid = 7, canInvite = true, canPromote = true, canKick = true, displayName = "Oberstabsarzt", salary = 9.50 },
        ["oberstarzt"]            = { uid = 8, canInvite = true, canPromote = true, canKick = true, displayName = "Oberstarzt", salary = 11.00 }
    },

    --------------------------------------------------------
    -- Army: Military Justice
    --------------------------------------------------------
    [CLASS_ARMYJUS] = {
        ["militaerrichter"] = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Militärrichter", salary = 8.00 },
        ["militaeranwalt"] = { uid = 2, canInvite = false, canPromote = false, canKick = false, displayName = "Militäranwalt", salary = 8.50},
        ["senatspraesident"] = { uid = 3, canInvite = true, canPromote = true, canKick = true, displayName = "Senatspräsident", salary = 10.00 },
        ["vizepraesident_rmg"] = { uid = 4, canInvite = true, canPromote = true, canKick = true, displayName = "Vizepräsident des Reichsmilitärgerichts", salary = 11.50 },
        ["praesident_rmg"] = { uid = 5, canInvite = true, canPromote = true, canKick = true, displayName = "Präsident des Reichsmilitärgerichts", salary = 13.00 }
    },

    --------------------------------------------------------
    -- Schutzpolizei
    --------------------------------------------------------
    [CLASS_SHU] = {
        ["schutzmann_anwaerter"]   = { uid = 1,  canInvite = false, canPromote = false, canKick = false, displayName = "Schutzmann‑Anwärter", salary = 1.25 },
        ["schutzmann"]             = { uid = 2,  canInvite = false, canPromote = false, canKick = false, displayName = "Schutzmann zu Fuß", salary = 1.75 },
        ["oberschutzmann"]         = { uid = 3,  canInvite = false, canPromote = false, canKick = false, displayName = "Oberschutzmann", salary = 2.25 },
        ["unterwachtmeister"]      = { uid = 4,  canInvite = true,  canPromote = false, canKick = false, displayName = "Unterwachtmeister", salary = 3.25 },
        ["wachtmeister"]           = { uid = 5,  canInvite = true,  canPromote = true,  canKick = false, displayName = "Wachtmeister", salary = 4.00 },
        ["abteilungswachtmeister"] = { uid = 6,  canInvite = true,  canPromote = true,  canKick = false, displayName = "Abteilungs‑wachtmeister", salary = 4.75 },
        ["stabswachtmeister"]      = { uid = 7,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Stabswachtmeister", salary = 5.25 },
        ["leutnant"]               = { uid = 8,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Leutnant", salary = 6.25 },
        ["oberleutnant"]           = { uid = 9,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Oberleutnant", salary = 7.25 },
        ["hauptmann"]              = { uid = 10, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Hauptmann", salary = 8.25 },
        ["oberst"]                 = { uid = 11, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Oberst", salary = 9.50 },
        ["chef_schutzpolizei"]     = { uid = 12, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Chef des Schutzpolizei", salary = 11.50 },
    },

    --------------------------------------------------------
    -- Kriminalpolizeiamt
    --------------------------------------------------------
    [CLASS_KPA] = {
        ["kriminalgehilfe"]         = { uid = 1,  canInvite = false, canPromote = false, canKick = false, displayName = "Kriminalgehilfe", salary = 2.00 },
        ["kriminalassistent"]       = { uid = 2,  canInvite = false, canPromote = false, canKick = false, displayName = "Kriminalassistent", salary = 2.50 },
        ["kriminalsekretaer"]       = { uid = 3,  canInvite = true,  canPromote = false, canKick = false, displayName = "Kriminalsekretär", salary = 3.25 },
        ["kriminalobersekretaer"]   = { uid = 4,  canInvite = true,  canPromote = true,  canKick = false, displayName = "Kriminalobersekretär", salary = 3.75 },
        ["kriminalinspektor"]       = { uid = 5,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Kriminalinspektor", salary = 4.50 },
        ["kriminaloberinspektor"]   = { uid = 6,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Kriminaloberinspektor", salary = 5.25 },
        ["kriminalkommissar"]       = { uid = 7,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Kriminalkommissar", salary = 6.25 },
        ["kriminaloberkommissar"]   = { uid = 8,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Kriminaloberkommissar", salary = 7.50 },
        ["kriminalhauptkommissar"]  = { uid = 9,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Kriminalhauptkommissar", salary = 8.50 },
        ["erster_kriminalhauptkommissar"] = { uid = 10, canInvite = true, canPromote = true, canKick = true, displayName = "Erster Kriminalhauptkommissar", salary = 9.50 },
        ["direktor_des_kpa"]        = { uid = 11, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Direktor des Kriminalpolizeiamt", salary = 11.50 }
    },

    --------------------------------------------------------
    -- Geheimpolizei
    --------------------------------------------------------
    [CLASS_GP] = {
        ["pgp_referat_i"]       = { uid = 1, canInvite = true, canPromote = false, canKick = false, displayName = "PGP Referat I - Politische Abteilung", salary = 6.00 },
        ["pgp_referat_ii"]      = { uid = 2, canInvite = true, canPromote = false, canKick = false, displayName = "PGP Referat II - Nachrichtendienstliche Abteilung", salary = 6.50 },
        ["pgp_referat_iii"]     = { uid = 3, canInvite = true, canPromote = false, canKick = false, displayName = "PGP Referat III - Ermittlung & Fahndung", salary = 6.50 },
        ["hauptstelle"]         = { uid = 4, canInvite = true, canPromote = true,  canKick = false, displayName = "Hauptstelle der Berliner Geheimpolizei", salary = 8.00 },
        ["sonderkommission"]    = { uid = 5, canInvite = true, canPromote = true,  canKick = false, displayName = "Sonderkommissionen (Krisenfälle)", salary = 9.00 },
        ["hauptstellenleiter"]  = { uid = 6, canInvite = true, canPromote = true,  canKick = true,  displayName = "Hauptstellenleiter der Berliner Geheimpolizei", salary = 11.50 }
    },
    --------------------------------------------------------
    -- Police High Command
    --------------------------------------------------------
    [CLASS_POLPRAS] = {
        ["stabschef_der_polizei"]  = { uid = 1, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Stabschef der Polizei", salary = 11.75 },
        ["polizei_vizepraesident"] = { uid = 2, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Polizei‑Vizepräsident", salary = 12.00 },
        ["polizeipraesident"]       = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Polizeipräsident", salary = 12.25 }
    },

    --------------------------------------------------------
    -- Interior Ministry
    --------------------------------------------------------
    [CLASS_IM] = {
        ["gehilfe"]                = { uid = 1,  canInvite = false, canPromote = false, canKick = false, displayName = "Gehilfe", salary = 2.50 },
        ["assistent"]              = { uid = 2,  canInvite = false, canPromote = false, canKick = false, displayName = "Assistent", salary = 3.00 },
        ["sekretaer"]              = { uid = 3,  canInvite = false, canPromote = false, canKick = false, displayName = "Sekretär", salary = 3.75 },
        ["obersekretaer"]          = { uid = 4,  canInvite = false, canPromote = false, canKick = false, displayName = "Obersekretär", salary = 4.25 },
        ["inspektor"]              = { uid = 5,  canInvite = true,  canPromote = false, canKick = false, displayName = "Inspektor", salary = 5.00 },
        ["oberinspektor"]          = { uid = 6,  canInvite = true,  canPromote = false, canKick = false, displayName = "Oberinspektor", salary = 5.50 },
        ["amtmann"]                = { uid = 7,  canInvite = true,  canPromote = true,  canKick = false, displayName = "Amtmann", salary = 6.00 },
        ["amtsrat"]                = { uid = 8,  canInvite = true,  canPromote = true,  canKick = false, displayName = "Amtsrat", salary = 6.50 },
        ["regierungsrat"]          = { uid = 9,  canInvite = true,  canPromote = true,  canKick = true,  displayName = "Regierungsrat", salary = 7.50 },
        ["oberregierungsrat"]      = { uid = 10, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Oberregierungsrat", salary = 8.50 },
        ["ministerialrat"]         = { uid = 11, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Ministerialrat", salary = 9.50 },
        ["ministerialdirigent"]    = { uid = 12, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Ministerialdirigent", salary = 10.50 },
        ["ministerialdirektor"]    = { uid = 13, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Ministerialdirektor", salary = 11.50 }
    },

    --------------------------------------------------------
    -- Interior Ministry High Command
    --------------------------------------------------------
    [CLASS_PIM] = {
        ["stellv_innenminister"]   = { uid = 1, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Preußischer Stellvertretender Innenminister", salary = 12.50 },
        ["preussischer_innenminister"] = { uid = 2, canInvite = true, canPromote = true, canKick = true, displayName = "Preußischer Innenminister", salary = 14.00 }
    },

    --------------------------------------------------------
    -- Imperial Cabinet
    --------------------------------------------------------
    [CLASS_KAB] = {
        ["kanzleisekretaer"]        = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Kanzleisekretär", salary = 10.25 },
        ["legationsrat_rk"]         = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Geheimer Legationsrat (Reichskanzlei)", salary = 10.50 },
        ["kabinettsrat"]            = { uid = 3, canInvite = true,  canPromote = true, canKick = false, displayName = "Kabinettsrat", salary = 10.75 },
        ["unterstaatssekretaer_rk"] = { uid = 4, canInvite = true,  canPromote = true,  canKick = true, displayName = "Unterstaatssekretär des Reichskanzleramts", salary = 11.00 },
        ["staatssekretaer_rk"]      = { uid = 5, canInvite = true,  canPromote = true,  canKick = true, displayName = "Staatssekretär des Reichskanzleramts", salary = 11.50 }
    },

    --------------------------------------------------------
    -- Foreign Office
    --------------------------------------------------------
    [CLASS_FOREIGN] = {
        ["botschafter_zivil"]    = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Ziviler Botschafter", salary = 7.50 },
        ["militaerattach"]       = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Militärattaché", salary = 7.50 },
        ["abteilungsleiter"]     = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Abteilungsleiter des Auswärtigen Amts", salary = 8.50 },
        ["unterstaatssekretaer"] = { uid = 4, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Unterstaatssekretär des Auswärtigen Amts", salary = 9.50 }
    },

    --------------------------------------------------------
    -- Foreign Office High Command
    --------------------------------------------------------
    [CLASS_SFOREIGN] = {
        ["staatssek_aa"] = { uid = 1, canInvite = true, canPromote = true, canKick = true, displayName = "Staatssekretär des Auswärtigen Amts", salary = 11.00 }
    },

    --------------------------------------------------------
    -- Finance Office
    --------------------------------------------------------
    [CLASS_KFA] = {
        ["reichsschatzrat"]       = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Reichsschatzrat", salary = 7.00 },
        ["oberreichsschatzrat"]   = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Oberreichsschatzrat", salary = 7.75 },
        ["abteilungsleiter"]      = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Abteilungsleiter des Reichsfinanzamts", salary = 8.50 },
        ["unterstaatssekretaer"]  = { uid = 4, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Unterstaatssekretär des Reichsfinanzamts", salary = 9.50 },
        ["praesident_reichsbank"] = { uid = 5, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Präsident der Reichsbank", salary = 10.50 }
    },

    --------------------------------------------------------
    -- Finance Office High Command
    --------------------------------------------------------
    [CLASS_SKFA] = {
        ["staatssek_finanz"] = { uid = 1, canInvite = true, canPromote = true, canKick = true, displayName = "Staatssekretär des Reichsfinanzamts", salary = 11.00 }
    },

    --------------------------------------------------------
    -- Naval Office
    --------------------------------------------------------
    [CLASS_MARINE] = {
        ["abteilungsleiter"]     = { uid = 1, canInvite = true, canPromote = true, canKick = false, displayName = "Abteilungsleiter des Reichsmarineamts", salary = 8.50 },
        ["unterstaatssekretaer"] = { uid = 2, canInvite = true, canPromote = true, canKick = true,  displayName = "Unterstaatssekretär des Reichsmarineamts", salary = 9.50 }
    },

    --------------------------------------------------------
    -- Naval Office High Command
    --------------------------------------------------------
    [CLASS_SMARINE] = {
        ["staatssek_marine"] = { uid = 1, canInvite = true, canPromote = true, canKick = true, displayName = "Staatssekretär des Reichsmarineamts", salary = 11.00 }
    },

    --------------------------------------------------------
    -- Justice Offices
    --------------------------------------------------------
    [CLASS_AMTSGER] = {
        ["amtsrichter"]         = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Amtsrichter", salary = 7.25 },
        ["oberamtsrichter"]     = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Oberamtsrichter", salary = 7.50 },
        ["direktor_amtsger"]    = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Direktor des Amtsgerichts", salary = 7.75 },
        ["er_dir_amtsger"]      = { uid = 4, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Erster Direktor des Amtsgerichts", salary = 8.00 }
    },

    [CLASS_LANDGER] = {
        ["landgerichtsrat"]     = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Landgerichtsrat", salary = 8.00 },
        ["landgerichtsdirektor"]= { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Landgerichtsdirektor", salary = 8.25 },
        ["pras_landger"]        = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Präsident des Landgerichts", salary = 8.50 }
    },

    [CLASS_OBLANDGER] = {
        ["oberlandesgerichtsrat"] = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Oberlandesgerichtsrat", salary = 8.50 },
        ["vpras_oblandger"]       = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Vizepräsident des Oberlandesgerichts", salary = 8.75 },
        ["pras_oblandger"]        = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Präsident des Oberlandesgerichts", salary = 9.00 }
    },

    [CLASS_KAMGER] = {
        ["kammergerichtsrat"]  = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Kammergerichtsrat", salary = 9.00 },
        ["vpras_kamger"]       = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Vizepräsident des Kammergerichts", salary = 9.10 },
        ["pras_kamger"]        = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Präsident des Kammergerichts", salary = 9.20 }
    },

    [CLASS_REICHGER] = {
        ["reichsgerichtsrat"]  = { uid = 1, canInvite = true,  canPromote = true,  canKick = false, displayName = "Reichsgerichtsrat", salary = 9.20 },
        ["vpras_reichger"]     = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Vizepräsident des Reichsgerichts", salary = 9.25 },
        ["pras_reichger"]      = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Präsident des Reichsgerichts", salary = 9.40 }
    },

    --------------------------------------------------------
    -- Amtsanwaltschaft (Local Court Prosecution Office)
    --------------------------------------------------------
    [CLASS_AMTSANW] = {
        ["amtsanwalt"]         = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Amtsanwalt", salary = 7.25 },
        ["oberamtsanwalt"]     = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Oberamtsanwalt", salary = 7.50 },
        ["leitender_amtsanwalt"] = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Leitender Amtsanwalt", salary = 7.75 },
        ["er_leit_amtsanwalt"] = { uid = 4, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Erster Leitender Amtsanwalt", salary = 8.00 }
    },

    --------------------------------------------------------
    -- Staatsanwaltschaft beim Landgericht
    --------------------------------------------------------
    [CLASS_LANDANW] = {
        ["staatsanwalt"]       = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Staatsanwalt", salary = 8.00 },
        ["oberstaatsanwalt"]   = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Oberstaatsanwalt", salary = 8.25 },
        ["leitender_staatsanwalt"] = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Leitender Staatsanwalt", salary = 8.50 }
    },

    --------------------------------------------------------
    -- Oberstaatsanwaltschaft beim Oberlandesgericht
    --------------------------------------------------------
    [CLASS_OBLANW] = {
        ["oberstaatsanwalt_olg"] = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Oberstaatsanwalt am Oberlandesgericht", salary = 8.50 },
        ["vgenstaatsanwalt"]     = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Vize-Generalstaatsanwalt", salary = 8.75 },
        ["genstaatsanwalt"]      = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Generalstaatsanwalt", salary = 9.00 }
    },

    --------------------------------------------------------
    -- Generalstaatsanwaltschaft beim Kammergericht
    --------------------------------------------------------
    [CLASS_KAMANW] = {
        ["kammergerichtsstaatsanwalt"] = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Staatsanwalt am Kammergericht", salary = 9.00 },
        ["vgenstaatsanwalt_kamger"]    = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Vize-Generalstaatsanwalt am Kammergericht", salary = 9.10 },
        ["genstaatsanwalt_kamger"]     = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Generalstaatsanwalt am Kammergericht", salary = 9.20 }
    },

    --------------------------------------------------------
    -- Reichsanwaltschaft beim Reichsgericht
    --------------------------------------------------------
    [CLASS_REICHANW] = {
        ["reichsanwalt"]        = { uid = 1, canInvite = true,  canPromote = true,  canKick = false, displayName = "Reichsanwalt", salary = 9.20 },
        ["vpras_reichsanwalt"]  = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Vizepräsident der Reichsanwaltschaft", salary = 9.25 },
        ["pras_reichsanwalt"]   = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Präsident der Reichsanwaltschaft", salary = 9.40 }
    },

    --------------------------------------------------------
    -- Justice Offices High Command
    --------------------------------------------------------
    [CLASS_SJUST] = {
        ["unterstaatssekretaer"] = { uid = 1, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Unterstaatssekretär des Reichsjustizamt", salary = 9.50 },
        ["staatssek_justiz"] = { uid = 2, canInvite = true, canPromote = true, canKick = true, displayName = "Staatssekretär des Reichsjustizamt", salary = 11.00 }
    },

    --------------------------------------------------------
    -- Colonial Office
    --------------------------------------------------------
    [CLASS_COLON] = {
        ["kolonialbeamte"]       = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Kolonialbeamte", salary = 6.50 },
        ["gouverneur"]           = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Gouverneur", salary = 8.75 },
        ["abteilungsleiter"]     = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Abteilungsleiter des Kolonialamtes", salary = 8.50 },
        ["unterstaatssekretaer"] = { uid = 4, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Unterstaatssekretär für Kolonialamtes", salary = 9.50 }
    },

    --------------------------------------------------------
    -- Colonial Office High Command
    --------------------------------------------------------
    [CLASS_SCOLON] = {
        ["staatssek_kolonial"] = { uid = 1, canInvite = true, canPromote = true, canKick = true, displayName = "Staatssekretär für Kolonial", salary = 11.00 }
    },

    --------------------------------------------------------
    -- Ministry of Spiritual, Educational, and Medical Affairs
    --------------------------------------------------------
    [CLASS_MEDU] = {
        ["medizinalrat"]              = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Medizinalrat", salary = 6.00 },
        ["ober-medizinalrat"]         = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Ober-Medizinalrat", salary = 6.50 },
        ["abteilungsleiter_med"]      = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Abteilungsleiter für Medizinalwesen", salary = 7.50 },
        ["unterstaatssekretaer_med"]  = { uid = 4, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Unterstaatssekretär für Medizinalangelegenheiten", salary = 8.50 }
    },

    [CLASS_GEDU] = {
        ["kirchenrat"]                = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Kirchenrat", salary = 6.00 },
        ["oberkirchenrat"]            = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Oberkirchenrat", salary = 6.50 },
        ["abteilungsleiter_kirche"]   = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Abteilungsleiter für Kirchliche Angelegenheiten", salary = 7.50 },
        ["unterstaatssekretaer_kirche"] = { uid = 4, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Unterstaatssekretär für Geistliche Angelegenheiten", salary = 8.50 }
    },

    [CLASS_UEDU] = {
        ["schulrat"]                  = { uid = 1, canInvite = true,  canPromote = false, canKick = false, displayName = "Schulrat", salary = 6.00 },
        ["oberschulrat"]              = { uid = 2, canInvite = true,  canPromote = true,  canKick = false, displayName = "Oberschulrat", salary = 6.50 },
        ["abteilungsleiter_unterricht"] = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Abteilungsleiter für Unterrichtswesen", salary = 7.50 }
    },

    [CLASS_SUEDU] = {
        ["unterstaatssekretaer_unterricht"] = { uid = 1, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Unterstaatssekretär für Unterrichtswesen", salary = 8.50 }
    },

    [CLASS_FWU] = {
        ["privatdozent"]   = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Privatdozent", salary = 4.50 },
        ["extraordinarius"] = { uid = 2, canInvite = false, canPromote = true,  canKick = false, displayName = "Extraordinarius (außerordentlicher Professor)", salary = 5.25 },
        ["ordinarius"]     = { uid = 3, canInvite = true,  canPromote = true,  canKick = false, displayName = "Ordinarius (ordentlicher Professor)", salary = 6.00 },
        ["prodekan"]       = { uid = 4, canInvite = true,  canPromote = true,  canKick = false, displayName = "Prodekan", salary = 6.50 },
        ["dekan"]          = { uid = 5, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Dekan", salary = 7.00 },
        ["prorektor"]      = { uid = 6, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Prorektor", salary = 7.50 },
        ["rektor"]         = { uid = 7, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Rektor der Friedrich-Wilhelms-Universität", salary = 8.00 }
    },

    [CLASS_SEDU] = {
        ["ministerialdirektor"]       = { uid = 1, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Ministerialdirektor", salary = 9.00 },
        ["staatssekretaer"]           = { uid = 2, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Staatssekretär des Ministeriums", salary = 9.50 },
        ["minister"]                  = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Minister für geistliche, Unterrichts- und Medizinalangelegenheiten", salary = 11.00 }
    },

    --------------------------------------------------------
    -- War Office
    --------------------------------------------------------
    [CLASS_WARO] = {
        ["stellvertretender_kriegsminister"] = { uid = 1, canInvite = true, canPromote = true, canKick = true, displayName = "Stellvertretender Kriegsminister", salary = 10.75 },
        ["preussischer_kriegsminister"]  = { uid = 2, canInvite = true, canPromote = true, canKick = true, displayName = "Preußischer Kriegsminister", salary = 12.00 }
    },

    --------------------------------------------------------
    -- Ausschuss für das Landheer und die Festungen
    --------------------------------------------------------
    [CLASS_AHF] = {
        ["mitglied_ausschuss_heer_festungen"]        = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Mitglied des Ausschusses für das Landheer und die Festungen", salary = 2.00 },
        ["stellv_vorsitz_ausschuss_heer_festungen"]  = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Stellvertretender Vorsitzender", salary = 4.00 },
        ["vorsitz_ausschuss_heer_festungen"]         = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Vorsitzender des Ausschusses für das Landheer und die Festungen", salary = 6.00 }
    },

    --------------------------------------------------------
    -- Ausschuss für das Seewesen
    --------------------------------------------------------
    [CLASS_ASW] = {
        ["mitglied_ausschuss_seewesen"]              = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Mitglied des Ausschusses für das Seewesen", salary = 2.00 },
        ["stellv_vorsitz_ausschuss_seewesen"]        = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Stellvertretender Vorsitzender", salary = 4.00 },
        ["vorsitz_ausschuss_seewesen"]               = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Vorsitzender des Ausschusses für das Seewesen", salary = 6.00 }
    },

    --------------------------------------------------------
    -- Ausschuss für das Zoll- und Steuerwesen
    --------------------------------------------------------
    [CLASS_AZS] = {
        ["mitglied_ausschuss_zoll_steuer"]           = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Mitglied des Ausschusses für das Zoll- und Steuerwesen", salary = 2.00 },
        ["stellv_vorsitz_ausschuss_zoll_steuer"]     = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Stellvertretender Vorsitzender", salary = 4.00 },
        ["vorsitz_ausschuss_zoll_steuer"]            = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Vorsitzender des Ausschusses für das Zoll- und Steuerwesen", salary = 6.00 }
    },

    --------------------------------------------------------
    -- Ausschuss für Handel und Verkehr
    --------------------------------------------------------
    [CLASS_AHV] = {
        ["mitglied_ausschuss_handel_verkehr"]        = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Mitglied des Ausschusses für Handel und Verkehr", salary = 2.00 },
        ["stellv_vorsitz_ausschuss_handel_verkehr"]  = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Stellvertretender Vorsitzender", salary = 4.00 },
        ["vorsitz_ausschuss_handel_verkehr"]         = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Vorsitzender des Ausschusses für Handel und Verkehr", salary = 6.00 }
    },

    --------------------------------------------------------
    -- Ausschuss für Justizwesen
    --------------------------------------------------------
    [CLASS_AJW] = {
        ["mitglied_ausschuss_justiz"]                = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Mitglied des Ausschusses für Justizwesen", salary = 2.00 },
        ["stellv_vorsitz_ausschuss_justiz"]          = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Stellvertretender Vorsitzender", salary = 4.00 },
        ["vorsitz_ausschuss_justiz"]                 = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Vorsitzender des Ausschusses für Justizwesen", salary = 6.00 }
    },

    --------------------------------------------------------
    -- Ausschuss für Rechnungswesen
    --------------------------------------------------------
    [CLASS_ARW] = {
        ["mitglied_ausschuss_rechnungswesen"]        = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Mitglied des Ausschusses für Rechnungswesen", salary = 2.00 },
        ["stellv_vorsitz_ausschuss_rechnungswesen"]  = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Stellvertretender Vorsitzender", salary = 4.00 },
        ["vorsitz_ausschuss_rechnungswesen"]         = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Vorsitzender des Ausschusses für Rechnungswesen", salary = 6.00 }
    },

    --------------------------------------------------------
    -- Ausschuss für Auswärtige Angelegenheiten
    --------------------------------------------------------
    [CLASS_AAA] = {
        ["mitglied_ausschuss_auswaertiges"]          = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Mitglied des Ausschusses für Auswärtige Angelegenheiten", salary = 2.00 },
        ["stellv_vorsitz_ausschuss_auswaertiges"]    = { uid = 2, canInvite = true,  canPromote = false, canKick = false, displayName = "Stellvertretender Vorsitzender", salary = 4.00 },
        ["vorsitz_ausschuss_auswaertiges"]           = { uid = 3, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Vorsitzender des Ausschusses für Auswärtige Angelegenheiten", salary = 6.00 }
    },

    --------------------------------------------------------
    -- Bundesrat
    --------------------------------------------------------
    [CLASS_BUND] = {
        ["praesident_bundesrat"]     = { uid = 1, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Präsident des Bundesrats", salary = 6.75 }
    },

    --------------------------------------------------------
    -- Reich Leadership & Parliament
    --------------------------------------------------------
    [CLASS_REICH] = {
        ["mitglied_reichstag"]        = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Mitglied des Reichstags", salary = 6.50 },
        ["reichstag_mitglied"]        = { uid = 2, canInvite = false, canPromote = false, canKick = false, displayName = "Deutscher Reichstag (Mitglied)", salary = 6.50 },
        ["reichstagsfraktionsleiter"] = { uid = 3, canInvite = true,  canPromote = false, canKick = false, displayName = "Reichstagsfraktionsleiter", salary = 8.00 },
        ["reichstag_vizepraesident"]  = { uid = 4, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Vizepräsident des Reichstags", salary = 9.50 },
        ["reichstag_praesident"]      = { uid = 5, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Reichstagspräsident", salary = 10.50 },
    },

    [CLASS_REICHKAN] = {
        ["reichskanzler"] = { uid = 1, canInvite = true,  canPromote = true,  canKick = true,  displayName = "Reichskanzler", salary = 18.50 }
    },

    --------------------------------------------------------
    -- Ministry of Labour & Economics (Arbeit und Wirtschaft)
    --------------------------------------------------------
    [CLASS_MAW] = {
        ["sekretaer_maw"]         = { uid = 1, canInvite = false, canPromote = false, canKick = false, displayName = "Sekretär im Ministerium für Arbeit und Wirtschaft", salary = 4.00 },
        ["obersekretaer_maw"]     = { uid = 2, canInvite = false, canPromote = false, canKick = false, displayName = "Obersekretär im Ministerium für Arbeit und Wirtschaft", salary = 5.00 },
        ["rat_maw"]               = { uid = 3, canInvite = true,  canPromote = false, canKick = false, displayName = "Ministerialrat für Arbeit und Wirtschaft", salary = 8.00 }
    },

    [CLASS_SMAW] = {
        ["staatssekretaer_maw"]   = { uid = 1, canInvite = true,  canPromote = true,  canKick = false, displayName = "Staatssekretär für Arbeit und Wirtschaft", salary = 9.50 }
    }
}
--/!/ KEEP THIS AT THE BOTTOM /!/--
return {
    RANKS = RANKS,
    DEFAULT_RANKS = DEFAULT_RANKS
}
--/!/ KEEP THIS AT THE BOTTOM /!/--
