#include code\common;
#include maps\mp\_utility;

init()
{
	if( level.dvar[ "old_hardpoints" ] )
		self thread drop();
	
	if( !isDefined( level.chopper ) && !isDefined( level.mannedchopper ) )
	{
		self iPrintLnBold( "ASF reports no enemy chopper" );
		return false;
	}
	
	if( isDefined( level.chopper ) )
	{
		if( level.teambased && level.dvar[ "doubleHeli" ] && !isDefined( level.chopper[ level.otherTeam[ self.team ] ] ) )
		{
			self iPrintLnBold( "ASF reports no enemy chopper" );
			return false;
		}
		else if( level.teambased && !level.dvar[ "doubleHeli" ] && level.chopper.team == self.team )
		{
			self iPrintLnBold( "ASF reports no enemy chopper" );
			return false;
		}
		else if( !level.teambased && level.chopper.owner == self )
		{
			self iPrintLnBold( "ASF reports no enemy chopper" );
			return false;
		}
	}
	
	if( isDefined( level.mannedchopper ) && level.mannedchopper.team == self.team && level.teambased )
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
	thread destroyPlane();
	
	if( !level.teamBased || !level.dvar[ "doubleHeli" ] )
	{
		if( isDefined( level.chopper ) )
			chopper = level.chopper;
		else
			chopper = level.mannedchopper;
	}
	else
	{
		if( isDefined( level.mannedchopper ) )
			chopper = level.mannedchopper;
		else
			chopper = level.chopper[ level.otherTeam[ self.team ] ];
	}

	self thread heliLeave( chopper );
	pathStart = chopper.origin + vector_scale( anglesToForward( chopper.angles ), 50000 );
	pathStart = ( pathStart[ 0 ], pathStart[ 1 ], chopper.origin[ 2 ] );

	
	level.plane[ "plane" ] = spawnplane( self, "script_model", pathStart );
	level.plane[ "plane" ] setModel( "vehicle_mig29_desert" );
	level.plane[ "plane" ].angles = VectorToAngles( chopper.origin - level.plane[ "plane" ].origin );
	level.plane[ "missile" ] = spawn( "script_model", level.plane[ "plane" ].origin );
	level.plane[ "missile" ] setModel( "projectile_hellfire_missile" );
	level.plane[ "missile" ] linkTo( level.plane[ "plane" ], "tag_left_wingtip" );
	thread callStrike_planeSound_credit( level.plane[ "plane" ], chopper.origin );
	
	for( ;; )
	{
		level.plane[ "plane" ].angles = VectorToAngles( chopper.origin - level.plane[ "plane" ].origin );
		vector = anglesToForward( level.plane[ "plane" ].angles );
		forward = level.plane[ "plane" ].origin + ( vector[ 0 ] * 1600, vector[ 1 ] * 1600, vector[ 2 ] * 1600 );
		level.plane[ "plane" ] moveTo( forward, .25 );
		
		wait .25;
		
		if( distanceSquared( level.plane[ "plane" ].origin, chopper.origin ) < 16000000 )
		{
			if( isDefined( level.mannedchopper ) )
				level.mannedchopper.owner thread code\heli::warning();
			self thread launchAA( chopper );
			break;
		}
	}
	
	level.plane[ "plane" ].angles = level.plane[ "plane" ].angles + ( 0, 0, 45 );
	
	for( i = 0; i < 20; i++ )
	{
		angles = level.plane[ "plane" ].angles;
		level.plane[ "plane" ].angles = ( angles[ 0 ] - 0.1, angles[ 1 ] - 8, angles[ 2 ] );
		vector = anglesToForward( level.plane[ "plane" ].angles );
		forward = level.plane[ "plane" ].origin + ( vector[ 0 ] * 280, vector[ 1 ] * 280, vector[ 2 ] * 280 );
		level.plane[ "plane" ] moveTo( forward, .05 );
		
		wait .05;
	}
	
	level.plane[ "plane" ].angles = level.plane[ "plane" ].angles - ( 0, 0, 45 );
	vector = anglesToForward( level.plane[ "plane" ].angles );
	forward = level.plane[ "plane" ].origin + ( vector[ 0 ] * 200000, vector[ 1 ] * 200000, vector[ 2 ] * 200000 );
	level.plane[ "plane" ] moveTo( forward, 12 );
	
			 // For manned chopper missile exp must terminate it
	wait 12; // heliLeave function will terminate the killstreak, this is just safety net incase missile goes all batshit crazy
	
	thread finish();
}

heliLeave( chopper )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	if( isDefined( level.mannedchopper ) )
		chopper common_scripts\utility::waittill_any( "ASFsafetynet", "heliEnd" );
	else
		chopper common_scripts\utility::waittill_any( "death", "crashing", "leaving", "helicopter gone", "ASFsafetynet" );
	level.plane[ "plane" ] notify("del");
	self thread finish();
}

finish()
{
	level notify( "flyOver" );

	level.flyingplane = undefined;
	level.missileLaunched = undefined;
	level notify( "flyOverDC" );
}

launchAA( ent )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	level.missileLaunched = true;
	counterNum = undefined;
	
	level.plane[ "missile" ] unLink();
	self thread trailFX();
	
	if( isDefined( level.counterMeasures ) )
	{
		counterNum = randomInt( 5 );
	}
	
	for( ;; )
	{
		if( !isDefined( level.counterMeasuresInAir ) || !isDefined( level.counterMeasures )  )
		{
			level.plane[ "missile" ].angles = VectorToAngles( ( ent.origin - ( 0, 0, 64 ) ) - level.plane[ "missile" ].origin );
			vector = anglesToForward( level.plane[ "missile" ].angles );
			forward = level.plane[ "missile" ].origin + ( vector[ 0 ] * 85, vector[ 1 ] * 85, vector[ 2 ] * 85 );
			collision = bulletTrace( level.plane[ "missile" ].origin, forward, false, self );
			level.plane[ "missile" ] moveTo( forward, .05 );
			
			if( collision[ "surfacetype" ] != "default" && collision[ "fraction" ] < 1 )
			{
				thread playSoundinSpace( "grenade_explode_default", level.plane[ "missile" ].origin );
				PlayFX( level.chopper_fx["explode"]["large"], level.plane[ "missile" ].origin );
				level.missileLaunched = undefined;
				if( !isDefined( level.mannedchopper ) )
					ent.damageTaken = ent.maxHealth + 1;
				else
				{
					if( isDefined( level.mannedchopper.playerInside ) )
					{
						level.mannedchopper.owner.sWeaponForKillcam = "ASF";
						level.mannedchopper.owner restoreHP();
						level.mannedchopper.owner thread [[level.callbackPlayerDamage]](
																						level.plane[ "missile" ],
																						self, 
																						1000000,
																						0,
																						"MOD_PROJECTILE_SPLASH", 
																						"artillery_mp", 
																						level.plane[ "missile" ].origin,
																						vectornormalize( level.plane[ "missile" ].origin - level.mannedchopper.owner.origin ),
																						"none",
																						0 
																						);
					}
					level.mannedchopper.damageTaken = level.mannedchopper.maxHealth;
				}
				self notify( "destroyed_helicopter" );
				self thread finish();
				break;
			}
		}
		
		else
		{
			if( !isDefined( counterNum ) )
				counterNum = randomInt( 5 );
			
			level.plane[ "missile" ].angles = VectorToAngles( level.counterMeasures[ counterNum ].origin - level.plane[ "missile" ].origin );
			vector = anglesToForward( level.plane[ "missile" ].angles );
			forward = level.plane[ "missile" ].origin + ( vector[ 0 ] * 85, vector[ 1 ] * 85, vector[ 2 ] * 85 );
			level.plane[ "missile" ] moveTo( forward, .05 );
			
			if( abs( distanceSquared( level.counterMeasures[ counterNum ].origin, level.plane[ "missile" ].origin ) ) < 10000 )
			{
				thread playSoundinSpace( "grenade_explode_default", level.plane[ "missile" ].origin );
				PlayFX( level.chopper_fx["explode"]["large"], level.plane[ "missile" ].origin );
				level.missileLaunched = undefined;
				dist = distance( level.plane[ "missile" ].origin, level.mannedchopper.origin );
				damage = 0;
				
				if( dist < 1000 )
				{
					damage = level.mannedchopper.maxHealth / ( dist / 20 );
					level.mannedchopper.owner.heliHud[ 5 ] setValue( int( level.mannedchopper.maxHealth - level.mannedchopper.damageTaken - damage ) );
				}
				
				if( level.mannedchopper.damageTaken + damage >= level.mannedchopper.maxHealth )
				{
					if( isDefined( level.mannedchopper.playerInside ) )
					{
						level.mannedchopper.owner.sWeaponForKillcam = "ASF";
						level.mannedchopper.owner restoreHP();
						level.mannedchopper.owner thread [[level.callbackPlayerDamage]](
																						level.plane[ "missile" ],
																						self, 
																						1000000,
																						0,
																						"MOD_PROJECTILE_SPLASH", 
																						"artillery_mp", 
																						level.plane[ "missile" ].origin,
																						vectornormalize( level.plane[ "missile" ].origin - level.mannedchopper.owner.origin ),
																						"none",
																						0 
																						);
					}
					
					level.mannedchopper.damageTaken = level.mannedchopper.maxHealth;
					
					r = 0.0 + ( level.mannedchopper.damageTaken / level.mannedchopper.maxHealth );
					g = 1.0 - ( level.mannedchopper.damageTaken / level.mannedchopper.maxHealth );
					
					level.mannedchopper.owner.heliHud[ 5 ].color = ( r, g, 0.0 );
					self notify( "destroyed_helicopter" );
				}
				else
				{
					level.mannedchopper.damageTaken += damage;
					
					r = 0.0 + ( level.mannedchopper.damageTaken / level.mannedchopper.maxHealth );
					g = 1.0 - ( level.mannedchopper.damageTaken / level.mannedchopper.maxHealth );
					
					level.mannedchopper.owner.heliHud[ 5 ].color = ( r, g, 0.0 );
				}
				
				self thread finish();
				break;
			}
		}
		
		wait .05;
	}
	
	if( isDefined( level.plane[ "missile" ] ) )
		level.plane[ "missile" ] delete();
}

trailFX( )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );

	while( isDefined( level.missileLaunched ) )
	{
		playFxonTag( level.hardEffects[ "hellfireGeo" ], level.plane[ "missile" ], "tag_origin" );
		
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

drop()
{
	self endon( "disconnect" );
	
	waittillframeend;
	
	if( isDefined( level.flyingPlane ) )
		return;
	
	self iPrintLnBold( "If you'd like to drop this hardpoint hold [{+activate}] for 2 seconds!" );
	
	time = 6 * 20;
	hold = 0;
	
	while( time > 0 )
	{
		while( self useButtonPressed() )
		{
			hold++;
			wait .1;
			
			if( hold >= 20 )
			{
				self takeWeapon( "radar_mp" );
				self setActionSlot( 4, "" );
				self.pers["hardPointItem"] = undefined;
				time = 0;
				break;
			}
		}
		hold = 0;
		wait .05;
	}
}
