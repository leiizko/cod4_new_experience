/*
	addDvar( dvarName, dvarType, dvarDefault, minValue, maxValue )
	
	DVARNAME = Name of the dvar
	DVARTYPE = Type of the dvar ( int, float or string )
	DVARDEFAULT = Default value of the dvar
	MINVALUE = Min value of the dvar ( for int or float )
	MAXVALUE = Max value of the dvar ( for int or float )
	
	----------------------------------------------------------------
	
	Use above function to add a custom dvar, dvar value can then be accessed in "level.dvar[ dvarName ]" variable.
*/

init()
{
	addDvar( "xp_multi", "int", 1, 1, 100 ); // XP multiplier - 1 normal XP, up to x100
	addDvar( "final_killcam", "int", 1, 0, 1 ); // Enable final killcam ( 1-yes ; 0-no )
	addDvar( "promod_sniper", "int", 1, 0, 1 ); // Steady sniper scope ( 1-yes ; 0-no )
	addDvar( "rcon_interface", "int", 0, 0, 1 ); // aka B3 custom command support ( 1-yes ; 0-no )
	addDvar( "fast_paced", "int", 1, 0, 1 ); // Increase sprint time and overall walking/running speed ( 1-yes ; 0-no )
	addDvar( "hitmarker", "int", 2, 0, 2 ); // Show hitmarker ( 0-no ; 1-always yes ; 2-yes if not wallbang )
	addDvar( "gun_position", "int", 1, 0, 1 ); // More realistic gun positions on screen ( 1-yes ; 0-no )
	addDvar( "spawn_protection", "int", 1, 0, 1 ); // Enable spawn protection ( 1-yes ; 0-no )
	addDvar( "prot_time", "int", 5, 1, 5 ); // Spawn protection time ( 1 - 10 secs )
	addDvar( "cmd_fov", "int", 1, 0, 1 ); // Allow players to change r_fullbright setting with script command ( 1-yes ; 0-no )
	addDvar( "cmd_fps", "int", 1, 0, 1 ); // Allow players to change cg_fovscale setting with script command ( 1-yes ; 0-no )
	addDvar( "cmd_promod", "int", 1, 0, 1 ); // Allow players to change promod vision setting with script command ( 1-yes ; 0-no )
	addDvar( "cmd_stats", "int", 1, 0, 1 ); // Allow players to see stats with script command ( 1-yes ; 0-no )
	addDvar( "old_hardpoints", "int", 0, 0, 1 ); // Hardpoints based off killstreak ( 1-yes ; 0-no )
	addDvar( "intro_text", "string", "Welcome to CoD4:NE" ); // Big text that shows when you first spawn
	addDvar( "website", "string", "www.mysite.com" ); // Will show under ^ big text
	addDvar( "intro_time", "int", 6, 1, 20 ); // How long should intro big text stay?
	addDvar( "credit_text", "string", "Thank you for playing CoD4:NE" ); // Credit
	addDvar( "disable_gl", "int", 0, 0, 1 ); // Disable Grenade Launcher attachment ( 1-yes ; 0-no )
	addDvar( "disable_rpg", "int", 0, 0, 1 ); // Disable RPG-7 perk ( 1-yes ; 0-no )
	addDvar( "disable_c4", "int", 0, 0, 1 ); // Disable C4 perk ( 1-yes ; 0-no )
	addDvar( "disable_claymore", "int", 0, 0, 1 ); // Disable CLAYMORE perk ( 1-yes ; 0-no )
	addDvar( "disable_tripplefrag", "int", 0, 0, 1 ); // Disable TRIPPLE FRAG perk ( 1-yes ; 0-no )
	addDvar( "disable_jugger", "int", 1, 0, 1 ); // Disable JUGGERNAUT perk ( 1-yes ; 0-no )
	addDvar( "disable_laststand", "int", 1, 0, 1 ); // Disable LAST STAND perk ( 1-yes ; 0-no )
	addDvar( "disable_marty", "int", 1, 0, 1 ); // Disable MARTYDROP perk ( 1-yes ; 0-no )
	// Used when script command support is disabled for specific setting
	addDvar( "default_fps", "int", 0, 0, 1 ); // Fullbright setting, players won't be able to change it ( 1-enable ; 0-disable )
	addDvar( "default_fov", "int", 2, 0, 2 ); // Field of view setting, players won't be able to change it ( 2-FOV=100 ; 1-FOV=90 ; 0-FOV=80 )
	addDvar( "default_promod", "int", 1, 0, 1 ); // promod setting, players won't be able to change it ( 1-enable ; 0-disable )
	addDvar( "hardpoint_streak", "int", 0, 0, 1 ); // Hardpoint kills count toward kill streak ( 1-yes ; 0-no )
	addDvar( "showXP", "int", 1, 0, 1 ); // Show score XP on kills
	addDvar( "shopXP", "int", 1, 0, 1 ); // Show shop $ gain instead of kill XP on kills
	
	// Hardpoints - old style, required kill streak
	addDvar( "radar", "int", 3, 1 );
	addDvar( "airstrike", "int", 5, 1 );
	addDvar( "helicopter", "int", 13, 1 );
	addDvar( "artillery", "int", 7, 1 ); 
	addDvar( "asf", "int", 11, 1 );
	addDvar( "agm", "int", 9, 1 );
	addDvar( "predator", "int", 16, 1 );
	addDvar( "ac130", "int", 19, 1 );
	addDvar( "mannedheli", "int", 22, 1 );
	addDvar( "nuke", "int", 28, 1 );
	
	// Hardpoints shop - required credits
	addDvar( "radar_shop", "int", 20, 1 );
	addDvar( "airstrike_shop", "int", 70, 1 );
	addDvar( "helicopter_shop", "int", 180, 1 );
	addDvar( "artillery_shop", "int", 70, 1 ); 
	addDvar( "asf_shop", "int", 100, 1 );
	addDvar( "agm_shop", "int", 100, 1 );
	addDvar( "predator_shop", "int", 280, 1 );
	addDvar( "ac130_shop", "int", 380, 1 );
	addDvar( "mannedheli_shop", "int", 500, 1 );
	addDvar( "nuke_shop", "int", 600, 1 );
	
	addDvar( "arty_shell_num", "int", 35, 10, 100 ); // Number of artillery shells
	
	// Mapvote stuff
	addDvar( "mapvote", "int", 1, 0, 1 ); // Enable map vote ( 1-enable ; 0-disable )
	addDvar( "mapvote_mapnum", "int", 5, 3, 8 ); // Number of maps in mapvote
	addDvar( "mapvote_norepeat", "int", 3, 0, 10 ); // For how many rounds should map not reappear
	addDvar( "mapvote_time", "int", 15, 5, 40 ); // Mapvote time
	addDvar( "gametypeVote", "int", 0, 0, 1 ); // Enable gametype vote ( 1-enable ; 0-disable )
	addDvar( "vote_gametypes", "string", "war dm sd sab koth dom" ); // gametype pool separated by space
	
	// Filesystem - Adds extra features but will make a lot of .db files, each file being less than 1kB in size.
	// fs_ending will make atleast 1 and a maximum of 2 files per unique map, depending if custom waypoints are used
	// fs_players will make 1 per unique player
	// Files get stored in <cod4 dir>/main/ne_db/
	// fs_players may cause lag on slower server if there is a lot of players online
	addDvar( "fs_ending", "int", 1, 0, 1 ); // Use filesystem to save map specific settings ( 1-enable ; 0-disable )
	addDvar( "fs_players", "int", 1, 0, 1 ); // Use filesystem to save player specific settings ( 1-enable ; 0-disable )
	
	addDvar( "shopbuttons_allowchange", "int", 1, 0, 1 ); // Allow the player do decide which buttons to use to navigate hardpoint shop ( 1-W/S ; 0-F/V )
	addDvar( "shopbuttons_default", "int", 0, 0, 1 ); // If above is set to 0, the players will be forced to use this buttons ( 1-W/S ; 0-F/V )
	
	addDvar( "trueskill", "int", 1, 0, 1 ); // Trueskill ranking system ( 1-enable ; 0-disable )
	addDvar( "trueskill_punish", "int", 1, 0, 1 ); // Punish players who leave early by giving them a loss ( 1-enable ; 0-disable )
	
	addDvar( "kct_default", "string", "Owned!" ); // Killcam default text
	addDvar( "welcome", "int", 1, 0, 1 ); // Geowelcome on player first connect ( 1-enable ; 0-disable )
	addDvar( "kcemblem", "int", 1, 0, 1 ); // Allow custom killcam emblem ( 1-enable ; 0-disable )
	
	addDvar( "strat_text", "string", "Strat time:" ); // Strat default text
	addDvar( "strat_time", "int", 5, 0, 10 ); // Default strat time
	addDvar( "strat", "int", 0, 0, 1 ); // use strat ( 1-enable ; 0-disable )
	
	addDvar( "cmd_spec_keys", "int", 0, 0, 1 ); // Allow changing setting to see spectators pressed keys ( 1-enable ; 0-disable )
	addDvar( "spec_keys_default", "int", 0, 0, 1 ); // Default cmd_spec_keys value, if == 0 then this is forced value ( 1-enable ; 0-disable )
	
	addDvar( "force_autoassign", "int", 1, 0, 1 ); // Force players to autoassign ( 1-enable ; 0-disable )
	
	addDvar( "realReload", "int", 0, 0, 1 ); // Drops all ammo left in clip when reloading ( 1-enable ; 0-disable )
	addDvar( "reloadFix", "int", 1, 0, 1 ); // Prevents rapid fire and stop reload binds ( 1-enable ; 0-disable )
	addDvar( "doubleHeli", "int", 1, 0, 1 ); // Allow two normal choppers at one time, manned heli can still only be alone ( 1-enable ; 0-disable )
	
	addDvar( "vip_balance", "int", 1, 0, 1 ); // Can VIP be team balanced ( 1-yes ; 0-no )
	addDvar( "vip_anyteam", "int", 0, 0, 1 ); // Allow VIP to join any team if force_autoassign is enabled ( 1-yes ; 0-no )
	addDvar( "vip_streak", "int", 1, 0, 1 ); // VIP needs 1 kill less to trigger killstreak ( 1-yes ; 0-no )
	
	addDvar( "end_scoreboard", "int", 0, 0, 1 ); // Enable scoreboard on game end ( 1-yes ; 0-no )
	addDvar( "end_scoreboard_time", "int", 5, 1, 30 ); // How long should scoreboard stay on game end in seconds
	
	addDvar( "mysql", "int", 0, 0, 1 ); // Enable mysql functionality ( 1-yes ; 0-no )
	addDvar( "mysql_host", "string", "localhost" ); // Mysql host
	addDvar( "mysql_user", "string", "user" ); // Mysql user
	addDvar( "mysql_pw", "string", "123456789" ); // Mysql password
	addDvar( "mysql_db", "string", "db_name" ); // Mysql database name
	addDvar( "mysql_port", "int", 3306, 0, 65535 ); // Mysql port
	addDvar( "mysql_trueskill_table", "string", "trueskill" ); // Mysql trueskill table name ( only if trueskill is enabled )
	addDvar( "mysql_mapstats_table", "string", "mapstats" ); // Mysql mapstats table
	
	addDvar( "wallbang", "int", 1, 0, 1 ); // Enable wall peneteration ( 1-yes ; 0-no )
	
	addDvar( "dynamic_rotation_enable", "int", 0, 0, 1 );
	addDvar( "dynamic_med", "int", 6, 1, 64 ); // Enable mysql functionality ( 1-yes ; 0-no )
	addDvar( "dynamic_high", "int", 14, 1, 64 ); // Enable mysql functionality ( 1-yes ; 0-no )
	addDvar( "dynamic_low_maps", "string", "map mp_shipment map mp_killhouse map mp_strike" );
	addDvar( "dynamic_med_maps", "string", "map mp_backlot map mp_crash map mp_crash_snow" );
	addDvar( "dynamic_high_maps", "string", "map mp_pipeline map mp_convoy map mp_broadcast" );
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Function by OpenWarfare
addDvar( dvarName, dvarType, dvarDefault, minValue, maxValue )
{
	// Initialize the return value just in case an invalid dvartype is passed
	dvarValue = "";

	// Assign the default value if the dvar is empty
	if ( getdvar( dvarName ) == "" ) 
	{
		dvarValue = dvarDefault;
		setDvar( dvarName, dvarValue ); // initialize the dvar if it isn't in config file
	} 
	
	else 
	{
		// If the dvar is not empty then bring the value
		switch ( dvarType ) 
		{
			case "int":
				dvarValue = getdvarint( dvarName );
				break;
				
			case "float":
				dvarValue = getdvarfloat( dvarName );
				break;
				
			case "string":
				dvarValue = getdvar( dvarName );
				break;
		}
	}

	// Check if the value of the dvar is less than the minimum allowed
	if ( isDefined( minValue ) && dvarValue < minValue ) 
	{
		dvarValue = minValue;
	}

	// Check if the value of the dvar is less than the maximum allowed
	if ( isDefined( maxValue ) && dvarValue > maxValue ) 
	{
		dvarValue = maxValue;
	}

	level.dvar[ dvarName ] = dvarValue;
}