//
//		TO BE USED WITH TRUESKILL COD4X PLUGIN
//	https://github.com/leiizko/cod4_trueskill_plugin
//
#include code\file;

init()
{
	thread code\events::addConnectEvent( ::onCon );
	if( level.dvar[ "fs_players" ] )
		thread topPlayers();
	
	while( !isDefined( level.inPrematchPeriod ) )
		wait .05;
	
	if( level.inPrematchPeriod )
		level waittill( "prematch_over" );
		
	waittillframeend;
		
	if( !isDefined( game[ "firstSpawnTime" ] ) )
		game[ "firstSpawnTime" ] = getTime();
}

// executed from _globallogic, function "endGame( winner, endReasonText )"
gameEnd( winner )
{
	level.TSGameTimeEnd = getTime();
	level.TSGameTime = getTime() - game[ "firstSpawnTime" ];
	
	if( level.players.size > 1 )
		updateSkill( winner );
	
	if( level.dvar[ "fs_players" ] )
	{
		players = level.players;
		for ( index = 0; index < players.size; index++ )
		{
			player = players[ index ];
			guid = player getGuid();
			
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
			
			saveRank( player );
		}
	}
}

updateSkill( winner )
{
	players = addPlayers();
	
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
		id = self getPlayerID();
		if( level.TSTopPlayers[ 0 ][ 0 ] == id )
			self.pers[ "prestige" ] = 9;
		else if( isDefined( level.TSTopPlayers[ 1 ] ) && level.TSTopPlayers[ 1 ][ 0 ] == id )
			self.pers[ "prestige" ] = 8;
		else if( isDefined( level.TSTopPlayers[ 2 ] ) && level.TSTopPlayers[ 2 ][ 0 ] == id )
			self.pers[ "prestige" ] = 6;
	}
	
	self waittill( "spawned_player" );

	if( !isDefined( self.pers[ "firstSpawnTime" ] ) )
		self.pers[ "firstSpawnTime" ] = getTime();
	
	if( !isDefined( game[ "firstSpawnTime" ] ) )
		game[ "firstSpawnTime" ] = self.pers[ "firstSpawnTime" ];
	
	wait .1;
	
	if( !level.dvar[ "fs_players" ] )
	{
		str = "" + self getStat( 3170 ) + "." + self getStat( 3171 );
		self.pers[ "mu" ] = floatNoDvar( str );
		
		wait .05;
		
		str = "" + self getStat( 3172 ) + "." + self getStat( 3173 );
		self.pers[ "sigma" ] = floatNoDvar( str );
		
		wait .05;
		
		check = self getStat( 3174 );
		
		if( check - 2 > self.pers[ "mu" ] - ( 3 * self.pers[ "sigma" ] ) )
		{
			self.pers[ "mu" ] = 25;
			self.pers[ "sigma" ] = 25 / 3;
		}
	}
}

saveRank( player )
{
	str = "" + player.pers[ "mu" ];
	strTok( str, "." );

	player setStat( 3170, int( str[ 0 ] ) );
	if( isDefined( str[ 1 ] ) )
		player setStat( 3171, int( str[ 1 ] ) );
	else
		player setStat( 3171, 0 );

	str = "" + player.pers[ "sigma" ];
	strTok( str, "." );

	player setStat( 3172, int( str[ 0 ] ) );
	if( isDefined( str[ 1 ] ) )
		player setStat( 3173, int( str[ 1 ] ) );
	else
		player setStat( 3173, 0 );

	player setStat( 3174, int( player.pers[ "mu" ] - ( 3 * player.pers[ "sigma" ] ) ) );
}

addPlayers()
{
	players = level.players;
	t = 0;
	rGroup = [];
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( player.team != "axis" && player.team != "allies" )
			continue;
			
		weight = ( level.TSGameTimeEnd - player.pers[ "firstSpawnTime" ] ) / level.TSGameTime;
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
	players = level.players;
	
	pool = [];
	
	for( i = 0; i < players.size; i++ )
	{
		pool[ i ][ 0 ] = players[ i ] getPlayerID();
		pool[ i ][ 1 ] = players[ i ].pers[ "mu" ] - ( 3 * players[ i ].pers[ "sigma" ] );
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
					if( level.TSTopPlayers[ i ][ 1 ] > pool[ n ][ 1 ] )
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
	n = 0;
	for( i = 0; i < 6; i += 2 )
	{
		arr[ i ] = pool[ n ][ 0 ];
		arr[ i + 1 ] = pool[ n ][ 1 ];
		n++;
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
			n = level.TSTopPlayers.size;
			level.TSTopPlayers[ n ][ 0 ] = array[ i ]; // ID
			level.TSTopPlayers[ n ][ 1 ] = floatNoDvar( array[ i + 1 ] ); // MEAN / 3*VARIANCE
		}
	}
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