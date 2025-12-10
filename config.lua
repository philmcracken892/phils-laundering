Config = {}

-- Money Press Prop Model
Config.MoneyPressProp = `p_workbench01x`


-- Required Items to Print Money
Config.RequiredItems = {
    { item = 'paper', label = 'Paper', amount = 5 },
    { item = 'ink', label = 'Ink', amount = 2 },
    
}


Config.MoneyPressItem = 'moneypress'


Config.Settings = {
    printTime = 600000, -- 10 minutes in milliseconds (600000ms = 10 min)
    moneyReward = { min = 150, max = 250 },
    interactionDistance = 2.5,
    maxPlacementDistance = 10.0,
}


Config.PrintAnimation = {
    dict = "amb_work@world_human_write_notebook@female_a@idle_c",
    anim = "idle_g",
    flag = 1,
}


Config.PickupAnimation = {
    dict = "pickup_object",
    anim = "pickup_low",
    flag = 0,
}


Config.PoliceAlert = {
    enabled = true,
    chance = 100,
    message = "Suspicious activity reported - possible counterfeiting operation",
}

-- Debug Mode
Config.Debug = false