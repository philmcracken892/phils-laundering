local RSGCore = exports['rsg-core']:GetCoreObject()


local isPrinting = false
local placementActive = false
local confirmed = false
local heading = 0.0


local placedMoneyPress = nil


local PromptPlacerGroup = GetRandomIntInRange(0, 0xffffff)


local CancelPrompt = nil
local SetPrompt = nil
local RotateLeftPrompt = nil
local RotateRightPrompt = nil


local keys = {
    ["LEFT"] = 0xA65EBAB4,
    ["RIGHT"] = 0xDEB34313,
}


local function DebugPrint(msg)
   
end


function LoadAnimDict(dict)
    if not DoesAnimDictExist(dict) then
       
        return false
    end
    
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
           
            return false
        end
    end
   
    return true
end


function InitializePlacementPrompts()
    
    
    -- Cancel Prompt
    local str = "Cancel"
    CancelPrompt = PromptRegisterBegin()
    PromptSetControlAction(CancelPrompt, 0xF84FA74F) -- X key
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(CancelPrompt, str)
    PromptSetEnabled(CancelPrompt, true)
    PromptSetVisible(CancelPrompt, true)
    PromptSetHoldMode(CancelPrompt, true)
    PromptSetGroup(CancelPrompt, PromptPlacerGroup)
    PromptRegisterEnd(CancelPrompt)

    -- Set Prompt
    str = "Place"
    SetPrompt = PromptRegisterBegin()
    PromptSetControlAction(SetPrompt, 0xC7B5340A) -- Enter key
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(SetPrompt, str)
    PromptSetEnabled(SetPrompt, true)
    PromptSetVisible(SetPrompt, true)
    PromptSetHoldMode(SetPrompt, true)
    PromptSetGroup(SetPrompt, PromptPlacerGroup)
    PromptRegisterEnd(SetPrompt)

    -- Rotate Left Prompt
    str = "Rotate Left"
    RotateLeftPrompt = PromptRegisterBegin()
    PromptSetControlAction(RotateLeftPrompt, 0xA65EBAB4) -- Left Arrow
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(RotateLeftPrompt, str)
    PromptSetEnabled(RotateLeftPrompt, true)
    PromptSetVisible(RotateLeftPrompt, true)
    PromptSetHoldMode(RotateLeftPrompt, false) -- Don't require hold
    PromptSetGroup(RotateLeftPrompt, PromptPlacerGroup)
    PromptRegisterEnd(RotateLeftPrompt)

    -- Rotate Right Prompt
    str = "Rotate Right"
    RotateRightPrompt = PromptRegisterBegin()
    PromptSetControlAction(RotateRightPrompt, 0xDEB34313) -- Right Arrow
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(RotateRightPrompt, str)
    PromptSetEnabled(RotateRightPrompt, true)
    PromptSetVisible(RotateRightPrompt, true)
    PromptSetHoldMode(RotateRightPrompt, false) -- Don't require hold
    PromptSetGroup(RotateRightPrompt, PromptPlacerGroup)
    PromptRegisterEnd(RotateRightPrompt)
    
    
end


function PlaceMoneyPressAdvanced()
   
    
   
    if placedMoneyPress and DoesEntityExist(placedMoneyPress) then
        lib.notify({
            title = 'Money Press',
            description = 'You already have a money press placed!',
            type = 'error'
        })
        return
    end

    if placementActive then
        DebugPrint('Placement already active')
        return
    end

    placementActive = true
    confirmed = false
    heading = 0.0

    
    local propModel = Config.MoneyPressProp
    local propHash = propModel
    
   
    if type(propModel) == 'string' then
        propHash = GetHashKey(propModel)
    end
    
    
    
    -- Check if model is valid
    if not IsModelValid(propHash) then
        
        lib.notify({
            title = 'Money Press',
            description = 'Invalid prop model!',
            type = 'error'
        })
        placementActive = false
        return
    end
    
    
    
    RequestModel(propHash)
    
    local timeout = 0
    while not HasModelLoaded(propHash) do
        Wait(100)
        timeout = timeout + 100
       
        if timeout > 10000 then
            DebugPrint('ERROR: Model loading timeout!')
            lib.notify({
                title = 'Money Press',
                description = 'Failed to load model!',
                type = 'error'
            })
            placementActive = false
            return
        end
    end
    
    

    
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)
    
   
    local x = pedCoords.x + (math.sin(math.rad(pedHeading)) * -1.0)
    local y = pedCoords.y + (math.cos(math.rad(pedHeading)) * -1.0)
    local z = pedCoords.z
    
    

    
    local tempProp = CreateObject(propHash, x, y, z, false, true, false)
    
    if not tempProp or tempProp == 0 then
       
        lib.notify({
            title = 'Money Press',
            description = 'Failed to create money press!',
            type = 'error'
        })
        placementActive = false
        SetModelAsNoLongerNeeded(propHash)
        return
    end
    
    
    Wait(0)
    
    if not DoesEntityExist(tempProp) then
       
        lib.notify({
            title = 'Money Press',
            description = 'Failed to create money press!',
            type = 'error'
        })
        placementActive = false
        SetModelAsNoLongerNeeded(propHash)
        return
    end
    
   
    
   
    SetEntityHeading(tempProp, pedHeading)
    SetEntityAlpha(tempProp, 150, false)
    SetEntityCollision(tempProp, false, false)
    FreezeEntityPosition(tempProp, true)
    PlaceObjectOnGroundProperly(tempProp)
    
    lib.notify({
        title = 'Money Press',
        description = 'Use Arrow Keys to rotate, Enter to place, X to cancel',
        type = 'inform',
        duration = 5000
    })

    
    CreateThread(function()
        while placementActive and not confirmed do
            Wait(0)
            
            
            local currentPed = PlayerPedId()
            local currentCoords = GetEntityCoords(currentPed)
            local currentHeading = GetEntityHeading(currentPed)
            
            
            local newX = currentCoords.x + (math.sin(math.rad(currentHeading)) * -1.0)
            local newY = currentCoords.y + (math.cos(math.rad(currentHeading)) * -1.0)
            local newZ = currentCoords.z
            
           
            if DoesEntityExist(tempProp) then
                SetEntityCoords(tempProp, newX, newY, newZ, false, false, false, false)
                SetEntityHeading(tempProp, heading)
                PlaceObjectOnGroundProperly(tempProp)
            else
                
            end
            
            
            SetTextScale(0.35, 0.35)
            SetTextColor(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextDropshadow(1, 0, 0, 0, 255)
            DisplayText(CreateVarString(10, "LITERAL_STRING", "Rotation: " .. math.floor(heading) .. "°"), 0.5, 0.88)

           
            local PropPlacerGroupName = CreateVarString(10, 'LITERAL_STRING', "Money Press Placement")
            PromptSetActiveGroupThisFrame(PromptPlacerGroup, PropPlacerGroupName)

            
            if IsControlPressed(1, 0xA65EBAB4) then -- Left arrow
                heading = heading + 2.0
                if heading >= 360.0 then heading = heading - 360.0 end
            end
            
            if IsControlPressed(1, 0xDEB34313) then -- Right arrow
                heading = heading - 2.0
                if heading < 0.0 then heading = heading + 360.0 end
            end

            -- Confirm placement
            if PromptHasHoldModeCompleted(SetPrompt) then
                DebugPrint('Placement confirmed')
                confirmed = true
                placementActive = false
                
                if DoesEntityExist(tempProp) then
                    -- Finalize placement
                    SetEntityAlpha(tempProp, 255, false)
                    SetEntityCollision(tempProp, true, true)
                    FreezeEntityPosition(tempProp, true)
                    PlaceObjectOnGroundProperly(tempProp)
                    
                  
                    placedMoneyPress = tempProp
                    
                    
                    TriggerServerEvent('rsg-moneypress:server:removeMoneyPressItem')
                    
                   
                    Wait(500)
                    AddMoneyPressTarget()
                    
                    lib.notify({
                        title = 'Money Press',
                        description = 'Money press placed successfully!',
                        type = 'success'
                    })
                    
                    
                end
                
                SetModelAsNoLongerNeeded(propHash)
            end

           
            if PromptHasHoldModeCompleted(CancelPrompt) then
               
                placementActive = false
                confirmed = true 
                
                if DoesEntityExist(tempProp) then
                    DeleteEntity(tempProp)
                    
                end
                
                SetModelAsNoLongerNeeded(propHash)
                
                lib.notify({
                    title = 'Money Press',
                    description = 'Placement cancelled',
                    type = 'error'
                })
            end
        end
    end)
end


function AddMoneyPressTarget()
    if not placedMoneyPress or not DoesEntityExist(placedMoneyPress) then 
       
        return 
    end
    
   
    
    local options = {
        {
            name = 'use_money_press',
            icon = 'fas fa-print',
            label = 'Use Money Press',
            onSelect = function()
                OpenMoneyPressMenu()
            end,
            canInteract = function()
                return not isPrinting
            end,
            distance = Config.Settings.interactionDistance
        },
        {
            name = 'packup_money_press',
            icon = 'fas fa-box',
            label = 'Pack Up Money Press',
            onSelect = function()
                PackUpMoneyPress()
            end,
            canInteract = function()
                return not isPrinting
            end,
            distance = Config.Settings.interactionDistance
        },
    }
    
    exports.ox_target:addLocalEntity(placedMoneyPress, options)
    
    
end


function RemoveMoneyPressTarget()
    if placedMoneyPress and DoesEntityExist(placedMoneyPress) then
        exports.ox_target:removeLocalEntity(placedMoneyPress, {'use_money_press', 'packup_money_press'})
       
    end
end


function OpenMoneyPressMenu()
    DebugPrint('Opening money press menu')
    
    if isPrinting then
        lib.notify({
            title = 'Money Press',
            description = 'The press is already running!',
            type = 'error'
        })
        return
    end
    
    local playerItems = lib.callback.await('rsg-moneypress:server:getPlayerItems', false)
    local hasAll, missingItems = CheckRequiredItems(playerItems)
    
    local menuOptions = {}
    
    if not hasAll then
        table.insert(menuOptions, {
            title = '⚠️ Missing Materials',
            description = table.concat(missingItems, ', '),
            icon = 'exclamation-triangle',
            disabled = true
        })
    end
    
    table.insert(menuOptions, {
        title = '💵 Start Printing Money',
        description = 'Print counterfeit money (10 minutes)',
        icon = 'print',
        disabled = not hasAll,
        onSelect = function()
            StartMoneyPress()
        end
    })
    
    table.insert(menuOptions, {
        title = '📋 View Required Materials',
        description = 'See what you need to print',
        icon = 'list',
        onSelect = function()
            OpenRequirementsMenu()
        end
    })
    
    table.insert(menuOptions, {
        title = '📦 Pack Up Press',
        description = 'Pack up the money press',
        icon = 'box',
        onSelect = function()
            PackUpMoneyPress()
        end
    })
    
    lib.registerContext({
        id = 'money_press_menu',
        title = '💵 Money Press',
        options = menuOptions
    })
    
    lib.showContext('money_press_menu')
end


function CheckRequiredItems(playerItems)
    local hasAll = true
    local missingItems = {}
    
    if not playerItems then
        return false, {"Unable to check inventory"}
    end
    
    for _, requiredItem in ipairs(Config.RequiredItems) do
        local playerAmount = playerItems[requiredItem.item] or 0
        
        if playerAmount < requiredItem.amount then
            hasAll = false
            table.insert(missingItems, requiredItem.label .. ' x' .. requiredItem.amount)
        end
    end
    
    return hasAll, missingItems
end


function OpenRequirementsMenu()
    local playerItems = lib.callback.await('rsg-moneypress:server:getPlayerItems', false)
    local options = {}
    
    for _, item in ipairs(Config.RequiredItems) do
        local playerAmount = 0
        if playerItems then
            playerAmount = playerItems[item.item] or 0
        end
        
        local hasEnough = playerAmount >= item.amount
        
        table.insert(options, {
            title = item.label,
            description = string.format('Required: %d | You have: %d', item.amount, playerAmount),
            icon = hasEnough and 'check-circle' or 'times-circle',
            iconColor = hasEnough and '#00ff00' or '#ff0000',
            disabled = true
        })
    end
    
    table.insert(options, {
        title = '← Back',
        icon = 'arrow-left',
        onSelect = function()
            OpenMoneyPressMenu()
        end
    })
    
    lib.registerContext({
        id = 'money_press_requirements',
        title = '📋 Required Materials',
        menu = 'money_press_menu',
        options = options
    })
    
    lib.showContext('money_press_requirements')
end


function StartMoneyPress()
    
    
    if not placedMoneyPress or not DoesEntityExist(placedMoneyPress) then
        lib.notify({
            title = 'Money Press',
            description = 'Money press not found!',
            type = 'error'
        })
        return
    end
    
    local canStart = lib.callback.await('rsg-moneypress:server:checkItems', false)
    
    if not canStart then
        lib.notify({
            title = 'Money Press',
            description = 'You don\'t have the required materials!',
            type = 'error'
        })
        return
    end
    
    local itemsRemoved = lib.callback.await('rsg-moneypress:server:removeItems', false)
    
    if not itemsRemoved then
        lib.notify({
            title = 'Money Press',
            description = 'Failed to use materials!',
            type = 'error'
        })
        return
    end
    
    isPrinting = true
    local ped = PlayerPedId()
    
    lib.notify({
        title = 'Money Press',
        description = 'Starting the money press... This will take 10 minutes.',
        type = 'inform',
        duration = 5000
    })
    
   
    local animLoaded = LoadAnimDict(Config.PrintAnimation.dict)
	TriggerServerEvent('rsg-lawman:server:lawmanAlert', 'money Laundering!')
    
    if animLoaded then
        TaskPlayAnim(ped, Config.PrintAnimation.dict, Config.PrintAnimation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end
    
    -- Progress loop
    local startTime = GetGameTimer()
    local duration = Config.Settings.printTime
    local cancelled = false
    
    CreateThread(function()
        while isPrinting and not cancelled do
            Wait(0)
            
            local currentTime = GetGameTimer()
            local elapsed = currentTime - startTime
            local remaining = duration - elapsed
            local progress = (elapsed / duration) * 100
            
            if remaining <= 0 then
                break
            end
            
            local minutes = math.floor(remaining / 60000)
            local seconds = math.floor((remaining % 60000) / 1000)
            local progressText = string.format("Printing Money... %d:%02d remaining", minutes, seconds)
            
            SetTextScale(0.4, 0.4)
            SetTextColor(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextDropshadow(1, 0, 0, 0, 255)
            DisplayText(CreateVarString(10, "LITERAL_STRING", progressText), 0.5, 0.85)
            
            SetTextScale(0.3, 0.3)
            SetTextColor(200, 200, 200, 255)
            SetTextCentre(true)
            SetTextDropshadow(1, 0, 0, 0, 255)
            
            
            DrawRect(0.5, 0.92, 0.2, 0.02, 50, 50, 50, 200)
            DrawRect(0.4 + (progress / 1000), 0.92, (progress / 500), 0.015, 0, 200, 0, 255)
            
            
        end
    end)
    
    while isPrinting do
        Wait(100)
        
        local currentTime = GetGameTimer()
        local elapsed = currentTime - startTime
        
        if elapsed >= duration or cancelled then
            break
        end
    end
    
    ClearPedTasks(ped)
    
    if not cancelled and (GetGameTimer() - startTime) >= duration then
        TriggerServerEvent('rsg-moneypress:server:giveMoney')
		
        
        lib.notify({
            title = 'Money Press',
            description = 'Money printing complete!',
            type = 'success'
        })
        
       
    else
        TriggerServerEvent('rsg-moneypress:server:cancelled')
        
        lib.notify({
            title = 'Money Press',
            description = 'Printing cancelled! Some materials were lost.',
            type = 'error'
        })
        
       
    end
    
    isPrinting = false
end


function PackUpMoneyPress()
    
    
    if isPrinting then
        lib.notify({
            title = 'Money Press',
            description = 'Cannot pack up while printing!',
            type = 'error'
        })
        return
    end
    
    if not placedMoneyPress or not DoesEntityExist(placedMoneyPress) then
        lib.notify({
            title = 'Money Press',
            description = 'No money press to pack up!',
            type = 'error'
        })
        return
    end
    
    local ped = PlayerPedId()
    
    
    local startTime = GetGameTimer()
    local duration = 3000
    local cancelled = false
    
    while GetGameTimer() - startTime < duration do
        Wait(0)
        
        local elapsed = GetGameTimer() - startTime
        local progress = (elapsed / duration) * 100
        
        SetTextScale(0.4, 0.4)
        SetTextColor(255, 255, 255, 255)
        SetTextCentre(true)
        SetTextDropshadow(1, 0, 0, 0, 255)
        DisplayText(CreateVarString(10, "LITERAL_STRING", "Packing up..."), 0.5, 0.85)
        
        DrawRect(0.5, 0.89, 0.2, 0.02, 50, 50, 50, 200)
        DrawRect(0.4 + (progress / 1000), 0.89, (progress / 500), 0.015, 0, 200, 0, 255)
        
        if IsControlJustPressed(0, 0x8CC9CD42) then
            cancelled = true
            break
        end
        
        DisableControlAction(0, 0x8FFC75D6, true)
        DisableControlAction(0, 0xD27782E3, true)
        DisableControlAction(0, 0x7065027D, true)
        DisableControlAction(0, 0xB4E465B4, true)
    end
	TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)  -- Remove this line if you don't want it restarting here
	Wait(2000)
	
	ClearPedTasksImmediately(PlayerPedId())
    
    ClearPedTasks(ped)
    
    if not cancelled then
        RemoveMoneyPressTarget()
        
        if DoesEntityExist(placedMoneyPress) then
            DeleteEntity(placedMoneyPress)
           
        end
        
        placedMoneyPress = nil
        
        TriggerServerEvent('rsg-moneypress:server:giveMoneyPressItem')
        
        lib.notify({
            title = 'Money Press',
            description = 'Money press packed up and returned to inventory!',
            type = 'success'
        })
        
       
    else
        lib.notify({
            title = 'Money Press',
            description = 'Pack up cancelled!',
            type = 'error'
        })
    end
end


RegisterNetEvent('rsg-moneypress:client:useMoneyPress', function()
    DebugPrint('Received useMoneyPress event')
    
    if placementActive then
        lib.notify({
            title = 'Money Press',
            description = 'Already placing a money press!',
            type = 'error'
        })
        return
    end
    
    if placedMoneyPress and DoesEntityExist(placedMoneyPress) then
        lib.notify({
            title = 'Money Press',
            description = 'You already have a money press placed!',
            type = 'error'
        })
        return
    end
    
    PlaceMoneyPressAdvanced()
end)

-- Key Press Check
function whenKeyJustPressed(key)
    return Citizen.InvokeNative(0x580417101DDB492F, 0, key)
end


CreateThread(function()
    while true do
        Wait(10)
        if placedMoneyPress and DoesEntityExist(placedMoneyPress) and not placementActive and not isPrinting then
            if whenKeyJustPressed(keys["LEFT"]) then
                local currentHeading = GetEntityHeading(placedMoneyPress)
                SetEntityHeading(placedMoneyPress, (currentHeading + 2) % 360)
            end
            if whenKeyJustPressed(keys["RIGHT"]) then
                local currentHeading = GetEntityHeading(placedMoneyPress)
                SetEntityHeading(placedMoneyPress, (currentHeading - 2) % 360)
            end
        end
    end
end)


CreateThread(function()
    Wait(2000)
    InitializePlacementPrompts()
   
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    ClearPedTasks(PlayerPedId())
    
    if placedMoneyPress and DoesEntityExist(placedMoneyPress) then
        RemoveMoneyPressTarget()
        DeleteEntity(placedMoneyPress)
    end
end)

AddEventHandler('RSGCore:Client:OnPlayerUnload', function()
    if placedMoneyPress and DoesEntityExist(placedMoneyPress) then
        RemoveMoneyPressTarget()
        DeleteEntity(placedMoneyPress)
        placedMoneyPress = nil
    end
end)

exports('IsPrinting', function()
    return isPrinting
end)

exports('HasPlacedPress', function()
    return placedMoneyPress and DoesEntityExist(placedMoneyPress)
end)