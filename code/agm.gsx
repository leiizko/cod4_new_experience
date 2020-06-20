#include code\common;

init()
{
	if( isDefined( level.flyingPlane ) )
	{
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "HARDPOINT_NOT_AVAILABLE" ), lua_getLocString( self.pers[ "language" ], "AGM" ) );
		return false;
	}
	
	if( self isProning() )
	{
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "HARDPOINT_MUST_STAND" ) );
		return false;
	}
	
	level.flyingPlane = true;
	
	self thread setup();
	
	if( isDefined( self.moneyhud ) )
		self.moneyhud destroy();
	
	return true;
}

setup()
{
	self thread notifyTeamLn( lua_getLocString( self.pers[ "language" ], "HARDPOINT_CALLED_BY" ), lua_getLocString( self.pers[ "language" ], "AGM" ), self.name );
	
	waittillframeend;
	
	self hide();
	
	waittillframeend;
	
	thread onPlayerDisconnect( self );
	self thread onGameEnd( ::endHardpoint );
	self thread onPlayerDeath( ::endHardpoint );
	
	waittillframeend;
	
	self thread godMod();
	self setClientDvar( "ui_hud_hardcore", 1 );
	
	waittillframeend;
	
	self.oldPosition = self getOrigin();
	self thread planeSetup_2();
	
	waittillframeend;
	
	self disableWeapons();
	self freezeControls( true );
}

planeSetup_2()
{
	self endon( "disconnect" );
	level endon( "flyOver" );
	
	level thread destroyPlane();

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
	
	trace = bulletTrace( start, start + anglestoforward( direction ) * -1 * 12000, false, undefined );
	
	startPoint = trace[ "position" ] + anglestoforward( direction ) * 700;
	
	trace = bulletTrace( start, start + anglestoforward( direction ) * 12000, false, undefined );

	endPoint = trace[ "position" ] + anglestoforward( direction ) * 700 * -1;
	
	planeFlySpeed = 2000;
	d = length( startPoint - endPoint );
	flyTime = ( d / planeFlySpeed );
	
	level.plane = [];
	level.plane[ "plane" ] = spawn( "script_model", startPoint );
	level.plane[ "plane" ] setModel( "vehicle_mig29_desert" );
	level.plane[ "plane" ].angles = direction;
	
	thread playPlaneFx();
	thread callStrike_planeSound_credit( level.plane[ "plane" ], level.heliCenterPoint );
	
	self.HCCam = spawn( "script_model", level.plane[ "plane" ].origin );
	self.HCCam setModel( "tag_origin" );
	self.HCCam hide();
	self.HCCam.angles = direction;
	
	offset = ( -500, 0, 25 );
	self.HCCam linkTo( level.plane[ "plane" ], "tag_origin", offset, ( 0, 0, 0 ) );
	
	self linkTo( self.HCCam, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	self setPlayerAngles( self.HCCam.angles );
	
	level.plane[ "missile" ] = spawn( "script_model", self.origin );
	level.plane[ "missile" ] setModel( "projectile_hellfire_missile" );
	level.plane[ "missile" ] linkTo( level.plane[ "plane" ], "tag_right_aphid_missile", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	level.plane[ "missile" ].angles = direction;
	
	level.plane[ "plane" ] moveTo( endPoint, flyTime );
	
	while( 1 )
	{
		if( distance2D( level.heliCenterPoint, level.plane[ "plane" ].origin ) < 1250 )
			break;
			
		wait .05;
	}
	
	self thread launchMissile();
}

launchMissile()
{
	self endon( "disconnect" );
	level endon( "flyOver" );
	
	level.AGMLaunchTime[ self getEntityNumber() ] = getTime();
	
	level.plane[ "missile" ] unLink();
	level.plane[ "missile" ].origin = level.plane[ "plane" ] getTagOrigin( "tag_right_aphid_missile" );
	
	wait .05;
	
	level.missileLaunched = true;
	
	pos = level.plane[ "missile" ].origin + ( 0, 0, -60 ) + anglesToForward( level.plane[ "missile" ].angles ) * 120;
	level.plane[ "missile" ] moveTo( pos, .25 );
	
	offset = ( -100, 0, 0 );
	self.HCCam linkTo( level.plane[ "missile" ], "tag_origin", offset, ( 0, 0, 0 ) );
	self.HCCam.angles = level.plane[ "missile" ].angles;
	self setPlayerAngles( self.HCCam.angles );
	
	wait .25;
	
	speed = 40;
	ticks = 20;
	
	pos = level.plane[ "missile" ].origin + anglesToForward( level.plane[ "missile" ].angles ) * ( ticks * speed );
	level.plane[ "missile" ] moveTo( pos, ( ticks * 0.05 ) );
	
	//level.plane[ "missile" ] playSound( "agm_burst" );
	level.plane[ "missile" ] playSound( "weap_cobra_missile_fire" );
	thread trailfx();
	
	wait ( ticks * 0.05 );
	
	for( i = 0; i < 6; i++ )
	{
		angles = level.plane[ "missile" ].angles;
		level.plane[ "missile" ].angles = ( angles[ 0 ] + 10, angles[ 1 ], angles[ 2 ] );
		forward = level.plane[ "missile" ].origin + anglesToForward( level.plane[ "missile" ].angles ) * speed;
		level.plane[ "missile" ] moveTo( forward, .1 );
		
		self.HCCam.angles = level.plane[ "missile" ].angles;
		
		if( i == 4 )
		{
			self setPlayerAngles( level.plane[ "missile" ].angles );
			self setClientDvar( "cg_fovscale", "0.75" );
			self thread initialVisionSettings();
			
			waittillframeend;
			
			self thread hudLogic( "normal" );
			self thread targetMarkers();
			self freezeControls( false );
			
			self unLink();
			self LinkTo( level.plane[ "missile" ], "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
		}
		
		wait .1;
	}
	
	waittillframeend;
	self.HCCam delete();
	canSpeedUp = 1;
	
	self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "AGM_SPEED_UP" ) );
	
	for( ;; )
	{
		if( canSpeedUp && self attackButtonPressed() )
		{
			canSpeedUp = 0;
			speed = 120;
		}
		angles = self getPlayerAngles();
		if( angles[ 0 ] <= 20 )
			self setPlayerAngles( ( 20, angles[1], angles[2] ) );
			
		level.plane[ "missile" ].angles = angles;
		vector = anglesToForward( level.plane[ "missile" ].angles );
		forward = level.plane[ "missile" ].origin + ( vector[ 0 ] * speed, vector[ 1 ] * speed, vector[ 2 ] * speed );
		collision = bulletTrace( level.plane[ "missile" ].origin, forward, false, self );
		level.plane[ "missile" ] moveTo( forward, .05 );
		
		if( collision[ "surfacetype" ] != "default" && collision[ "fraction" ] < 1 ) 
		{
			level.missileLaunched = undefined;
			target = collision[ "position" ];
			self unlink();
			self setOrigin( self.oldPosition );
			level.AGMLaunchTime[ self getEntityNumber() ] = getTime() - level.AGMLaunchTime[ self getEntityNumber() ];
			wait .05;
			thread explodeAGM( target );
			wait .1;
			thread endHardpoint();
			break;
		}
		
		if( ( self.oldPosition[ 2 ] - 800 ) > level.plane[ "missile" ].origin[ 2 ] ) //in case missile goes under map
		{
			level.missileLaunched = undefined;
			target = level.plane[ "missile" ].origin;
			self unlink();
			self setOrigin( self.oldPosition );
			level.AGMLaunchTime[ self getEntityNumber() ] = getTime() - level.AGMLaunchTime[ self getEntityNumber() ];
			wait .05;
			thread explodeAGM( target );
			wait .1;
			thread endHardpoint();
			break;
		}
		
		wait .05;
	}
}

trailFX()
{
	level endon( "flyOver" );
	
	wait .05;

	while( isDefined( level.missileLaunched ) )
	{
		playFxonTag( level.hardEffects[ "hellfireGeo" ], level.plane[ "missile" ], "tag_fx" );
		
		wait 2;
	}
}

playPlaneFx()
{
	level endon( "flyOver" );
	
	wait .05;

	while( isDefined( level.plane[ "plane" ] ) )
	{
		playfxontag( level.fx_airstrike_afterburner, level.plane[ "plane" ], "tag_engine_right" );
		playfxontag( level.fx_airstrike_afterburner, level.plane[ "plane" ], "tag_engine_left" );
		playfxontag( level.fx_airstrike_contrail, level.plane[ "plane" ], "tag_right_wingtip" );
		playfxontag( level.fx_airstrike_contrail, level.plane[ "plane" ], "tag_left_wingtip" );
		
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
	wait .4;
	plane notify ( "stop sound" + "veh_mig29_dist_loop" );
}

explodeAGM( target )
{
	if( !isDefined( target ) && isDefined( level.plane ) && isDefined( level.plane[ "missile" ] ) )
		target = level.plane[ "missile" ].origin;

	if( isDefined( target ) )
	{
		thread playSoundinSpace( "agm_exp", target );
		PlayFX( level.hardEffects[ "tankerExp" ], target );
		
		ents = maps\mp\gametypes\_weapons::getDamageableents( target, 400 );
		for( i = 0; i < ents.size; i++ )
		{
			if ( !ents[ i ].isPlayer || isAlive( ents[ i ].entity ) )
			{
				if( !isDefined( ents[ i ] ) )
					continue;
					
				if( ents[ i ].entity sightConeTrace( target, ents[ i ].entity ) < 0.1 )
					continue;
				
				if( isPlayer( ents[ i ].entity ) )
					ents[ i ].entity.sWeaponForKillcam = "agm";

				ents[ i ] maps\mp\gametypes\_weapons::damageEnt(
																self, 
																self, 
																2500, 
																"MOD_PROJECTILE_SPLASH", 
																"artillery_mp", 
																target, 
																vectornormalize( target - ents[ i ].entity.origin ) 
																);
			}
		}
		
		earthquake( 3, 1.2, target, 700 );
	}

	if( isDefined( level.plane ) && isDefined( level.plane[ "missile" ] ) )
		level.plane[ "missile" ] delete();
}

endHardpoint()
{
	self endon( "disconnect" );
	level notify( "flyOver" );
	
	waittillframeend;
	
	level.missileLaunched = undefined;
	self.oldPosition = undefined;
	
	if( !level.dvar[ "old_hardpoints" ] )
		self thread code\hardpoints::moneyHud();
	
	waittillframeend;
	
	self thread restoreHP();
	self show();
	self enableWeapons();
	self thread clearHUD();
	
	waittillframeend;
	
	
	self thread restoreVisionSettings();
	
	wait .1;
	
	level.flyingPlane = undefined;
	level notify( "flyOverDC" );
}