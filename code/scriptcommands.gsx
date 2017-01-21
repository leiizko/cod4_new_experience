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
	addscriptcommand( "haha", 1 );
}

/*
	Stats 3150 and above are free and can be used

	Stat 3160 used for r_fullbright setting
	Stat 3161 used for cg_fovscale / cg_fov setting
	Stat 3162 used for promod vision tweak setting
*/

commandHandler( cmd, arg )
{
	self endon( "disconnect" );
	
	switch( cmd )
	{
		case "fps":
			if( !level.dvar["cmd_fps"] )
				break;

			if( self.pers["fullbright"] == 0 )
			{
				self iPrintlnBold( "Fullbright ^2ON ^7" );
				self setClientDvar( "r_fullbright", 1 );
				self setstat(3160,1);
				self.pers["fullbright"] = 1;
					
				if( self.pers["promodTweaks"] == 1 )
				{
					self iPrintlnBold( "Promod vision ^1OFF" );
					self SetClientDvars( "r_filmusetweaks", "0",
										 "r_filmTweakenable", "0" );
					self setstat(3162,0);
					self.pers["promodTweaks"] = 0;
				}
			}
			else
			{
				self iPrintlnBold( "Fullbright ^1OFF" );
				self setClientDvar( "r_fullbright", 0 );
				self setstat(3160,0);
				self.pers["fullbright"] = 0;
			}
			break;

		case "fov":
			if( !level.dvar["cmd_fov"] )
				break;
				
			if(self.pers["fov"] == 1 )
			{
			self iPrintlnBold( "Field of View Scale: ^11.0" );
			self setClientDvar( "cg_fovscale", 1.0 );
			self setClientDvar( "cg_fov", 80 );
			self setstat(3161,0);
			self.pers["fov"] = 0;
			}
			else if(self.pers["fov"] == 0)
			{
				self iPrintlnBold( "Field of View Scale: ^11.25" );
				self setClientDvar( "cg_fovscale", 1.25 );
				self setClientDvar( "cg_fov", 80 );
				self setstat(3161,2);
				self.pers["fov"] = 2;
			}
			else if(self.pers["fov"] == 2)
			{
				self iPrintlnBold( "Field of View Scale: ^11.125" );
				self setClientDvar( "cg_fovscale", 1.125 );
				self setClientDvar( "cg_fov", 80 );
				self setstat(3161,1);
				self.pers["fov"] = 1;
			}
			break;
			
		case "promod":
			if( !level.dvar["cmd_promod"] )
				break;

			if( self.pers["promodTweaks"] == 0 )
			{
				self iPrintlnBold( "Promod vision ^2ON ^7" );
				self SetClientDvars( "r_filmTweakInvert", "0",
									 "r_filmTweakBrightness", "0",
									 "r_filmusetweaks", "1",
									 "r_filmTweakenable", "1",
									 "r_filmtweakLighttint", "0.8 0.8 1",
									 "r_filmTweakContrast", "1.2",
									 "r_filmTweakDesaturation", "0",
									 "r_filmTweakDarkTint", "1.8 1.8 2" );

				self setstat(3162,1);
				self.pers["promodTweaks"] = 1;
					
				if( self.pers[ "fullbright" ] == 1 )
				{
					self iPrintlnBold( "Fullbright ^1OFF" );
					self setClientDvar( "r_fullbright", 0 );
					self setstat(3160,0);
					self.pers["fullbright"] = 0;
				}
			}
			else
			{
				self iPrintlnBold( "Promod vision ^1OFF" );
				self SetClientDvars( "r_filmusetweaks", "0",
										 "r_filmTweakenable", "0" );
				self setstat(3162,0);
				self.pers["promodTweaks"] = 0;
			}
			break;
				
		default:
			print( "If you see me you fucked something up :(\n" );
	}
}