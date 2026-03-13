-- ╔════════════════════════════════════════════════════════════════════╗
-- ║      D O C   W A R E H O U S E   L O G I S T I C S   M O N I T O R ║
-- ║────────────────────────────────────────────────────────────────────║
-- ║  Version: 1.0                                                      ║
-- ║  Author: Doc ✪                                                    ║
-- ║                                                                    ║
-- ║  Description:                                                      ║
-- ║   This script monitors warehouse supply levels at BLUE airbases    ║
-- ║   and automatically reports shortages to Discord using the         ║
-- ║   DCS Discord Bot integration.                                     ║
-- ║                                                                    ║
-- ║   The system checks warehouse inventory periodically and sends     ║
-- ║   alerts based on supply severity levels:                          ║
-- ║                                                                    ║
-- ║      🚨 CRITICAL  → Pings Logistics role in Discord                ║
-- ║      ⚠ MEDIUM     → Discord notification (no ping)                 ║
-- ║      ✅ RECOVERED  → Discord notification (no ping)                ║
-- ║                                                                    ║
-- ║   Anti-spam logic ensures alerts are only sent when a supply       ║
-- ║   state actually changes.                                          ║
-- ║                                                                    ║
-- ║────────────────────────────────────────────────────────────────────║
-- ║  REQUIREMENTS                                                      ║
-- ║                                                                    ║
-- ║   This script REQUIRES the DCS Discord Bot to function.            ║
-- ║                                                                    ║
-- ║   GitHub:                                                          ║
-- ║   https://github.com/Special-K-s-Flightsim-Bots/DCSServerBot       ║
-- ║                                                                    ║
-- ║   Without DCSServerBot installed, Discord alerts will NOT work.    ║
-- ║                                                                    ║
-- ║────────────────────────────────────────────────────────────────────║
-- ║  REQUIRED DCS SERVER SETUP                                         ║
-- ║                                                                    ║
-- ║   1. DESANITIZE MISSION SCRIPTING                                  ║
-- ║                                                                    ║
-- ║   Edit this file on the server:                                    ║
-- ║                                                                    ║
-- ║      Saved Games\DCS\Scripts\MissionScripting.lua                  ║
-- ║                                                                    ║
-- ║   Comment out these lines:                                         ║
-- ║                                                                    ║
-- ║      -- sanitizeModule('os')                                       ║
-- ║      -- sanitizeModule('io')                                       ║
-- ║      -- sanitizeModule('lfs')                                      ║
-- ║                                                                    ║
-- ║   This allows DCS to access server scripts like DCSServerBot.      ║
-- ║                                                                    ║
-- ║────────────────────────────────────────────────────────────────────║
-- ║  MISSION EDITOR SETUP                                              ║
-- ║                                                                    ║
-- ║   Step 1 — Load the Discord Bot API                                ║
-- ║                                                                    ║
-- ║   Create a trigger:                                                ║
-- ║                                                                    ║
-- ║      TYPE:   MISSION START                                         ║
-- ║      ACTION: DO SCRIPT                                             ║
-- ║                                                                    ║
-- ║      dofile(lfs.writedir() ..                                      ║
-- ║             'Scripts/net/DCSServerBot/DCSServerBot.lua')           ║
-- ║                                                                    ║
-- ║                                                                    ║
-- ║   Step 2 — Load this warehouse script                              ║
-- ║                                                                    ║
-- ║   Create another trigger:                                          ║
-- ║                                                                    ║
-- ║      TYPE:   MISSION START                                         ║
-- ║      ACTION: DO SCRIPT FILE                                        ║
-- ║      FILE:   warehouseMonitor.lua                                  ║
-- ║                                                                    ║
-- ║                                                                    ║
-- ║   Once the mission starts, the script will automatically monitor   ║
-- ║   warehouses and send alerts to Discord.                           ║
-- ║                                                                    ║
-- ║────────────────────────────────────────────────────────────────────║
-- ║  IN-GAME FEATURE                                                   ║
-- ║                                                                    ║
-- ║   An F10 menu option will appear:                                  ║
-- ║                                                                    ║
-- ║        F10 → Other → Check Warehouse Inventory                     ║
-- ║                                                                    ║
-- ║   This allows players or admins to manually check supply levels.   ║
-- ║                                                                    ║
-- ║────────────────────────────────────────────────────────────────────║
-- ║  CONFIGURATION                                                     ║
-- ║                                                                    ║
-- ║   The following settings can be customized below to fit your       ║
-- ║   server's logistics needs.                                        ║
-- ║                                                                    ║
-- ╚════════════════════════════════════════════════════════════════════╝

-------------------------------------------------
-- DISCORD SETTINGS
-------------------------------------------------
local EnableDiscord = true             -- Toggle Discord alerts on/off
local DiscordChannel = '12345678'      -- Discord channel ID where alerts will be sent
local LogisticsRole = "<@&12345678>"   -- Discord role that will be pinged for CRITICAL shortages

-------------------------------------------------
-- CHECK TIMER
-------------------------------------------------

local CheckInterval = 300              -- How often warehouses are checked (seconds)
                                       -- 300 = 5 minutes
                                       -- 600 = 10 minutes (recommended for large servers)

-------------------------------------------------
-- WEAPON SUPPLY THRESHOLDS
-------------------------------------------------

local WeaponThresholds = {
    LOW = 60,                          -- Below this = LOW supply warning
    MEDIUM = 40,                       -- Below this = MEDIUM warning
    CRITICAL = 20                      -- Below this = CRITICAL shortage (Discord role ping)
}

-------------------------------------------------
-- FUEL SUPPLY THRESHOLDS
-------------------------------------------------

local FuelThresholds = {
    LOW = 50000,                       -- Below this = LOW fuel warning
    MEDIUM = 25000,                    -- Below this = MEDIUM fuel warning
    CRITICAL = 10000                   -- Below this = CRITICAL fuel shortage
}
-------------------------------------------------
-- STATE MEMORY (ANTI SPAM)
-------------------------------------------------

local LastState = {}

-------------------------------------------------
-- PRIORITY FUNCTION
-------------------------------------------------

local function GetPriority(value, thresholds)

    if value < thresholds.CRITICAL then
        return "CRITICAL"

    elseif value < thresholds.MEDIUM then
        return "MEDIUM"

    elseif value < thresholds.LOW then
        return "LOW"
    end

    return "OK"
end

-------------------------------------------------
-- CLEAN WEAPON NAME
-------------------------------------------------

local function ProcessWeaponName(fullName)

    local category = "Other"

    if string.find(fullName, "weapons.missiles.") then
        category = "Missile"

    elseif string.find(fullName, "weapons.bombs.") then
        category = "Bomb"

    elseif string.find(fullName, "weapons.nurs.") then
        category = "Rocket"
    end

    local shortName = string.match(fullName, "[^%.]+$") or fullName
    shortName = string.gsub(shortName, "_", "-")

    return shortName, category
end

-------------------------------------------------
-- MAIN CHECK
-------------------------------------------------

function CheckBlueWarehouses()

    local success, err = pcall(function()

        local report = ""

        local criticalEmbed = {}
        local mediumEmbed = {}
        local recoveredEmbed = {}

        local criticalChange = false
        local mediumChange = false
        local recoveredChange = false

        local airbases = world.getAirbases()

        for _, airbase in ipairs(airbases) do

            if airbase:getCoalition() == coalition.side.BLUE then

                local warehouse = airbase:getWarehouse()

                if warehouse then

                    local airbaseName = airbase:getName()

                    local criticalText = ""
                    local mediumText = ""
                    local recoveredText = ""

                    -------------------------------------------------
                    -- FUEL CHECK
                    -------------------------------------------------

                    local jetFuel = warehouse:getLiquidAmount(0) or 0

                    local fuelState = GetPriority(jetFuel, FuelThresholds)

                    local fuelID = airbaseName .. "-JetFuel"

                    if LastState[fuelID] ~= fuelState then

                        if fuelState == "CRITICAL" then

                            criticalText =
                                criticalText ..
                                "Jet Fuel — " ..
                                jetFuel ..
                                "\n"

                            criticalChange = true

                        elseif fuelState == "MEDIUM" then

                            mediumText =
                                mediumText ..
                                "Jet Fuel — " ..
                                jetFuel ..
                                "\n"

                            mediumChange = true

                        elseif LastState[fuelID] ~= nil then

                            recoveredText =
                                recoveredText ..
                                "Jet Fuel Restored\n"

                            recoveredChange = true
                        end

                        LastState[fuelID] = fuelState
                    end

                    -------------------------------------------------
                    -- WEAPON CHECK
                    -------------------------------------------------

                    local inventory = warehouse:getInventory()

                    if inventory and inventory.weapon then

                        for weaponKey, amount in pairs(inventory.weapon) do

                            if type(amount) == "number" then

                                local cleanName =
                                    ProcessWeaponName(weaponKey)

                                local id =
                                    airbaseName ..
                                    "-" ..
                                    cleanName

                                local state =
                                    GetPriority(
                                        amount,
                                        WeaponThresholds
                                    )

                                if LastState[id] ~= state then

                                    if state == "CRITICAL" then

                                        criticalText =
                                            criticalText ..
                                            cleanName ..
                                            " — " ..
                                            amount ..
                                            "\n"

                                        criticalChange = true

                                    elseif state == "MEDIUM" then

                                        mediumText =
                                            mediumText ..
                                            cleanName ..
                                            " — " ..
                                            amount ..
                                            "\n"

                                        mediumChange = true

                                    elseif LastState[id] ~= nil then

                                        recoveredText =
                                            recoveredText ..
                                            cleanName ..
                                            " Restored\n"

                                        recoveredChange = true
                                    end

                                    LastState[id] = state
                                end
                            end
                        end
                    end

                    -------------------------------------------------
                    -- BUILD IN GAME REPORT
                    -------------------------------------------------

                    if criticalText ~= "" or mediumText ~= "" then

                        report =
                            report ..
                            airbaseName ..
                            "\n"

                        if criticalText ~= "" then

                            report =
                                report ..
                                "CRITICAL\n" ..
                                criticalText
                        end

                        if mediumText ~= "" then

                            report =
                                report ..
                                "MEDIUM\n" ..
                                mediumText
                        end

                        report = report .. "\n"
                    end

                    -------------------------------------------------
                    -- EMBEDS
                    -------------------------------------------------

                    if criticalText ~= "" then
                        criticalEmbed[airbaseName] = criticalText
                    end

                    if mediumText ~= "" then
                        mediumEmbed[airbaseName] = mediumText
                    end

                    if recoveredText ~= "" then
                        recoveredEmbed[airbaseName] = recoveredText
                    end
                end
            end
        end

        -------------------------------------------------
        -- DISCORD ALERTS
        -------------------------------------------------

        if EnableDiscord then
        
            if criticalChange then
            
                dcsbot.sendEmbed(
                    "🚨 Logistics Critical",
                    LogisticsRole ..
                        "\nCritical supply shortage detected.",
                    nil,
                    criticalEmbed,
                    "DCS Logistics Monitor",
                    DiscordChannel
                )
            end
        
            if mediumChange then
            
                dcsbot.sendEmbed(
                    "⚠ Logistics Warning",
                    "Supply levels dropping.",
                    nil,
                    mediumEmbed,
                    "DCS Logistics Monitor",
                    DiscordChannel
                )
            end
        
            if recoveredChange then
            
                dcsbot.sendEmbed(
                    "✅ Supply Restored",
                    "Warehouse supply levels restored.",
                    nil,
                    recoveredEmbed,
                    "DCS Logistics Monitor",
                    DiscordChannel
                )
            end
        
        end

                -------------------------------------------------
                -- IN GAME REPORT
                -------------------------------------------------

                if report == "" then
                
                    trigger.action.outText(
                        "All Warehouses Above Threshold",
                        15
                    )
                
                else
                
                    trigger.action.outText(
                        "WAREHOUSE INVENTORY REPORT\n\n" .. report,
                        30
                    )
                end
            
            end)
        
            if not success then
            
                trigger.action.outText(
                    "WAREHOUSE SCRIPT ERROR:\n" ..
                        tostring(err),
                    20
                )
            end
        end

    -------------------------------------------------
    -- AUTO LOOP
    -------------------------------------------------
        
    function AutoWarehouseCheck()
    
        CheckBlueWarehouses()
    
        return timer.getTime() + CheckInterval
    end
    
    timer.scheduleFunction(
        AutoWarehouseCheck,
        nil,
        timer.getTime() + CheckInterval
    )
    
    -------------------------------------------------
    -- F10 MENU
    -------------------------------------------------
    
    missionCommands.addCommand(
        "Check Warehouse Inventory",
        nil,
        CheckBlueWarehouses
    )
