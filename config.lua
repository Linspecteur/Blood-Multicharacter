Config = {}

-- Activer le mode débogage pour afficher les logs dans la console
Config.Debug = false

-- =========================================================================
--             CONFIGURATION DES EMPLACEMENTS DE PERSONNAGES (SLOTS)
-- =========================================================================
-- type = 'free'  : Accessible gratuitement à tous les joueurs.
-- type = 'vip'   : Réservé aux membres VIP et au Staff.
-- type = 'staff' : Strictement réservé aux membres du Staff / Administration.
Config.Slots = {
    [1] = { type = 'free',  label = "Emplacement 1" },
    [2] = { type = 'vip',   label = "Emplacement 2 (VIP)" },
    [3] = { type = 'vip',   label = "Emplacement 3 (VIP)" },
    [4] = { type = 'staff', label = "Emplacement 4 (STAFF)" }
}

-- Nombre de slots maximum gérés
Config.MaxSlots = 4

-- =========================================================================
--             GRADES AUTORISÉS POUR LES EMPLACEMENTS VIP (Slots 2 & 3)
-- =========================================================================
Config.VIPGrades = {
    ['vip'] = true,
    ['vip_gold'] = true,
    ['vip_diamond'] = true,
    ['vip_platine'] = true,
    ['premium'] = true,
    ['donateur'] = true
}

-- =========================================================================
--         GRADES AUTORISÉS POUR L'EMPLACEMENT STAFF (Slot 4) & VIP
-- =========================================================================
-- Vérifié via bl_admin (table 'bl_staff' -> colonne 'grade') ou ESX ('group')
Config.StaffGrades = {
    ['mod'] = true,
    ['moderateur'] = true,
    ['admin'] = true,
    ['superadmin'] = true,
    ['gerant'] = true,
    ['fondateur'] = true,
    ['owner'] = true,
    ['boss'] = true,
    ['responsable'] = true,
    ['staff'] = true,
    ['developpeur'] = true,
    ['dev'] = true
}

-- Whitelists manuelles par licence Rockstar (Rockstar License)
Config.VIPLicenses = {
    -- ["license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"] = true
}

Config.StaffLicenses = {
    -- ["license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"] = true
}

-- Coordonnées et orientation du ped de sélection (Legion Square)
Config.PedCoords = vector4(194.14, -889.02, 32.12, 270.0)

-- Emplacements disponibles dans le sélecteur de spawn
Config.Spawns = {
    {
        name = "Dernière Position",
        coords = nil,
        icon = "fa-solid fa-location-dot",
        description = "Réapparaître là où vous étiez lors de votre dernière déconnexion."
    },
    {
        name = "Aéroport de Los Santos",
        coords = vector3(-1037.71, -2738.13, 20.17),
        heading = 330.0,
        icon = "fa-solid fa-plane",
        description = "Commencez votre voyage depuis le terminal d'arrivée."
    },
    {
        name = "Gare Centrale",
        coords = vector3(-210.8, -1004.2, 29.1),
        heading = 250.0,
        icon = "fa-solid fa-train",
        description = "Arrivez directement au cœur du centre-ville."
    },
    {
        name = "Plage de Del Perro",
        coords = vector3(-1769.85, -1154.77, 13.07),
        heading = 70.0,
        icon = "fa-solid fa-umbrella-beach",
        description = "Profitez du sable chaud et du coucher de soleil."
    },
    {
        name = "Aérodrome de Sandy Shores",
        coords = vector3(1725.49, 3279.79, 41.07),
        heading = 120.0,
        icon = "fa-solid fa-helicopter",
        description = "Commencez votre voyage depuis le désert de Grand Senora."
    }
}

-- Temps de rechargement (en secondes) requis entre chaque changement de personnage (/mc)
Config.RelogCooldown = 600
