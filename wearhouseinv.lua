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

-- EnableDiscord:
-- true  = send shortage alerts to Discord
-- false = run in standalone mode with in-game reporting only
local EnableDiscord = true

-- DiscordChannel:
-- The Discord channel ID used by DCSServerBot for alert messages.
local DiscordChannel = '12345678'

-- LogisticsRole:
-- Optional Discord role mention used for CRITICAL alerts.
-- Leave the format as a Discord role mention: <@&ROLE_ID>
local LogisticsRole = "<@&12345678>"

-------------------------------------------------
-- CHECK TIMER
-------------------------------------------------

-- CheckInterval:
-- How often the script scans all BLUE warehouses, in seconds.
-- 300 = 5 minutes
-- 600 = 10 minutes
local CheckInterval = 300

-------------------------------------------------
-- DEBUG SETTINGS
-------------------------------------------------

-- EnableDebug:
-- true  = enable extra debug output from the script
-- false = normal operation
local EnableDebug = false

-- DebugToGame:
-- true  = show debug text with trigger.action.outText in DCS
-- false = suppress in-game debug text
local DebugToGame = false

-- DebugDisplayTime:
-- How long debug messages stay visible on screen, in seconds.
local DebugDisplayTime = 10

-------------------------------------------------
-- IN-GAME REPORT SETTINGS
-------------------------------------------------

-- MaxInGameReportItems:
-- Maximum number of shortage items shown in the short in-game report
-- when Discord is enabled.
local MaxInGameReportItems = 5

-- FullInGameReportWithoutDiscord:
-- true  = if Discord is disabled, show the full in-game shortage list
-- false = still cap the in-game list using MaxInGameReportItems
local FullInGameReportWithoutDiscord = true

-------------------------------------------------
-- WEAPON SUPPLY THRESHOLDS
-------------------------------------------------

-- WeaponThresholds:
-- Item amounts below these values will be treated as shortage states.
-- CRITICAL is the highest priority and appears first in reports.
local WeaponThresholds = {
    LOW = 60,                          -- Below this = LOW supply warning
    MEDIUM = 40,                       -- Below this = MEDIUM warning
    CRITICAL = 20                      -- Below this = CRITICAL shortage (Discord role ping)
}

-------------------------------------------------
-- FUEL SUPPLY THRESHOLDS
-------------------------------------------------

-- FuelThresholds:
-- Jet fuel amounts below these values will be treated as shortage states.
local FuelThresholds = {
    LOW = 75000,                       -- Below this = LOW fuel warning
    MEDIUM = 50000,                    -- Below this = MEDIUM fuel warning
    CRITICAL = 25000                   -- Below this = CRITICAL fuel shortage
}

-------------------------------------------------
-- STATE MEMORY (ANTI SPAM)
-------------------------------------------------

local LastState = {}

-------------------------------------------------
-- DEBUG OUTPUT
-------------------------------------------------

local function DebugOut(message)

    if not EnableDebug then
        return
    end

    if DebugToGame then
        trigger.action.outText(
            "WAREHOUSE DEBUG\n" .. tostring(message),
            DebugDisplayTime
        )
    end
end

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

local function GetSeverityRank(state)

    if state == "CRITICAL" then
        return 1
    elseif state == "MEDIUM" then
        return 2
    elseif state == "LOW" then
        return 3
    end

    return 4
end

local function AddReportItem(reportItems, airbaseName, itemName, amount, state)

    reportItems[#reportItems + 1] = {
        airbase = airbaseName,
        name = itemName,
        amount = amount,
        state = state,
        severityRank = GetSeverityRank(state)
    }
end

local function BuildInGameReport(reportItems)

    if #reportItems == 0 then
        return ""
    end

    table.sort(reportItems, function(left, right)

        if left.severityRank ~= right.severityRank then
            return left.severityRank < right.severityRank
        end

        if left.amount ~= right.amount then
            return left.amount < right.amount
        end

        if left.airbase ~= right.airbase then
            return left.airbase < right.airbase
        end

        return left.name < right.name
    end)

    local showFullReport = not EnableDiscord and FullInGameReportWithoutDiscord
    local itemCount = #reportItems

    if not showFullReport then
        itemCount = math.min(#reportItems, MaxInGameReportItems)
    end

    local parts = {}

    for index = 1, itemCount do
        local item = reportItems[index]
        parts[#parts + 1] =
            item.airbase ..
            " " ..
            item.name ..
            " " ..
            tostring(item.amount)
    end

    local summary = table.concat(parts, " | ")

    if EnableDiscord and #reportItems > MaxInGameReportItems then
        summary = summary .. " | See Discord for full list."
    end

    return summary
end

-------------------------------------------------
-- MAIN CHECK
-------------------------------------------------

function CheckBlueWarehouses(showReport)

    showReport = showReport == true

    local success, err = pcall(function()

        local report = ""
        local reportItems = {}

        local criticalEmbed = {}
        local mediumEmbed = {}
        local recoveredEmbed = {}

        local criticalChange = false
        local mediumChange = false
        local recoveredChange = false

        local blueAirbaseCount = 0
        local warehouseCount = 0
        local criticalChangeCount = 0
        local mediumChangeCount = 0
        local recoveredChangeCount = 0

        DebugOut("Warehouse scan started.")

        local airbases = world.getAirbases()

        for _, airbase in ipairs(airbases) do

            if airbase:getCoalition() == coalition.side.BLUE then

                blueAirbaseCount = blueAirbaseCount + 1

                local warehouse = airbase:getWarehouse()

                if warehouse then

                    warehouseCount = warehouseCount + 1

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
                            criticalChangeCount = criticalChangeCount + 1
                            AddReportItem(
                                reportItems,
                                airbaseName,
                                "Jet Fuel",
                                jetFuel,
                                fuelState
                            )

                        elseif fuelState == "MEDIUM" then

                            mediumText =
                                mediumText ..
                                "Jet Fuel — " ..
                                jetFuel ..
                                "\n"

                            mediumChange = true
                            mediumChangeCount = mediumChangeCount + 1
                            AddReportItem(
                                reportItems,
                                airbaseName,
                                "Jet Fuel",
                                jetFuel,
                                fuelState
                            )

                        elseif LastState[fuelID] ~= nil then

                            recoveredText =
                                recoveredText ..
                                "Jet Fuel Restored\n"

                            recoveredChange = true
                            recoveredChangeCount = recoveredChangeCount + 1
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
                                        criticalChangeCount = criticalChangeCount + 1
                                        AddReportItem(
                                            reportItems,
                                            airbaseName,
                                            cleanName,
                                            amount,
                                            state
                                        )

                                    elseif state == "MEDIUM" then

                                        mediumText =
                                            mediumText ..
                                            cleanName ..
                                            " — " ..
                                            amount ..
                                            "\n"

                                        mediumChange = true
                                        mediumChangeCount = mediumChangeCount + 1
                                        AddReportItem(
                                            reportItems,
                                            airbaseName,
                                            cleanName,
                                            amount,
                                            state
                                        )

                                    elseif LastState[id] ~= nil then

                                        recoveredText =
                                            recoveredText ..
                                            cleanName ..
                                            " Restored\n"

                                        recoveredChange = true
                                        recoveredChangeCount = recoveredChangeCount + 1
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

        report = BuildInGameReport(reportItems)

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

                if showReport then

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
                end

                DebugOut(
                    "Scan complete. Blue airbases: " ..
                        blueAirbaseCount ..
                        ", Warehouses: " ..
                        warehouseCount ..
                        ", Critical changes: " ..
                        criticalChangeCount ..
                        ", Medium changes: " ..
                        mediumChangeCount ..
                        ", Recovered changes: " ..
                        recoveredChangeCount
                )
            
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
    
        CheckBlueWarehouses(false)
    
        return timer.getTime() + CheckInterval
    end

    local function ShowWarehouseInventoryReport()

        CheckBlueWarehouses(true)
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
        ShowWarehouseInventoryReport
    )
