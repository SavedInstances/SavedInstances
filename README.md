<div align="center">
  
# SavedInstances

[![Build Status](https://github.com/SavedInstances/SavedInstances/workflows/CI/badge.svg)](https://github.com/SavedInstances/SavedInstances/actions?workflow=CI)

</div>

An addon that keeps track of the instance/raid lockouts saved against your characters, and related currencies and cooldowns. 

## Features:

- Tooltip display shows current lockouts and data for all your characters, and optionally expired lockouts
- Secondary tooltip (per-lockout) shows lockout details including bosses available, lock status and time remaining, and can be linked into chat
- Tracks the honor points and conquest points of all your characters, including weekly caps
- Tracks seals, resources, money, and other useful currencies (configurable display)
- Tracks weekly World Boss Loots 
- Tracks LFR bosses looted
- Tracks holiday boss encounters
- Tracks daily and weekly quests completed for each toon (mouseover entry to list completed quests)
- Tracks Tanaan Jungle oil bosses: Doomroller, Deathtalon, Terrorfist, Vengeance (mouseover daily quests)
- Tracks Garrison invasion rewards (mouseover weekly quests)
- Tracks monthly Darkmoon Faire quests completed for each toon (mouseover weekly quests)
- Tracks weekly "special" loots on the Timeless Isle and Isle of Thunder (mouseover weekly quests)
- Tracks trade skill cooldowns (eg. Celestial cloth, Living Steel transmute, Secrets of Draenor, etc.)
- Tracks data for all your characters across servers and factions
- Can be configured to always show your favorite instances so you can use it like a shopping list
- Tracks Blizzard's 10 instance per hour per account limit (*)
- Tracking Bonus Loot Rolls (hidden by default), to help in "gaming" the bad luck protection (*)

[Bug Reports and Feature Requests](https://github.com/SavedInstances/SavedInstances/issues) (Bug reports in comments might not be seen)

Translators: Apply localization [here](http://www.wowace.com/addons/saved_instances/localization/)

Featured in [Hearthcast Podcast #181](http://hearthcast.com/download.php?filename=2013-08-14_ep181.mp3)

## Known Issues

SavedInstances is pretty good, but it's still not quite perfect. There are currently a few issues:

- When first installed, SavedInstances has no knowledge of your other characters: you'll need to log into each for their information to be recorded
- (*) = Indicates a feature displaying data that cannot be directly queried from the server, but rather is collected by the addon while observing player actions. Actions taken while the addon is disabled, or from other computers, or before a client crash, can result in this display being temporarily out-of-date or incomplete.
- Lockout time remaining and other features may be off by an hour when your region changes to and from Daylight Savings Time, or if you manually adjust the timezone of your computer.
- Tracking for the 10 instance per hour limit uses heuristic detection and hence may occasionally be inaccurate (notably when another player has lead and performs explicit resets), but does a reasonable job for common cases.

## Usage

SavedInstances will create a new button on the minimap, and you can use it to interact with SavedInstances just fine. The addon can also be displayed using a LibDataBroker-compatible display addon. I personally use Chocolate Bar which works quite well. Finally, you can bind a key or use "/si show" to open a detached window containing the display.

### Multiple Accounts

If you are playing with multiple WoW accounts but want to keep track of all of them, you need to use [Symlinks](https://en.wikipedia.org/wiki/Symbolic_link) on your saved variable files.
