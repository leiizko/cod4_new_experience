#include code\common;
#include maps\mp\_utility;

init()
{
	self endon( "disconnect" );
	
	if( isDefined( level.flyingPlane ) )
	{
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "HARDPOINT_NOT_AVAILABLE" ), lua_getLocString( self.pers[ "language" ], "NUKE" ) );
		return false;
	}

	level.flyingPlane = true;
	
	trace = bulletTrace( level.heliCenterPoint + ( 0, 0, 1200 ), level.heliCenterPoint - ( 0, 0, 10000 ), false, undefined );
	
	self thread setup( trace[ "position" ] );
	return true;
}

setup( endPos )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	thread notifyTeam( lua_getLocString( self.pers[ "language" ], "NUKE_FRIENDLY" ), ( 0.1, 0.1, 1 ), 3 );
	self thread notifyTeamLn( lua_getLocString( self.pers[ "language" ], "HARDPOINT_CALLED_BY" ), lua_getLocString( self.pers[ "language" ], "NUKE" ), self.name );
	
	thread playerDC( self );
	thread gameEnd();
	
	wait 3;
	
	direction = ( 0, randomInt( 360 ), 0 );
	
	trace = bulletTrace( level.heliCenterPoint + ( 0, 0, 600 ), level.heliCenterPoint + ( 0, 0, 60000 ), false, undefined );
	
	height = trace[ "position" ][ 2 ] - 200;
	
	trace = bulletTrace( level.heliCenterPoint + ( 0, 0, height ), level.heliCenterPoint - ( 0, 0, 60000 ), false, undefined );
	
	if( height - trace[ "position" ][ 2 ] > 2800 )
	{
		down = height - trace[ "position" ][ 2 ] - 2800;
		height -= down;
	}
	
	start = ( level.heliCenterPoint[ 0 ], level.heliCenterPoint[ 1 ], height );
	
	startPoint = start + anglestoforward( direction ) * 20000;
	endPosAir = start + anglestoforward( direction ) * 2000;
	
	
	level.tacticalNuke = spawn( "script_model", startPoint );
	nuke = level.tacticalNuke;
	nuke.owner = self;
	nuke setModel( "projectile_sa6_missile_woodland" );
	nuke.angles = VectorToAngles( endPosAir - nuke.origin );
	
	self thread trailFX();
	nuke playSound( "nuke_incoming" );
	
	nuke moveTo( endPosAir, 3.45 );
	
	wait 3.45;
	
	speed = 250;
	for( i = 0; i < 11; i++ )
	{
		angles = vectorToAngles( endPos - nuke.origin );
		
		nukePitch = nuke.angles[ 0 ];
		maxdiff = 10;
		
		if( abs( angles[ 0 ] - nukePitch ) > maxdiff )
		{
			if( abs( angles[ 0 ] - nukePitch ) > 180 )
			{
				if( angles[ 0 ] > nukePitch )
					angles = ( int( nukePitch - maxdiff + 360 ) % 360, angles[ 1 ], angles[ 2 ] );
				else
					angles = ( int( nukePitch + maxdiff ) % 360, angles[ 1 ], angles[ 2 ] );
			}
			else
			{
				if( angles[ 0 ] > nukePitch )
					angles = ( int( nukePitch + maxdiff ) % 360, angles[ 1 ], angles[ 2 ] );
				else
					angles = ( int( nukePitch - maxdiff + 360 ) % 360, angles[ 1 ], angles[ 2 ] );
			}
		}
		
		nuke.angles = angles;
		vector = anglesToForward( nuke.angles );
		forward = nuke.origin + ( vector[ 0 ] * speed, vector[ 1 ] * speed, vector[ 2 ] * speed );
		nuke moveTo( forward, .05 );
		
		wait .05;
	}
	
//	AmbientStop( 20 );
	
//	setExpFog( 50, 750, 230/255, 140/255, 60/255, 12 );
	
	wait .1;
	
	thread playSoundinSpace( "ac130_105mm_exp", endPos );
	playFx( level.hardEffects[ "nukeExp" ], endPos );
//	level thread ashFx();
	
	earthquake( 2, 2.5, endPos, 80000 );
//	PhysicsExplosionSphere( endPos, 25000, 5000, 5 );
	
	wait .05;
	
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
				nuke, 
				self, 
				64000,
				"MOD_PROJECTILE_SPLASH", 
				"artillery_mp", 
				endPos, 
				vectornormalize( endPos - ents[ i ].entity.origin ) 
			);
		}
	}
	
	nuke delete();
	
	level thread timedRestore();
	
	level notify( "nukeDone" );
}

timedRestore()
{
	wait 20;
	
	level.flyingPlane = undefined;
}

ashFx()
{
	self notify( "anotherAshFxThread" );
	self endon( "anotherAshFxThread" );
	
	
	locs = [];
	for( i = 0; i < 360; i += 90 )
		locs[ locs.size ] = ( level.heliCenterPoint[ 0 ] + ( 2048 * cos( i ) ),  level.heliCenterPoint[ 1 ] + ( 2048 * sin( i ) ), level.heliCenterPoint[ 2 ] );
	
	
	for( i = 0; i < 120; i++ )
	{
		playFx( level.hardEffects[ "nukeAsh" ], level.heliCenterPoint );
		for( n = 0; n < locs.size; n++ )
			playFx( level.hardEffects[ "nukeAsh" ], locs[ n ] );
		
		wait 0.5;
	}
}

gameEnd()
{
	level endon( "nukeDone" );
	
	level waittill( "game_ended" );
	
	if( isDefined( level.tacticalNuke ) )
		level.tacticalNuke delete();
		
	level.tacticalNuke = undefined;
	level.flyingPlane = undefined;
}

playerDC( player )
{
	level endon( "nukeDone" );
	level endon( "game_ended" );

	player waittill( "disconnect" );
	
	if( isDefined( level.tacticalNuke ) )
		level.tacticalNuke delete();

	level.flyingPlane = undefined;
	level.tacticalNuke = undefined;
}

trailFX()
{
	while( isDefined( level.tacticalNuke ) )
	{
		playFxonTag( level.hardEffects[ "hellfireGeo" ], level.tacticalNuke, "tag_fx" );
		wait 2;
	}
}