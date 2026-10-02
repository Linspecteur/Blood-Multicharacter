local ESX = exports['es_extended']:getSharedObject()

-- Vérifie au démarrage qu'es_extended tourne en mode multicharacter.
-- Sans ça, ESX charge le joueur tout seul à la connexion et ouvre le menu d'apparence
-- avant que le joueur ait pu créer son premier personnage.
CreateThread(function()
    local esxConfig = ESX.GetConfig and ESX.GetConfig() or {}
    if not esxConfig.Multichar then
        print("^1[bl_multicharacter] ==================================================================^7")
        print("^1[bl_multicharacter] Config.Multichar est désactivé dans es_extended !^7")
        print("^1[bl_multicharacter] Les joueurs ne pourront pas créer leur personnage.^7")
        print("^1[bl_multicharacter] Mettez Config.Multichar = true dans la config d'es_extended puis redémarrez le serveur.^7")
        print("^1[bl_multicharacter] ==================================================================^7")
    end
end)

-- Helper to get player's primary identifier matching ESX config
local function getPrimaryIdentifier(source)
    if ESX.GetIdentifier then
        local ident = ESX.GetIdentifier(source)
        if ident then return ident end
    end
    
    -- Fallback to Rockstar license
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(identifier, 1, 8) == "license:" then
            return identifier
        end
    end
    
    return GetPlayerIdentifiers(source)[1]
end

-- Phone column check state
local phoneColumn = nil

MySQL.ready(function()
    pcall(function()
        local checkPhone = MySQL.query.await("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND (COLUMN_NAME = 'phone_number' OR COLUMN_NAME = 'phone')")
        if checkPhone and #checkPhone > 0 then
            local hasPhoneNumber = false
            local hasPhone = false
            for _, col in ipairs(checkPhone) do
                if col.COLUMN_NAME == 'phone_number' then
                    hasPhoneNumber = true
                elseif col.COLUMN_NAME == 'phone' then
                    hasPhone = true
                end
            end
            if hasPhoneNumber then
                phoneColumn = 'phone_number'
            elseif hasPhone then
                phoneColumn = 'phone'
            end
            print(("^2[bl_multicharacter]^7 Colonne de téléphone détectée : '%s'"):format(phoneColumn))
        end
    end)
end)

-- Internal function to format accounts
local function parseAccounts(accountsStr)
    local accounts = {}
    if accountsStr and type(accountsStr) == 'string' then
        pcall(function()
            accounts = json.decode(accountsStr) or {}
        end)
    elseif type(accountsStr) == 'table' then
        accounts = accountsStr
    end
    
    local bank = 0
    local money = 0
    if accounts.bank then bank = accounts.bank end
    if accounts.money then money = accounts.money end
    
    return money, bank
end

-- Generate a random 9-digit SSN
local function generateSSN()
    local ssn = ""
    for i = 1, 9 do
        ssn = ssn .. tostring(math.random(0, 9))
    end
    return ssn
end

-- Generate a formatted phone number (e.g. 555-4821)
local function generatePhoneNumber()
    local prefix = math.random(100, 999)
    local suffix = math.random(1000, 9999)
    return tostring(prefix) .. "-" .. tostring(suffix)
end

-- Un slot n'est valide que s'il est un entier entre 1 et Config.MaxSlots
local function getValidSlot(value)
    local slot = tonumber(value)
    if not slot or slot ~= math.floor(slot) then return nil end
    if slot < 1 or slot > (Config.MaxSlots or 4) then return nil end
    return slot
end

local function getSlotType(slotNum)
    local slotData = Config.Slots and Config.Slots[slotNum] or {}
    return slotData.type or (slotNum == 4 and 'staff' or ((slotNum == 2 or slotNum == 3) and 'vip' or 'free'))
end

-- Nom / prénom : 2 à 32 octets, sans chiffres, balises ni caractères spéciaux
local function sanitizeName(value)
    if type(value) ~= 'string' then return nil end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if #value < 2 or #value > 32 then return nil end
    if value:find("[%d%c<>\"`{}%[%]\\;=%%]") then return nil end
    return value
end

-- Date de naissance au format JJ/MM/AAAA
local function sanitizeDateOfBirth(value)
    if type(value) ~= 'string' then return nil end
    local day, month, year = value:match("^(%d%d)/(%d%d)/(%d%d%d%d)$")
    day, month, year = tonumber(day), tonumber(month), tonumber(year)
    if not day or day < 1 or day > 31 or month < 1 or month > 12 or year < 1900 or year > 2015 then
        return nil
    end
    return value
end

local function sanitizeCharacterData(data)
    if type(data) ~= 'table' then return nil end
    local height = tonumber(data.height)
    local character = {
        firstname = sanitizeName(data.firstname),
        lastname = sanitizeName(data.lastname),
        dateofbirth = sanitizeDateOfBirth(data.dateofbirth),
        sex = (data.sex == 'm' or data.sex == 'f') and data.sex or nil,
        height = (height and height >= 140 and height <= 220) and math.floor(height) or nil
    }
    if not (character.firstname and character.lastname and character.dateofbirth and character.sex and character.height) then
        return nil
    end
    return character
end

-- Rouvre le menu côté client quand le serveur refuse une action (évite l'écran noir)
local function rejectAction(src, message)
    TriggerClientEvent('esx:showNotification', src, message)
    TriggerClientEvent('bl_multicharacter:actionFailed', src)
end

-- Comprehensive Multi-Source Resolver to check VIP and Staff status independently
local function checkPlayerPermissions(src, primaryIdentifier, baseLicense)
    if not src then return false, false end
    
    local allIdentifiers = GetPlayerIdentifiers(src) or {}
    if primaryIdentifier and #allIdentifiers == 0 then
        table.insert(allIdentifiers, primaryIdentifier)
    end

    local isStaff = false
    local isVip = false
    local staffGrade = nil
    local vipGrade = nil

    -- 1. Whitelists manuelles par licence Rockstar
    for _, id in ipairs(allIdentifiers) do
        if Config.StaffLicenses and Config.StaffLicenses[id] then
            isStaff = true
            staffGrade = "Config.StaffLicenses"
        end
        if Config.VIPLicenses and Config.VIPLicenses[id] then
            isVip = true
            vipGrade = "Config.VIPLicenses"
        end
    end

    -- Extraction des hash/hex d'identifiants
    local hexList = {}
    if baseLicense then table.insert(hexList, baseLicense) end
    for _, id in ipairs(allIdentifiers) do
        local hex = string.match(id, "(%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)")
        if hex then table.insert(hexList, hex) end
        local prefix, base = string.match(id, "^([^:]+:)(.+)$")
        if base and #base > 6 then table.insert(hexList, base) end
    end

    -- Helper de validation de grades
    local function isStaffGrade(grade)
        if not grade then return false end
        local gLow = tostring(grade):lower():gsub("%s+", "")
        return (Config.StaffGrades and (Config.StaffGrades[gLow] or Config.StaffGrades[tostring(grade)])) or false
    end

    local function isVIPGrade(grade)
        if not grade then return false end
        local gLow = tostring(grade):lower():gsub("%s+", "")
        return (Config.VIPGrades and (Config.VIPGrades[gLow] or Config.VIPGrades[tostring(grade)])) or false
    end

    -- 2. Vérification dans la table bl_staff (bl_admin)
    for _, id in ipairs(allIdentifiers) do
        local ok, staffQuery = pcall(function()
            return MySQL.query.await("SELECT grade FROM bl_staff WHERE identifier = @id OR identifier LIKE @likeId", {
                ['@id'] = id,
                ['@likeId'] = '%' .. id .. '%'
            })
        end)
        if ok and staffQuery and #staffQuery > 0 then
            for _, row in ipairs(staffQuery) do
                if isStaffGrade(row.grade) then
                    isStaff = true
                    staffGrade = row.grade
                end
                if isVIPGrade(row.grade) then
                    isVip = true
                    vipGrade = row.grade
                end
            end
        end
    end
    
    if not isStaff or not isVip then
        for _, hex in ipairs(hexList) do
            local ok, staffQuery = pcall(function()
                return MySQL.query.await("SELECT grade FROM bl_staff WHERE identifier LIKE @likeHex", {
                    ['@likeHex'] = '%' .. hex .. '%'
                })
            end)
            if ok and staffQuery and #staffQuery > 0 then
                for _, row in ipairs(staffQuery) do
                    if isStaffGrade(row.grade) then
                        isStaff = true
                        staffGrade = row.grade
                    end
                    if isVIPGrade(row.grade) then
                        isVip = true
                        vipGrade = row.grade
                    end
                end
            end
        end
    end

    -- 3. Vérification via l'instance xPlayer active d'ESX
    if ESX and ESX.GetPlayerFromId then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            local group = xPlayer.getGroup and xPlayer.getGroup() or xPlayer.group
            if isStaffGrade(group) then
                isStaff = true
                staffGrade = group
            end
            if isVIPGrade(group) then
                isVip = true
                vipGrade = group
            end
        end
    end

    -- 4. Vérification dans la table users d'ESX
    if not isStaff or not isVip then
        for _, hex in ipairs(hexList) do
            local ok, userRows = pcall(function()
                return MySQL.query.await("SELECT `group` FROM users WHERE identifier LIKE @likeHex", {
                    ['@likeHex'] = '%' .. hex .. '%'
                })
            end)
            if ok and userRows and #userRows > 0 then
                for _, row in ipairs(userRows) do
                    if isStaffGrade(row.group) then
                        isStaff = true
                        staffGrade = row.group
                    end
                    if isVIPGrade(row.group) then
                        isVip = true
                        vipGrade = row.group
                    end
                end
            end
        end
    end

    if not isStaff or not isVip then
        for _, id in ipairs(allIdentifiers) do
            local ok, userRows = pcall(function()
                return MySQL.query.await("SELECT `group` FROM users WHERE identifier = @id OR identifier LIKE @likeId", {
                    ['@id'] = id,
                    ['@likeId'] = '%' .. id .. '%'
                })
            end)
            if ok and userRows and #userRows > 0 then
                for _, row in ipairs(userRows) do
                    if isStaffGrade(row.group) then
                        isStaff = true
                        staffGrade = row.group
                    end
                    if isVIPGrade(row.group) then
                        isVip = true
                        vipGrade = row.group
                    end
                end
            end
        end
    end

    -- Le staff a automatiquement tous les privilèges VIP
    if isStaff then
        isVip = true
    end

    if isStaff then
        print(("^2[bl_multicharacter]^7 Rôle STAFF accordé (Grade: %s) pour %s"):format(staffGrade or "staff", primaryIdentifier or "inconnu"))
    elseif isVip then
        print(("^2[bl_multicharacter]^7 Rôle VIP accordé (Grade: %s) pour %s"):format(vipGrade or "vip", primaryIdentifier or "inconnu"))
    end

    return isVip, isStaff
end

-- Get characters for a player with self-healing DB migration and VIP/Staff slot permission check
ESX.RegisterServerCallback('bl_multicharacter:getCharacters', function(source, cb)
    local src = source
    local primaryIdentifier = getPrimaryIdentifier(src)
    
    if not primaryIdentifier then
        cb({}, {}, 0, false, false)
        return
    end

    -- Put player in a unique routing bucket (virtual dimension)
    pcall(function() SetPlayerRoutingBucket(src, src) end)

    local baseLicense = string.gsub(primaryIdentifier, "^[^:]+:", "")
    local prefix, baseHex = string.match(primaryIdentifier, "^([^:]+:)(.+)$")

    -- Check player's VIP and Staff privileges
    local isVip, isStaff = false, false
    local ok, resVip, resStaff = pcall(checkPlayerPermissions, src, primaryIdentifier, baseLicense)
    if ok then
        isVip = resVip or false
        isStaff = resStaff or false
    end

    -- Build dynamic slots configuration state
    local slotConfigs = {}
    for i = 1, (Config.MaxSlots or 4) do
        local slotData = Config.Slots and Config.Slots[i] or {}
        local slotType = slotData.type
        if not slotType then
            if slotData.staffOnly or i == 4 then
                slotType = 'staff'
            elseif slotData.vipOnly or (i == 2 or i == 3) then
                slotType = 'vip'
            else
                slotType = 'free'
            end
        end

        local isLocked = false
        if slotType == 'staff' then
            if not isStaff then
                isLocked = true
            end
        elseif slotType == 'vip' then
            if not isVip and not isStaff then
                isLocked = true
            end
        end

        table.insert(slotConfigs, {
            slot = i,
            type = slotType,
            isLocked = isLocked,
            label = slotData.label or ("Emplacement " .. i)
        })
    end

    local function formatPlaytime(seconds)
        if not seconds or seconds == 0 then return "0 m" end
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        if hours > 0 then
            if minutes > 0 then
                return hours .. " h " .. minutes .. " m"
            else
                return hours .. " h"
            end
        else
            return minutes .. " m"
        end
    end

    local function proceedFetch()
        local characters = {}
        local success, result = pcall(function()
            return MySQL.query.await("SELECT * FROM users WHERE identifier LIKE @identifier", {
                ['@identifier'] = '%' .. baseLicense .. '%'
            })
        end)
        
        if success and result then
            -- On ignore les lignes sans préfixe charN: (ex. une ligne "license:xxx" créée par ESX
            -- quand Config.Multichar était désactivé) : elles s'afficheraient en "Inconnu" et ne sont pas jouables
            local slotRows = {}
            for _, row in ipairs(result) do
                local slotStr = string.match(row.identifier or "", "^char(%d+):")
                if slotStr then
                    row._slot = tonumber(slotStr)
                    table.insert(slotRows, row)
                end
            end

            for _, char in ipairs(slotRows) do
                local cash, bank = parseAccounts(char.accounts)

                local slot = char._slot

                local jobLabel = char.job or "Sans emploi"
                local gradeLabel = tostring(char.job_grade or "")
                pcall(function()
                    if ESX.DoesJobExist and ESX.DoesJobExist(char.job, char.job_grade) then
                        local jobObj = ESX.GetJobs()[char.job]
                        if jobObj then
                            jobLabel = jobObj.label or jobLabel
                            if jobObj.grades and jobObj.grades[tostring(char.job_grade)] then
                                gradeLabel = jobObj.grades[tostring(char.job_grade)].label or gradeLabel
                            end
                        end
                    end
                end)

                local phoneVal = nil
                if phoneColumn and char[phoneColumn] and tostring(char[phoneColumn]) ~= "" and tostring(char[phoneColumn]) ~= "null" then
                    phoneVal = tostring(char[phoneColumn])
                elseif char.phone_number and tostring(char.phone_number) ~= "" and tostring(char.phone_number) ~= "null" then
                    phoneVal = tostring(char.phone_number)
                elseif char.phone and tostring(char.phone) ~= "" and tostring(char.phone) ~= "null" then
                    phoneVal = tostring(char.phone)
                end

                -- Auto-génération et persistance permanente si aucun numéro n'était défini
                if not phoneVal or phoneVal == "" or phoneVal == "Non défini" or phoneVal == "null" then
                    local newPhone = generatePhoneNumber()
                    phoneVal = newPhone
                    pcall(function()
                        local colToUpdate = phoneColumn or 'phone_number'
                        MySQL.update.await(("UPDATE users SET %s = @phone WHERE identifier = @ident"):format(colToUpdate), {
                            ['@phone'] = newPhone,
                            ['@ident'] = char.identifier
                        })
                    end)
                end

                table.insert(characters, {
                    id = slot,
                    identifier = char.identifier,
                    slot = slot,
                    firstname = char.firstname or 'Inconnu',
                    lastname = char.lastname or '',
                    dateofbirth = char.dateofbirth or '01/01/2000',
                    sex = char.sex or 'm',
                    height = char.height or 180,
                    job = char.job or 'unemployed',
                    job_grade = char.job_grade or 0,
                    jobLabel = jobLabel,
                    jobGradeLabel = gradeLabel,
                    money = cash,
                    bank = bank,
                    playtime = formatPlaytime(char.playtime or 0),
                    skin = char.skin,
                    phone = phoneVal
                })
            end
        end
        cb(characters, slotConfigs, #GetPlayers(), isVip, isStaff)
    end

    if prefix and baseHex then
        pcall(function()
            local dbUsers = MySQL.query.await("SELECT identifier FROM users WHERE identifier LIKE @query", {
                ['@query'] = '%:' .. baseHex
            })
            
            if dbUsers and #dbUsers > 0 then
                local migrateList = {}
                for _, row in ipairs(dbUsers) do
                    local slot = string.match(row.identifier or "", "^char(%d+):")
                    if slot then
                        local expectedIdentifier = "char" .. slot .. ":" .. primaryIdentifier
                        if row.identifier ~= expectedIdentifier then
                            table.insert(migrateList, { old = row.identifier, new = expectedIdentifier })
                        end
                    end
                end
                
                if #migrateList > 0 then
                    for _, mig in ipairs(migrateList) do
                        print(("^2[bl_multicharacter]^7 Migration identifiant DB: %s -> %s"):format(mig.old, mig.new))
                        MySQL.update.await("UPDATE users SET identifier = @new WHERE identifier = @old", {
                            ['@new'] = mig.new,
                            ['@old'] = mig.old
                        })
                    end
                end
            end
        end)
    end

    proceedFetch()
end)

-- Create a new character with server-side VIP and Staff validation
RegisterNetEvent('bl_multicharacter:createCharacter')
AddEventHandler('bl_multicharacter:createCharacter', function(data)
    local src = source
    local license = getPrimaryIdentifier(src)
    
    if not license then return end
    
    local slotNum = getValidSlot(type(data) == 'table' and data.slot)
    if not slotNum then
        rejectAction(src, "Emplacement invalide.")
        return
    end

    local character = sanitizeCharacterData(data)
    if not character then
        rejectAction(src, "Informations du personnage invalides.")
        return
    end

    local baseLicense = string.gsub(license, "^[^:]+:", "")

    -- Security verification: Check slot type against player permissions
    local slotType = getSlotType(slotNum)
    local isVip, isStaff = checkPlayerPermissions(src, license, baseLicense)

    if slotType == 'staff' and not isStaff then
        rejectAction(src, "Cet emplacement est strictement réservé au STAFF !")
        return
    elseif slotType == 'vip' and not isVip and not isStaff then
        rejectAction(src, "Cet emplacement est réservé aux membres VIP / Staff !")
        return
    end

    local newIdentifier = "char" .. slotNum .. ":" .. license

    local exists = MySQL.scalar.await("SELECT 1 FROM users WHERE identifier = @identifier", {
        ['@identifier'] = newIdentifier
    })
    
    if exists then
        rejectAction(src, "Cet emplacement est déjà utilisé !")
        return
    end

    local startingMoney = Config.StartingMoney or {}
    local accounts = json.encode({bank = startingMoney.bank or 50000, money = startingMoney.money or 1000})
    local ssn = generateSSN()
    local phoneNumber = generatePhoneNumber()
    
    local insertQuery = 'INSERT INTO users (identifier, firstname, lastname, dateofbirth, sex, height, accounts, ssn) VALUES (@identifier, @firstname, @lastname, @dob, @sex, @height, @accounts, @ssn)'
    local insertParams = {
        ['@identifier'] = newIdentifier,
        ['@firstname'] = character.firstname,
        ['@lastname'] = character.lastname,
        ['@dob'] = character.dateofbirth,
        ['@sex'] = character.sex,
        ['@height'] = character.height,
        ['@accounts'] = accounts,
        ['@ssn'] = ssn
    }

    if phoneColumn then
        insertQuery = ('INSERT INTO users (identifier, firstname, lastname, dateofbirth, sex, height, accounts, ssn, %s) VALUES (@identifier, @firstname, @lastname, @dob, @sex, @height, @accounts, @ssn, @phone)'):format(phoneColumn)
        insertParams['@phone'] = phoneNumber
    end

    MySQL.insert.await(insertQuery, insertParams)

    print(("^2[bl_multicharacter]^7 Nouveau personnage créé pour %s (Slot %d, SSN: %s, Tel: %s)"):format(newIdentifier, slotNum, ssn, phoneNumber))

    SetPlayerRoutingBucket(src, 0)
    TriggerEvent('esx:onPlayerJoined', src, "char" .. slotNum)

    if ESX.Players and license then
        ESX.Players[license] = "char" .. slotNum
    end
end)

-- Delete character with full multi-table cascade
RegisterNetEvent('bl_multicharacter:deleteCharacter')
AddEventHandler('bl_multicharacter:deleteCharacter', function(charId)
    local src = source
    local license = getPrimaryIdentifier(src)
    if not license then return end

    local slotNum = getValidSlot(charId)
    if not slotNum then return end

    -- Impossible de supprimer un personnage pendant qu'on le joue
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then return end

    local targetIdentifier = "char" .. slotNum .. ":" .. license

    -- Comprehensive list of tables to clean on character deletion
    local tablesToClean = {
        { table = 'users', column = 'identifier' },
        { table = 'user_accounts', column = 'identifier' },
        { table = 'user_inventory', column = 'identifier' },
        { table = 'user_licenses', column = 'owner' },
        { table = 'owned_vehicles', column = 'owner' },
        { table = 'ox_inventory', column = 'owner' },
        { table = 'billing', column = 'identifier' },
        { table = 'addon_account_data', column = 'owner' },
        { table = 'addon_inventory_items', column = 'owner' },
        { table = 'datastore_data', column = 'owner' },
        { table = 'bl_properties', column = 'owner' },
        { table = 'bl_keys', column = 'owner' }
    }

    for _, target in ipairs(tablesToClean) do
        pcall(function()
            MySQL.query.await(("DELETE FROM %s WHERE %s = @ident"):format(target.table, target.column), {
                ['@ident'] = targetIdentifier
            })
        end)
    end

    print(("^1[bl_multicharacter]^7 Personnage supprimé: %s"):format(targetIdentifier))
    TriggerClientEvent('bl_multicharacter:setupCharacters', src)
end)

-- Relog handling
local relogCooldowns = {}

RegisterNetEvent('bl_multicharacter:relog')
AddEventHandler('bl_multicharacter:relog', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer then
        local license = getPrimaryIdentifier(src)
        if license then
            local baseLicense = string.gsub(license, "^[^:]+:", "")
            local isVip, isStaff = checkPlayerPermissions(src, license, baseLicense)
            
            if not isVip and not isStaff then
                local now = os.time()
                local cooldown = Config.RelogCooldown or 600
                if relogCooldowns[license] and (now - relogCooldowns[license]) < cooldown then
                    local timeLeft = cooldown - (now - relogCooldowns[license])
                    local minutes = math.floor(timeLeft / 60)
                    local seconds = timeLeft % 60
                    local timeString = ""
                    if minutes > 0 then
                        timeString = minutes .. "m " .. seconds .. "s"
                    else
                        timeString = seconds .. "s"
                    end
                    TriggerClientEvent('esx:showNotification', src, "Vous devez attendre " .. timeString .. " avant de pouvoir changer de personnage.")
                    return
                end
                relogCooldowns[license] = now
            end
        end
        
        SetPlayerRoutingBucket(src, src)
        TriggerEvent('esx:playerLogout', src)
    end
end)

-- Play character event to handle safe in-game login
RegisterNetEvent('bl_multicharacter:playCharacter')
AddEventHandler('bl_multicharacter:playCharacter', function(charId)
    local src = source
    local primaryIdentifier = getPrimaryIdentifier(src)
    local slotNum = getValidSlot(charId)
    if not primaryIdentifier or not slotNum then
        rejectAction(src, "Emplacement invalide.")
        return
    end

    -- Déjà connecté sur un personnage : on ignore (évite un double chargement)
    if ESX.GetPlayerFromId(src) then return end

    -- Le personnage doit exister : sinon ESX en créerait un vide et contournerait la création
    local charPrefix = "char" .. slotNum
    local exists = MySQL.scalar.await("SELECT 1 FROM users WHERE identifier = @identifier", {
        ['@identifier'] = charPrefix .. ":" .. primaryIdentifier
    })
    if not exists then
        rejectAction(src, "Ce personnage n'existe pas.")
        return
    end

    -- Un ancien personnage VIP / Staff reste jouable seulement si le joueur a toujours le grade
    local slotType = getSlotType(slotNum)
    if slotType ~= 'free' then
        local baseLicense = string.gsub(primaryIdentifier, "^[^:]+:", "")
        local isVip, isStaff = checkPlayerPermissions(src, primaryIdentifier, baseLicense)
        if (slotType == 'staff' and not isStaff) or (slotType == 'vip' and not isVip) then
            rejectAction(src, "Cet emplacement est verrouillé.")
            return
        end
    end

    SetPlayerRoutingBucket(src, 0)
    TriggerEvent('esx:onPlayerJoined', src, charPrefix)
    
    if ESX.Players and primaryIdentifier then
        ESX.Players[primaryIdentifier] = charPrefix
    end
end)

-- Playtime tracking
MySQL.ready(function()
    pcall(function()
        local check = MySQL.query.await("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'playtime'")
        if not check or #check == 0 then
            MySQL.query.await("ALTER TABLE users ADD COLUMN playtime INT DEFAULT 0")
        end
    end)
end)

local activePlaytimes = {}

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    activePlaytimes[playerId] = os.time()
end)

local function savePlayerPlaytime(playerId)
    if activePlaytimes[playerId] then
        local now = os.time()
        local elapsed = now - activePlaytimes[playerId]
        activePlaytimes[playerId] = now
        
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and elapsed > 0 then
            pcall(function()
                MySQL.update("UPDATE users SET playtime = playtime + @time WHERE identifier = @identifier", {
                    ['@time'] = elapsed,
                    ['@identifier'] = xPlayer.identifier
                })
            end)
        end
    end
end

RegisterNetEvent('esx:playerLogout')
AddEventHandler('esx:playerLogout', function(playerId)
    savePlayerPlaytime(playerId)
    activePlaytimes[playerId] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    savePlayerPlaytime(src)
    activePlaytimes[src] = nil
end)

CreateThread(function()
    while true do
        Wait(60000)
        for playerId, _ in pairs(activePlaytimes) do
            savePlayerPlaytime(playerId)
        end
    end
end)