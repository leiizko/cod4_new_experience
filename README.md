# CoD4 New Experience
Call of Duty 4 New Experience server side modification aims to bring new life into the game and provide a library of scripts for server admins to explore.

## Features:
* Player slide (sprint + crouch) with a 10 second cooldown
* Unified HUD template for shop, money, slide, spawn protection, killcam, and anti-cheat warnings
* Player-level anti-cheat (speed, fire-rate, damage spikes, slide spam) with warn then kick
* Shop gear: Extra Ammo, Extra Health, Smoke Cover, Extra Slide
* Brand new hardpoint system
* New hardpoints
* XP multiplier mode
* Fast paced mode
* Smart spawn protection
* Custom and final killcam
* Dynamic killcam times
* Map specific best players on game end
* Custom spectating - You can see spectating player FPS and his vision settings
* Script and rcon command support for vision settings
* Geowelcome system ( with MaxMind GeoIP database )
* Ability to disable attachements and perks such as grenade launcher, juggernaut, etc.
* Optimisation to the stock code making game feel smoother
* Mapvote system
* Custom waypoint based end screen
* Trueskill rating system
* Ability to save client data serverside
* MySQL support
* And more...

## Hardpoints:
* UAV
* Airstrike
* Artillery - using ballistic trajectory and simulated projectiles
* Air superiority fighter - will seek enemy helicopter and destroy it
* Air to Ground missile
* Unmanned helicopter
* Predator drone
* AC130 gunship
* Manned helicopter - bringing Battlefield to CoD4, take control of your helicopter
* Nuclear missile - kill everyone and leave radiation zone that will stop the enemy in its tracks

## New hardpoint system
Buy hardpoints by spending your hard earned credits and take control of the game. There is no longer need to camp to get hard to reach hardpoints, get your credits by killing your enemies and gain even more by getting headshots and melee kills. You won't lose any of the credits on death so feel free to rush enemy team or bring your hidden ninja to the game.

Shop prices (credits):
* Radar - 15
* Extra Ammo - 40
* Smoke Cover - 35
* Extra Slide - 50
* Airstrike - 50
* Artillery - 55
* Extra Health - 60
* Hellfire Missile - 80
* Fighter Support - 90
* Helicopter - 140
* Predator Drone - 220
* AC130 Gunship - 300
* Manned Helicopter - 400
* Thermonuclear Bomb - 550

## Shop gear
Gear items sit in the same shop list as hardpoints and last until death unless noted:
* Extra Ammo - refill current weapon, last weapon, and offhand
* Extra Health - 150 HP until death (refused if already active)
* Smoke Cover - give one smoke grenade, or +1 if you already have it
* Extra Slide - 3 second slide cooldown until death (refused if already active)

Open the shop with action slot 4 (hardpoint key). Attack buys the selected item. Navigation is melee/use or W/S depending on `$shop`.

## Player slide
Sprint then press crouch to slide. Server-side slide lasts about 0.7 seconds, then you stand back up.

* 10 second cooldown after each slide
* Extra Slide shop item drops cooldown to 3 seconds until death
* Disabled in shop, spawn protection, killcam, and hardpoint vehicles
* Bottom-right cooldown bar uses the shared HUD template
* Collision traces stop the slide instead of pushing through walls

Dvars: `slide_enable`, `slide_cooldown`, `slide_duration`.

## Unified HUD
Shop, money, slide cooldown, spawn protection, killcam chrome, and anti-cheat warnings share one template: dark panel, orange accent bar, objective titles.

## Anti-cheat
Per-player suspicion score for this map only. GSC cannot catch wallhacks or aimbots. It flags server-visible abuse:

* Impossible speed (relative to `g_speed` and sprint scale)
* Fire-rate / click spam
* Damage spikes (more than 10 hits in 1 second)
* Slide spam while on cooldown

At `anticheat_warn` (default 30) the player gets a HUD warning. At `anticheat_kick` (default 60) they are kicked. Sampling is skipped during slide, spawn protection, killcam, and hardpoint control.

VIP players can run `$acflags` to print every connected player's score and recent flags.

Dvars: `anticheat_enable`, `anticheat_warn`, `anticheat_kick`.

## Requirements:
* Latest version of CoD4X server modification, available on [Github repo](https://github.com/callofduty4x/CoD4x_Server)

## Optional:
* Maxmind geoIP database, available on [MaxMind.com](http://dev.maxmind.com/geoip/legacy/install/country/)
* CoD4X Trueskill plugin, available on [Github repo](https://github.com/leiizko/cod4_trueskill_plugin)
* CoD4X MySQL plugin, available on [Github repo](https://github.com/callofduty4x/mysql)

## Installation:
* Place the code, ghost, and maps folders into your <CoD4x Server Dir>/main_shared/ folder
* Place config.cfg into your <CoD4x Server Dir>/main/ folder
* Customise settings in config file to your desire and exec it from your main config file
* Start the server

## Trueskill installation:
* Download Trueskill plugin
* Place trueskill plugin into your plugins directory
* Enable Trueskill in your config file
* Load plugin in your main config file or in server command line

## MySQL installation:
* Download MySQL plugin, be careful about dependencies
* Place MySQL plugin into your plugins directory
* Make a clean database and user - do not use root
* Enable MySQL funtionality in your config file and write down all required information
* Load plugin in your main config file or in server command line

## Setting rcon commands with BigBrotherBot
* Set rcon_interface dvar to 1 in your New Experience config file
* Enable custom commands plugin in your B3 config file
* Add following lines to your B3 custom commands plugin:
```
fps = cmd fps:<PLAYER:PID>
fov = cmd fov:<PLAYER:PID>
promod = cmd promod:<PLAYER:PID>
shop = cmd shop:<PLAYER:PID>
stats = cmd stats:<PLAYER:PID>:<ARG:OPT:{}>
emblem = cmd emblem:<PLAYER:PID>:<ARG>
speckeys = cmd speckeys:<PLAYER:PID>
acflags = cmd acflags:<PLAYER:PID>
```
