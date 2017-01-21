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
	addDvar( "promod_sniper", "int", 1, 0, 1 ); // Steady sniper score ( 1-yes ; 0-no )
	addDvar( "rcon_interface", "int", 0, 0, 1 ); // aka B3 custom command support ( 1-yes ; 0-no )
	addDvar( "fast_paced", "int", 1, 0, 1 ); // Increase sprint time and overall walking/running speed ( 1-yes ; 0-no )
	addDvar( "gun_position", "int", 1, 0, 1 ); // More realistic gun positions on screen ( 1-yes ; 0-no )
	addDvar( "spawn_protection", "int", 1, 0, 1 ); // Enable spawn protection ( 1-yes ; 0-no )
	addDvar( "cmd_fov", "int", 1, 0, 1 ); // Allow players to change r_fullbright setting with script command ( 1-yes ; 0-no )
	addDvar( "cmd_fps", "int", 1, 0, 1 ); // Allow players to change cg_fovscale setting with script command ( 1-yes ; 0-no )
	addDvar( "cmd_promod", "int", 1, 0, 1 ); // Allow players to change promod vision setting with script command ( 1-yes ; 0-no )
	addDvar( "old_hardpoints", "int", 0, 0, 1 ); // Hardpoints based off killstreak ( 1-yes ; 0-no )
	addDvar( "intro_text", "string", "Welcome to XYZ" ); // Big text that shows when you first spawn
	addDvar( "website", "string", "www.mysite.com" ); // Will show under ^ big text
	addDvar( "intro_time", "int", 6, 1, 20 ); // How long should intro big text stay?
	addDvar( "credit_text", "string", "Thank you for playing" ); // Credit
	addDvar( "disable_gl", "int", 0, 0, 1 ); // Disable Grenade Launcher attachment ( 1-yes ; 0-no )
	addDvar( "disable_rpg", "int", 0, 0, 1 ); // Disable RPG-7 perk ( 1-yes ; 0-no )
	addDvar( "disable_c4", "int", 0, 0, 1 ); // Disable C4 perk ( 1-yes ; 0-no )
	addDvar( "disable_claymore", "int", 0, 0, 1 ); // Disable CLAYMORE perk ( 1-yes ; 0-no )
	addDvar( "disable_tripplefrag", "int", 0, 0, 1 ); // Disable TRIPPLE FRAG perk ( 1-yes ; 0-no )
	addDvar( "disable_jugger", "int", 1, 0, 1 ); // Disable JUGGERNAUT perk ( 1-yes ; 0-no )
	addDvar( "disable_laststand", "int", 1, 0, 1 ); // Disable LAST STAND perk ( 1-yes ; 0-no )
	addDvar( "disable_marty", "int", 1, 0, 1 ); // Disable MARTYDROP perk ( 1-yes ; 0-no )
	addDvar( "arty_shell_num", "int", 1, 100, 35 ); // Number of artillery shells
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