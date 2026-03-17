# DCS Warehouse Logistics Monitor

A warehouse monitoring script for DCS World that watches BLUE coalition airbases, detects supply shortages, and reports them in-game or to Discord.

This is intended for persistent multiplayer servers, logistics-heavy missions, and dynamic campaign environments.

## Features

- Automatic warehouse checks on a timer
- Optional Discord alerts through DCSServerBot
- Standalone mode with no Discord dependency
- In-game F10 report menu
- Short, prioritized in-game shortage summary
- Full Discord embeds for detailed shortage lists
- Anti-spam logic that only alerts on state changes
- Configurable thresholds for weapons and fuel
- Optional in-game debug output

## Alert Levels

- `CRITICAL`: highest priority, pings the configured Discord role
- `MEDIUM`: warning level, Discord notification without role ping
- `RECOVERED`: sent when stock returns from a shortage state

## Requirements

Discord support uses DCSServerBot:

https://github.com/Special-K-s-Flightsim-Bots/DCSServerBot

If `EnableDiscord = true`, DCSServerBot must be installed and loaded in the mission.

If `EnableDiscord = false`, the script can run fully standalone with in-game reporting only.

## DCS Server Setup

### 1. Desanitize mission scripting

Edit this file on the server:

`Saved Games\DCS\Scripts\MissionScripting.lua`

Comment out these lines:

```lua
-- sanitizeModule('os')
-- sanitizeModule('io')
-- sanitizeModule('lfs')
```

This allows DCS to access external scripts such as DCSServerBot.

### 2. Load DCSServerBot in the mission

If you are using Discord integration, add a `MISSION START` trigger with `DO SCRIPT`:

```lua
dofile(lfs.writedir() .. 'Scripts/net/DCSServerBot/DCSServerBot.lua')
```

### 3. Load this script in the mission

Add another `MISSION START` trigger with `DO SCRIPT FILE` and select:

```text
wearhouseinv.lua
```

## In-Game Usage

Once the mission starts, the script automatically scans BLUE warehouses on the configured interval.

Players or admins can manually check shortages from:

`F10 -> Other -> Check Warehouse Inventory`

### In-game report behavior

- If Discord is enabled, the in-game message shows the top shortage items only
- The in-game message is capped by `MaxInGameReportItems`
- The most critical items appear first
- If there are more items than shown, the message ends with `See Discord for full list.`
- Discord still receives the full detailed shortage list

### Standalone behavior

- If Discord is disabled and `FullInGameReportWithoutDiscord = true`, the in-game report shows the full list
- If Discord is disabled and `FullInGameReportWithoutDiscord = false`, the in-game report still uses the short capped list

## Configuration

All user-editable settings are grouped at the top of `wearhouseinv.lua`.

### Discord settings

```lua
local EnableDiscord = true
local DiscordChannel = '12345678'
local LogisticsRole = "<@&12345678>"
```

- `EnableDiscord`: enable or disable Discord integration
- `DiscordChannel`: Discord channel ID used for alerts
- `LogisticsRole`: optional role mention for critical shortages

### Check timer

```lua
local CheckInterval = 300
```

- `300` = 5 minutes
- `600` = 10 minutes

### Debug settings

```lua
local EnableDebug = false
local DebugToGame = false
local DebugDisplayTime = 10
```

- `EnableDebug`: enables script debug output
- `DebugToGame`: shows debug text in DCS with `trigger.action.outText`
- `DebugDisplayTime`: how long debug messages stay on screen

### In-game report settings

```lua
local MaxInGameReportItems = 5
local FullInGameReportWithoutDiscord = true
```

- `MaxInGameReportItems`: number of items shown in the short in-game report
- `FullInGameReportWithoutDiscord`: shows the full in-game report when Discord is disabled

### Weapon thresholds

```lua
local WeaponThresholds = {
	LOW = 60,
	MEDIUM = 40,
	CRITICAL = 20
}
```

Weapon counts below these values are treated as shortage states.

### Fuel thresholds

```lua
local FuelThresholds = {
	LOW = 75000,
	MEDIUM = 50000,
	CRITICAL = 25000
}
```

Jet fuel amounts below these values are treated as shortage states.

## Sorting and Priority

Shortage items shown in-game are sorted in this order:

1. `CRITICAL`
2. `MEDIUM`
3. Lower quantity first within the same severity
4. Airbase name and item name as final tie-breakers

This keeps the most urgent shortages at the front of the in-game message.

## Example In-Game Summary

```text
Batumi AIM-120C 2 | Kobuleti Jet Fuel 12000 | Senaki GBU-12 5 | See Discord for full list.
```

## Example Discord Alerts

### Critical shortage

```text
🚨 Logistics Critical
@Logistics

Kobuleti
AIM-120C — 4
GBU-12 — 2
```

### Supply restored

```text
✅ Supply Restored

Batumi
Jet Fuel Restored
AIM-120C Restored
```

## Use Cases

- Persistent multiplayer servers
- Logistics-focused gameplay
- Dynamic campaign missions
- Training servers
- Event missions with supply management

## License

Free to use, modify, and share.

Credit to Doc is appreciated but not required.
