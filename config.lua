Config = {}

-- Activer le mode débogage pour afficher les logs dans la console
Config.Debug = false

Config.DefaultSlots = 2 -- Default slot count for regular players
Config.MaxSlots = 4     -- Max slot count possible for staff / VIPs

-- ESX Groups that unlock all character slots (Config.MaxSlots)
Config.StaffGroups = {
    ['admin'] = true,
    ['superadmin'] = true,
    ['boss'] = true
}

-- Specific player licenses (Rockstar licenses) that unlock all character slots
Config.VIPLicenses = {
    -- ["license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"] = true
}

-- Selection ped coordinates and heading (Legion Square)
Config.PedCoords = vector4(194.14, -889.02, 32.12, 270.0)

-- Locations available in the Spawn Selector
Config.Spawns = {
    {
        name = "Dernière Position",
        coords = nil, -- uses player's database last coords
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

-- Temps de rechargement (en secondes) requis entre chaque changement de personnage (/mc) pour éviter l'abus de téléportation/spawn
Config.RelogCooldown = 600

