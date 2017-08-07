//
//	TO BE USED WITH TRUESKILL COD4X PLUGIN
//
init()
{
	thread code\events::addConnectEvent( ::onCon );
	
	while( !isDefined( level.inPrematchPeriod ) )
		wait .05;
	
	if( level.inPrematchPeriod )
		level waittill( "prematch_over" );
		
	waittillframeend;
		
	if( isDefined( game[ "firstSpawnTime" ] ) )
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