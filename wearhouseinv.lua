--========================================================--
--        D O C ' S   W A R E H O U S E   I N V E N T O R Y
--========================================================--
--  Displays BLUE airfield warehouse shortages and fuel
--  levels using a priority-based reporting system.
--========================================================--


---------------------------------------------------------------------
--  F10 WAREHOUSE PRIORITY REPORT
--  Use F10 Menu → "Check Blue Warehouse Priorities"
--
--  • Automatically scans ALL BLUE-controlled airfields
--  • Reports ONLY items below threshold
--  • Groups by airfield
--  • Sorts lowest stock first
--  • 3 Priority Levels:
--        CRITICAL
--        MEDIUM
--        LOW
--
--  Default Thresholds:
--      Weapons:
--          CRITICAL < 10
--          MEDIUM   < 18
--          LOW      < 25
--
--      Jet Fuel:
--          CRITICAL < 10,000 
--          MEDIUM   < 18,000
--          LOW      < 25,000
---------------------------------------------------------------------
-- Thresholds
local WeaponThresholds = {
    LOW = 60,
    MEDIUM = 40,
    CRITICAL = 20
}

local FuelThresholds = {
    LOW = 50000,
    MEDIUM = 25000,
    CRITICAL = 10000
}

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
    return nil
end

-------------------------------------------------
-- CLEAN + CATEGORY DETECTION
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

    -- Strip prefix (everything before last dot)
    local shortName = string.match(fullName, "[^%.]+$") or fullName

    -- Replace underscores with dashes
    shortName = string.gsub(shortName, "_", "-")

    return shortName, category
end

-------------------------------------------------
-- SORT FUNCTION
-------------------------------------------------

local function SortByAmount(a, b)
    return a.amount < b.amount
end

-------------------------------------------------
-- MAIN CHECK
-------------------------------------------------

function CheckBlueWarehouses()

    local success, err = pcall(function()

        local report = ""
        local airbases = world.getAirbases()

        for _, airbase in ipairs(airbases) do

            if airbase:getCoalition() == coalition.side.BLUE then

                local warehouse = airbase:getWarehouse()
                if warehouse then

                    local airbaseName = airbase:getName()

                    local critical = {}
                    local medium   = {}
                    local low      = {}

                    -------------------------------------------------
                    -- FUEL
                    -------------------------------------------------

                    local jetFuel = warehouse:getLiquidAmount(0) or 0
                    local fuelPriority = GetPriority(jetFuel, FuelThresholds)

                    if fuelPriority then
                        local entry = {
                            name = "Jet Fuel",
                            category = "Fuel",
                            amount = jetFuel
                        }

                        if fuelPriority == "CRITICAL" then
                            table.insert(critical, entry)
                        elseif fuelPriority == "MEDIUM" then
                            table.insert(medium, entry)
                        else
                            table.insert(low, entry)
                        end
                    end

                    -------------------------------------------------
                    -- WEAPONS
                    -------------------------------------------------

                    local inventory = warehouse:getInventory()

                    if inventory and inventory.weapon then
                        for weaponKey, amount in pairs(inventory.weapon) do
                            if type(amount) == "number" then

                                local weaponPriority = GetPriority(amount, WeaponThresholds)

                                if weaponPriority then
                                    local cleanName, category =
                                        ProcessWeaponName(weaponKey)

                                    local entry = {
                                        name = cleanName,
                                        category = category,
                                        amount = amount
                                    }

                                    if weaponPriority == "CRITICAL" then
                                        table.insert(critical, entry)
                                    elseif weaponPriority == "MEDIUM" then
                                        table.insert(medium, entry)
                                    else
                                        table.insert(low, entry)
                                    end
                                end
                            end
                        end
                    end

                    -------------------------------------------------
                    -- SORT EACH PRIORITY
                    -------------------------------------------------

                    table.sort(critical, SortByAmount)
                    table.sort(medium, SortByAmount)
                    table.sort(low, SortByAmount)

                    -------------------------------------------------
                    -- BUILD AIRFIELD BLOCK
                    -------------------------------------------------

                    if #critical > 0 or #medium > 0 or #low > 0 then

                        report = report .. airbaseName .. "\n"

                        local function AppendSection(title, list)
                            if #list > 0 then
                                report = report .. title .. "\n"
                                for _, item in ipairs(list) do
                                    report = report ..
                                        "    " ..
                                        item.name ..
                                        " (" .. item.category .. ")" ..
                                        ": " .. item.amount .. "\n"
                                end
                            end
                        end

                        AppendSection("CRITICAL", critical)
                        AppendSection("MEDIUM", medium)
                        AppendSection("LOW", low)

                        report = report .. "\n"
                    end
                end
            end
        end

        -------------------------------------------------
        -- FINAL OUTPUT
        -------------------------------------------------

        if report == "" then
            trigger.action.outText("All Warehouses Above Threshold", 15)
        else
            trigger.action.outText(
                "WAREHOUSE INVENTORY REPORT\n\n" .. report,
                30
            )
        end

    end)

    if not success then
        trigger.action.outText("WAREHOUSE SCRIPT ERROR:\n" .. tostring(err), 20)
    end
end

-------------------------------------------------
-- F10 MENU
-------------------------------------------------

missionCommands.addCommand(
    "Check Warehouse Inventory",
    nil,
    CheckBlueWarehouses
)
