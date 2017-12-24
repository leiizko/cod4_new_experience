init()
{
	if( isDefined( game[ "mysql" ] ) )
		return;
		
	game[ "mysql" ] = mysql_real_connect( level.dvar[ "mysql_host" ], level.dvar[ "mysql_user" ], level.dvar[ "mysql_pw" ], level.dvar[ "mysql_db" ], level.dvar[ "mysql_port" ] );
	
	query = "CREATE TABLE IF NOT EXISTS `players` ( `id` BIGINT( 32 ) UNSIGNED NOT NULL PRIMARY KEY, `fps` TINYINT( 1 ) NOT NULL DEFAULT '" + level.dvar[ "default_fps" ] + "', `fov` TINYINT( 1 ) NOT NULL DEFAULT '" + level.dvar[ "default_fov" ] + "', `promod` TINYINT( 1 ) NOT NULL DEFAULT '" + level.dvar[ "default_promod" ] + "', `shop` TINYINT( 1 ) NOT NULL DEFAULT '" + level.dvar[ "shopbuttons_default" ] + "', `spec` TINYINT( 1 ) NOT NULL DEFAULT '"	+ level.dvar[ "spec_keys_default" ] + "', `emblem` VARCHAR( 80 ) NOT NULL DEFAULT '" + level.dvar[ "kct_default" ] + "', `vip` TINYINT( 1 ) NOT NULL DEFAULT '0', `vipexp` DATETIME NOT NULL DEFAULT 0 );";
	
	mysql_query( game[ "mysql" ], query );
	
	query = "CREATE TABLE IF NOT EXISTS `" + level.dvar[ "mysql_mapstats_table" ] + "` ( `id` VARCHAR( 32 ) NOT NULL PRIMARY KEY, `kills` VARCHAR( 64 ), `deaths` VARCHAR( 64 ), `meleekills` VARCHAR( 64 ), `headshots` VARCHAR( 64 ), `explosivekills` VARCHAR( 64 ) );";
	
	mysql_query( game[ "mysql" ], query );
	
	if( level.dvar[ "trueskill" ] )
		thread initTS();
}

initTS()
{
	query = "CREATE TABLE IF NOT EXISTS `" + level.dvar[ "mysql_trueskill_table" ] + "` ( `id` BIGINT( 32 ) UNSIGNED NOT NULL PRIMARY KEY, `mean` DOUBLE NOT NULL DEFAULT '25', `variance` DOUBLE NOT NULL DEFAULT '8.33333333', `skill` DOUBLE NOT NULL DEFAULT '0' );";
	
	mysql_query( game[ "mysql" ], query );
}

getData( table, id )
{
	query = "SELECT * FROM `" + table + "` WHERE `id` = " + id + " LIMIT 1";
	
	mysql_query( game[ "mysql" ], query );
	
	if( mysql_num_rows( game[ "mysql" ] ) != 1 )
        return undefined;
	
	return mysql_fetch_row( game[ "mysql" ] );
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
	
	mysql_query( game[ "mysql" ], query );
}

DBLookup()
{
	while( self getGuid().size < 2 )
		wait .05;

	data = getdata( "players", self getGuid() );
	
	if( !isDefined( data ) )
	{
		q[ 0 ] = "id=" + self getGuid();
		sendData( "players", q );
		
		self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
		self.pers[ "fov" ] = level.dvar[ "default_fov" ];
		self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
		self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
		self.pers[ "spec_keys" ] = level.dvar[ "spec_keys_default" ];
		self.pers[ "killcamText" ] = level.dvar[ "kct_default" ];
		self.pers[ "mu" ] = 25;
		self.pers[ "sigma" ] = 25 / 3;
		
		return;
	}
	
	self.pers[ "fullbright" ] = int( data[ "fps" ] );
	self.pers[ "fov" ] = int( data[ "fov" ] );
	self.pers[ "promodTweaks" ] = int( data[ "promod" ] );
	self.pers[ "hardpointSType" ] = int( data[ "shop" ] );
	self.pers[ "spec_keys" ] = int( data[ "spec" ] );
	self.pers[ "killcamText" ] = data[ "emblem" ];
	
	if( !level.dvar["cmd_fps"] )
		self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
	
	if( !level.dvar["cmd_fov"] )
		self.pers[ "fov" ] = level.dvar[ "default_fov" ];
	
	if( !level.dvar["cmd_promod"] )
		self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
	
	if( !level.dvar[ "shopbuttons_allowchange" ] )
		self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
	
	if( !level.dvar[ "cmd_spec_keys" ] )
		self.pers[ "spec_keys" ] = level.dvar[ "spec_keys_default" ];
		
	if( !level.dvar[ "kcemblem" ] )
		self.pers[ "killcamText" ] = level.dvar[ "kct_default" ];
	
	if( int( data[ "vip" ] ) )
	{
		query = "SELECT * FROM `players` WHERE `id` = " + self getGuid() + " AND NOW() < `vipexp`";
		mysql_query( game[ "mysql" ], query );
		
		if( mysql_num_rows( game[ "mysql" ] ) == 1 )
			self.pers[ "vip" ] = true;
		else
		{
			q[ 0 ] = "id=" + self getGuid();
			q[ 1 ] = "vip=0";
			sendData( "players", q );
		}
	}
	
	if( level.dvar[ "trueskill" ] )
	{
		data = getdata( level.dvar[ "mysql_trueskill_table" ], self getGuid() );
		
		if( !isDefined( data ) )
		{
			self.pers[ "mu" ] = 25;
			self.pers[ "sigma" ] = 25 / 3;
			q[ 0 ] = "id=" + self getGuid();
			sendData( level.dvar[ "mysql_trueskill_table" ], q );
			return;
		}
		
		self.pers[ "mu" ] = float( data[ "mean" ] );
		self.pers[ "sigma" ] = float( data[ "variance" ] );
	}
	else
	{
		self.pers[ "mu" ] = 25;
		self.pers[ "sigma" ] = 8.3;
	}
}

saveRank()
{
	q[ 0 ] = "id=" + self getGuid();
	q[ 1 ] = "mean=" + self.pers[ "mu" ];
	q[ 2 ] = "variance=" + self.pers[ "sigma" ];
	q[ 3 ] = "skill=" + ( self.pers[ "mu" ] - ( 3 * self.pers[ "sigma" ] ) );
	
	sendData( level.dvar[ "mysql_trueskill_table" ], q );
}

topPlayers( guid )
{
	while( !isDefined( game[ "mysql" ] ) )
		wait .05;

	query = "SELECT * FROM `" + level.dvar[ "mysql_trueskill_table" ] + "` ORDER BY `skill` DESC LIMIT 3";
	
	mysql_query( game[ "mysql" ], query );
	
	size = mysql_num_rows( game[ "mysql" ] );
	
	result = mysql_fetch_rows( game[ "mysql" ] );
	
	for( i = 0; i < size; i++ )
	{
		level.TSTopPlayers[ i ][ 0 ] = result[ i ][ "id" ];
	}
}

#if isSyscallDefined TS_Rate
punishTS( guid, time )
{
	if( getTime() - time < 120000 || level.players.size < 2 )
		return;
		
	while( isDefined( level.TSPenality ) )
		wait .05;
		
	level.TSPenality = true;
		
	data = getdata( level.dvar[ "mysql_trueskill_table" ], guid );
	
	if( isDefined( data ) )
	{
		mu = float( data[ "mean" ] );
		sigma = float( data[ "variance" ] );
		
		TS_AddPlayer( 0, mu, sigma, 1, 1 );
		TS_AddPlayer( 1, mu, sigma, 2, 1 );
		p = TS_Rate( 2, "1 0" );
		
		q[ 0 ] = "id=" + guid;
		q[ 1 ] = "mean=" + p[ 0 ][ 0 ];
		q[ 2 ] = "variance=" + p[ 0 ][ 1 ];
		q[ 3 ] = "skill=" + ( p[ 0 ][ 0 ] - ( 3 * p[ 0 ][ 1 ] ) );
		
		sendData( level.dvar[ "mysql_trueskill_table" ], q );
	}
	
	level.TSPenality = undefined;
}
#else
punishTS( guid, time ) {}
#endif
