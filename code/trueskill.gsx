//
//		TO BE USED WITH TRUESKILL COD4X PLUGIN
//	https://github.com/leiizko/cod4_trueskill_plugin
//
#include code\file;

init()
{
	thread code\events::addConnectEvent( ::onCon );
	
#if isSyscallDefined mysql_close
	if( level.dvar[ "mysql" ] )
		thread code\mysql::topPlayers();
#endif
	
	if( level.dvar[ "fs_players" ] && !level.dvar[ "mysql" ] )
		thread topPlayers();
}

// executed from _globallogic, function "endGame( winner, endReasonText )"
gameEnd( winner )
{	
	if( level.players.size < 2 )
		return;
	
	updateSkill( winner );
		
	if( level.dvar[ "mysql" ] )
	{
#if isSyscallDefined mysql_close
		players = level.players;
		for ( index = 0; index < players.size; index++ )
		{
			player = players[ index ];
			
			if( !isDefined( player.pers[ "mu" ] ) || !isDefined( player.pers[ "sigma" ] ) )
				continue;
			
			player thread code\mysql::saveRank();
		}
#endif
	}
	else if( level.dvar[ "fs_players" ] )
	{
		players = level.players;
		for ( index = 0; index < players.size; index++ )
		{
			player = players[ index ];
			guid = player getGuid();
			
			if( !isDefined( player.pers[ "mu" ] ) || !isDefined( player.pers[ "sigma" ] ) )
				continue;
			
			level.FSCD[ guid ][ 6 ] = "mu;" + player.pers[ "mu" ];
			level.FSCD[ guid ][ 7 ] = "sigma;" + player.pers[ "sigma" ];
			
			player thread code\player::FSSave( guid );
		}
	}
	else
	{
		players = level.players;
		for ( index = 0; index < players.size; index++ )
		{
			player = players[ index ];
			
			if( !isDefined( player.pers[ "mu" ] ) || !isDefined( player.pers[ "sigma" ] ) )
				continue;
			
			player thread saveRank();
		}
	}
}

updateSkill( winner )
{
	players = addPlayers();
	
	if( !isArray( players ) || players.size < 2 )
		return;
	
	if( level.teambased )
	{
		if( winner == "axis" )
			rank = "1 0";
		else if( winner == "tie" )
			rank = "0 0";
		else
			rank = "0 1";
			
		ratedPlayers = TS_Rate( 2, rank );
	}
	else
	{
		sorted = [];
		for( i = 0; i < players.size; i++ )
		{
			sorted[ i ][ 0 ] = players[ i ];
			sorted[ i ][ 1 ] = i;
		}
		
		for( i = 0; i < sorted.size; i++ )
		{
			for( n = i + 1; n < sorted.size; n++ )
			{
				if( sorted[ i ][ 0 ].score < sorted[ n ][ 0 ].score )
				{
					tmp = sorted[ i ];
					sorted[ i ] = sorted[ n ];
					sorted[ n ] = tmp;
				}
			}
		}

		r_a = [];
		n = 0;
		for( i = 0; i < sorted.size; i++ )
		{
			r_a[ sorted[ i ][ 1 ] ] = n;
			
			if( i < sorted.size - 1 && sorted[ i ][ 0 ].score != sorted[ i + 1 ][ 0 ].score )
			{
				n++;
			}
		}
		
		ranks = "";
		ranks += "" + r_a[ 0 ];
		for( i = 1; i < r_a.size; i++ )
			ranks += " " + r_a[ i ];
		
		ratedPlayers = TS_Rate( players.size, ranks );
	}
	
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		player.pers[ "mu" ] = ratedPlayers[ i ][ 0 ];
		player.pers[ "sigma" ] = ratedPlayers[ i ][ 1 ];
	}
	
	if( level.dvar[ "fs_players" ] )
		thread updateTopPlayers();
}

onCon()
{
	self endon( "disconnect" );
	
	waittillframeend;
	
	if( isArray( level.TSTopPlayers ) )
	{
		id = self getGuid();
		if( level.TSTopPlayers[ 0 ][ 0 ] == id )
			self.pers[ "prestige" ] = 9;
		else if( isDefined( level.TSTopPlayers[ 1 ] ) && level.TSTopPlayers[ 1 ][ 0 ] == id )
			self.pers[ "prestige" ] = 8;
		else if( isDefined( level.TSTopPlayers[ 2 ] ) && level.TSTopPlayers[ 2 ][ 0 ] == id )
			self.pers[ "prestige" ] = 6;
	}
	
	if( level.dvar[ "fs_players" ] || level.dvar[ "mysql" ] )
		return;
	
	self waittill( "spawned_player" );
	
	wait .1;

	str = "" + self getStat( 3170 ) + "." + self getStat( 3171 );
	self.pers[ "mu" ] = float( str );
		
	wait .05;
		
	str = "" + self getStat( 3172 ) + "." + self getStat( 3173 );
	self.pers[ "sigma" ] = float( str );
		
	wait .05;
		
	check = self getStat( 3174 );
	check_init = self getStat( 3175 );
		
	if( check - 2 > self.pers[ "mu" ] - ( 3 * self.pers[ "sigma" ] ) || check_init != 100111 )
	{
		self.pers[ "mu" ] = 25;
		self.pers[ "sigma" ] = 25 / 3;
		self setStat( 3175, 100111 );
	}
}

saveRank()
{
	str_f = "" + self.pers[ "mu" ];
	str = strTok( str_f, "." );

	self setStat( 3170, int( str[ 0 ] ) );
	if( isDefined( str[ 1 ] ) )
		self setStat( 3171, int( str[ 1 ] ) );
	else
		self setStat( 3171, 0 );

	str = undefined;
	str_f = "" + self.pers[ "sigma" ];
	str = strTok( str_f, "." );

	self setStat( 3172, int( str[ 0 ] ) );
	if( isDefined( str[ 1 ] ) )
		self setStat( 3173, int( str[ 1 ] ) );
	else
		self setStat( 3173, 0 );

	self setStat( 3174, int( self.pers[ "mu" ] - ( 3 * self.pers[ "sigma" ] ) ) );
}

addPlayers()
{
	waittillframeend;
	
	if( isDefined( level.TSPenality ) )
		wait .05;

	players = level.players;
	t = 0;
	rGroup = [];
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( ( player.team != "axis" && player.team != "allies" ) || !isDefined( player.pers[ "firstSpawnTime" ] ) )
			continue;
			
		weight = ( level.GameTimeEnd - player.pers[ "firstSpawnTime" ] ) / level.GameTime;
		
		if( !isDefined( weight ) )
			weight = 0;
		
		if( weight > 0.95 )
			weight = 1.0;
		else if( weight < 0.05 )
			weight = 0.0;
		
		if( level.teambased )
		{
			if( player.team == "allies" )
				team = 1;
			else
				team = 2;
		}
		else
		{
			t++;
			team = t;
		}

		TS_AddPlayer( player getEntityNumber(), player.pers[ "mu" ], player.pers[ "sigma" ], team, weight );
		rGroup[ rGroup.size ] = player;
	}
	
	return rGroup;
}

updateTopPlayers()
{
	waittillframeend;
	players = level.players;
	
	pool = [];
	
	for( i = 0; i < players.size; i++ )
	{
		if( !isDefined( players[ i ].pers[ "mu" ] ) || !isDefined( players[ i ].pers[ "sigma" ] ) )
			continue;

		n = pool.size;
		pool[ n ][ 0 ] = players[ i ] getGuid();
		pool[ n ][ 1 ] = players[ i ].pers[ "mu" ] - ( 3 * players[ i ].pers[ "sigma" ] );
	}
	
	if( isArray( level.TSTopPlayers ) )
	{
		psize = pool.size;
		for( i = 0; i < level.TSTopPlayers.size; i++ )
		{
			next = false;
			for( n = 0; n < psize; n++ )
			{
				if( level.TSTopPlayers[ i ][ 0 ] == pool[ n ][ 0 ] )
				{
					pool[ n ][ 1 ] = level.TSTopPlayers[ i ][ 1 ];
					next = true;
					break;
				}
			}
			
			if( !next )
			{
				n = pool.size;
				pool[ n ][ 0 ] = level.TSTopPlayers[ i ][ 0 ];
				pool[ n ][ 1 ] = level.TSTopPlayers[ i ][ 1 ];
			}
		}
	}
	
	for( i = 0; i < pool.size; i++ )
	{
		for( n = i + 1; n < pool.size; n++ )
		{
			if( pool[ i ][ 1 ] < pool[ n ][ 1 ] )
			{
				tmp = pool[ i ];
				pool[ i ] = pool[ n ];
				pool[ n ] = tmp;
			}
		}
	}
	
	arr = [];
	for( i = 0; i < 3; i++ )
	{
		if( !isArray( pool[ i ] ) )
			break;

		arr[ arr.size ] = pool[ i ][ 0 ];
		arr[ arr.size ] = pool[ i ][ 1 ];
	}
	
	writeToFile( "./ne_db/players/topratedplayers.db", arr );
}

topPlayers()
{
	array = readFile( "./ne_db/players/topratedplayers.db" );
	if( isArray( array ) )
	{
		level.TSTopPlayers = [];
		for( i = 0; i < array.size; i += 2 )
		{
			if( !isDefined( array[ i ] ) || !isDefined( array[ i + 1 ] ) )
			{
				FS_Remove( "./ne_db/players/topratedplayers.db" );
				level.TSTopPlayers = undefined;
				return;
			}
			
			n = level.TSTopPlayers.size;
			level.TSTopPlayers[ n ][ 0 ] = array[ i ]; // ID
			level.TSTopPlayers[ n ][ 1 ] = float( array[ i + 1 ] ); // MEAN / 3*VARIANCE
		}
	}
}

penality( guid, time )
{
	if( getTime() - time < 120000 || level.players.size < 2 )
		return;
		
	while( isDefined( level.TSPenality ) )
		wait .05;
		
	level.TSPenality = true;
	
	mu = strtok( level.FSCD[ guid ][ 6 ], ";" );
	mu = float( mu[ 1 ] );
	
	sigma = strtok( level.FSCD[ guid ][ 7 ], ";" );
	sigma = float( sigma[ 1 ] );
	
	TS_AddPlayer( 0, mu, sigma, 1, 1 );
	TS_AddPlayer( 1, mu, sigma, 2, 1 );
	p = TS_Rate( 2, "1 0" );
	
	level.TSPenality = undefined;
	
	level.FSCD[ guid ][ 6 ] = "mu;" + p[ 0 ][ 0 ];
	level.FSCD[ guid ][ 7 ] = "sigma;" + p[ 0 ][ 1 ];
}

// legacy
floatNoDvar( string )
{
	nums = strTok( string, "." );
	
	num1 = int( nums[ 0 ] ) + 0.0;
	
	if( !isDefined( nums[ 1 ] ) )
		return num1;
		
	by = "1";
	for( i = 0; i < nums[ 1 ].size; i++ )
		by += 0;
	num2 = int( nums[ 1 ] ) / int( by );
	
	return num1 + num2;
}