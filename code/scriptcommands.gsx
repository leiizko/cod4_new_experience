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
	addscriptcommand( "pbss", 1 );
	addscriptcommand( "vip", 1 );
	addscriptcommand( "help", 1 );
	addscriptcommand( "report", 1 );
	addscriptcommand( "language", 1 );
	
	addscriptcommand( "dev", 1 );
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
		self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_UNAVAILABLE" ) );
		return;
	}
	
	switch( toLower( cmd ) )
	{
		case "dev":			
			self thread code\dev::__devCmd( arg );	
			break;
			
		case "language":
			if( arg == "" )
			{
				self iPrintLnBold( "Usage: $language <wanted language>" );
				self thread listLanguages();
				break;
			}
			
			arg = toLower( arg );
			
			if( !lua_languageExists( arg ) )
			{
				self thread listLanguages();
				break;
			}
			
			self thread code\player::localization( arg );
			
			q[ 0 ] = "id=" + self getGuid();
			q[ 1 ] = "language='" + arg + "'";
			
#if isSyscallDefined httpPostJson
			self thread code\mysql::sendData( level.dvar[ "mysql_player_table" ], q );
#endif
			
			break;
			
		case "fps":
			if( !level.dvar[ "cmd_fps" ] )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_DISABLED" ) );
				break;
			}
			killTweaks = undefined;
			stat = 0;

			if( self.pers[ "fullbright" ] == 0 )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_FPS_NOTIFY" ), "^2ON" );
				stat = 1;
				self.pers[ "fullbright" ] = 1;
					
				if( self.pers[ "promodTweaks" ] == 1 )
				{
					self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_PROMOD_NOTIFY" ), "^1OFF" );
					killTweaks = true;
					self.pers[ "promodTweaks" ] = 0;
				}
			}
			else
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_FPS_NOTIFY" ), "^1OFF" );
				stat = 0;
				self.pers[ "fullbright" ] = 0;
			}

			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "fps=" + self.pers[ "fullbright" ];
				if( isDefined( killTweaks ) )
					q[ 2 ] = "promod=" + self.pers[ "promodTweaks" ];
				
#if isSyscallDefined httpPostJson
				self thread code\mysql::sendData( level.dvar[ "mysql_player_table" ], q );
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
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_DISABLED" ) );
				break;
			}
			
			if( !isDefined( arg ) || arg == "" )
			{
				self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CMD_FOV_USAGE" ) );
				break;
			}
			
			arg_c = arg;
			if( arg_c.size > 5 )
				arg_c = arg[ 0 ] + arg[ 1 ] + arg[ 2 ] + arg[ 3 ] + arg[ 4 ];
			else if( arg_c.size < 5 )
			{
				while( arg_c.size != 5 )
				{
					if( arg_c.size == 1 )
						arg_c += ".";
					else
						arg_c += "0";
				}
			}
			
			arg_f = float( arg_c );
			if( arg_f < 0.75 || arg_f > 1.50 )
			{
				self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CMD_FOV_FLOAT" ) );
				break;
			}
			
			self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_FOV_NOTIFY" ), arg_f );
			self.pers[ "fov" ] = arg_f;
			
			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "fov=" + self.pers[ "fov" ];
				
#if isSyscallDefined httpPostJson
				self thread code\mysql::sendData( level.dvar[ "mysql_player_table" ], q );
#endif
			}

			else if( !level.dvar[ "fs_players" ] )
			{
				stat = "1" + arg_c[ 0 ] + arg_c[ 2 ] + arg_c[ 3 ] + arg_c[ 4 ];
				self setstat( 3161, int( stat ) );
			}
			else
				level.FSCD[ self getGuid() ][ 1 ] = "fov;" + self.pers[ "fov" ];

			self thread code\player::userSettings();
			break;
			
		case "promod":
			if( !level.dvar[ "cmd_promod" ] )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_DISABLED" ) );
				break;
			}
			stat = 0;
			killFPS = undefined;

			if( self.pers[ "promodTweaks" ] == 0 )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_PROMOD_NOTIFY" ), "^2ON" );
				stat = 1;
				self.pers[ "promodTweaks" ] = 1;
					
				if( self.pers[ "fullbright" ] == 1 )
				{
					self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_FPS_NOTIFY" ), "^1OFF" );
					killFPS = true;
					self.pers[ "fullbright" ] = 0;
				}
			}
			else
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_PROMOD_NOTIFY" ), "^1OFF" );
				stat = 0;
				self.pers[ "promodTweaks" ] = 0;
			}
			
			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "promod=" + self.pers[ "promodTweaks" ];
				if( isDefined( killFPS ) )
					q[ 2 ] = "fps=" + self.pers[ "fullbright" ];
				
#if isSyscallDefined httpPostJson
				self thread code\mysql::sendData( level.dvar[ "mysql_player_table" ], q );
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
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_DISABLED" ) );
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
				
#if isSyscallDefined httpPostJson
				self thread code\mysql::sendData( level.dvar[ "mysql_player_table" ], q );
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
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_DISABLED" ) );
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
				
				kda = "0";
				if( self.kda_data.deaths )
					kda = "" + ( self.kda_data.kills + self.kda_data.assists ) / self.kda_data.deaths;
					
				kda = getSubStr( kda, 0, 5 );
				kda_s = " - K/D/A: " + self.kda_data.kills + "/" + self.kda_data.deaths + "/" + self.kda_data.assists + " ( " + kda + " )";
				
				string = "Trueskill rating: " + int( rank ) + kda_s;
				
#if isSyscallDefined httpPostJson
				if( game[ "playerCount" ] > 2 && game[ "minKillCount" ] < self.kda_data.kills )
				{
					if( isDefined( self.globalPos ) && self.globalPos > -1 )
					{
						if( self.globalPos > -1 )
							string += " - Rank: " + self.globalPos + "/" + game[ "playerCount" ];
						else
							string += " - Rank: Unranked"; 
					}
					else
					{
						self thread code\mysql::getPos( string, self );
						break;
					}
				}
				else
					string += " - Rank: Unranked"; 
#endif
				
				printClient( self, string );
			}
			else
			{
				if( isInt( arg ) && arg.size <= 2 )
				{
					player = getEntByNum( int( arg ) );
					if( !isDefined( player ) || !isPlayer( player ) )
					{
						printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_NO_MATCH" ),  "#" + arg );
						break;
					}
				}
				else
				{
					player = self getEntByStr( arg );
					if( !isDefined( player ) || !isPlayer( player ) )
					{
						//printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_NO_MATCH" ), arg );
						break;
					}
				}
				
				if( !isDefined( player.pers[ "sigma" ] ) )
				{
					self iPrintlnBold( "Please try again in a moment!" );
					break;
				}
				rank = player.pers[ "mu" ] - ( 3 * player.pers[ "sigma" ] );
				
				kda = "0";
				if( player.kda_data.deaths )
					kda = "" + ( player.kda_data.kills + player.kda_data.assists ) / player.kda_data.deaths;
				
				kda = getSubStr( kda, 0, 5 );
				kda_s = " - K/D/A: " + player.kda_data.kills + "/" + player.kda_data.deaths + "/" + player.kda_data.assists + " ( " + kda + " )";
				
				string = "Trueskill rating: " + int( rank ) + kda_s;
				
#if isSyscallDefined httpPostJson
				if( game[ "playerCount" ] > 2 && game[ "minKillCount" ] < player.kda_data.kills )
				{
					if( isDefined( player.globalPos ) )
					{
						if( player.globalPos > -1 )
							string += " - Rank: " + player.globalPos + "/" + game[ "playerCount" ];
						else
							string += " - Rank: Unranked"; 
					}
					else
					{
						player thread code\mysql::getPos( string, self );
						break;
					}
				}
				else
					string += " - Rank: Unranked"; 
#endif
				
				printClient( self, string );
			}
			break;
		
		case "emblem":
			if( !level.dvar[ "fs_players" ] && !level.dvar[ "mysql" ] )
			{
				self iPrintlnBold( "This command is unavailable on this server." );
				return;
			}
			
			if( !level.dvar[ "kcemblem" ] )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_DISABLED" ) );
				break;
			}
			
			if( !isDefined( arg ) || arg == "" )
			{
				printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_EMBLEM_CURRENT" ), self.pers[ "killcamText" ] );
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_EMBLEM_USAGE" ) );
				return;
			}
			
			if( isSubStr( arg, ";" ) )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_EMBLEM_ILLEGAL_CHAR" ) );
				return;
			}
			
			if( arg.size > 80 )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_EMBLEM_SIZE_EXCEDED" ) );
				return;
			}
			
			self.pers[ "killcamText" ] = arg;
			
			if( level.dvar[ "mysql" ] )
			{
				q[ 0 ] = "id=" + self getGuid();
				q[ 1 ] = "emblem='" + self.pers[ "killcamText" ] + "'";
				
#if isSyscallDefined httpPostJson
				self thread code\mysql::sendData( level.dvar[ "mysql_player_table" ], q );
#endif
			}

			else
				level.FSCD[ self getGuid() ][ 5 ] = "killcamText;" + self.pers[ "killcamText" ];
			break;
			
		case "speckeys":
			if( !level.dvar[ "cmd_spec_keys" ] )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_DISABLED" ) );
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
				
#if isSyscallDefined httpPostJson
				self thread code\mysql::sendData( level.dvar[ "mysql_player_table" ], q );
#endif
			}

			else if( !level.dvar[ "fs_players" ] )
				self setstat( 3164, stat );
			else
				level.FSCD[ self getGuid() ][ 4 ] = "spec_keys;" + self.pers[ "spec_keys" ];
			
			break;
			
		case "pbss":
			if( level.gameEnded )
			{
				printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_SS_ENDGAME" ) );
				break;
			}

			if( !isDefined( arg ) || arg == "" )
			{
				printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_SS_USAGE" ) );
			}
			else
			{
				if( isInt( arg ) && arg.size <= 2 )
				{
					player = getEntByNum( int( arg ) );
				}
				else
				{
					player = self getEntByStr( arg );
				}
				
				if( !isDefined( player ) || !isPlayer( player ) )
				{
					printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_NO_MATCH" ), "#" + arg );
					break;
				}
				else if( player == self )
				{
					printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_SS_CANT_SELF" ) );
					break;
				}
				
				if( !isArray( player.pers[ "screens" ] ) )
				{
					player.pers[ "screens" ] = [];
				}
				
				if( player.pers[ "screens" ].size > 2 )
				{
					printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_SS_TOO_MANY_TIMES" ), player.name );
					break;
				}
				
				result = execex( "getss " + player getEntityNumber() );
				
				if( !isSubStr( result, "Still" ) && !isSubStr( result, "Already" ) && !isSubStr( result, "Error" ) )
				{
					player.pers[ "screens" ][ player.pers[ "screens" ].size ] = true;
				}
				
				printClient( self, result );
			}
			break;
			
		case "report":	
			if( !isDefined( arg ) || arg == "" )
			{
				printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_REPORT_USAGE" ) );
				printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_REPORT_EXAMPLE" ) );
			}
			else
			{	
				tokens = strTok( arg, " " );
				if( tokens.size < 2 )
				{
					printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_REPORT_MISSING_PARAM" ) );
					break;
				}
				
				if( isInt( tokens[ 0 ] ) && tokens[ 0 ].size <= 2 )
				{
					player = getEntByNum( int( tokens[ 0 ] ) );
				}
				else
				{
					player = self getEntByStr( tokens[ 0 ] );
				}
				
				if( !isDefined( player ) || !isPlayer( player ) )
				{
					printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_NO_MATCH" ), "#" + tokens[ 0 ] );
					break;
				}
				else if( player == self )
				{
					printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_REPORT_CANT_SELF" ) );
					break;
				}
				else if( isDefined( player.alreadyReported ) )
				{
					printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_REPORT_ALREADY" ) );
					break;
				}
				
				fullreason = tokens[ 1 ];
				for( i = 2; i < tokens.size; i++ )
				{
					fullreason += " " + tokens[ i ];
				}
				
				servername = stripShit( stripColor( getDvar( "sv_hostname" ) ) );
				suspect = stripShit( stripColor( player.name ) );
				suspect += " \\n" + player getGuid();
				acuser = stripShit( stripColor( self.name ) );
				acuser += " \\n" + self getGuid();
				
				data = "{ \"embeds\": [ {\"color\": 15466496, \"author\": { \"name\": \"CALLADMIN\", \"url\": \"https:\/\/iceops.co\", \"icon_url\": \"https:\/\/cdn.discordapp.com/embed/avatars/0.png\" }, \"fields\": [ ";
				data = embed( data, "Suspect", suspect, "true" );
				data += ", ";
				data = embed( data, "Acuser", acuser, "true" );
				data += ", ";
				data = embed( data, "Reason", fullreason, "false" );
				data += ", ";
				data = embed( data, "Server", servername, "true" );
				data += ", ";
				ip = getDvar( "net_ip" ) + ":" + getDvar( "net_port" );
				ips = "[" + ip + "](cod4://" + ip + ")";
				data = embed( data, "IP", ips, "true" );
				
				data += " ] } ] }";

#if isSyscallDefined httpPostJson
				httpPostJson( "https://iceops.co/cod4httpapi/discord.php", data, ::reportCallback );
#endif		
				
				printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_REPORT_DONE" ) );
				player.alreadyReported = true;
			}
			break;
			
		case "help":
			if( toLower( arg ) == "pbss" )
			{
				self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_FULL_CONSOLE" ) );
				self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_SS_SYNTAX" ), "\n\n\n^5" );
				self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_SS_L1" ) );
				self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_SS_L2" ) );
				break;
			}
			
			self iPrintlnBold( lua_getLocString( self.pers[ "language" ], "CMD_FULL_CONSOLE" ) );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_HEADER" ), "\n\n\n^5" );
			
			self iPrintLn( "&&1 Sets the language of translated texts",							 "^5$language    ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_FOV" ),			 "^5$fov         ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_FPS" ),			 "^5$fps         ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_PROMOD" ),		 "^5$promod      ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_STATS" ),		 "^5$stats       ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_EMBLEM" ),		 "^5$emblem      ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_SS" ),			 "^5$pbss        ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_REPORT" ),		 "^5$report      ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_MINISTATUS" ),	 "^5$ministatus  ^7-->" );
			self iPrintLn( lua_getLocString( self.pers[ "language" ], "CMD_HELP_VIP" ),			 "^5$vip         ^7-->", "\n\n\n" );
			break;
			
		case "vip":
			if( isDefined( self.pers[ "vip" ] ) )
			{
				self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CMD_VIP_1" ) );
			}
			else
			{
				self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CMD_VIP_2" ), "http:\/\/iceops.co" );
				self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CMD_VIP_3" ), "http:\/\/iceops.co" );
			}
			break;	
			
		default:
			break;
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

stripColor( string )
{
	clean = "";
	
	for( i = 0; i < string.size; i++ )
	{
		if( string[ i ] == "^" )
		{
			i++;
			continue;
		}
			
		clean += string[ i ];
	}
	
	return clean;
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
		
		printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_MATCH_FOUND" ), string );
	}
	
	else if( array.size < 1 )
		printClient( self, lua_getLocString( self.pers[ "language" ], "CMD_NO_MATCH" ), s );
		
	else
		return array[ 0 ];
	
	return undefined;
}

printClient( ent, str, arg1, arg2 )
{
	if( isDefined( arg2 ) )
		str_f = strReplace( str, arg1, arg2 );
	else if( isDefined( arg1 ) )
		str_f = strReplace( str, arg1 );
	else
		str_f = str;
		
	exec( "tell " + ent getEntityNumber() + " " + str_f );
}

stripShit( s )
{
	clean = strCtrlStrip( s );
	
	if( clean.size == 0 )
		return "NoName";
	else
		return clean;
}

stripShit_old( s )
{
	clean = "";
	
	for( i = 0; i < s.size; i++ )
	{
		switch( s[ i ] )
		{
			case "'":
			case "\"":
			case "\b":
			case "\f":
			case "\n":
			case "\r":
			case "\t":
			case "\\":
			case "/":
				break;

			default:
				clean += s[ i ];
				break;
				
		}		
	}
	
	if( s.size == 0 )
		clean = "NoName";
		
	return clean;
}

embed( string, name, value, inline )
{
	s1 = "\"name\":\"" + name + "\", ";
	s2 = "\"value\":\"" + value + "\", ";
	s3 = "\"inline\":" + inline;
	string += "{ " + s1 + s2 +s3 + " }";
	return string;
}

listLanguages()
{
	langs = lua_listLanguages();
	
	s = "";
	
	for( i = 0; i < langs.size; i++ )
		s += langs[ i ] + " ";
		
	self iPrintLnBold( "Supported languages:" );
	self iPrintLnBold( s );
}

#if isSyscallDefined httpPostJson
reportCallback( handle )
{
	jsonReleaseObject( handle );
}
#endif
