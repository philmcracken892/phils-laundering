local RSGCore = exports['rsg-core']:GetCoreObject()


local function DebugPrint(msg)
    if Config.Debug then
        print('[MoneyPress Server]: ' .. msg)
    end
end


CreateThread(function()
    Wait(2000)
    
    RSGCore.Functions.CreateUseableItem(Config.MoneyPressItem, function(source, item)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)
        
        if not Player then 
            
            return 
        end
        
        local hasItem = Player.Functions.GetItemByName(Config.MoneyPressItem)
        
        if hasItem and hasItem.amount > 0 then
            DebugPrint('Player ' .. src .. ' using money press item')
            TriggerClientEvent('rsg-moneypress:client:useMoneyPress', src)
        else
            DebugPrint('Player does not have money press item')
            lib.notify(src, {
                title = 'Money Press',
                description = 'You don\'t have a money press!',
                type = 'error'
            })
        end
    end)
    
   
end)


lib.callback.register('rsg-moneypress:server:getPlayerItems', function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then 
        return nil
    end
    
    local items = {}
    
    for _, requiredItem in ipairs(Config.RequiredItems) do
        local playerItem = Player.Functions.GetItemByName(requiredItem.item)
        if playerItem then
            items[requiredItem.item] = playerItem.amount
        else
            items[requiredItem.item] = 0
        end
    end
    
    return items
end)


RegisterNetEvent('rsg-moneypress:server:removeMoneyPressItem', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then 
        
        return 
    end
    
    local hasItem = Player.Functions.GetItemByName(Config.MoneyPressItem)
    
    if hasItem and hasItem.amount > 0 then
        Player.Functions.RemoveItem(Config.MoneyPressItem, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.MoneyPressItem], 'remove', 1)
        
    else
       
    end
end)


RegisterNetEvent('rsg-moneypress:server:giveMoneyPressItem', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then 
        
        return 
    end
    
    local success = Player.Functions.AddItem(Config.MoneyPressItem, 1)
    
    if success then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.MoneyPressItem], 'add', 1)
        
        
        lib.notify(src, {
            title = 'Money Press',
            description = 'Money press returned to your inventory!',
            type = 'success'
        })
    else
        
        
        lib.notify(src, {
            title = 'Money Press',
            description = 'Failed to return money press - inventory full?',
            type = 'error'
        })
    end
end)


lib.callback.register('rsg-moneypress:server:checkItems', function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then 
       
        return false 
    end
    
    for _, item in ipairs(Config.RequiredItems) do
        local playerItem = Player.Functions.GetItemByName(item.item)
        if not playerItem or playerItem.amount < item.amount then
            
            return false
        end
    end
    
   
    return true
end)


lib.callback.register('rsg-moneypress:server:removeItems', function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then 
        DebugPrint('ERROR: removeItems - Player not found: ' .. src)
        return false 
    end
    
    for _, item in ipairs(Config.RequiredItems) do
        local playerItem = Player.Functions.GetItemByName(item.item)
        if not playerItem or playerItem.amount < item.amount then
            DebugPrint('Player missing item on remove check: ' .. item.item)
            return false
        end
    end
    
    for _, item in ipairs(Config.RequiredItems) do
        Player.Functions.RemoveItem(item.item, item.amount)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.item], 'remove', item.amount)
        DebugPrint('Removed item: ' .. item.item .. ' x' .. item.amount)
    end
    
    lib.notify(src, {
        title = 'Money Press',
        description = 'Materials consumed. Press is starting...',
        type = 'inform'
    })
    
    return true
end)


RegisterNetEvent('rsg-moneypress:server:giveMoney', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then 
        
        return 
    end
    
    local reward = math.random(Config.Settings.moneyReward.min, Config.Settings.moneyReward.max)
    
    Player.Functions.AddMoney('cash', reward)
    
    lib.notify(src, {
        title = 'Money Press',
        description = 'You printed $' .. reward .. ' in counterfeit money!',
        type = 'success'
    })
    
    
    
    if Config.PoliceAlert.enabled then
        local alertChance = math.random(1, 100)
        if alertChance <= Config.PoliceAlert.chance then
            TriggerPoliceAlert(src)
        end
    end
    
    LogTransaction(src, Player.PlayerData.citizenid, reward)
end)


RegisterNetEvent('rsg-moneypress:server:cancelled', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local refundChance = math.random(1, 100)
    
    if refundChance <= 50 then
        local paperItem = Config.RequiredItems[1]
        local refundAmount = math.floor(paperItem.amount / 2)
        
        if refundAmount > 0 then
            Player.Functions.AddItem(paperItem.item, refundAmount)
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[paperItem.item], 'add', refundAmount)
            
            lib.notify(src, {
                title = 'Money Press',
                description = 'You salvaged ' .. refundAmount .. ' ' .. paperItem.label .. '.',
                type = 'inform'
            })
        end
    end
    
    
end)


function TriggerPoliceAlert(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    
    local players = RSGCore.Functions.GetPlayers()
    for _, playerId in ipairs(players) do
        local TargetPlayer = RSGCore.Functions.GetPlayer(playerId)
        if TargetPlayer then
            local job = TargetPlayer.PlayerData.job.name
            if job == 'vallaw' or job == 'blklaw' or job == 'rholaw' or job == 'stdenlaw' or job == 'strlaw'then
                lib.notify(playerId, {
                    title = '📞 Dispatch',
                    description = Config.PoliceAlert.message,
                    type = 'inform',
                    duration = 10000
                })
            end
        end
    end
    
    
end


function LogTransaction(source, citizenid, amount)
    local logMessage = string.format(
        '[Money Press] Player: %s (Source: %s) printed $%d at %s',
        citizenid,
        source,
        amount,
        os.date('%Y-%m-%d %H:%M:%S')
    )
    
   
end



AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
   
end)