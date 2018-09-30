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
	addscriptcommand( "stats", 1 );
	addscriptcommand( "emblem", 1 );
	addscriptcommand( "speckeys", 1 );
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
	if( !isDefined( self.pers[ "promodTweaks" ] ) )
	{
		self iPrintlnBold( "Commands currently unavailable, please try again later" );
		return;
	}
		
	switch( toLower( cmd ) )
	{
		case "fps":
			if( !level.dvar[ "cmd_fps" ] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
			killTweaks = undefined;
			stat = 0;

			if( self.pers[ "fullbright" ] == 0 )
			{
				self iPrintlnBold( "Fullbright ^2ON ^7" );
				stat = 1;
				self.pers[ "fullbright" ] = 1;
					
				if( self.pers[ "promodTweaks" ] == 1 )
				{
					self iPrintlnBold( "Promod vision ^1OFF" );
					killTweaks = true;
					self.pers[ "promodTweaks" ] = 0;
				}
			}
			else
			{
				self iPrintlnBold( "Fullbright ^1OFF" );
				stat = 0;
				self.pers[ "fullbright" ] = 0;
			}

			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "fps=" + self.pers[ "fullbright" ];
				if( isDefined( killTweaks ) )
					q[ 2 ] = "promod=" + self.pers[ "promodTweaks" ];
				
#if isSyscallDefined mysql_close
				self thread code\mysql::sendData( "players", q );
#endif
			}

			else if( !level.dvar[ "fs_players" ] )
			{
				self setstat( 3160, stat );
				
				if( isDefined( killTweaks ) )
					self setstat(3162,0);
				
			}
			else
			{
				guid = self getGuid();
				level.FSCD[ guid ][ 0 ] = "fullbright;" + self.pers[ "fullbright" ];
				level.FSCD[ guid ][ 2 ] = "promodTweaks;" + self.pers[ "promodTweaks" ];
			}
			
			self thread code\player::userSettings();
			break;

		case "fov":
			if( !level.dvar[ "cmd_fov" ] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
			stat = 0;
				
			if(self.pers[ "fov" ] == 1 )
			{
				self iPrintlnBold( "Field of View Scale: ^11.0" );
				stat = 0;
				self.pers[ "fov" ] = 0;
			}
			else if(self.pers[ "fov" ] == 0)
			{
				self iPrintlnBold( "Field of View Scale: ^11.25" );
				stat = 2;
				self.pers[ "fov" ] = 2;
			}
			else if(self.pers[ "fov" ] == 2)
			{
				self iPrintlnBold( "Field of View Scale: ^11.125" );
				stat = 1;
				self.pers[ "fov" ] = 1;
			}
			
			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "fov=" + self.pers[ "fov" ];
				
#if isSyscallDefined mysql_close
				self thread code\mysql::sendData( "players", q );
#endif
			}

			else if( !level.dvar[ "fs_players" ] )
				self setstat( 3161, stat );
			else
				level.FSCD[ self getGuid() ][ 1 ] = "fov;" + self.pers[ "fov" ];

			self thread code\player::userSettings();
			break;
			
		case "promod":
			if( !level.dvar[ "cmd_promod" ] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
			stat = 0;
			killFPS = undefined;

			if( self.pers[ "promodTweaks" ] == 0 )
			{
				self iPrintlnBold( "Promod vision ^2ON ^7" );
				stat = 1;
				self.pers[ "promodTweaks" ] = 1;
					
				if( self.pers[ "fullbright" ] == 1 )
				{
					self iPrintlnBold( "Fullbright ^1OFF" );
					killFPS = true;
					self.pers[ "fullbright" ] = 0;
				}
			}
			else
			{
				self iPrintlnBold( "Promod vision ^1OFF" );
				stat = 0;
				self.pers[ "promodTweaks" ] = 0;
			}
			
			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "promod=" + self.pers[ "promodTweaks" ];
				if( isDefined( killFPS ) )
					q[ 2 ] = "fps=" + self.pers[ "fullbright" ];
				
#if isSyscallDefined mysql_close
				self thread code\mysql::sendData( "players", q );
#endif
			}

			else if( !level.dvar[ "fs_players" ] )
			{
				self setstat( 3162, stat );
				
				if( isDefined( killFPS ) )
					self setstat(3160,0);
				
			}
			else
			{
				guid = self getGuid();
				level.FSCD[ guid ][ 0 ] = "fullbright;" + self.pers[ "fullbright" ];
				level.FSCD[ guid ][ 2 ] = "promodTweaks;" + self.pers[ "promodTweaks" ];
			}
			
			self thread code\player::userSettings();
			break;
		
		case "shop":
			if( !level.dvar[ "shopbuttons_allowchange" ] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
			stat = 0;
			
			if( self.pers[ "hardpointSType" ] == 1 )
			{
				self.pers[ "hardpointSType" ] = 0;
				stat = 0;
				self iPrintlnBold( "Shop buttons changed to [{+melee}] / [{+activate}]" );
			}
			
			else
			{
				self.pers[ "hardpointSType" ] = 1;
				stat = 1;
				self iPrintlnBold( "Shop buttons changed to [{+forward}] / [{+back}]" );
			}
			
			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "shop=" + self.pers[ "hardpointSType" ];
				
#if isSyscallDefined mysql_close
				self thread code\mysql::sendData( "players", q );
#endif
			}

			else if( !level.dvar[ "fs_players" ] )
				self setstat( 3163, stat );
			else
				level.FSCD[ self getGuid() ][ 3 ] = "hardpointSType;" + self.pers[ "hardpointSType" ];
			
			break;
			
		case "stats":
			if( !level.dvar[ "cmd_stats" ] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
			
			if( !isDefined( arg ) || arg == "" )
			{
				if( !isDefined( self.pers[ "sigma" ] ) )
				{
					self iPrintlnBold( "Please try again in a moment!" );
					break;
				}
				rank = self.pers[ "mu" ] - ( 3 * self.pers[ "sigma" ] );
				printClient( self, "Your Trueskill rating is: " + int( rank ) );
			}
			else
			{
				if( isInt( arg ) )
				{
					player = getEntByNum( int( arg ) );
					if( !isDefined( player ) || !isPlayer( player ) )
					{
						printClient( self, "No players found matching #" + arg );
						break;
					}
				}
				else
				{
					player = self getEntByStr( arg );
					if( !isDefined( player ) || !isPlayer( player ) )
						break;
				}
				
				if( !isDefined( player.pers[ "sigma" ] ) )
				{
					self iPrintlnBold( "Please try again in a moment!" );
					break;
				}
				rank = player.pers[ "mu" ] - ( 3 * player.pers[ "sigma" ] );
				printClient( self, player.name + "'s Trueskill rating is: " + int( rank ) );
			}
			break;
		
		case "emblem":
			if( !level.dvar[ "fs_players" ] )
			{
				self iPrintlnBold( "This command is unavailable on this server." );
				return;
			}
			
			if( !level.dvar[ "kcemblem" ] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
			
			if( !isDefined( arg ) || arg == "" )
			{
				printClient( self, "Your current emblem: " + self.pers[ "killcamText" ] );
				self iPrintlnBold( "Usage: $emblem <text>" );
				return;
			}
			
			if( isSubStr( arg, ";" ) )
			{
				self iPrintlnBold( "Illegal character ;" );
				return;
			}
			
			if( arg.size > 80 )
			{
				self iPrintlnBold( "Maximum text size is 80 characters long" );
				return;
			}
			
			self.pers[ "killcamText" ] = arg;
			
			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "emblem=" + self.pers[ "killcamText" ];
				
#if isSyscallDefined mysql_close
				self thread code\mysql::sendData( "players", q );
#endif
			}

			else
				level.FSCD[ self getGuid() ][ 5 ] = "killcamText;" + self.pers[ "killcamText" ];
			break;
			
		case "speckeys":
			if( !level.dvar[ "cmd_spec_keys" ] )
			{
				self iPrintlnBold( "This command was disabled by server admin." );
				break;
			}
			
			stat = 0;
			
			if( self.pers[ "spec_keys" ] == 1 )
			{
				self.pers[ "spec_keys" ] = 0;
				stat = 0;
				self iPrintlnBold( "Spectator keys OFF" );
			}
			
			else
			{
				self.pers[ "spec_keys" ] = 1;
				stat = 1;
				self iPrintlnBold( "Spectator keys ON" );
			}
			
			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "spec=" + self.pers[ "spec_keys" ];
				
#if isSyscallDefined mysql_close
				self thread code\mysql::sendData( "players", q );
#endif
			}

			else if( !level.dvar[ "fs_players" ] )
				self setstat( 3164, stat );
			else
				level.FSCD[ self getGuid() ][ 4 ] = "spec_keys;" + self.pers[ "spec_keys" ];
			
			break;
				
		default:
			print( "If you see me you fucked something up :(\n" );
	}
}

// Built in function is crap
isInt( s )
{
	for( i = 0; i < s.size; i++ )
	{
		if( s[ i ] != "0" && !int( s[ i ] ) )
		{
			return false;
		}
	}
	
	return true;
}

getEntByStr( s )
{
	array = [];
	sl = toLower( s );
	
	players = level.players;
	for( i = 0; i < level.players.size; i++ )
	{
		player = players[ i ];
		
		if( isSubStr( toLower( player.name ), sl ) )
			array[ array.size ] = player;
	}
	
	if( array.size > 1  )
	{
		string = "";
		for( i = 0; i < array.size; i++ )
			string += array[ i ].name + "[" + array[ i ] getEntityNumber() + "], ";
		
		printClient( self, "Players found: " + string );
	}
	
	else if( array.size < 1 )
		printClient( self, "No players found matching " + s );
		
	else
		return array[ 0 ];
	
	return undefined;
}

printClient( ent, str )
{
	exec( "tell " + ent getEntityNumber() + " " + str );
}