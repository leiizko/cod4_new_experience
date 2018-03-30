#include code\common;
#include maps\mp\_utility;

init()
{
	self endon( "disconnect" );
	
	if( isDefined( level.flyingPlane ) )
	{
		self iPrintLnBold( "TACTICAL NUKE not available" );
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

	if ( isDefined( level.flyingPlane ) )
	{
		self iPrintLnBold( "TACTICAL NUKE not available" );
		self thread maps\mp\gametypes\_hardpoints::stopAirstrikeLocationSelection( false );
		return false;
	}

	self thread finishUsage( location );
	return true;
}

finishUsage( location )
{
	self notify( "used" );
	self endon( "disconnect" );
	wait ( 0.05 );
	self thread maps\mp\gametypes\_hardpoints::stopAirstrikeLocationSelection( false );
	self thread setup( location );
	level.flyingPlane = true;
	return true;
}

setup( endPos )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self thread notifyTeamBig( "FRIENDLY NUKE INBOUND!", ( 0.1, 0.1, 1 ), 5 );
	self thread notifyTeamLn( "Friendly tactical nuke called by^1 " + self.name );
	
	trace = bullettrace( self.origin + ( 0, 0, 10000 ), self.origin, false, undefined );
	pos = ( endPos[ 0 ], endPos[ 1 ], trace[ "position" ][ 2 ] - 400 );
	trace = bullettrace( pos, pos - ( 0, 0, 10000 ), false, undefined );
	endPos = trace[ "position" ];
	
	thread playerDC( self );
	thread gameEnd();
	
	angles = ( randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ) ); // So random, much wow...
	endPosAir = endPos + ( 0, 0, 1500 );
	startPos = endPosAir + vector_scale( anglesToForward( angles ), 20000 );
	
	waittillframeend;
	
	level.tacticalNuke = spawn( "script_model", startPos );
	level.tacticalNuke.owner = self;
	level.tacticalNuke setModel( "projectile_cbu97_clusterbomb" );
	level.tacticalNuke.angles = VectorToAngles( endPosAir - level.tacticalNuke.origin );
	
	self thread doFX();
	level.nukeInProgress = true;
	
	thread callStrike_planeSound_nuke( level.tacticalNuke, endPos );
	
	
	// Straight flight
	for( ;; ) // 39?
	{
		level.tacticalNuke.angles = VectorToAngles( endPosAir - level.tacticalNuke.origin );
		forward = level.tacticalNuke.origin + vector_scale( anglesToForward( level.tacticalNuke.angles ), 500 );
		level.tacticalNuke moveTo( forward, .15 );
		
		wait .15;
		
		if( distance2d( level.tacticalNuke.origin, endPosAir ) <= 512 )
			break;
	}
	
	// Arch
	for( i = 0; i < 18; i++ )
	{
		angles = level.tacticalNuke.angles;
		level.tacticalNuke.angles = ( angles[ 0 ] + 5, angles[ 1 ], angles[ 2 ] );
		forward = level.tacticalNuke.origin + vector_scale( anglesToForward( level.tacticalNuke.angles ), 25 );
		level.tacticalNuke moveTo( forward, .05 );
		
		wait .05;
	}
	
	// Straight down
	for( i = 0; i < 20; i++ )
	{
		level.tacticalNuke.angles = VectorToAngles( endPos - level.tacticalNuke.origin );
		forward = level.tacticalNuke.origin + vector_scale( anglesToForward( level.tacticalNuke.angles ), 52 );
		level.tacticalNuke moveTo( forward, .1 );
		
		wait .1;
	}
	
	level.tacticalNuke notify( "del" );
	level notify( "nukeSTOP" );
	angles = level.tacticalNuke.angles;
	self notify( "endFirstFX" );	
	
	position = level.tacticalNuke.origin;
	
	for( i = 0; i < 360; i += 45 )
		PlayFX( level.chopper_fx["explode"]["large"], ( position[ 0 ] + ( 512 * cos( i ) ),  position[ 1 ] + ( 512 * sin( i ) ), position[ 2 ] - 32 ) );
	
	PlayFX( level.hardEffects[ "tankerExp" ], position );
	thread playSoundinSpace( "exp_suitcase_bomb_main", position + ( 0, 0, 256 ) );
	
	thread radiationZone( endPos );
	
	ents = maps\mp\gametypes\_weapons::getDamageableents( endPos, 100000 );
	
	for( i = 0; i < ents.size; i++ )
	{
		if ( !ents[ i ].isPlayer || isAlive( ents[ i ].entity ) )
		{
			if( !isDefined( ents[ i ] ) )
				continue;
			
			if( isDefined( ents[ i ].entity.team ) && ents[ i ].entity.team == self.team )
				continue;
			
			if( isPlayer( ents[ i ].entity ) )
			{
				ents[ i ].entity.sWeaponForKillcam = "nuke_main";
				ents[ i ].entity restoreHP();
			}

			ents[ i ] maps\mp\gametypes\_weapons::damageEnt(
				level.tacticalNuke, 
				self, 
				64000,
				"MOD_PROJECTILE_SPLASH", 
				"artillery_mp", 
				endPos, 
				vectornormalize( endPos - ents[ i ].entity.origin ) 
			);
		}
	}
	
	level.tacticalNuke delete(); // Delete it to stop the bloody sound
	waittillframeend;
	
	level.tacticalNuke = spawn( "script_model", endPos );
	level.tacticalNuke.owner = self;
	level.tacticalNuke setModel( "projectile_cbu97_clusterbomb" );
	level.tacticalNuke.angles = angles;
	
	self thread doRadFX();
	
	level notify( "stopGameEnd" );
}

gameEnd()
{
	level endon( "stopGameEnd" );
	
	level waittill( "game_ended" );
	
	level.tacticalNuke notify( "del" );
	level notify( "nukeSTOP" );
	level.tacticalNuke delete();
}

playerDC( player )
{
	level endon( "endWatch" );
	level endon( "game_ended" );

	player waittill( "disconnect" );
	
	level notify( "stopGameEnd" );
	level.nukeInProgress = undefined;
	level notify( "endRadationZone" );
	if( isDefined( level.tacticalNuke ) )
		level.tacticalNuke delete();
	level.flyingPlane = undefined;
	level.tacticalNuke = undefined;
	if( isDefined( level.radiationZone ) )
		level.radiationZone delete();
	setExpFog( 1000, 100000, 51/255, 51/255, 51/255, 20 );
}

callStrike_planeSound_nuke( plane, bombsite )
{
	level endon( "nukeSTOP" );
	plane thread maps\mp\gametypes\_hardpoints::play_loop_sound_on_entity( "veh_mig29_dist_loop" );
	while( !maps\mp\gametypes\_hardpoints::targetisclose( plane, bombsite ) )
		wait .01;
	plane notify ( "stop sound" + "veh_mig29_dist_loop" );
	plane thread maps\mp\gametypes\_hardpoints::play_loop_sound_on_entity( "veh_mig29_close_loop" );
	while( maps\mp\gametypes\_hardpoints::targetisinfront( plane, bombsite ) )
		wait .01;
	wait .25;
	plane thread playSoundinSpace( "veh_mig29_sonic_boom", bombsite );
	while( maps\mp\gametypes\_hardpoints::targetisclose( plane, bombsite ) )
		wait .01;
	plane notify ( "stop sound" + "veh_mig29_close_loop" );
	plane thread maps\mp\gametypes\_hardpoints::play_loop_sound_on_entity( "veh_mig29_dist_loop" );
	plane waittill("del");
	plane notify ( "stop sound" + "veh_mig29_dist_loop" );
}

doFX()
{
	self endon( "disconnect" );
	self endon( "endFirstFX" );

	while( isDefined( level.tacticalNuke ) )
	{
		playFxonTag( level.hardEffects[ "hellfireGeo" ], level.tacticalNuke, "tag_origin" );
		wait 2;
	}
}

doRadFX()
{
	self endon( "disconnect" );

	while( isDefined( level.tacticalNuke ) )
	{
		playFxonTag( level.hardEffects[ "fire" ], level.tacticalNuke, "tag_origin" );
		wait 1;
	}
}

radiationZone( location )
{
	level endon( "game_ended" );
	level endon( "endRadationZone" );
	
	level.radiationZone = spawn( "trigger_radius", location, 0, 1536, 2048 );
	
	thread endRadationZone();
	setExpFog( 0, 75, 51/255, 51/255, 51/255, 0 );
	
	while( 1 )
	{
		level.radiationZone waittill( "trigger", player );
		
		if( isDefined( player.spawnprotected ) || !isDefined( player ) || player == level.tacticalNuke.owner )
			continue;
		
		if( !isDefined( player.pers[ "radsLastTime" ] ) )
			player.pers[ "radsLastTime" ] = getTime();
		
		if( getTime() - player.pers[ "radsLastTime" ] > 1000 )
		{
			player.pers[ "radsLastTime" ] = getTime();
			
			if( !isAlive( player ) )
				continue;
			
			if( player.health - ( int( player.maxHealth / 8 ) ) <= 0 )
				player.sWeaponForKillcam = "nuke_rad";
			
			player thread [[level.callbackPlayerDamage]](
														level.tacticalNuke,
														level.tacticalNuke.owner, 
														int( player.maxHealth / 8 ),
														0,
														"MOD_PROJECTILE_SPLASH", 
														"artillery_mp", 
														level.tacticalNuke.origin,
														vectornormalize( level.tacticalNuke.origin - player.origin ),
														"none",
														0 
														);
														
			if( isAlive( player ) )
			{
				if( player.health < player.maxHealth / 2.2 )
					player shellshock( "radiation_high", 4 );
				
				else if( player.health < player.maxHealth / 1.3 )
					player shellshock( "radiation_med", 2 );
			}
		}
	}
}

endRadationZone()
{
	level endon( "game_ended" );
	level endon( "endRadationZone" );
	
	wait 15;
	setExpFog( 5, 100, 51/255, 51/255, 51/255, 5 );
	wait 10;
	setExpFog( 20, 150, 51/255, 51/255, 51/255, 5 );
	wait 5;
	setExpFog( 1000, 100000, 51/255, 51/255, 51/255, 20 );
	
	level.nukeInProgress = undefined;
	level notify( "endWatch" );
	if( isDefined( level.tacticalNuke ) )
		level.tacticalNuke delete();
	level.flyingPlane = undefined;
	level.tacticalNuke = undefined;
	if( isDefined( level.radiationZone ) )
		level.radiationZone delete();
	level notify( "endRadationZone" );
}