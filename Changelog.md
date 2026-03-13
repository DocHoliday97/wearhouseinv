Changelog

All notable changes to DCS Warehouse Logistics Monitor will be documented in this file.

This project follows a simple versioning structure:

MAJOR.MINOR.PATCH

Example:

2.0.0
[2.0.0] — 2026-03-13
Added

• Standalone operation mode
• EnableDiscord configuration toggle
• Supply recovery notifications when stock levels return to normal
• Clear three-tier alert severity system

CRITICAL → role ping
MEDIUM → notification only
RECOVERED → notification only

• Anti-spam alert system that only triggers when supply state changes

• Configurable thresholds for:

Weapons

Fuel

• Improved configuration documentation in script header

Improved

• Cleaner Discord embed formatting
• Improved warehouse report formatting in-game
• Better weapon name parsing for readability
• More reliable supply state tracking logic
• Clearer configuration comments for server admins

Changed

• Alert system now triggers on state transitions rather than raw values

Example:

OK → MEDIUM
MEDIUM → CRITICAL
CRITICAL → RECOVERED

This significantly reduces Discord spam on persistent servers.

Compatibility

Optional integration with:

DCSServerBot

Script can now run with or without Discord integration.

[1.0.0] — 2026-03-12
Initial Release

Initial release of Warehouse Logistics Monitor.

Features

• Automatic warehouse monitoring for BLUE airbases
• Configurable weapon supply thresholds
• Configurable fuel supply thresholds
• Discord alerts using DCSServerBot
• Role ping for critical shortages
• Automatic warehouse checks on a timer
• In-game F10 menu supply report

Planned

Future improvements under consideration:

• Airbase-specific supply thresholds
• Carrier and ship warehouse monitoring
• Frontline logistics priority system
• Live Discord supply dashboard
• Multi-coalition monitoring support
