//
//	TO BE USED WITH TRUESKILL COD4X PLUGIN
//
init()
{
	thread code\events::addConnectEvent( ::onCon );
	
	level waittill( "game_ended" );
	
	level.TSGameTimeEnd = getTime();
	level.TSGameTime = getTime() - game[ "firstSpawnTime" ];
	
	updateSkill();
	
	if( level.dvar[ "fs_players" ] )
	{
		players = level.players;
		for ( index = 0; index < players.size; index++ )
		{
			player = players[ index ];
			guid = player getGuid();
			
			level.FSCD[ guid ][ 6 ] = player.pers[ "mu" ];
			level.FSCD[ guid ][ 7 ] = player.pers[ "sigma" ];
			
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

updateSkill()
{
	players = addPlayers();
	
	// TS_Rate: players must be added via TS_AddPlayer, returns 2D array of players with updated ratings in same order as added, deletes all added players.
	ratedPlayers = TS_Rate();
	
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		player.pers[ "mu" ] = ratedPlayers[ i ];
		player.pers[ "sigma" ] = ratedPlayers[ i ];
	}	
}

onCon()
{
	self endon( "disconnect" );
	self waittill( "spawned_player" );

	if( !isDefined( self.pers[ "firstSpawnTime" ] ) )
		self.pers[ "firstSpawnTime" ] = getTime();
	
	if( !isDefined( game[ "firstSpawnTime" ] ) )
		game[ "firstSpawnTime" ] = self.pers[ "firstSpawnTime" ];
	
	wait .1;
	
	if( !level.dvar[ "fs_players" ] )
	{
		str = "" + self getStat( 3170 ) + "." + self getStat( 3171 );
		self.pers[ "mu" ] = float( str );
		
		wait .05;
		
		str = "" + self getStat( 3172 ) + "." + self getStat( 3173 );
		self.pers[ "sigma" ] = float( str );
		
		wait .05;
		
		check = self getStat( 3174 );
		
		if( check - 2 > self.pers[ "mu" ] - ( 3 * self.pers[ "sigma" ] ) )
		{
			self.pers[ "mu" ] = 25;
			self.pers[ "sigma" ] = 25 / 3;
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
	rGroup = [];
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( player.team != "axis" && player.team != "allies" )
			continue;
			
		weight = ( player.pers[ "firstSpawnTime" ] - level.TSGameTimeEnd ) / level.TSGameTime;
		if( weight > 0.95 )
			weight = 1.0;
		else if( weight < 0.05 )
			weight = 0.0;
		
		// Usage: TS_AddPlayer( (INT)<player ID>, (FLOAT)<player mu>, (FLOAT)<player sigma>, (STRING)<player team>, (FLOAT)[<player weight>] )
		TS_AddPlayer( int( player getGuid() ), player.pers[ "mu" ], player.pers[ "sigma" ], player.team, weight );
		rGroup[ rGroup.size ] = player;
	}
	
	return rGroup;
}