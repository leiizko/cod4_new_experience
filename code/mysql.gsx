init()
{
	if( isDefined( game[ "mysql" ] ) )
		return;
	
	level.rankxptomysql = [];
		
	game[ "minKillCount" ] = 200;
	
	game[ "mysql" ] = "{ \"host\":\"" + level.dvar[ "mysql_host" ] + "\", \"user\":\"" + level.dvar[ "mysql_user" ] + "\", \"password\":\"" + level.dvar[ "mysql_pw" ] + "\", \"database\":\"" + level.dvar[ "mysql_db" ] + "\", \"query\":\"";
	game[ "mysql_vip" ] = "{ \"host\":\"" + level.dvar[ "mysql_host" ] + "\", \"user\":\"" + level.dvar[ "mysql_user" ] + "\", \"password\":\"" + level.dvar[ "mysql_pw" ] + "\", \"database\":\"ips\", \"query\":\"";
	game[ "mysql_sb" ] = "{ \"host\":\"" + level.dvar[ "mysql_host" ] + "\", \"user\":\"" + level.dvar[ "mysql_user" ] + "\", \"password\":\"" + level.dvar[ "mysql_pw" ] + "\", \"database\":\"sourcebans\", \"query\":\"";
	
	if( !getDvarInt( "player_db" ) )
	{
		query = "CREATE TABLE IF NOT EXISTS `" + level.dvar[ "mysql_player_table" ] + "` ( `id` BIGINT( 32 ) UNSIGNED NOT NULL PRIMARY KEY, `fps` TINYINT( 1 ) NOT NULL DEFAULT '" + level.dvar[ "default_fps" ] + "', `fov` FLOAT( 4, 3 ) NOT NULL DEFAULT '" + level.dvar[ "default_fov" ] + "', `promod` TINYINT( 1 ) NOT NULL DEFAULT '" + level.dvar[ "default_promod" ] + "', `shop` TINYINT( 1 ) NOT NULL DEFAULT '" + level.dvar[ "shopbuttons_default" ] + "', `spec` TINYINT( 1 ) NOT NULL DEFAULT '"	+ level.dvar[ "spec_keys_default" ] + "', `unlocked` TINYINT( 1 ) NOT NULL DEFAULT '0', `emblem` VARCHAR( 80 ) NOT NULL DEFAULT '" + level.dvar[ "kct_default" ] + "', `language` VARCHAR( 80 ) NOT NULL DEFAULT '' );";
	
		json = game[ "mysql" ] + query + "\"}";

		httpPostJson( level.dvar[ "web" ], json, ::release );
		
		setDvar( "player_db", 1 );
	}

	if( !getDvarInt( "mapstats_db" ) && getDvarInt( "legacy_ending" ) )
	{
		query = "CREATE TABLE IF NOT EXISTS `" + level.dvar[ "mysql_mapstats_table" ] + "` ( `id` VARCHAR( 32 ) NOT NULL PRIMARY KEY, `kills` VARCHAR( 64 ), `deaths` VARCHAR( 64 ), `meleekills` VARCHAR( 64 ), `headshots` VARCHAR( 64 ), `explosivekills` VARCHAR( 64 ) );";
	
		json = game[ "mysql" ] + query + "\"}";

		httpPostJson( level.dvar[ "web" ], json, ::release );
		
		setDvar( "mapstats_db", 1 );
	}
	
	if( level.dvar[ "trueskill" ] && !getDvarInt( "trueskill_db" ) )
		thread initTS();
		
	if( level.dvar[ "hardpoint_menu" ] && !getDvarInt( "hp_db" ) )
	{
		query = "CREATE TABLE IF NOT EXISTS `" + level.dvar[ "mysql_hardpoint_table" ] + "` ( `id` BIGINT( 32 ) UNSIGNED NOT NULL PRIMARY KEY, `streak1` VARCHAR( 64 ) DEFAULT '', `streak2` VARCHAR( 64 ) DEFAULT '', `streak3` VARCHAR( 64 ) DEFAULT '' );";
	
		json = game[ "mysql" ] + query + "\"}";

		httpPostJson( level.dvar[ "web" ], json, ::release );
		
		setDvar( "hp_db", 1 );
	}
	
	if( !getDvarInt( "rank_db" ) )
	{
		query = "CREATE TABLE IF NOT EXISTS `" + level.dvar[ "mysql_rank_table" ] + "` ( `id` BIGINT( 32 ) UNSIGNED NOT NULL PRIMARY KEY, `xp` BIGINT( 64 ) UNSIGNED NOT NULL DEFAULT '0' );";
	
		json = game[ "mysql" ] + query + "\"}";

		httpPostJson( level.dvar[ "web" ], json, ::release );
		
		setDvar( "rank_db", 1 );
	}
		
	query = "SELECT COUNT(*) AS count FROM `" + level.dvar[ "mysql_trueskill_table" ] + "` WHERE `kills` > " + game[ "minKillCount" ];
	json = game[ "mysql" ] + query + "\"}";	
	httpPostJson( level.dvar[ "web" ], json, ::playerCount );
	
	time = int( TimeToString ( GetRealTime(), 0, "%j"  ) );
	dvar = "deletionDate" + time;
	if( time % 7 == 0 && getDvar( dvar ) == "" )
	{
		query = "DELETE FROM `" + level.dvar[ "mysql_trueskill_table" ] + "` WHERE UNIX_TIMESTAMP( `time` ) < UNIX_TIMESTAMP( DATE_SUB( NOW(), INTERVAL 90 DAY ) )";
		json = game[ "mysql" ] + query + "\"}";
		httpPostJson( level.dvar[ "web" ], json, ::release );
		
		query = "UPDATE `" + level.dvar[ "mysql_trueskill_table" ] + "` SET `kda` = 0, `skill` = 0 WHERE UNIX_TIMESTAMP( `time` ) < UNIX_TIMESTAMP( DATE_SUB( NOW(), INTERVAL 7 DAY ) )";
		json = game[ "mysql" ] + query + "\"}";
		httpPostJson( level.dvar[ "web" ], json, ::release );
		
		setDvar( dvar, "true" );
	}
}

initTS()
{
	query = "CREATE TABLE IF NOT EXISTS `" + level.dvar[ "mysql_trueskill_table" ] + "` ( `id` BIGINT( 32 ) UNSIGNED NOT NULL PRIMARY KEY, `name` VARCHAR( 32 ) NOT NULL, `mean` DOUBLE NOT NULL DEFAULT '100', `variance` DOUBLE NOT NULL DEFAULT '33.33333333', `skill` DOUBLE NOT NULL DEFAULT '0' , `kills` MEDIUMINT UNSIGNED NOT NULL DEFAULT '0' , `deaths` MEDIUMINT UNSIGNED NOT NULL DEFAULT '0' , `assists` MEDIUMINT UNSIGNED NOT NULL DEFAULT '0', `kda` DOUBLE NOT NULL DEFAULT '0', `time` TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP );";
	
	json = game[ "mysql" ] + query + "\"}";

	httpPostJson( level.dvar[ "web" ], json, ::release );
	
	setDvar( "trueskill_db", 1 );
}

sendData( table, data )
{
	query = "INSERT INTO `" + table + "` ( ";
	midquery = " ) VALUES ( ";
	if( data.size > 1 )
		endquery = " ) ON DUPLICATE KEY UPDATE ";
	else
		endquery = " )";
	
	for( i = 0; i < data.size; i++ )
	{
		temp = strTok( data[ i ], "=" );
		
		query += temp[ 0 ];
		midquery += temp[ 1 ];
		if( i > 0 )
			endquery += data[ i ];
		
		if( i + 1 != data.size )
		{
			query += ", ";
			midquery += ", ";
			
			if( i > 0 )
				endquery += ", ";
		}
	}
	
	query += midquery + endquery + ";";
	
	json = game[ "mysql" ] + query + "\"}";
	
	httpPostJson( level.dvar[ "web" ], json, ::release );
}

DBLookup()
{
	self endon( "disconnect" );
	
	while( self getGuid().size < 2 )
		wait .05;

	query = "SELECT * FROM `" + level.dvar[ "mysql_player_table" ] + "` WHERE `id` = " + self getGuid() + " LIMIT 1";
	
	json = game[ "mysql" ] + query + "\"}";

	httpPostJson( level.dvar[ "web" ], json, ::player, self );
	
	if( level.dvar[ "trueskill" ] )
	{
		query = "SELECT * FROM `" + level.dvar[ "mysql_trueskill_table" ] + "` WHERE `id` = " + self getGuid() + " LIMIT 1";

		json = game[ "mysql" ] + query + "\"}";

		httpPostJson( level.dvar[ "web" ], json, ::playerTS, self );
	}
	else
	{
		self.pers[ "mu" ] = 25;
		self.pers[ "sigma" ] = 8.3;
	}

	if( self getSteamID() != "0" )
	{
		query = "SELECT `member_group_id`, `mgroup_others` FROM `core_members` WHERE `steamid` = " + self getSteamID() + " LIMIT 1;";

		json = game[ "mysql_vip" ] + query + "\"}";
		
		httpPostJson( level.dvar[ "web" ], json, ::vip, self );
	}
}

banLookup( id )
{
	concat = "CONCAT('STEAM_', ((CAST('" + id + "' AS UNSIGNED) >> CAST('56' AS UNSIGNED)) - CAST('1' AS UNSIGNED)), ':', (CAST('" + id + "' AS UNSIGNED) & CAST('1' AS UNSIGNED)), ':', (CAST('" + id + "' AS UNSIGNED) & CAST('4294967295' AS UNSIGNED)) >> CAST('1' AS UNSIGNED))";
	query = "SELECT `length`, '" + id + "' AS player_id FROM `sb_bans` WHERE `authid` = " + concat + " LIMIT 1";
	json = game[ "mysql_sb" ] + query + "\"}";
	
	httpPostJson( level.dvar[ "web" ], json, ::banLookupAsync );
}

banLookupAsync( handle )
{
	if( !handle )
		return;
		
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		jsonReleaseObject( handle );
		return;
	}
	
	if( jsonGetString( handle, "0.length" ) == "0" )
	{
		id = jsonGetString( handle, "0.player_id" );
		
		query = "DELETE FROM `" + level.dvar[ "mysql_trueskill_table" ] + "` WHERE `id` = " + id;
	
		json = game[ "mysql" ] + query + "\"}";
		
		httpPostJson( level.dvar[ "web" ], json, ::release );
	}		
		
	jsonReleaseObject( handle );
}

saveRank()
{
	q[ 0 ] = "id=" + self getGuid();
	q[ 1 ] = "mean=" + self.pers[ "mu" ];
	q[ 2 ] = "variance=" + self.pers[ "sigma" ];
	q[ 3 ] = "skill=" + ( self.pers[ "mu" ] - ( 3 * self.pers[ "sigma" ] ) );
	q[ 4 ] = "kills=" + self.kda_data.kills;
	q[ 5 ] = "deaths=" + self.kda_data.deaths;
	q[ 6 ] = "assists=" + self.kda_data.assists;
	
	kda = "0";
	if( self.kda_data.deaths )
		kda = "" + ( ( self.kda_data.kills + self.kda_data.assists ) / self.kda_data.deaths );
		
	if( kda.size > 6 )
		kda = getSubStr( kda, 0, 6 );
		
	q[ 7 ] = "kda=" + kda;
	
	thread sendData( level.dvar[ "mysql_trueskill_table" ], q );
}

saveKDA( guid, kda_data )
{
	if( !isDefined( kda_data ) )
		return;
		
	kills = kda_data.kills;
	deaths = kda_data.deaths;
	assists = kda_data.assists;

	q[ 0 ] = "id=" + guid;
	q[ 1 ] = "kills=" + kills;
	q[ 2 ] = "deaths=" + deaths;
	q[ 3 ] = "assists=" + assists;
	
	kda = "0";
	if( deaths )
		kda = "" + ( ( kills + assists ) / deaths );
		
	if( kda.size > 6 )
		kda = getSubStr( kda, 0, 6 );
		
	q[ 4 ] = "kda=" + kda;
	
	thread sendData( level.dvar[ "mysql_trueskill_table" ], q );
}

topPlayers()
{
	wait .05;
	
	order = "skill";
	if( level.teamBased )
		order = "kda";
	
	query = "SELECT * FROM `" + level.dvar[ "mysql_trueskill_table" ] + "` ORDER BY `" + order + "` DESC LIMIT 3";
	
	json = game[ "mysql" ] + query + "\"}";

	httpPostJson( level.dvar[ "web" ], json, ::topPlayersH );
}

#if isSyscallDefined TS_Rate
punishTS( guid, time )
{
	if( !isDefined( time ) || getTime() - time < 120000 || level.players.size < 2 )
		return;
		
	while( isDefined( level.TSPenality ) )
		wait .05;
		
	level.TSPenality = true;

	query = "SELECT * FROM `" + level.dvar[ "mysql_trueskill_table" ] + "` WHERE `id` = " + guid + " LIMIT 1";
		
	json = game[ "mysql" ] + query + "\"}";

	httpPostJson( level.dvar[ "web" ], json, ::punishPlayer );
}

punishPlayer( handle )
{
	if( !handle )
	{
		level.TSPenality = undefined;
		return;
	}
		
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		jsonReleaseObject( handle );
		level.TSPenality = undefined;

		return;
	}

	mu = float( jsonGetString( handle, "0.mean" ) );
	sigma = float( jsonGetString( handle, "0.variance" ) );
	guid = jsonGetString( handle, "0.id" );
		
	TS_AddPlayer( 0, mu, sigma, 1, 1 );
	TS_AddPlayer( 1, mu, sigma, 2, 1 );
	p = TS_Rate( 2, "1 0" );
	
	level.TSPenality = undefined;
		
	q[ 0 ] = "id=" + guid;
	q[ 1 ] = "mean=" + p[ 0 ][ 0 ];
	q[ 2 ] = "variance=" + p[ 0 ][ 1 ];
	q[ 3 ] = "skill=" + ( p[ 0 ][ 0 ] - ( 3 * p[ 0 ][ 1 ] ) );
		
	sendData( level.dvar[ "mysql_trueskill_table" ], q );

	jsonReleaseObject( handle );
}
#else
punishTS( guid, time ) {}
#endif

playerTS( handle )
{
	if( !handle )
	{
		self.pers[ "mu" ] = 100;
		self.pers[ "sigma" ] = 100 / 3;
		self.kda_data = spawnStruct();
		self.kda_data.kills = 0;
		self.kda_data.deaths = 0;
		self.kda_data.assists = 0;
		return;
	}
	
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		self.pers[ "mu" ] = 100;
		self.pers[ "sigma" ] = 100 / 3;
		self.kda_data = spawnStruct();
		self.kda_data.kills = 0;
		self.kda_data.deaths = 0;
		self.kda_data.assists = 0;

		if( jsonGetString( handle, "status" ) == "no_results" )
		{
			self thread updatePlayerTS();
		}

		jsonReleaseObject( handle );

		return;
	}

	self.pers[ "mu" ] = float( jsonGetString( handle, "0.mean" ) );
	self.pers[ "sigma" ] = float( jsonGetString( handle, "0.variance" ) );
	
	self.kda_data = spawnStruct();
	self.kda_data.kills = int( jsonGetString( handle, "0.kills" ) );
	self.kda_data.deaths = int( jsonGetString( handle, "0.deaths" ) );
	self.kda_data.assists = int( jsonGetString( handle, "0.assists" ) );

	jsonReleaseObject( handle );
}

getRankXP()
{
	self endon( "disconnect" );
	
	guid = self getGuid();
	query = "SELECT * FROM `" + level.dvar[ "mysql_rank_table" ] + "` WHERE `id` = " + guid + " LIMIT 1";
	json = game[ "mysql" ] + query + "\"}";	
	httpPostJson( level.dvar[ "web" ], json, ::getRankXP_cb, self );
}

getRankXP_cb( handle )
{
	if( !handle )
	{
		self.pers["rankxp"] = 0;
		self notify( "getRankXP_cb" );
		return;
	}
	
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		jsonReleaseObject( handle );
		self.pers["rankxp"] = 0;
		self notify( "getRankXP_cb" );
		return;
	}

	rankxp = int( jsonGetString( handle, "0.xp" ) );
	
	self.pers["rankxp"] = rankxp;
	self notify( "getRankXP_cb" );

	jsonReleaseObject( handle );
}

UpdateRankXP( xp )
{
	q[ 0 ] = "id=" + self getGuid();
	q[ 1 ] = "xp=" + xp;
	
	sendData( level.dvar[ "mysql_rank_table" ], q );
}

UpdateRankXP_DC( entnum )
{
	if( !isDefined( level.rankxptomysql[ entnum ] ) || !isDefined( level.rankxptomysql[ entnum ][ 1 ] ) ) // DC before rank was fetched, no game was played
		return;

	q[ 0 ] = "id=" + level.rankxptomysql[ entnum ][ 0 ];
	q[ 1 ] = "xp=" + level.rankxptomysql[ entnum ][ 1 ];
	
	sendData( level.dvar[ "mysql_rank_table" ], q );
}

updateHP()
{
	q[ 0 ] = "id=" + self getGuid();
	
	for( i = 0; i < 3; i++ )
	{
		if( isDefined( self.pers[ "selectedHP" ][ i ] ) )
			q[ q.size ] = "streak" + ( i + 1 ) + "='" + self.pers[ "selectedHP" ][ i ] + "'";
	}
	
	sendData( level.dvar[ "mysql_hardpoint_table" ], q );
}

DBLookupHP()
{
	guid = self getGuid();
	query = "SELECT * FROM `" + level.dvar[ "mysql_hardpoint_table" ] + "` WHERE `id` = " + guid + " LIMIT 1";
	json = game[ "mysql" ] + query + "\"}";	
	httpPostJson( level.dvar[ "web" ], json, ::DBLookupHP_cb, self );
}

DBLookupHP_cb( handle )
{
	if( !handle )
	{
		self.pers[ "selectedHP" ] = [];
		self.pers[ "selectedHP" ][ 0 ] = "radar_mp";
		self.pers[ "selectedHP" ][ 1 ] = "airstrike_mp";
		self.pers[ "selectedHP" ][ 2 ] = "helicopter_mp";
		
		return;
	}
	
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		if( jsonGetString( handle, "status" ) == "no_results" )
		{
			self.pers[ "selectedHP" ] = [];
			self.pers[ "selectedHP" ][ 0 ] = "radar_mp";
			self.pers[ "selectedHP" ][ 1 ] = "airstrike_mp";
			self.pers[ "selectedHP" ][ 2 ] = "helicopter_mp";
			
			self setClientDvars( "hardpoint_1", "radar_mp",
								 "hardpoint_2", "airstrike_mp",
								 "hardpoint_3", "helicopter_mp" );
								 
			self thread asignHPNums();
			
			self thread onSpawnOpenMenu();
		}
		jsonReleaseObject( handle );
		return;
	}

	self.pers[ "selectedHP" ] = [];
	self.pers[ "selectedHP" ][ 0 ] = jsonGetString( handle, "0.streak1" );
	self.pers[ "selectedHP" ][ 1 ] = jsonGetString( handle, "0.streak2" );
	self.pers[ "selectedHP" ][ 2 ] = jsonGetString( handle, "0.streak3" );
	
	self thread asignHPNums();
	
	self setClientDvars( "hardpoint_1", self.pers[ "selectedHP" ][ 0 ],
						 "hardpoint_2", self.pers[ "selectedHP" ][ 1 ],
						 "hardpoint_3", self.pers[ "selectedHP" ][ 2 ] );
						 
	for( i = 0; i < 3; i++ )
	{
		if( self.pers[ "selectedHP" ][ i ] == "" )
			self.pers[ "selectedHP" ][ i ] = undefined;
	}
	
	jsonReleaseObject( handle );
}

onSpawnOpenMenu()
{
	self waittill( "spawned_player" );
	
	wait .25;
	
	self closeMenu();
	self closeInGameMenu();
	self openMenu( "hardpoint" );
	
	wait .05;
	
	self setClientDvar( "hardpoint_lastError", lua_getLocString( self.pers[ "language" ], "HP_E_FIRST_TIME" ) );
}

asignHPNums()
{
	self.pers[ "selectedHP_s" ] = [];
	
	assert( self.pers[ "selectedHP" ].size == 3 );
	
	for( i = 0; i < 3; i++ )
	{	
		n = lua_getHardpointIndex( self.pers[ "selectedHP" ][ i ] );
		if( n >= 0 )
			self.pers[ "selectedHP_s" ][ i ] = level.hardpointStreakData[ n ][ 0 ];
		else
			self.pers[ "selectedHP_s" ][ i ] = 999999;
	}
	
	self setClientDvars( "ui_hp_taken_1", self.pers[ "selectedHP_s" ][ 0 ],
						 "ui_hp_taken_2", self.pers[ "selectedHP_s" ][ 1 ],
						 "ui_hp_taken_3", self.pers[ "selectedHP_s" ][ 2 ] );
}

getPos( string, player )
{
	self.globalPos = -1;
	
	self endon( "disconnect" );
	
	order = "skill";
	if( level.teamBased )
		order = "kda";
	
	query = "SELECT `rank` FROM ( SELECT @rownum := @rownum + 1 AS rank, `id` FROM `" + level.dvar[ "mysql_trueskill_table" ] + "`, (SELECT @rownum := 0) t" + " WHERE `kills` > " + game[ "minKillCount" ] + " ORDER BY `" + order + "` DESC ) AS R WHERE `id` = " + self getGuid();
	json = game[ "mysql" ] + query + "\"}";	
	httpPostJson( level.dvar[ "web" ], json, ::getPosAsync, self );
	
	self waittill( "getPosAsync", rank );
	
	self.globalPos = rank;
	
	if( rank > -1 )
	{
		string += " - Rank: " + rank + "/" + game[ "playerCount" ];
	}
	else
	{
		string += " - Rank: N/A";
	}

	thread code\scriptcommands::printClient( player, string );
}

getPosAsync( handle )
{
	if( !handle )
	{
		self notify( "getPosAsync", -1 );
		return;
	}
	
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		jsonReleaseObject( handle );
		self notify( "getPosAsync", -1 );
		return;
	}

	rank = int( jsonGetString( handle, "0.rank" ) );
	
	self notify( "getPosAsync", rank );

	jsonReleaseObject( handle );
}

updatePlayerTS()
{
	self endon( "disconnect" );
	
	while( self getGuid().size < 2 || self.name.size < 2 )
		wait .05;
	
	q[ 0 ] = "id=" + self getGuid();
			
	name = stripShit( code\scriptcommands::stripColor( self.name ) );
	if( name.size > 32 )
		name = getSubStr( name, 0, 32 );
				
	q[ 1 ] = "name='" + name + "'";

	thread sendData( level.dvar[ "mysql_trueskill_table" ], q );
}

player( handle )
{
	if( !handle )
	{
		self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
		self.pers[ "fov" ] = level.dvar[ "default_fov" ];
		self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
		self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
		self.pers[ "spec_keys" ] = level.dvar[ "spec_keys_default" ];
		self.pers[ "killcamText" ] = level.dvar[ "kct_default" ];
		
		self thread code\player::localization();
		
		return;
	}
	
	if( jsonGetString( handle, "status" ) != "okay" )
	{		
		self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
		self.pers[ "fov" ] = level.dvar[ "default_fov" ];
		self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
		self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
		self.pers[ "spec_keys" ] = level.dvar[ "spec_keys_default" ];
		self.pers[ "killcamText" ] = level.dvar[ "kct_default" ];
		
		self thread code\player::localization();

		if( jsonGetString( handle, "status" ) == "no_results" )
		{
			q[ 0 ] = "id=" + self getGuid();
			thread sendData( level.dvar[ "mysql_player_table" ], q );
			
			self thread unlockAll();
		}

		jsonReleaseObject( handle );

		return;
	}
	
	if( !level.dvar["cmd_fps"] )
		self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
	else
		self.pers[ "fullbright" ] = int( jsonGetString( handle, "0.fps" ) );
	
	if( !level.dvar["cmd_fov"] )
		self.pers[ "fov" ] = level.dvar[ "default_fov" ];
	else
		self.pers[ "fov" ] = float( jsonGetString( handle, "0.fov" ) );
	
	if( !level.dvar["cmd_promod"] )
		self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
	else
		self.pers[ "promodTweaks" ] = int( jsonGetString( handle, "0.promod" ) );
	
	if( !level.dvar[ "shopbuttons_allowchange" ] )
		self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
	else
		self.pers[ "hardpointSType" ] = int( jsonGetString( handle, "0.shop" ) );
	
	if( !level.dvar[ "cmd_spec_keys" ] )
		self.pers[ "spec_keys" ] = level.dvar[ "spec_keys_default" ];
	else
		self.pers[ "spec_keys" ] = int( jsonGetString( handle, "0.spec" ) );
		
	if( !level.dvar[ "kcemblem" ] )
		self.pers[ "killcamText" ] = level.dvar[ "kct_default" ];
	else
		self.pers[ "killcamText" ] = jsonGetString( handle, "0.emblem" );
		
	unlocked = int( jsonGetString( handle, "0.unlocked" ) );
	
	lang = jsonGetString( handle, "0.language" );
	
	self thread code\player::localization( lang );
	
	if( !unlocked )
		self thread unlockAll();

	jsonReleaseObject( handle );
}

vip( handle )
{
	if( !handle )
		return;
	
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		jsonReleaseObject( handle );
		return;
	}

	group = jsonGetString( handle, "0.member_group_id" );

	if( isSubStr( group, "9" ) )
	{
		self.pers[ "vip" ] = true;
	}
	else
	{
		group = jsonGetString( handle, "0.mgroup_others" );
		if( isSubStr( group, "9" ) )
			self.pers[ "vip" ] = true;
	}

	jsonReleaseObject( handle );
}

topPlayersH( handle )
{
	if( !handle )
		return;
	
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		jsonReleaseObject( handle );
		return;
	}

	size = int( jsonGetString( handle, "num" ) );

	for( i = 0; i < size; i++ )
	{
		s = "" + i + ".id";
		level.TSTopPlayers[ i ][ 0 ] = jsonGetString( handle, s );
	}

	jsonReleaseObject( handle );
}

playerCount( handle )
{
	if( !handle )
	{
		game[ "playerCount" ] = 0;
		return;
	}
	
	if( jsonGetString( handle, "status" ) != "okay" )
	{
		jsonReleaseObject( handle );
		game[ "playerCount" ] = 0;
		return;
	}

	game[ "playerCount" ] = int( jsonGetString( handle, "0.count" ) );

	jsonReleaseObject( handle );
}

release( handle )
{
	if( !handle )
		return;
		
	jsonReleaseObject( handle );
}

stripShit( s )
{
	return code\scriptcommands::stripShit( s );
}

unlockAll()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill( "spawned_player" );
	
	wait 5;
	
	self code\rank::AttachCamoUnlock();
	
	wait .25;
	
	q[ 0 ] = "id=" + self getGuid();
	q[ 1 ] = "unlocked=1";
	thread sendData( level.dvar[ "mysql_player_table" ], q );
}