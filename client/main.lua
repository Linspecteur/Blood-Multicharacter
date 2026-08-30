local ESX = exports['es_extended']:getSharedObject()
if ESX.GetConfig() then
    ESX.GetConfig().Multichar = true
end
local cam = nil
local previewPed = nil
local isUIVisible = false
local originalSkin = nil

-- Position en fond pour la sélection (Legion Square)
local PedCoords = Config.PedCoords or vector4(194.14, -889.02, 32.12, 270.0)

local function deletePreviewPed()
    -- No-op since we use PlayerPedId directly
end

-- Comprehensive Protected wrapper to hide/show all standard and custom HUDs/status bars safely
local function hideCustomHUDs(state)
    local visible = not state
    local displayVal = state and 0.0 or 0.5
    
    -- GTA Native HUD & Radar
    DisplayRadar(visible)
    DisplayHud(visible)
    
    -- State Bag Flags for modern FiveM scripts
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('isLoggedIn', visible, false)
        LocalPlayer.state:set('inCreator', state, false)
        LocalPlayer.state:set('hud_hidden', state, false)
    end
    
    -- ESX & Legacy Systems
    TriggerEvent('esx_status:setDisplay', displayVal)
    TriggerEvent('esx_status:toggle', visible)
    TriggerEvent('esx_status:toggleDisplay', visible)
    TriggerEvent('esx_hud:toggleHUD', visible)
    TriggerEvent('esx_hud:toggle', visible)
    TriggerEvent('esx_hud:hide', state)
    TriggerEvent('esx:hud:setMinimapVisible', visible)
    TriggerEvent('esx:hud:hide', state)
    TriggerEvent('esx:hud:toggle', visible)
    TriggerEvent('esx_basicneeds:toggleVal', visible)
    TriggerEvent('esx_basicneeds:toggle', visible)
    
    -- Generic & Standalone HUDs
    TriggerEvent('hud:toggle', visible)
    TriggerEvent('hud:hide', state)
    TriggerEvent('hud:show', visible)
    TriggerEvent('hud:display', visible)
    TriggerEvent('hud:client:ToggleHud', visible)
    TriggerEvent('hud:client:Toggle', visible)
    TriggerEvent('hud:client:hide', state)
    TriggerEvent('status:toggle', visible)
    TriggerEvent('status:hide', state)
    TriggerEvent('ui:toggle', visible)
    TriggerEvent('ui:hide', state)
    TriggerEvent('framework:hideHud', state)
    TriggerEvent('framework:toggleHud', visible)
    
    -- Popular Premium HUDs
    TriggerEvent('okokHud:toggleHud', visible)
    TriggerEvent('okokHud:toggle', visible)
    TriggerEvent('okokHud:hide', state)
    TriggerEvent('wasabi_hud:toggle', visible)
    TriggerEvent('wasabi_hud:hide', state)
    TriggerEvent('codem-blackhudv2:toggleHud', visible)
    TriggerEvent('codem-blackhudv2:toggle', visible)
    TriggerEvent('codem-hud:toggle', visible)
    TriggerEvent('vms_hud:toggle', visible)
    TriggerEvent('al_hud:toggle', visible)
    TriggerEvent('b-hud:toggle', visible)
    TriggerEvent('t-hud:toggle', visible)
    TriggerEvent('s-hud:toggle', visible)
    TriggerEvent('qs-hud:toggle', visible)
    TriggerEvent('qhud:toggle', visible)
    TriggerEvent('cd_easytime:Toggle', visible)
    TriggerEvent('cd_easytime:Hide', state)
    TriggerEvent('carControl:toggle', visible)
    TriggerEvent('seatbelt:toggle', visible)
    TriggerEvent('speedometer:toggle', visible)
    
    -- atg_hud_player & BloodLeak Scripts
    TriggerEvent('atg_hud:toggle', visible)
    TriggerEvent('atg_hud:hide', state)
    pcall(function() exports['bl_hud_player']:toggle(visible) end)
    pcall(function() exports['bl_hud_player']:hide(state) end)
    -- BloodLeak Scripts
    TriggerEvent('bl_hud:toggle', visible)
    TriggerEvent('bl_hud:hide', state)
    TriggerEvent('bloodleak:hideHud', state)
    TriggerEvent('bloodleak_hud:toggle', visible)
    TriggerEvent('bl_chat:toggleChat', visible)
    
    -- Voice Systems
    TriggerEvent('pma-voice:toggleHud', visible)
    TriggerEvent('pma-voice:setVoiceProperty', 'micClicks', visible)
    TriggerEvent('mumbleVoice:toggleUi', visible)
    TriggerEvent('SaltyChat_ToggleUi', visible)
    TriggerEvent('esx_voice:setVoiceStatus', visible)
    TriggerEvent('esx_voice:toggle', visible)
    
    -- Chat Systems
    TriggerEvent('chat:toggleChat', visible)
    TriggerEvent('chat:show', visible)
    
    -- Protected calls (pcall) to hide/show various standalone custom HUD exports safely without throwing Lua errors
    pcall(function()
        if state then
            exports['hud']:HideHud()
        else
            exports['hud']:ShowHud()
        end
    end)
    pcall(function() exports['hud']:toggleHud(visible) end)
    pcall(function() exports['hud']:toggle(visible) end)
    pcall(function() exports['hud']:hide(state) end)
    pcall(function() exports['esx_hud']:toggleHud(visible) end)
    pcall(function() exports['esx_hud']:toggle(visible) end)
    pcall(function() exports['esx_hud']:hide(state) end)
    pcall(function() exports['qb-hud']:toggleHud(visible) end)
    pcall(function() exports['qb-hud']:toggle(visible) end)
    pcall(function() exports['qb-hud']:hide(state) end)
    pcall(function() exports['okokHud']:toggle(visible) end)
    pcall(function() exports['wasabi_hud']:toggle(visible) end)
    pcall(function() exports['codem-blackhudv2']:toggle(visible) end)
    pcall(function() exports['codem-hud']:toggle(visible) end)
    pcall(function() exports['vms_hud']:toggle(visible) end)
    pcall(function() exports['pma-voice']:toggleVoiceUi(visible) end)
    pcall(function() exports['bl_chat']:toggleChat(visible) end)
    pcall(function() exports['bl_hud']:toggle(visible) end)
    pcall(function() exports['bl_hud']:hide(state) end)
end

local function setupCamera()
    DoScreenFadeOut(500)
    Wait(500)
    
    if cam and DoesCamExist(cam) then
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        cam = nil
    end
    
    local ped = PlayerPedId()
    SetEntityCoords(ped, PedCoords.x, PedCoords.y, PedCoords.z - 1.0)
    SetEntityHeading(ped, PedCoords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, true, false)
    
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    
    -- Hide chat resource, radar, and custom HUDs
    TriggerEvent('chat:toggleChat', false)
    TriggerEvent('chat:show', false)
    DisplayRadar(false)
    hideCustomHUDs(true)
    
    -- Mathematically perfect vertical and horizontal centering (1.8m distance, looking at character center)
    local pedCoords = GetEntityCoords(ped)
    local camOffset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.8, 0.0)
    SetCamCoord(cam, camOffset.x, camOffset.y, camOffset.z)
    PointCamAtCoord(cam, pedCoords.x, pedCoords.y, pedCoords.z - 0.05)
    
    DoScreenFadeIn(500)
end

local function destroyCamera(keepHUD, immediate)
    if cam then
        if immediate then
            RenderScriptCams(false, false, 0, true, true)
        else
            RenderScriptCams(false, true, 500, true, true)
        end
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        cam = nil
    end
    
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
    
    if not keepHUD then
        -- Restore chat, radar, and custom HUDs
        TriggerEvent('chat:toggleChat', true)
        TriggerEvent('chat:show', true)
        DisplayRadar(true)
        hideCustomHUDs(false)
    end
end

local function openMulticharacterUI(isManual)
    if isUIVisible then return end
    isUIVisible = true
    
    if not isManual then
        ESX.PlayerLoaded = false
        ESX.PlayerData = {}
    end
    
    -- Force shutdown any GTA loading screen or NUI loading screen to prevent getting stuck
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    
    -- Save original skin before previewing to prevent overwriting previous character skins on save/unload
    originalSkin = nil
    if ESX.PlayerLoaded then
        local success = pcall(function()
            originalSkin = exports['fivem-appearance']:getPedAppearance(PlayerPedId())
        end)
        if not success or not originalSkin then
            success = pcall(function()
                originalSkin = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
            end)
        end
        if not success or not originalSkin then
            TriggerEvent('skinchanger:getSkin', function(skin)
                originalSkin = skin
            end)
        end
    end
    
    setupCamera()

    ESX.TriggerServerCallback('bl_multicharacter:getCharacters', function(characters, slotConfigs, playerCount, isVip, isStaff)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openUI",
            characters = characters,
            slotConfigs = slotConfigs,
            maxSlots = slotConfigs,
            playerCount = playerCount or 1,
            canClose = isManual or ESX.PlayerLoaded,
            isVIP = isVip or false,
            isStaff = isStaff or false,
            spawns = Config.Spawns
        })
    end)
end

RegisterNetEvent('bl_multicharacter:setupCharacters')
AddEventHandler('bl_multicharacter:setupCharacters', function()
    -- Re-fetch and update UI (useful after create/delete)
    if isUIVisible then
        ESX.TriggerServerCallback('bl_multicharacter:getCharacters', function(characters, slotConfigs, playerCount, isVip, isStaff)
            SendNUIMessage({
                action = "openUI",
                characters = characters,
                slotConfigs = slotConfigs,
                maxSlots = slotConfigs,
                playerCount = playerCount or 1,
                isVIP = isVip or false,
                isStaff = isStaff or false,
                spawns = Config.Spawns
            })
        end)
    end
end)

-- Core Function for ultra-fast, accurate character skin application & preview
local function ApplyCharacterSkin(ped, skin)
    if not ped or not DoesEntityExist(ped) then ped = PlayerPedId() end
    if not skin then return end
    
    -- 1. Determine target model (Female or Male)
    local isFemale = false
    if skin.sex == 1 or skin.sex == '1' or skin.sex == 'f' or skin.sex == 'F' or skin.sex == true then
        isFemale = true
    end
    
    local targetModel = isFemale and `mp_f_freemode_01` or `mp_m_freemode_01`
    local currentModel = GetEntityModel(ped)
    
    -- Instant Model Switch if needed
    if currentModel ~= targetModel then
        RequestModel(targetModel)
        while not HasModelLoaded(targetModel) do Wait(0) end
        SetPlayerModel(PlayerId(), targetModel)
        ped = PlayerPedId()
        SetPedDefaultComponentVariation(ped)
        SetModelAsNoLongerNeeded(targetModel)
    end
    
    -- Temporarily unfreeze to allow native components/props attachment
    FreezeEntityPosition(ped, false)
    
    -- 2. Direct fast application via bl_appearance export
    local applied = false
    if GetResourceState('bl_appearance') == 'started' then
        pcall(function()
            exports['bl_appearance']:setPedAppearance(ped, skin)
            applied = true
        end)
    end
    
    if not applied and GetResourceState('fivem-appearance') == 'started' then
        pcall(function()
            exports['fivem-appearance']:setPedAppearance(ped, skin)
            applied = true
        end)
    end
    
    if not applied and GetResourceState('illenium-appearance') == 'started' then
        pcall(function()
            exports['illenium-appearance']:setPedAppearance(ped, skin)
            applied = true
        end)
    end
    
    -- 3. Fallback to skinchanger & esx_skin
    TriggerEvent('skinchanger:loadSkin', skin)
    TriggerEvent('esx_skin:loadSkin', skin)
    
    -- Teleport to PedCoords and re-freeze
    SetEntityCoords(ped, PedCoords.x, PedCoords.y, PedCoords.z - 1.0)
    SetEntityHeading(ped, PedCoords.w)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    isUIVisible = false
    SetNuiFocus(false, false)
    destroyCamera()
    SendNUIMessage({ action = "closeUI" })
    
    -- Restore original skin
    if originalSkin then
        ApplyCharacterSkin(PlayerPedId(), originalSkin)
        originalSkin = nil
    end
    
    cb('ok')
end)

RegisterNUICallback('previewCharacter', function(data, cb)
    local charId = data.charId
    local skinData = data.skin
    local ped = PlayerPedId()
    
    local skin = nil
    if skinData then
        if type(skinData) == 'table' then
            skin = skinData
        elseif type(skinData) == 'string' and skinData ~= "" and skinData ~= "null" then
            skin = json.decode(skinData)
        end
    end
    
    if skin then
        ApplyCharacterSkin(ped, skin)
    else
        -- Fallback default male ped
        local model = `mp_m_freemode_01`
        if GetEntityModel(ped) ~= model then
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end
            SetPlayerModel(PlayerId(), model)
            ped = PlayerPedId()
            SetPedDefaultComponentVariation(ped)
            SetModelAsNoLongerNeeded(model)
        end
        SetEntityCoords(ped, PedCoords.x, PedCoords.y, PedCoords.z - 1.0)
        SetEntityHeading(ped, PedCoords.w)
        FreezeEntityPosition(ped, true)
        SetEntityVisible(ped, true, false)
    end
    
    -- Re-evaluate ped ID after optional model load
    ped = PlayerPedId()
    
    -- Position camera exactly 1.8 meters in front of the player ped, perfectly centered
    local camOffset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.8, 0.0)
    SetCamCoord(cam, camOffset.x, camOffset.y, camOffset.z)
    PointCamAtCoord(cam, PedCoords.x, PedCoords.y, PedCoords.z - 0.05)
    
    cb('ok')
end)

RegisterNUICallback('previewEmpty', function(data, cb)
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    
    -- Position camera facing the empty spawn point
    local rad = math.rad(PedCoords.w)
    local cx = PedCoords.x + (math.sin(-rad) * 1.8)
    local cy = PedCoords.y + (math.cos(-rad) * 1.8)
    
    SetCamCoord(cam, cx, cy, PedCoords.z)
    PointCamAtCoord(cam, PedCoords.x, PedCoords.y, PedCoords.z - 0.05)
    
    cb('ok')
end)

local chosenSpawnCoords = nil

RegisterNUICallback('playCharacter', function(data, cb)
    local charId = data.charId
    chosenSpawnCoords = data.spawnCoords -- Store coordinates from Spawn Selector
    
    isUIVisible = false
    SetNuiFocus(false, false)
    
    -- Fade out the screen completely to block rendering before any camera/ped changes occur
    DoScreenFadeOut(500)
    Wait(500)
    
    destroyCamera(true, true) -- Destroy NUI camera immediately in the dark but keep HUD hidden
    SendNUIMessage({ action = "closeUI" })
    
    -- We discard originalSkin here since the player is logging in as a different character and the old character has already been saved and unloaded safely.
    originalSkin = nil
    
    -- Trigger our custom server event to handle safe logout and login!
    TriggerServerEvent('bl_multicharacter:playCharacter', charId)
    cb('ok')
end)

local lastCreatedGender = 'm'
local isCreatingNewChar = false

RegisterNUICallback('createCharacter', function(data, cb)
    isUIVisible = false
    SetNuiFocus(false, false)
    lastCreatedGender = (data and data.sex) or 'm'
    isCreatingNewChar = true
    
    -- Fade out the screen completely to block rendering before creator transition
    DoScreenFadeOut(500)
    Wait(500)
    
    destroyCamera(true, true) -- Destroy multicharacter camera immediately in the dark
    SendNUIMessage({ action = "closeUI" })
    originalSkin = nil

    TriggerServerEvent('bl_multicharacter:createCharacter', data)
    cb('ok')
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    TriggerServerEvent('bl_multicharacter:deleteCharacter', data.charId)
    cb('ok')
end)

RegisterNUICallback('rotateCharacter', function(data, cb)
    if isUIVisible then
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            local currentHeading = GetEntityHeading(ped)
            local newHeading = currentHeading - (data.delta * 0.8)
            SetEntityHeading(ped, newHeading)
        end
    end
    cb('ok')
end)

-- Helper function to detect if skin is empty or unset
local function isSkinEmpty(skin)
    if not skin then return true end
    if type(skin) == 'table' then
        return next(skin) == nil
    end
    if type(skin) == 'string' then
        return skin == "" or skin == "{}" or skin == "null" or skin == "[]"
    end
    return false
end

-- Handle Player Loaded to actually spawn the player into the world
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData, isNew, skin)
    local spawnCoords = nil
    local isNewCharacter = isCreatingNewChar or isNew or isSkinEmpty(skin)
    isCreatingNewChar = false
    
    -- Fallback for ESX Legacy where skin is inside playerData
    if not skin and playerData and playerData.skin then
        skin = playerData.skin
    end
    
    if type(skin) == 'string' and skin ~= "" and skin ~= "null" and skin ~= "[]" then
        skin = json.decode(skin)
    end
    
    -- Diagnostic F8 console print to see parameters passed by ESX
    if Config.Debug then
        print(("[bl_multicharacter] esx:playerLoaded triggered | isNewCharacter: %s | isNew: %s | skin type: %s"):format(tostring(isNewCharacter), tostring(isNew), type(skin)))
    end
    
    if isNewCharacter then
        spawnCoords = {x = Config.PedCoords.x, y = Config.PedCoords.y, z = Config.PedCoords.z, heading = Config.PedCoords.w}
    elseif chosenSpawnCoords then
        -- Dispersion anti-collision : Décalage radial aléatoire (1.2m à 3.0m) pour éviter la superposition de joueurs
        local angle = math.random() * 2 * math.pi
        local radius = math.random(12, 30) / 10.0
        local offsetX = math.cos(angle) * radius
        local offsetY = math.sin(angle) * radius
        local headingOffset = math.random(-15, 15)
        
        spawnCoords = {
            x = chosenSpawnCoords.x + offsetX,
            y = chosenSpawnCoords.y + offsetY,
            z = chosenSpawnCoords.z,
            heading = ((chosenSpawnCoords.heading or 0.0) + headingOffset) % 360.0
        }
    elseif playerData.coords then
        spawnCoords = {
            x = playerData.coords.x,
            y = playerData.coords.y,
            z = playerData.coords.z,
            heading = playerData.coords.heading or 0.0
        }
    else
        spawnCoords = {x = Config.PedCoords.x, y = Config.PedCoords.y, z = Config.PedCoords.z, heading = Config.PedCoords.w}
    end

    chosenSpawnCoords = nil -- Reset chosen coords

    -- Determine gender accurately before spawning so player spawns DIRECTLY as female or male
    local isFemale = (lastCreatedGender == 'f' or lastCreatedGender == 'F' or lastCreatedGender == 1 or lastCreatedGender == '1' or (playerData and (playerData.sex == 'f' or playerData.sex == 'F' or playerData.sex == '1' or playerData.sex == 1)))
    local initialSpawnSkin = skin
    if isNewCharacter then
        initialSpawnSkin = { sex = isFemale and 1 or 0 }
    else
        if not initialSpawnSkin or type(initialSpawnSkin) ~= 'table' or not initialSpawnSkin.sex then
            initialSpawnSkin = { sex = 0 }
        end
    end

    ESX.SpawnPlayer(initialSpawnSkin, spawnCoords, function()
        local playerPed = PlayerPedId()
        FreezeEntityPosition(playerPed, true)
        SetEntityVisible(playerPed, false, false)
        SetEntityCollision(playerPed, true, true)
        
        if isNewCharacter then
            local defaultModel = isFemale and `mp_f_freemode_01` or `mp_m_freemode_01`
            local genderSex = isFemale and 1 or 0
            
            RequestModel(defaultModel)
            while not HasModelLoaded(defaultModel) do Wait(10) end
            SetPlayerModel(PlayerId(), defaultModel)
            SetPedDefaultComponentVariation(PlayerPedId())
            SetModelAsNoLongerNeeded(defaultModel)
            
            -- Reset skinchanger's internal cache with complete clean gender presets
            if genderSex == 1 then
                TriggerEvent('skinchanger:loadSkin', {
                    sex = 1,
                    face_1 = 21, face_2 = 21, face_mix = 50,
                    skin_1 = 21, skin_2 = 21, skin_mix = 50,
                    hair_1 = 4, hair_color_1 = 0,
                    tshirt_1 = 14, torso_1 = 14, pants_1 = 14, arms = 15, shoes_1 = 35
                })
            else
                TriggerEvent('skinchanger:loadSkin', {
                    sex = 0,
                    face_1 = 0, face_2 = 0, face_mix = 50,
                    skin_1 = 0, skin_2 = 0, skin_mix = 50,
                    hair_1 = 1, hair_color_1 = 0,
                    tshirt_1 = 15, torso_1 = 15, pants_1 = 1, arms = 15, shoes_1 = 1
                })
            end
            
            -- Re-evaluate playerPed after changing model
            playerPed = PlayerPedId()
            FreezeEntityPosition(playerPed, false)
            SetEntityVisible(playerPed, true, false)
            
            TriggerServerEvent('esx:onPlayerSpawn')
            TriggerEvent('esx:onPlayerSpawn')
            TriggerEvent('esx:restoreLoadout')
            
            Wait(300)

            -- Fade in the screen completely so the world and player ped are rendered
            DoScreenFadeIn(600)
            Wait(600)
            
            -- Open appearance customization menu (MANDATORY for new characters)
            CreateThread(function()
                Wait(150)
                if GetResourceState('bl_appearance') == 'started' then
                    exports['bl_appearance']:startPlayerCustomization(function(appearance)
                        if appearance then
                            print("[bl_multicharacter] Skin appearance saved successfully!")
                        end
                    end)
                elseif GetResourceState('fivem-appearance') == 'started' then
                    exports['fivem-appearance']:startPlayerCustomization(function(appearance)
                        if appearance then
                            print("[bl_multicharacter] Skin appearance saved successfully!")
                        end
                    end)
                elseif GetResourceState('illenium-appearance') == 'started' then
                    exports['illenium-appearance']:startPlayerCustomization(function(appearance)
                        if appearance then
                            print("[bl_multicharacter] Skin appearance saved successfully!")
                        end
                    end)
                else
                    TriggerEvent('esx_skin:openSaveableMenu', function()
                        print("[bl_multicharacter] Skin saved via esx_skin!")
                    end, function()
                        print("[bl_multicharacter] Skin creation cancelled!")
                    end)
                end
            end)
        else
            -- Force screen fade out during loading to prevent premature fade-ins from other scripts (e.g. spawnmanager, HUDs)
            local keepBlack = true
            CreateThread(function()
                while keepBlack do
                    DoScreenFadeOut(0)
                    Wait(0)
                end
            end)

            -- Ground-level cinematic transition for existing characters (Prevents high-altitude entity/map streaming pool crash)
            Wait(200)
            
            TriggerServerEvent('esx:onPlayerSpawn')
            TriggerEvent('esx:onPlayerSpawn')
            TriggerEvent('esx:restoreLoadout')
            
            -- Teleport player ped to target coordinates in the dark
            SetEntityCoords(playerPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
            SetEntityHeading(playerPed, spawnCoords.heading or 0.0)
            FreezeEntityPosition(playerPed, true)
            SetEntityVisible(playerPed, true, false)
            
            -- Refresh player ped entity ID in case it changed during spawning/Wait
            playerPed = PlayerPedId()
            
            -- Load character skin in the dark using the most appropriate export/event
            local loaded = pcall(function()
                exports['fivem-appearance']:setPlayerAppearance(skin)
            end)
            if not loaded then
                loaded = pcall(function()
                    exports['fivem-appearance']:setPedAppearance(playerPed, skin)
                end)
            end
            if not loaded then
                loaded = pcall(function()
                    exports['illenium-appearance']:setPlayerAppearance(skin)
                end)
            end
            if not loaded then
                loaded = pcall(function()
                    exports['illenium-appearance']:setPedAppearance(playerPed, skin)
                end)
            end
            if not loaded then
                TriggerEvent('skinchanger:loadSkin', skin)
                TriggerEvent('esx_skin:loadSkin', skin)
            end
            
            -- Request collision and wait for it to stream in in the dark (essential to prevent falling through map)
            RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
            local colTimeout = 0
            while not HasCollisionLoadedAroundEntity(playerPed) and colTimeout < 150 do
                Wait(10)
                colTimeout = colTimeout + 1
            end
            
            -- Briefly unfreeze the player to let them drop to the ground naturally in the dark (prevents floating in the air during camera transition)
            FreezeEntityPosition(playerPed, false)
            Wait(300)
            FreezeEntityPosition(playerPed, true)
            
            -- Stop forcing the screen black since we are ready to render the sky camera
            keepBlack = false
            Wait(50)
            
            -- Create the sky camera (300 meters above the spawn location, looking down)
            local skyCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            SetCamCoord(skyCam, spawnCoords.x, spawnCoords.y, spawnCoords.z + 300.0)
            PointCamAtCoord(skyCam, spawnCoords.x, spawnCoords.y, spawnCoords.z)
            SetCamFov(skyCam, 65.0)
            
            -- Render the sky camera instantly in the dark
            SetCamActive(skyCam, true)
            RenderScriptCams(true, false, 0, true, true)
            
            -- Fade in the screen to show the sky view
            DoScreenFadeIn(1000)
            Wait(1000)
            
            -- Create the ground camera in front of the player
            local groundCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            local camOffset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 3.0, 0.8)
            SetCamCoord(groundCam, camOffset.x, camOffset.y, camOffset.z)
            local currentCoords = GetEntityCoords(playerPed)
            PointCamAtCoord(groundCam, currentCoords.x, currentCoords.y, currentCoords.z + 0.5)
            SetCamFov(groundCam, 45.0)
            
            -- Smoothly interpolate from the sky camera to the ground camera (GTA Online style)
            SetCamActiveWithInterp(groundCam, skyCam, 3500, 1, 1)
            Wait(3500)
            
            -- Destroy the sky camera as it is no longer needed
            DestroyCam(skyCam, true)
            
            -- Smoothly transition from the ground camera back to the player's gameplay camera
            RenderScriptCams(false, true, 1500, true, true)
            Wait(1500)
            
            -- Clean up the remaining camera and restore control
            DestroyAllCams(true)
            
            FreezeEntityPosition(playerPed, false)
            
            -- Protection de Spawn & Mode Fantôme (4 secondes pour préserver le RP et éviter les collisions)
            CreateThread(function()
                local ped = PlayerPedId()
                SetEntityInvincible(ped, true)
                SetPlayerInvincible(PlayerId(), true)
                SetEntityAlpha(ped, 140, false) -- Semi-transparent / fantôme
                
                local timerEnd = GetGameTimer() + 4000
                while GetGameTimer() < timerEnd do
                    SetEntityInvincible(ped, true)
                    SetPlayerInvincible(PlayerId(), true)
                    Wait(100)
                end
                
                -- Transition fluide vers la visibilité normale
                for a = 140, 255, 15 do
                    SetEntityAlpha(ped, a, false)
                    Wait(30)
                end
                ResetEntityAlpha(ped)
                SetEntityInvincible(ped, false)
                SetPlayerInvincible(PlayerId(), false)
            end)
            
            -- Restore HUD elements
            TriggerEvent('chat:toggleChat', true)
            TriggerEvent('chat:show', true)
            DisplayRadar(true)
            hideCustomHUDs(false)
        end
    end)
end)

-- Command to switch characters
RegisterCommand('mc', function()
    -- Immediately hide HUD & fade out client
    DoScreenFadeOut(500)
    hideCustomHUDs(true)
    
    -- Log the player out of ESX cleanly, which will save their data and trigger esx:onPlayerLogout
    TriggerServerEvent('bl_multicharacter:relog')
end, false)

-- Handle ESX Player Logout
RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    hideCustomHUDs(true)
    DoScreenFadeOut(500)
    
    -- Reset ped to default model so new characters don't inherit previous character's features
    local model = `mp_m_freemode_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    SetPlayerModel(PlayerId(), model)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(model)
    
    -- Reset skin cache so new characters don't inherit the previous character's skin
    TriggerEvent('skinchanger:loadSkin', {sex = 0})
    TriggerEvent('esx_skin:resetFirstSpawn')
    
    Wait(2000)
    openMulticharacterUI(false)
end)

-- Loop to continuously hide GTA standard HUD, radar and custom HUDs while UI is open
CreateThread(function()
    while true do
        if isUIVisible then
            HideHudAndRadarThisFrame()
            for i = 1, 22 do
                HideHudComponentThisFrame(i)
            end
            DisplayRadar(false)
            DisplayHud(false)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Thread to make the preview ped dynamically look at the mouse cursor
CreateThread(function()
    while true do
        if isUIVisible then
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) and IsEntityVisible(ped) then
                local screenX, screenY = GetActiveScreenResolution()
                local mouseX, mouseY = GetNuiCursorPosition()
                
                -- Only execute if coordinates are valid
                if mouseX and mouseY and screenX and screenY and screenX > 0 and screenY > 0 then
                    -- Normalize coordinates from -0.5 to 0.5
                    local normX = (mouseX / screenX) - 0.5
                    local normY = (mouseY / screenY) - 0.5
                    
                    -- Calculate a 3D point in front of the player ped based on normalized cursor position
                    -- Entity coordinates are looking facing the camera, X is left/right, Z is height
                    local target = GetOffsetFromEntityInWorldCoords(ped, normX * 2.5, 1.8, -normY * 1.5)
                    
                    -- Force the ped to look at the calculated 3D coordinate
                    TaskLookAtCoord(ped, target.x, target.y, target.z, 200, 2048, 3)
                end
            end
            Wait(100) -- Smooth update interval
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if isUIVisible then
            -- Periodically hide custom status and HUD interfaces to keep them off-screen
            hideCustomHUDs(true)
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

-- Automatically open the UI when the player connects to the server
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    if ESX.DisableSpawnManager then
        ESX.DisableSpawnManager()
    end
    DoScreenFadeOut(0)
    
    -- Small delay to ensure resources are ready
    Wait(500)
    
    if not ESX.PlayerLoaded and not isUIVisible then
        openMulticharacterUI(false)
    end
end)









