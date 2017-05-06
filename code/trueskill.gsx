/*
init()
{
	thread code\events::addConnectEvent( ::onCon );
	
	level waittill( "game_ended" );
	
	level.TSGameTimeEnd = getTime();
	level.TSGameTime = getTime() - game[ "firstSpawnTime" ];
	
	updateSkill();
	
	wait .1;
	
	if( level.dvar[ "fs_players" ] )
	{
		players = level.players;
		for ( index = 0; index < players.size; index++ )
		{
			players[ index ] thread code\player::FSSave( players[ index ] getGuid() );
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
	addPlayers();
	
	TS_Rate();
	
	TS_ClearAllPlayers();
}

onCon()
{
	self endon( "disconnect" );
	self waittill( "spawned_player" );

	if( !isDefined( self.pers[ "firstSpawnTime" ] ) )
		self.pers[ "firstSpawnTime" ] = getTime();
	
	if( !isDefined( game[ "firstSpawnTime" ] ) )
		game[ "firstSpawnTime" ] = self.pers[ "firstSpawnTime" ];
	
	wait .5;
	
	if( !level.dvar[ "fs_players" ] )
	{
		str = "" + self getStat( 3170 ) + "." + self getStat( 3170 );
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
*/
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
/*
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


// Plugin_Scr_Error( "Usage: TS_AddPlayer( <player_cid>, <player mu>, <player sigma>, <player team>, [<player weight>] )\n" );
addPlayers()
{
	players = level.players;
	for( i = 0; i < level.players.size; i++ )
	{
		player = players[ i ];
		
		if( player.team != "axis" && player.team != "allies" )
			continue;
			
		weight = ( player.pers[ "firstSpawnTime" ] - level.TSGameTimeEnd ) / level.TSGameTime;
		if( weight > 0.98 )
			weight = 1;
		
		TS_AddPlayer( player getEntityNumber(), player.pers[ "mu" ], player.pers[ "sigma" ], player.team, weight );
	}
}
*/