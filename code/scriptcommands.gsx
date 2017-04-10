/*
	addScriptCommand( COMMAND_NAME, COMMAND_POWER )
	
	COMMAND_NAME = Command name, this is used to invoke the command ingame with $
	COMMAND_POWER = Power (integer) needed to invoke the command. Set to 1 if you want it to be usable by anyone. 0 will make it rcon only.

	--- commandHandler ---
	self = the player entity invoking the command
	cmd = command name from addScriptCommand
	arg = arguments supplied with command
*/
init()
{
	addscriptcommand( "fov", 1 );
	addscriptcommand( "fps", 1 );
	addscriptcommand( "promod", 1 );
	addscriptcommand( "shop", 1 );
}

/*
	Stats 3150 and above are free and can be used

	Stat 3160 used for r_fullbright setting
	Stat 3161 used for cg_fovscale / cg_fov setting
	Stat 3162 used for promod vision tweak setting
	Stat 3163 used for hardpoint shop button setting
*/

commandHandler( cmd, arg )
{
	switch( cmd )
	{
		case "fps":
			if( !level.dvar["cmd_fps"] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}

			if( self.pers["fullbright"] == 0 )
			{
				self iPrintlnBold( "Fullbright ^2ON ^7" );
				self setstat(3160,1);
				self.pers["fullbright"] = 1;
					
				if( self.pers["promodTweaks"] == 1 )
				{
					self iPrintlnBold( "Promod vision ^1OFF" );
					self setstat(3162,0);
					self.pers["promodTweaks"] = 0;
				}
			}
			else
			{
				self iPrintlnBold( "Fullbright ^1OFF" );
				self setstat(3160,0);
				self.pers["fullbright"] = 0;
			}
			self thread code\player::userSettings();
			break;

		case "fov":
			if( !level.dvar["cmd_fov"] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
				
			if(self.pers["fov"] == 1 )
			{
				self iPrintlnBold( "Field of View Scale: ^11.0" );
				self setstat(3161,0);
				self.pers["fov"] = 0;
			}
			else if(self.pers["fov"] == 0)
			{
				self iPrintlnBold( "Field of View Scale: ^11.25" );
				self setstat(3161,2);
				self.pers["fov"] = 2;
			}
			else if(self.pers["fov"] == 2)
			{
				self iPrintlnBold( "Field of View Scale: ^11.125" );
				self setstat(3161,1);
				self.pers["fov"] = 1;
			}
			self thread code\player::userSettings();
			break;
			
		case "promod":
			if( !level.dvar["cmd_promod"] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}

			if( self.pers["promodTweaks"] == 0 )
			{
				self iPrintlnBold( "Promod vision ^2ON ^7" );
				self setstat(3162,1);
				self.pers["promodTweaks"] = 1;
					
				if( self.pers[ "fullbright" ] == 1 )
				{
					self iPrintlnBold( "Fullbright ^1OFF" );
					self setstat(3160,0);
					self.pers["fullbright"] = 0;
				}
			}
			else
			{
				self iPrintlnBold( "Promod vision ^1OFF" );
				self setstat(3162,0);
				self.pers["promodTweaks"] = 0;
			}
			self thread code\player::userSettings();
			break;
		
		case "shop":
			if( !level.dvar[ "shopbuttons_allowchange" ] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
			
			if( self.pers[ "hardpointSType" ] == 1 )
			{
				self.pers[ "hardpointSType" ] = 0;
				self setStat( 3163, 0 );
				self iPrintlnBold( "Shop buttons changed to [{+melee}] / [{+activate}]" );
			}
			
			else
			{
				self.pers[ "hardpointSType" ] = 1;
				self setStat( 3163, 1 );
				self iPrintlnBold( "Shop buttons changed to [{+forward}] / [{+back}]" );
			}
			break;
				
		default:
			print( "If you see me you fucked something up :(\n" );
	}
}