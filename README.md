DCS Warehouse Logistics Monitor

A lightweight warehouse monitoring script for DCS World that tracks supply levels at BLUE coalition airbases and reports shortages in-game and optionally to Discord.

Designed for persistent multiplayer servers, logistics gameplay, and dynamic campaigns.

Features

• Automatic warehouse monitoring
• Configurable supply thresholds
• In-game F10 menu supply report
• Optional Discord alerts via DCSServerBot
• Anti-spam alert system (only reports changes)

Alert Levels

🚨 CRITICAL
• Pings Logistics role in Discord
• Indicates immediate resupply needed

⚠ MEDIUM
• Discord notification only
• Warns supply levels are dropping

✅ RECOVERED
• Notification when supplies are restored

Requirements

This script optionally integrates with:

DCSServerBot

GitHub:
https://github.com/Special-K-s-Flightsim-Bots/DCSServerBot

Important

If Discord integration is enabled, DCSServerBot must be installed and running.

The script can also run completely standalone without Discord.

DCS Server Setup
1. Desanitize Mission Scripting

Edit the following file on your server:

Saved Games\DCS\Scripts\MissionScripting.lua

Comment out the following lines:

-- sanitizeModule('os')
-- sanitizeModule('io')
-- sanitizeModule('lfs')

This allows the mission to access external scripts such as DCSServerBot.

Mission Editor Installation
Step 1 — Load DCSServerBot

Create a trigger:

TYPE

MISSION START

ACTION

DO SCRIPT

Paste:

dofile(lfs.writedir() .. 'Scripts/net/DCSServerBot/DCSServerBot.lua')
Step 2 — Load the Warehouse Script

Create another trigger:

TYPE

MISSION START

ACTION

DO SCRIPT FILE

Select:

warehouseMonitor.lua
In-Game Usage

Once the mission starts the script will automatically begin monitoring warehouses.

Players and admins can manually check supplies using:

F10 → Other → Check Warehouse Inventory

This will display a full supply report in-game.

Configuration

All configuration is located at the top of the script.

Example:

local EnableDiscord = true
local DiscordChannel = '12345678'
local LogisticsRole = "<@&12345678>"
EnableDiscord
true  = Discord alerts enabled
false = Standalone in-game mode only
CheckInterval
local CheckInterval = 300

How often warehouses are scanned.

Examples:

300 = 5 minutes
600 = 10 minutes (recommended)
Weapon Thresholds
WeaponThresholds = {
LOW = 60,
MEDIUM = 40,
CRITICAL = 20
}

Defines supply warning levels for weapons.

Fuel Thresholds
FuelThresholds = {
LOW = 50000,
MEDIUM = 25000,
CRITICAL = 10000
}

Defines supply warning levels for fuel.

Example Discord Alerts
Critical Shortage
🚨 Logistics Critical
@Logistics

Kobuleti
AIM-120C — 4
GBU-12 — 2
Supply Restored
✅ Supply Restored

Batumi
Jet Fuel Restored
AIM-120C Restored
Use Cases

This script is ideal for:

• Persistent multiplayer servers
• Logistics-focused gameplay
• Dynamic campaign missions
• Training environments
• Event missions with supply management

License

Free to use, modify, and share.

Credit to Doc ✪ is appreciated but not required.
