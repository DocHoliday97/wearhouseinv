DOC’S WAREHOUSE INVENTORY

A dynamic logistics monitoring script for DCS World that scans all BLUE-controlled airfields and reports supply shortages using a priority-based system.

Overview

Doc’s Warehouse Inventory is designed for mission makers and server operators who want better visibility into logistics without manually tracking warehouse data.

With a single F10 command, the script:

Automatically scans all BLUE airfields

Checks fuel levels

Checks all stocked weapons

Filters out items above threshold

Categorizes shortages into:

Critical
Medium
Low

Sorts items numerically (lowest stock first)

Cleans weapon names for readability

Auto-detects weapon category (Missile / Bomb / Rocket)

No need to manually define airfields.
No need to hardcode weapon names.

The script dynamically adapts to captured airfields and changing mission states.

Features

F10 menu trigger

Automatic BLUE coalition detection

Dynamic airfield scanning

Fuel monitoring

Global minimum thresholds

Priority-based reporting

Clean formatted output

Zero clutter (only shows shortages)

Default Thresholds

These can be adjusted inside the script.

Fuel

Critical: Below configured critical level

Medium: Below configured medium level

Low: Below configured low level

(Default example: Minimum fuel alert at 25,000)

Weapons

Minimum stock example: 25

Sorted from lowest quantity to highest

Categorized automatically

Only items below threshold are displayed.

Installation

Open your mission in Mission Editor.

Create a new trigger:

Type: MISSION START

Action: DO SCRIPT FILE

Select the script file.

Save mission.

An F10 menu option will appear in-game to run the warehouse check.

Usage

In-game:

F10 → Other → Check Warehouse Inventory

The script will display a formatted report listing:

Airfield
Priority level
Item(s) needing resupply

If everything is above threshold, nothing is displayed.

Planned Features

Discord webhook integration for automatic alerts

Automated logistics task generation

Persistent resupply tracking

Scheduled automatic checks

Optional red coalition support

Intended Use

Multiplayer servers

Persistent campaign missions

Dynamic frontline operations

Logistics-focused gameplay

Combined Arms coordination

Requirements

DCS World with warehouse system enabled

Airfields using active warehouse logic

Author

DOC
