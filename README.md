# CoD4 New Experience
Call of Duty 4 New Experience server side modification aims to bring new life into the game and provide a library of scripts for server admins to explore.

## Features:
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

## Requirements:
* Latest version of CoD4X server modification, available on [Github repo](https://github.com/callofduty4x/CoD4x_Server)

## Optional:
* Maxmind geoIP database, available on [MaxMind.com](http://dev.maxmind.com/geoip/legacy/install/country/)
* CoD4X Trueskill plugin, available on [Github repo](https://github.com/leiizko/cod4_trueskill_plugin)
* CoD4X MySQL plugin, available on [Github repo](https://github.com/callofduty4x/mysql)

## Installation:
* Place both code and maps folders into your <CoD4x Server Dir>/main_shared/ folder
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
```
