startBarrage( endPos, startPos )
{
	self endon( "disconnect" );
	level endon( "endBarage" );
	
	self thread code\common::notifyTeamLn( "Friendly artillery called by^1 " + self.name );
	level thread playerDC( self );
	
	players = level.players;
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];

		player PlaySoundToPlayer( "distant_artillery_barrage", player );
	}
	
	wait 1.5;

	players = level.players;
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];

		player PlaySoundToPlayer( "distant_artillery_barrage", player );
	}
	
	wait 1;
	
	// Z = 1381.95 
	// X and Y divided by 3.4
	// Randomized starting point to avoid hitting another shell
	
	for( i = 0; i < level.dvar[ "arty_shell_num" ]; i++ )
	{
		level.mortarShell[ i ] = spawn( "script_model", ( startPos[ 0 ] + RandomIntRange( -375, 375 ), startPos[ 1 ] + RandomIntRange( -375, 375 ), startPos[ 2 ] ) );
		level.mortarShell[ i ] setModel( "projectile_hellfire_missile" );
		
		power = ( ( endPos[ 0 ] - startPos[ 0 ] ) / 3.4 + RandomIntRange( -25, 25 ), ( endPos[ 1 ] - startPos[ 1 ] ) / 3.4 + RandomIntRange( -25, 25 ), 1381.95 );
		level.mortarShell[ i ] MoveGravity( power, 4 );
		level.mortarShell[ i ].fireTime = getTime();
		
		thread roundThink( level.mortarShell[ i ] );
		
		if( i != level.dvar[ "arty_shell_num" ] - 1 )
			wait randomFloatRange( 0.25, 0.7 );
	}
	
	wait 3.8;
	
	thread endBarage();
}

endBarage()
{
	level notify( "endBarage" );
	
	wait .1;
	
	if( isDefined( level.mortarShell ) )
	{
		for( i = 0; i < level.dvar[ "arty_shell_num" ]; i++ )
		{
			if( isDefined( level.mortarShell[ i ] ) )
				level.mortarShell[ i ] delete();
				
			waittillframeend;
		}
	}
	level.mortarShell = undefined;
	
	wait .1;
	
	level.artilleryBarrage = undefined;
}

playerDC( player )
{
	level endon( "endBarage" );
	level endon( "game_ended" );
	
	player waittill( "disconnect" );
	
	thread endBarage();
}

roundThink( ent )
{
	self endon( "disconnect" );
	level endon( "endBarage" );
	
	while( isDefined( ent ) )
	{
		start = ent.origin;
		
		if( getTime() - ent.fireTime > 1900 && !isDefined( ent.incomingSound ) )
		{
			ent.incomingSound = true;
			ent playSound( "fast_artillery_round" );
		}
		
		if( getTime() - ent.fireTime > 500 )
		{
			vector = anglesToForward( ent.angles );
			forward = ent.origin + ( vector[ 0 ] * 100, vector[ 1 ] * 100, vector[ 2 ] * 100 );
			collision = bulletTrace( ent.origin, forward, false, ent );
			
			if( collision[ "surfacetype" ] != "default" && collision[ "fraction" ] < 1 ) 
			{
				playFx( level.hardEffects[ "artilleryExp" ], collision[ "position" ]  );
				ents = maps\mp\gametypes\_weapons::getDamageableents( collision[ "position" ], 240 );
			
				for( i = 0; i < ents.size; i++ )
				{
					if ( !ents[ i ].isPlayer || isAlive( ents[ i ].entity ) )
					{
						if( !isDefined( ents[ i ] ) )
							continue;
							
						if( isPlayer( ents[ i ].entity ) )
							ents[ i ].entity.sWeaponForKillcam = "artillery";

						ents[ i ] maps\mp\gametypes\_weapons::damageEnt(
							ent, 
							self, 
							1000, 
							"MOD_PROJECTILE_SPLASH", 
							"artillery_mp", 
							collision[ "position" ], 
							vectornormalize( collision[ "position" ] - ents[ i ].entity.origin ) 
						);
					}
				}
				earthquake( 2.4, 0.7, collision[ "position" ], 280 );
				thread code\common::playSoundinSpace( "artillery_impact", collision[ "position" ] );
				
				if( isDefined( ent ) )
					ent delete();
				
				break;
			}
		}
		
		wait .05;
		
		if( !isDefined( ent ) )
			break;
		
		end = ent.origin;
		ent.angles = vectorToAngles( end - start );
	}
}

selectLocation()
{
	self endon("disconnect");
	
	if ( isDefined( level.artilleryBarrage ) )
	{
		self iPrintLnBold( "ARTILLERY BARRAGE not available" );
		return false;
	}
	else if( isDefined( self.pers[ "lastArtyUse" ] ) && getTime() - self.pers[ "lastArtyUse" ] < 45000 )
	{
		time = int( 45 - ( getTime() - self.pers[ "lastArtyUse" ] ) / 1000 );
		self iPrintLnBold( "ARTILLERY REARMING - ETA " + time + " SECONDS" );
		return false;
	}
	
	if( !isDefined( level.heliDistanceMax ) || level.heliDistanceMax == 0 )
	{
		self iPrintLnBold( "ARTILLERY BARRAGE not available this match!" );
		print( "\n********** ERROR **********\n" );
		print( "Heli map plot was not successful, possible unsuported map. Terminating hardpoint!\n\n" );
		return false;
	}

	self beginLocationSelection( "map_artillery_selector", level.artilleryDangerMaxRadius * 1.2 );
	self.selectingLocation = true;

	self thread maps\mp\gametypes\_hardpoints::endSelectionOn( "cancel_location" );
	self thread maps\mp\gametypes\_hardpoints::endSelectionOn( "death" );
	self thread maps\mp\gametypes\_hardpoints::endSelectionOn( "disconnect" );
	self thread maps\mp\gametypes\_hardpoints::endSelectionOn( "used" );
	self thread maps\mp\gametypes\_hardpoints::endSelectionOnGameEnd();

	self endon( "stop_location_selection" );
	self waittill( "confirm_location", location );

	if ( isDefined( level.artilleryBarrage ) )
	{
		self iPrintLnBold( "ARTILLERY BARRAGE not available" );
		self thread maps\mp\gametypes\_hardpoints::stopAirstrikeLocationSelection( false );
		return false;
	}

	self thread finishUsage( location );
	level.artilleryBarrage = true;
	self.pers[ "lastArtyUse" ] = getTime();
	return true;
}

finishUsage( location )
{
	self endon("disconnect");
	self notify( "used" );
	
	wait .05;
	self thread maps\mp\gametypes\_hardpoints::stopAirstrikeLocationSelection( false );
	
	self thread calculateDirection( location );
	
	return true;
}

calculateDirection( pos )
{
	// Get the location on the upper layer of ground
	trace = bullettrace( self.origin + ( 0, 0, 100000 ), self.origin, false, undefined );
	pos = ( pos[ 0 ], pos[ 1 ], trace[ "position" ][ 2 ] - 400 );
	trace = bullettrace( pos, pos - ( 0, 0, 100000 ), false, undefined );
	pos = trace[ "position" ];
	
	// initialise the variable in case no optimal solution is found
	startLocation = ( level.heliCenterPoint[ 0 ] + level.heliDistanceMax * cos( 0 ), level.heliCenterPoint[ 1 ] + level.heliDistanceMax * sin( 0 ), pos[ 2 ] );
	
	// Get the shell firing position by checking if the shell can directly hit desired position from specific starting point
	for( k = 0;k < 360; k += 10 )
	{
		// heliCenterPoint & heliDistanceMax are calculated in heli script
		checkFrom = ( ( level.heliCenterPoint[ 0 ] + level.heliDistanceMax * cos( k ) ) / 2, ( level.heliCenterPoint[ 1 ] + level.heliDistanceMax * sin( k ) ) / 2, pos[ 2 ] + 1400 );
		trace = bullettrace( checkFrom, pos, false, undefined );
		if( DistanceSquared( trace[ "position" ], pos ) == 0 )
		{
			start = ( level.heliCenterPoint[ 0 ] + level.heliDistanceMax * cos( k ), level.heliCenterPoint[ 1 ] + level.heliDistanceMax * sin( k ), pos[ 2 ] );
			trace = bullettrace( checkFrom, ( start[ 0 ], start[ 1 ], pos[ 2 ] ), false, undefined );
			if( DistanceSquared( trace[ "position" ], ( start[ 0 ], start[ 1 ], pos[ 2 ] ) ) < 15625 ) // dist < 125
			{
				startLocation = ( start[ 0 ], start[ 1 ], pos[ 2 ] );
				break;
			}
			else
				startLocation = ( start[ 0 ], start[ 1 ], pos[ 2 ] ); // if it can't find a perfect match
		}
		waittillframeend;
	}
	
	self thread startBarrage( pos, startLocation );
}