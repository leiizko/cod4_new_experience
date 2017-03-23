#include code\common;
#include maps\mp\_utility;

init()
{
	if( !isDefined( level.chopper ) && !isDefined( level.mannedchopper ) )
	{
		self iPrintLnBold( "ASF reports no enemy chopper" );
		return false;
	}
	
	if( isDefined( level.chopper ) && level.chopper.team == self.team )
	{
		self iPrintLnBold( "ASF reports no enemy chopper" );
		return false;
	}
	
	if( isDefined( level.mannedchopper ) && level.mannedchopper.team == self.team )
	{
		self iPrintLnBold( "ASF reports no enemy chopper" );
		return false;
	}
	
	if( isDefined( level.flyingplane ) )
	{
		self iPrintLnBold( "Air Superiority Fighter not available" );
		return false;
	}
	
	level.flyingPlane = true;
	
	self thread setup();
	
	return true;
}

setup()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	thread onPlayerDisconnect( self );
	self thread onGameEnd( ::finish );
	
	if( isDefined( level.chopper ) )
	{
		self thread heliLeave();
		pathStart = level.chopper.origin + vector_scale( anglesToForward( level.chopper.angles ), 50000 );
		pathStart = ( pathStart[ 0 ], pathStart[ 1 ], level.chopper.origin[ 2 ] );
		ent = level.chopper;
	}
	else
	{
		self thread mannedHeliLeave();
		pathStart = level.mannedchopper.origin + vector_scale( anglesToForward( level.mannedchopper.angles ), 50000 );
		pathStart = ( pathStart[ 0 ], pathStart[ 1 ], level.mannedchopper.origin[ 2 ] );
		ent = level.mannedchopper;
	}
	
	self.plane = spawnplane( self, "script_model", pathStart );
	self.plane setModel( "vehicle_mig29_desert" );
	self.plane.angles = VectorToAngles( ent.origin - self.plane.origin );
	self.missile = spawn( "script_model", self.plane.origin );
	self.missile setModel( "projectile_hellfire_missile" );
	self.missile linkTo( self.plane, "tag_left_wingtip" );
	thread callStrike_planeSound_credit( self.plane, ent.origin );
	
	for( ;; )
	{
		self.plane.angles = VectorToAngles( ent.origin - self.plane.origin );
		vector = anglesToForward( self.plane.angles );
		forward = self.plane.origin + ( vector[ 0 ] * 1600, vector[ 1 ] * 1600, vector[ 2 ] * 1600 );
		self.plane moveTo( forward, .25 );
		
		wait .25;
		
		if( distanceSquared( self.plane.origin, ent.origin ) < 16000000 )
		{
			if( isDefined( level.mannedchopper ) )
				level.mannedchopper.owner thread code\heli::warning();
			self thread launchAA( ent );
			break;
		}
	}
	
	self.plane.angles = self.plane.angles + ( 0, 0, 45 );
	
	for( i = 0; i < 20; i++ )
	{
		angles = self.plane.angles;
		self.plane.angles = ( angles[ 0 ] - 0.1, angles[ 1 ] - 8, angles[ 2 ] );
		vector = anglesToForward( self.plane.angles );
		forward = self.plane.origin + ( vector[ 0 ] * 280, vector[ 1 ] * 280, vector[ 2 ] * 280 );
		self.plane moveTo( forward, .05 );
		
		wait .05;
	}
	
	self.plane.angles = self.plane.angles - ( 0, 0, 45 );
	vector = anglesToForward( self.plane.angles );
	forward = self.plane.origin + ( vector[ 0 ] * 200000, vector[ 1 ] * 200000, vector[ 2 ] * 200000 );
	self.plane moveTo( forward, 12 );
	
			 // For manned chopper missile exp must terminate it
	wait 12; // heliLeave function will terminate the killstreak, this is just safety net incase missile goes all batshit crazy
	
	thread finish();
}

heliLeave()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	level.chopper common_scripts\utility::waittill_any( "death", "crashing", "leaving", "helicopter gone", "ASFsafetynet" );
	self.plane notify("del");
	self thread finish();
}

mannedHeliLeave()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	level.mannedchopper common_scripts\utility::waittill_any( "ASFsafetynet", "heliEnd" );
	self.plane notify("del");
	self thread finish();
}

finish()
{
	level notify( "flyOver" );
	
	self.plane notify("del");
	
	wait .2;
	
	if( isDefined( self.plane ) )
		self.plane delete();

	level.flyingplane = undefined;
	
	if( isDefined( self.missile ) )
		self.missile delete();
		
	level.missileLaunched = undefined;
}

launchAA( ent )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	level.missileLaunched = true;
	counterNum = undefined;
	
	self.missile unLink();
	self thread trailFX();
	
	if( isDefined( level.counterMeasures ) )
	{
		counterNum = randomInt( 5 );
	}
	
	for( ;; )
	{
		if( !isDefined( level.counterMeasuresInAir ) || !isDefined( level.counterMeasures )  )
		{
			self.missile.angles = VectorToAngles( ( ent.origin - ( 0, 0, 64 ) ) - self.missile.origin );
			vector = anglesToForward( self.missile.angles );
			forward = self.missile.origin + ( vector[ 0 ] * 85, vector[ 1 ] * 85, vector[ 2 ] * 85 );
			collision = bulletTrace( self.missile.origin, forward, false, self );
			self.missile moveTo( forward, .05 );
			
			if( collision[ "surfacetype" ] != "default" && collision[ "fraction" ] < 1 )
			{
				thread playSoundinSpace( "grenade_explode_default", self.missile.origin );
				PlayFX( level.chopper_fx["explode"]["large"], self.missile.origin );
				level.missileLaunched = undefined;
				if( !isDefined( level.mannedchopper ) )
					level.chopper.damageTaken = level.chopper.maxHealth + 1;
				else
				{
					level.mannedchopper.damageTaken = level.mannedchopper.maxHealth;
					if( isDefined( level.mannedchopper.playerInside ) )
						level.mannedchopper.owner thread [[level.callbackPlayerDamage]](
																						self.missile,
																						self, 
																						1000000,
																						0,
																						"MOD_PROJECTILE_SPLASH", 
																						"artillery_mp", 
																						self.missile.origin,
																						vectornormalize( self.missile.origin - level.mannedchopper.owner.origin ),
																						"none",
																						0 
																						);
				}
				self notify( "destroyed_helicopter" );
				break;
			}
		}
		
		else
		{
			if( !isDefined( counterNum ) )
				counterNum = randomInt( 5 );
			
			self.missile.angles = VectorToAngles( level.counterMeasures[ counterNum ].origin - self.missile.origin );
			vector = anglesToForward( self.missile.angles );
			forward = self.missile.origin + ( vector[ 0 ] * 85, vector[ 1 ] * 85, vector[ 2 ] * 85 );
			self.missile moveTo( forward, .05 );
			
			if( abs( distanceSquared( level.counterMeasures[ counterNum ].origin, self.missile.origin ) ) < 10000 )
			{
				thread playSoundinSpace( "grenade_explode_default", self.missile.origin );
				PlayFX( level.chopper_fx["explode"]["large"], self.missile.origin );
				level.missileLaunched = undefined;
				dist = distance( self.missile.origin, level.mannedchopper.origin );

				if( dist < 500 )
				{
					level.mannedchopper.damageTaken += level.mannedchopper.maxHealth / ( dist / 20 );
					level.mannedchopper.owner.heliHud[ 5 ] setValue( int( level.mannedchopper.maxHealth - level.mannedchopper.damageTaken ) );
					
					if( level.mannedchopper.damageTaken > level.mannedchopper.maxHealth )
						level.mannedchopper.damageTaken = level.mannedchopper.maxHealth;
					
					r = 0.0 + ( level.mannedchopper.damageTaken / level.mannedchopper.maxHealth );
					g = 1.0 - ( level.mannedchopper.damageTaken / level.mannedchopper.maxHealth );
					
					level.mannedchopper.owner.heliHud[ 5 ].color = ( r, g, 0.0 );
				}
				if( level.mannedchopper.damageTaken >= level.mannedchopper.maxHealth )
				{
					if( isDefined( level.mannedchopper.playerInside ) )
						level.mannedchopper.owner thread [[level.callbackPlayerDamage]](
																						self.missile,
																						self, 
																						1000000,
																						0,
																						"MOD_PROJECTILE_SPLASH", 
																						"artillery_mp", 
																						self.missile.origin,
																						vectornormalize( self.missile.origin - level.mannedchopper.owner.origin ),
																						"none",
																						0 
																						);
					self notify( "destroyed_helicopter" );
				}
				self thread finish();
				break;
			}
		}
		
		wait .05;
	}
	
	if( isDefined( self.missile ) )
		self.missile delete();
}

trailFX( )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );

	while( isDefined( level.missileLaunched ) )
	{
		playFxonTag( level.hardEffects[ "hellfireGeo" ], self.missile, "tag_origin" );
		
		wait 2;
	}
}

callStrike_planeSound_credit( plane, bombsite )
{
	level endon( "flyOver" );
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