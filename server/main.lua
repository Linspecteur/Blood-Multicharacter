local ESX = exports['es_extended']:getSharedObject()
if ESX.GetConfig() then
    ESX.GetConfig().Multichar = true
end
local maxSlots = 4

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
    
    -- Second fallback to first identifier
    return GetPlayerIdentifiers(source)[1]
end


-- Phone column check state
local phoneColumn = nil

MySQL.ready(function()
    -- Check phone number column in the users table
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
    else
        print("^1[bl_multicharacter]^7 Aucune colonne de téléphone ('phone_number' ou 'phone') trouvée dans 'users'.")
    end
end)

-- Internal function to format accounts
local function parseAccounts(accountsStr)
    local accounts = {}
    if accountsStr and type(accountsStr) == 'string' then
        accounts = json.decode(accountsStr) or {}
    end
    
    local bank = 0
    local money = 0
    if accounts.bank then
        bank = accounts.bank
    end
    if accounts.money then
        money = accounts.money
    end
    
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

-- Get characters for a player with self-healing DB migration
ESX.RegisterServerCallback('bl_multicharacter:getCharacters', function(source, cb)
    local src = source
    local primaryIdentifier = getPrimaryIdentifier(src)
    
    if not primaryIdentifier then
        cb({})
        return
    end

    -- Put player in a unique routing bucket (virtual dimension) to hide them from other players
    SetPlayerRoutingBucket(src, src)

    local baseLicense = string.gsub(primaryIdentifier, "^[^:]+:", "")
    local prefix, baseHex = string.match(primaryIdentifier, "^([^:]+:)(.+)$")

    -- Check if player has custom slots in multicharacter_slots table
    local playerMaxSlots = MySQL.scalar.await("SELECT slots FROM multicharacter_slots WHERE identifier = @identifier", {
        ['@identifier'] = primaryIdentifier
    })
    
    -- Query player's group from database to determine if staff or VIP
    local userGroup = MySQL.scalar.await("SELECT `group` FROM users WHERE identifier LIKE @identifier", {
        ['@identifier'] = '%' .. baseLicense .. '%'
    }) or "user"
    
    local isStaffOrVip = false
    if Config.StaffGroups[userGroup] or Config.VIPLicenses[primaryIdentifier] then
        isStaffOrVip = true
    end

    local allowedSlots = Config.DefaultSlots or 2
    if isStaffOrVip then
        allowedSlots = Config.MaxSlots or 4
    end
    if playerMaxSlots then
        allowedSlots = tonumber(playerMaxSlots)
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
        -- Build SELECT dynamically to avoid query crashes if phone column does not exist
        local querySelect = "SELECT identifier, firstname, lastname, job, job_grade, accounts, dateofbirth, sex, height, skin, playtime"
        if phoneColumn then
            querySelect = querySelect .. ", " .. phoneColumn
        end
        querySelect = querySelect .. " FROM users WHERE identifier LIKE @identifier"

        local result = MySQL.query.await(querySelect, {
            ['@identifier'] = '%' .. baseLicense .. '%'
        })
        
        local characters = {}
        if result then
            for i, char in ipairs(result) do
                local cash, bank = parseAccounts(char.accounts)
                
                -- Detect slot based on identifier (e.g. char1:license:...) or assume order
                local slotStr = string.match(char.identifier, "char(%d+):")
                local slot = slotStr and tonumber(slotStr) or i
                
                -- Fetch job labels
                local jobLabel = char.job
                local gradeLabel = char.job_grade
                if ESX.DoesJobExist(char.job, char.job_grade) then
                    local jobObj = ESX.GetJobs()[char.job]
                    jobLabel = jobObj.label
                    gradeLabel = jobObj.grades[tostring(char.job_grade)].label
                end

                -- Dynamic phone extraction
                local phoneVal = "Non défini"
                if phoneColumn and char[phoneColumn] then
                    phoneVal = char[phoneColumn]
                end

                table.insert(characters, {
                    id = slot,
                    identifier = char.identifier,
                    slot = slot,
                    firstname = char.firstname or 'Unknown',
                    lastname = char.lastname or 'Unknown',
                    dateofbirth = char.dateofbirth or 'Unknown',
                    sex = char.sex or 'm',
                    height = char.height or 180,
                    job = char.job,
                    job_grade = char.job_grade,
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
        cb(characters, allowedSlots, #GetPlayers(), isStaffOrVip)
    end

    if prefix and baseHex then
        local dbUsers = MySQL.query.await("SELECT identifier FROM users WHERE identifier LIKE @query", {
            ['@query'] = '%:' .. baseHex
        })
        
        if dbUsers and #dbUsers > 0 then
            local migrateList = {}
            for _, row in ipairs(dbUsers) do
                local slot = string.match(row.identifier, "^char(%d+):")
                if slot then
                    local expectedIdentifier = "char" .. slot .. ":" .. primaryIdentifier
                    if row.identifier ~= expectedIdentifier then
                        table.insert(migrateList, { old = row.identifier, new = expectedIdentifier })
                    end
                end
            end
            
            if #migrateList == 0 then
                proceedFetch()
            else
                for _, mig in ipairs(migrateList) do
                    print(("^2[bl_multicharacter]^7 Migrating character database record from %s to %s"):format(mig.old, mig.new))
                    MySQL.update.await("UPDATE users SET identifier = @new WHERE identifier = @old", {
                        ['@new'] = mig.new,
                        ['@old'] = mig.old
                    })
                end
                proceedFetch()
            end
        else
            proceedFetch()
        end
    else
        proceedFetch()
    end
end)

-- Create a new character
RegisterNetEvent('bl_multicharacter:createCharacter')
AddEventHandler('bl_multicharacter:createCharacter', function(data)
    local src = source
    local license = getPrimaryIdentifier(src)
    
    if not license then return end
    
    local newIdentifier = "char" .. data.slot .. ":" .. license

    -- Basic check to prevent overwrite
    local exists = MySQL.scalar.await("SELECT 1 FROM users WHERE identifier = @identifier", {
        ['@identifier'] = newIdentifier
    })
    
    if exists then
        TriggerClientEvent('esx:showNotification', src, "Slot already taken!")
        return
    end
    
    -- Insert into DB
    local accounts = json.encode({bank = 50000, money = 1000}) -- default starting bank and cash
    local ssn = generateSSN()
    
    MySQL.insert.await('INSERT INTO users (identifier, firstname, lastname, dateofbirth, sex, height, accounts, ssn) VALUES (@identifier, @firstname, @lastname, @dob, @sex, @height, @accounts, @ssn)', {
        ['@identifier'] = newIdentifier,
        ['@firstname'] = data.firstname,
        ['@lastname'] = data.lastname,
        ['@dob'] = data.dateofbirth,
        ['@sex'] = data.sex,
        ['@height'] = data.height,
        ['@accounts'] = accounts,
        ['@ssn'] = ssn
    })
    
    TriggerClientEvent('esx:showNotification', src, "Character created successfully!")
    TriggerClientEvent('bl_multicharacter:setupCharacters', src)
end)

-- Delete a character
RegisterNetEvent('bl_multicharacter:deleteCharacter')
AddEventHandler('bl_multicharacter:deleteCharacter', function(charId)
    local src = source
    local license = getPrimaryIdentifier(src)
    
    if not license then return end
    
    -- Reconstruct the full identifier to delete since UI now passes the slot integer
    local fullIdentifier = "char" .. tostring(charId) .. ":" .. license
    
    MySQL.update.await('DELETE FROM users WHERE identifier = @identifier', {
        ['@identifier'] = fullIdentifier
    })
    
    TriggerClientEvent('esx:showNotification', src, "Character deleted.")
    TriggerClientEvent('bl_multicharacter:setupCharacters', src)
end)

-- Relog command handler
local relogCooldowns = {}

RegisterNetEvent('bl_multicharacter:relog')
AddEventHandler('bl_multicharacter:relog', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer then
        local license = getPrimaryIdentifier(src)
        if license then
            local userGroup = "user"
            if xPlayer.getGroup then
                userGroup = xPlayer.getGroup()
            elseif xPlayer.group then
                userGroup = xPlayer.group
            end
            
            -- Check if player is Staff or VIP
            local isStaffOrVip = false
            if Config.StaffGroups[userGroup] or Config.VIPLicenses[license] then
                isStaffOrVip = true
            end
            
            if not isStaffOrVip then
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
        
        -- Put player in a unique routing bucket (virtual dimension) to hide them from other players
        SetPlayerRoutingBucket(src, src)
        
        -- This will trigger esx:onPlayerLogout on the client
        TriggerEvent('esx:playerLogout', src)
    end
end)

-- Play character event to handle safe in-game login
RegisterNetEvent('bl_multicharacter:playCharacter')
AddEventHandler('bl_multicharacter:playCharacter', function(charId)
    local src = source
    local charPrefix = "char" .. tostring(charId)
    local primaryIdentifier = getPrimaryIdentifier(src)
    
    -- Reset player's routing bucket to the default dimension (0) before spawning them in the game
    SetPlayerRoutingBucket(src, 0)

    -- Trigger the player joined event first, so ESX can load the character prefix correctly
    TriggerEvent('esx:onPlayerJoined', src, charPrefix)
    
    -- Cache the prefix in ESX.Players after joining
    if ESX.Players and primaryIdentifier then
        ESX.Players[primaryIdentifier] = charPrefix
    end
end)

-- =========================================================================
--            AUTOMATIC PLAYTIME TRACKING & SELF-HEALING DATABASE
-- =========================================================================

-- Self-healing database: Automatically add the 'playtime' column if it's missing in 'users'
MySQL.ready(function()
    local check = MySQL.query.await("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'users' AND COLUMN_NAME = 'playtime'")
    if not check or #check == 0 then
        print("^2[bl_multicharacter]^7 Colonne 'playtime' introuvable dans 'users'. Ajout automatique en cours...")
        local success = pcall(function()
            MySQL.query.await("ALTER TABLE users ADD COLUMN playtime INT DEFAULT 0")
        end)
        if success then
            print("^2[bl_multicharacter]^7 Colonne 'playtime' ajoutée avec succès !")
        else
            print("^1[bl_multicharacter]^7 Erreur lors de l'ajout de la colonne 'playtime' !")
        end
    end
end)

-- Session tracking for online players (SourceId -> LoginTimestamp)
local activePlaytimes = {}

-- Track session start when a player loaded a character successfully
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    activePlaytimes[playerId] = os.time()
end)

-- Helper to flush accumulated playtime for a single player to the database
local function savePlayerPlaytime(playerId)
    if activePlaytimes[playerId] then
        local now = os.time()
        local elapsed = now - activePlaytimes[playerId]
        activePlaytimes[playerId] = now -- Reset baseline for the next interval
        
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and elapsed > 0 then
            MySQL.update("UPDATE users SET playtime = playtime + @time WHERE identifier = @identifier", {
                ['@time'] = elapsed,
                ['@identifier'] = xPlayer.identifier
            })
        end
    end
end

-- Track session end when player logs out cleanly
RegisterNetEvent('esx:playerLogout')
AddEventHandler('esx:playerLogout', function(playerId)
    savePlayerPlaytime(playerId)
    activePlaytimes[playerId] = nil
end)

-- Track session end if player drops out/disconnects
AddEventHandler('playerDropped', function()
    local src = source
    savePlayerPlaytime(src)
    activePlaytimes[src] = nil
end)

-- Background thread: Periodically flush playtime every 60 seconds to prevent data loss on crashes
CreateThread(function()
    while true do
        Wait(60000) -- Flush playtime to DB every minute
        for playerId, _ in pairs(activePlaytimes) do
            savePlayerPlaytime(playerId)
        end
    end
end)




