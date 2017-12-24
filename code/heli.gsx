#include maps\mp\_utility;

init()
{
	if( isDefined( level.chopper ) || isDefined( level.mannedchopper ) )
	{
		self iPrintLnBold( "MANNED HELICOPTER not available!" );
		return false;
	}
	
	if( isDefined( level.tacticalNuke ) )
	{
		self iPrintLnBold( "MANNED HELICOPTER not available due to radiation!" );
		return false;
	}
	
	if( self isProning() )
	{
		self iPrintLnBold( "You must stand to use this hardpoint!" );
		return false;
	}
	
	if( !isDefined( level.heliDistanceMax ) || level.heliDistanceMax == 0 )
	{
		self iPrintLnBold( "MANNED HELICOPTER not available this match!" );
		print( "\n********** ERROR **********\n" );
		print( "Heli map plot was not successful, possible unsuported map. Terminating hardpoint!\n\n" );
		return false;
	}
	
	self thread setup();
	
	if( isDefined( self.moneyhud ) )
		self.moneyhud destroy();
	
	return true;
}

setup()
{
	self endon( "disconnect" );
	
	self thread code\common::notifyTeam( "FRIENDLY MANNED HELI INBOUND!", ( 0.1, 0.1, 1 ), 3 );
	self thread code\common::notifyTeamLn( "Friendly MANNED HELI called by^1 " + self.name );

	heliOrigin = self.origin + ( 0, 0, 1000 );
	heliAngles = self.angles;
	
	if( self.team == "allies" )
	{
		chopper = spawnHelicopter( self, heliOrigin, heliAngles, "cobra_mp", "vehicle_cobra_helicopter_fly" );
		chopper playLoopSound( "mp_cobra_helicopter" );
	}
	else
	{
		chopper = spawnHelicopter( self, heliOrigin, heliAngles, "cobra_mp", "vehicle_mi24p_hind_desert" );
		chopper playLoopSound( "mp_hind_helicopter" );
	}
	
	cockpit = spawn( "script_model", chopper.origin );
	cockpit setModel( "projectile_m203grenade" );
	cockpit hide();
	
	gunner = spawn( "script_model", chopper.origin );
	gunner setModel( "projectile_m203grenade" );
	gunner hide();
	
	if( self.team == "allies" )
	{
		//cockpit linkTo( chopper, "tag_store_r_2", ( 115, 40, 980 ), ( 0, 0, 0 ) );
		cockpit linkTo( chopper, "tag_store_r_2", ( 115, 40, -20 ), ( 0, 0, 0 ) );
		gunner linkTo( chopper, "tag_store_r_2", ( 90, 40, -90 ), ( 0, 0, 0 ) );
	}
	else
	{
		//cockpit linkTo( chopper, "tag_store_r_2", ( 192, 102, 960 ), ( 0, 0, 0 ) );
		cockpit linkTo( chopper, "tag_store_r_2", ( 192, 102, -40 ), ( 0, 0, 0 ) );
		gunner linkTo( chopper, "tag_store_r_2", ( 165, 102, -105 ), ( 0, 0, 0 ) );
	}
	
	self.oldPosition = self.origin;
	
	chopper.maxHealth = 2000 + ( level.players.size * 200 );
	chopper.health_low = 800;
	chopper.currentstate = "ok";
	chopper.evasive = false;
	chopper.health_evasive = false;
	chopper.missile_ammo = 8; // Clip size, gotta reload after depleted
	chopper.timeLeft = 120;
	chopper.flares = 1;
	chopper.owner = self;
	chopper.playerInside = true;
	chopper setSpeed( 100, 20 );
	chopper setAirResistance( 160 );
	chopper.team = self.team;
	chopper.pers[ "team" ] = self.team;
	chopper.loopcount = 0; 
	chopper.attacker = undefined;
	chopper.waittime = level.heli_dest_wait;
	chopper setHoverParams( 0, 0, 0 );
	chopper.angles = self.angles;
	
	self linkTo( cockpit, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	
	level.heliCockpit = cockpit;
	level.gunnerCockpit = gunner;
	
	level.mannedchopper = chopper;
	
	self thread HudStuff();
	
	self disableWeapons();
	
	chopper thread playerDC( self );
	chopper thread onGameEnd();
	chopper thread damageMonitor();
	chopper thread heliHealth();
	
	self thread yaw();
	self thread flyControls();
	self thread fireControls();
	self thread miscStuff();
	self thread death();
	self thread emergency();
	
	self setClientDvars( "cg_fovscale", 1.25,
						 "cg_fov", 80,
						 "g_compassshowenemies", 1,
						 "ui_hud_hardcore", 1 );
}

HudStuff()
{
	self endon( "disconnect" );
	level.mannedchopper endon( "heliEnd" );
	
	n = 0;
	
	self.heliHud[ n ] = newClientHudElem(self);
	self.heliHud[ n ].elemType = "font";
	self.heliHud[ n ].x = -32;
	self.heliHud[ n ].y = -45;
	self.heliHud[ n ].alignX = "center";
	self.heliHud[ n ].alignY = "bottom";
	self.heliHud[ n ].horzAlign = "center";
	self.heliHud[ n ].vertAlign = "bottom";
	self.heliHud[ n ] setText("^1Fly time left:");
	self.heliHud[ n ].color = (0.0, 0.8, 0.0);
	self.heliHud[ n ].fontscale = 1.4;
	self.heliHud[ n ].archived = 0;
	
	n = 1;
	
	self.heliHud[ n ] = newClientHudElem( self );
	self.heliHud[ n ].elemType = "font";
	self.heliHud[ n ].x = 32;
	self.heliHud[ n ].y = -45;
	self.heliHud[ n ].alignX = "center";
	self.heliHud[ n ].alignY = "bottom";
	self.heliHud[ n ].horzAlign = "center";
	self.heliHud[ n ].vertAlign = "bottom";
	self.heliHud[ n ] setTimer( int( level.mannedchopper.timeLeft ) );
	self.heliHud[ n ].color = ( 1.0, 0.0, 0.0 );
	self.heliHud[ n ].fontscale = 1.4;
	self.heliHud[ n ].archived = 0;
	
	n = 2;
	
	self.heliHud[ n ] = newClientHudElem( self );
	self.heliHud[ n ].archived = false;
	self.heliHud[ n ].alignX = "right";
	self.heliHud[ n ].alignY = "bottom";
	self.heliHud[ n ].label = &"Rockets: ";
	self.heliHud[ n ].horzAlign = "right";
	self.heliHud[ n ].vertAlign = "bottom";
	self.heliHud[ n ].fontscale = 1.7;
	self.heliHud[ n ].x = -20;
	self.heliHud[ n ].y = -40;
	self.heliHud[ n ] setValue( int( level.mannedchopper.missile_ammo ) );
	self.heliHud[ n ].archived = 0;
	
	n = 3;
	
	self.heliHud[ n ] = newClientHudElem( self );
	self.heliHud[ n ].elemType = "font";
	self.heliHud[ n ].x = 0;
	self.heliHud[ n ].y = 20;
	self.heliHud[ n ].alignX = "center";
	self.heliHud[ n ].alignY = "top";
	self.heliHud[ n ].horzAlign = "center";
	self.heliHud[ n ].vertAlign = "top";
	self.heliHud[ n ] setText( "^1[{+attack}] ^7to ^1fire^7 minigun, ^2[{+toggleads_throw}] ^7to ^2fire rockets^7, ^1[{+forward}], [{+back}], [{+moveleft}], [{+moveright}] ^7to ^1pilot \nthe helicopter^7, ^2[{+gostand}] ^7to ^2climb up, ^3[{+breath_sprint}] ^7to ^3climb down," );
	//self.heliHud[ n ].color = ( 0.0, 0.8, 0.0 );
	self.heliHud[ n ].fontscale = 1.4;
	self.heliHud[ n ].archived = 0;
	
	n = 4;
	
	self.heliHud[ n ] = newClientHudElem( self );
	self.heliHud[ n ].elemType = "font";
	self.heliHud[ n ].x = 0;
	self.heliHud[ n ].y = 53;
	self.heliHud[ n ].alignX = "center";
	self.heliHud[ n ].alignY = "top";
	self.heliHud[ n ].horzAlign = "center";
	self.heliHud[ n ].vertAlign = "top";
	self.heliHud[ n ] setText( "^1[{+activate}] ^7to ^1freeze helicopter angle, ^2[{+melee}] ^7to ^2change gunner view^7, ^3[{+frag}] ^7to ^3pop flares, ^1[{+leanright}] ^7to ^1eject!" );
	//self.heliHud[ n ].color = ( 0.0, 0.8, 0.0 );
	self.heliHud[ n ].fontscale = 1.4;
	self.heliHud[ n ].archived = 0;
	
	n = 5;
	
	self.heliHud[ n ] = newClientHudElem( self );
	self.heliHud[ n ].archived = false;
	self.heliHud[ n ].alignX = "right";
	self.heliHud[ n ].alignY = "bottom";
	self.heliHud[ n ].label = &"Helicopter Health: ";
	self.heliHud[ n ].horzAlign = "right";
	self.heliHud[ n ].vertAlign = "bottom";
	self.heliHud[ n ].fontscale = 1.7;
	self.heliHud[ n ].x = -20;
	self.heliHud[ n ].y = -20;
	self.heliHud[ n ].color = ( 0.0, 1, 0.0 );
	self.heliHud[ n ].archived = 0;
	
	if( !isDefined( level.mannedchopper.damageTaken ) )
		level.mannedchopper.damageTaken = 0;
	
	self.heliHud[ n ] setValue( int( level.mannedchopper.maxHealth - level.mannedchopper.damageTaken ) );
}

emergency()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	while( 1 )
	{
		if( self fragButtonPressed() && level.mannedchopper.flares > 0 )
		{
			self thread doFlares();
			level.mannedchopper.flares--;
		}
		
		if( self leanRightButtonPressed() )
		{
			self iPrintLnBold( "Press [{+leanright}] to confirm ejection, [{+frag}] to cancel!" );
			wait .2;
			num = 0;
			while( num < 40 )
			{
				num++;
				
				if( self fragButtonPressed() )
					break;
					
				if( self leanRightButtonPressed() )
					self thread endHeli( 1 );
				
				wait .05;
			}
			
			wait .25;
		}
		
		wait .05;
	}
}

flareFx()
{
	level.mannedchopper endon( "heliEnd" );
	
	while( isDefined( self ) )
	{
		playFxonTag( level.hardEffects[ "hellfireGeo" ], self, "tag_origin" );
		
		wait 2;
	}
}

doFlares()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	level.counterMeasures= [];
	level.counterMeasuresInAir = true;
	out = self.origin;
	
	for( i = 0; i < 5; i++ )
	{
		level.counterMeasures[ i ] = spawn( "script_model", out );
		level.counterMeasures[ i ] setModel( "projectile_m203grenade" );
		level.counterMeasures[ i ] thread flareFx();
	}
	
	for( z = 1; z < 11; z++ )
	{
		for( i = 0; i < 5; i++ )
		{
			k = i * 60;
			pos = ( out[ 0 ] + 30 * cos( k ) * z, out[ 1 ] + 30 * sin( k ) * z, out[ 2 ] - 15 * z  );
			level.counterMeasures[ i ] moveTo( pos, .05 );
		}
		
		wait .05;
	}
	
	for( i = 0; i < 5; i++ )
	{
		pos = level.counterMeasures[ i ].origin - ( 0, 0, 800 );
		level.counterMeasures[ i ] moveTo( pos, 5 );
	}
	
	wait 4.9;
	
	level.counterMeasuresInAir = undefined;
	
	wait .1;
	
	for( i = 0; i < 5; i++ )
	{
		if( isDefined( level.counterMeasures[ i ] ) )
			level.counterMeasures[ i ] delete();
	}
	
	level.counterMeasures = undefined;
}

warning()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	self iPrintLnBold( "^1WARNING: MISSILE LOCK!" );
	self iPrintLnBold( "Press [{+frag}] to pop flares" );
	
	waittillframeend;
	
	while( isDefined( level.missileLaunched ) )
	{
		self PlayLocalSound( "ui_mp_suitcasebomb_timer" );
		
		wait .2;
	}
}

miscStuff()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	waittillframeend;
	
	self thread code\common::godMod();	
	
	self iPrintLnBold( "Use [{+forward}], [{+back}], [{+moveleft}], [{+moveright}] to pilot the helicopter" );
	self iPrintLnBold( "[{+gostand}] to climb up, [{+breath_sprint}] to climb down" );
	self iPrintLnBold( "[{+activate}] to freeze helicopter, [{+melee}] to change gunner view" );
	self iPrintLnBold( "[{+attack}] to fire minigun, [{+toggleads_throw}] to fire rockets." );

	while( level.mannedchopper.timeLeft > 0 )
	{
		wait 1;
		level.mannedchopper.timeLeft--;
		if( distance2D( level.heliCenterPoint, level.mannedchopper.origin ) > level.heliDistanceMax || abs( level.mannedchopper.origin[ 2 ] - level.heliCenterPoint[ 2 ] ) > 1500 )
		{
			self iprintlnbold( "You have left the combat zone. Move back or you will be shot!" );
			
			self.countdown[ 0 ] = newClientHudElem( self );
			self.countdown[ 0 ].x = 0;
			self.countdown[ 0 ].y = 180;
			self.countdown[ 0 ].alignX = "center";
			self.countdown[ 0 ].alignY = "middle";
			self.countdown[ 0 ].horzAlign = "center_safearea";
			self.countdown[ 0 ].vertAlign = "center_safearea";
			self.countdown[ 0 ].alpha = 1;
			self.countdown[ 0 ].archived = false;
			self.countdown[ 0 ].font = "default";
			self.countdown[ 0 ].fontscale = 1.4;
			self.countdown[ 0 ].color = ( 0.980, 0.996, 0.388 );
			self.countdown[ 0 ] setText( "Out of combat zone!" );
			self.countdown[ 0 ].archived = 0;

			self.countdown[ 1 ] = newClientHudElem( self );
			self.countdown[ 1 ].x = 0;
			self.countdown[ 1 ].y = 160;
			self.countdown[ 1 ].alignX = "center";
			self.countdown[ 1 ].alignY = "middle";
			self.countdown[ 1 ].horzAlign = "center_safearea";
			self.countdown[ 1 ].vertAlign = "center_safearea";
			self.countdown[ 1 ].alpha = 1;
			self.countdown[ 1 ].fontScale = 1.8;
			self.countdown[ 1 ].color = ( .99, .00, .00 );	
			self.countdown[ 1 ] setTenthsTimer( 10 );
			self.countdown[ 1 ].archived = 0;
			
			time = 10;
			
			while( distance2D( level.heliCenterPoint, level.mannedchopper.origin ) > level.heliDistanceMax || abs( level.mannedchopper.origin[ 2 ] - level.heliCenterPoint[ 2 ] ) > 1500 )
			{
				wait 1;
				level.mannedchopper.timeLeft--;
				time--;
				if( time == 0 )
				{
					self thread endHeli( 0 );
					wait 1;
					break;
				}
				else if( level.mannedchopper.timeLeft < 1 )
					break;
			}
			
			if( isDefined( self.countdown ) )
			{
				if( isDefined( self.countdown[ 0 ] ) )
					self.countdown[ 0 ] destroy();
				
				if( isDefined( self.countdown[ 1 ] ) )
					self.countdown[ 1 ] destroy();
			}
		}
	}
	
	self thread endHeli( 2 );
}

yaw()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	waittillframeend;
	
	while( 1 )
	{
		level.mannedchopper SetGoalYaw( self.angles[ 1 ] );
		
		if( self useButtonPressed() )
		{
			self iPrintLn( "Chopper angle locked!" );
			wait .25;
			while( !self useButtonPressed() && !self meleeButtonPressed() )
				wait .05;
			
			self iPrintLn( "Chopper angle unlocked!" );
			
			wait .2;
		}
		
		if( self meleeButtonPressed() && !isDefined( self.inGunner ) )
		{
			self thread gunnerView();
			wait .15;
		}
			
		wait .05;
	}
}

gunnerView()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	self.inGunner = true;
	
	waittillframeend;
	
	self hide();
	
	waittillframeend;
	
	self unlink();
	self linkto( level.gunnerCockpit, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	
	coord = strTok( "-73, -85, 25, 2; -85, -73, 2, 25; 73, 85, 25, 2; 85, 73, 2, 25; -73, 85, 25, 2; -85, 73, 2, 25; 73, -85, 25, 2; 85, -73, 2, 25; -25, 0, 40, 2; 25, 0, 40, 2; 0, 38, 2, 70; 10, 6, 9, 1; 6, 10, 1, 9; 15, 12, 9, 1; 11, 16, 1, 9; 22, 18, 9, 1; 18, 22, 1, 9; 28, 24, 9, 1; 24, 28, 1, 9; 37, 29, 9, 1; 33, 33, 1, 9", ";" ); 
	self setClientDvars( "cg_fovscale", 0.75,
						 "cg_fov", 80 );
	
	for( k = 0; k < coord.size; k++ )
	{
		tCoord = strTok( coord[ k ], "," );
		self.r[ k ] = newClientHudElem( self );
		self.r[ k ].archived = false;
		self.r[ k ].sort = 100;
		self.r[ k ].alpha = .8;
		self.r[ k ] setShader( "white", int( tCoord[ 2 ] ), int( tCoord[ 3 ] ) );
		self.r[ k ].x = int( tCoord[ 0 ] );
		self.r[ k ].y = int( tCoord[ 1 ] );
		self.r[ k ].hideWhenInMenu = true;
		self.r[ k ].alignX = "center";
		self.r[ k ].alignY = "middle";
		self.r[ k ].horzAlign = "center";
		self.r[ k ].vertAlign = "middle";
	}
	
	/////////////////////////////////
	//  PART 1 END
	/////////////////////////////////
	
	wait .25;
	
	while( !self meleeButtonPressed() )
		wait .1;
	
	/////////////////////////////////
	//  PART 2 START - Clean up & return to cockpit view
	/////////////////////////////////
	
	self unlink();
	
	self linkto( level.heliCockpit, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
		
	waittillframeend;
		
	if( isDefined( self.r ) ) 
	{
		for( k = 0; k < self.r.size; k++ ) 
				self.r[ k ] destroy();
	}
	
	self setClientDvars( "cg_fovscale", 1.25,
						 "cg_fov", 80 );
						 
	waittillframeend;
	
	self show();
	
	wait .3;
	
	self.inGunner = undefined;
}

fireControls()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	if ( self.team == "allies" )
		weaponName = "cobra_FFAR_mp";
	else
		weaponName = "hind_FFAR_mp";
		
	wait .1;
	
	while( 1 )
	{
		trace = BulletTrace( self getEye() + ( 0, 0, 20 ) , self getEye() + ( 0, 0, 20 ) + anglesToForward( self getPlayerAngles() ) * 10000, false, level.mannedchopper );
		level.mannedchopper SetTurretTargetVec( trace[ "position" ] );
		
		if( self attackButtonPressed() )
		{
			level.mannedchopper setVehWeapon( "cobra_20mm_mp" );
			miniGun = level.mannedchopper fireWeapon( "tag_flash" );
		}
		
		if( self aimButtonPressed() && level.mannedchopper.missile_ammo > 0 && !isDefined( level.mannedchopper.reloadInProgress ) )
		{
			level.mannedchopper setVehWeapon( weaponName );
			rocketLauncher = level.mannedchopper fireWeapon( "tag_flash" );
			
			level.mannedchopper.missile_ammo--;
			
			self.heliHud[ 2 ] setValue( int( level.mannedchopper.missile_ammo ) );
			
			if( level.mannedchopper.missile_ammo == 0 )
				self iprintlnbold( "Press [{+reload}] to Re-Arm Rockets!" );
				
			while( self aimButtonPressed() )
				wait .05;
		}
		
		if( self reloadButtonPressed() && !isDefined( level.mannedchopper.reloadInProgress ) )
			thread reloadMissiles();
			
		wait .05;
	}
}

reloadMissiles()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	level.mannedchopper.reloadInProgress = true;
	self iprintlnbold( "Rockets Re-Arming..." );
	
	wait 5;
	
	level.mannedchopper.missile_ammo = 12;
	level.mannedchopper.reloadInProgress = undefined;
	
	self.heliHud[ 2 ] setValue( int( level.mannedchopper.missile_ammo ) );
	self iprintlnbold( "Rockets Re-Armed" );
}

/*
flyControls()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	waittillframeend;
	
	level.mannedchopper setvehgoalpos( level.mannedchopper.origin, 1 );

	
	while( 1 )
	{
		if( self forwardButtonPressed() )
		{
			vector = vector_scale( anglesToForward( level.mannedchopper.angles ), 200 );
			new = level.mannedchopper.origin + vector;
			level.mannedchopper setvehgoalpos( new, 1 );
		}
		
		else if( self backButtonPressed() )
		{
			vector = vector_scale( anglesToForward( level.mannedchopper.angles ), 200 );
			new = level.mannedchopper.origin - vector;
			level.mannedchopper setvehgoalpos( new, 1 );
		}
		
		else if( self moveLeftButtonPressed() )
		{
			vector = vector_scale( anglesToRight( level.mannedchopper.angles ), 100 );
			new = level.mannedchopper.origin - vector;
			level.mannedchopper setvehgoalpos( new, 1 );
		}
		
		else if( self moveRightButtonPressed() )
		{
			vector = vector_scale( anglesToRight( level.mannedchopper.angles ), 100 );
			new = level.mannedchopper.origin + vector;
			level.mannedchopper setvehgoalpos( new, 1 );
		}
		
		else if( self jumpButtonPressed() )
		{
			vector = vector_scale( anglesToUp( level.mannedchopper.angles ), 100 );
			new = level.mannedchopper.origin + vector;
			level.mannedchopper setvehgoalpos( new, 1 );
		}
		
		else if( self sprintButtonPressed() )
		{
			vector = vector_scale( anglesToUp( level.mannedchopper.angles ), 100 );
			new = level.mannedchopper.origin - vector;
			level.mannedchopper setvehgoalpos( new, 1 );
		}
			
		wait .05;
	}
}
*/

flyControls()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	waittillframeend;

	while( 1 )
	{
		new = level.mannedchopper.origin;
		
		if( self forwardButtonPressed() )
		{
			vector = vector_scale( anglesToForward( level.mannedchopper.angles ), 200 );
			new += vector;
		}
		
		if( self backButtonPressed() )
		{
			vector = vector_scale( anglesToForward( level.mannedchopper.angles ), 200 );
			new -= vector;
		}
		
		if( self moveRightButtonPressed() )
		{
			vector = vector_scale( anglesToRight( level.mannedchopper.angles ), 100 );
			new += vector;
		}
		
		if( self moveLeftButtonPressed() )
		{
			vector = vector_scale( anglesToRight( level.mannedchopper.angles ), 100 );
			new -= vector;
		}
		
		if( self jumpButtonPressed() )
		{
			vector = vector_scale( anglesToUp( level.mannedchopper.angles ), 100 );
			new += vector;
		}
		
		if( self sprintButtonPressed() )
		{
			vector = vector_scale( anglesToUp( level.mannedchopper.angles ), 100 );
			new -= vector;
		}
		
		level.mannedchopper setVehGoalPos( new, 1 );
		
		wait .05;
		
		while( !self forwardButtonPressed() && !self backButtonPressed() && !self moveLeftButtonPressed() && !self moveRightButtonPressed() && !self jumpButtonPressed() && !self sprintButtonPressed() )
			wait .05;
	}
}

onGameEnd()
{
	self endon( "heliEnd" );
	
	level waittill( "game_ended" );
	
	self.owner thread endHeli( 2 );
}

playerDC( player )
{
	self endon( "heliEnd" );
	
	player waittill( "disconnect" );
	
	thread endHeli( 3 );
}

heliHealth()
{
	self endon( "heliEnd" );
	
	self.currentstate = "ok";
	self.laststate = "ok";
	self setdamagestage( 3 );
	
	for ( ;; )
	{
		hpleft = self.maxHealth - self.damageTaken;
		
		if ( hpleft <= 3000 )
			self.currentstate = "light smoke";
		else if ( hpleft <= 1000 )
			self.currentstate = "heavy smoke";
			
		if ( self.currentstate == "light smoke" && self.laststate != "light smoke" )
		{
			self setdamagestage( 2 );
			self.laststate = self.currentstate;
			self.owner iprintlnbold( "Warning: Heavy damage sustained" );
		}
		if ( self.currentstate == "heavy smoke" && self.laststate != "heavy smoke" )
		{
			self setdamagestage( 1 );
			self notify ( "stop body smoke" );
			self.laststate = self.currentstate;
			self.owner iprintlnbold( "Warning: Critical damage sustained" );
		}
		
		if( self.damageTaken >= self.maxhealth )
		{
			if( isDefined( self.playerInside ) )
				self.owner thread endHeli( 0 );
			else
				self.owner thread endHeli( 1 );
				
			break;
		}
		
		wait 1;
	}
}

damageMonitor()
{
	self endon( "heliEnd" );
	
	self.damageTaken = 0;
	
	for( ;; )
	{
		self waittill( "damage", damage, attacker, direction_vec, P, type );
		
		if( !isdefined( attacker ) || !isplayer( attacker ) || attacker == self )
			continue;
			
		if ( level.teamBased )
			isValidAttacker = (isdefined( attacker.pers[ "team" ] ) && attacker.pers[ "team" ] != self.team);
		else
			isValidAttacker = true;

		if ( !isValidAttacker )
			continue;
			
		self.damageTaken += damage;
		
		if( self.damageTaken > self.maxHealth )
			self.damageTaken = self.maxHealth;
			
		self.owner.heliHud[ 5 ] setValue( int( self.maxHealth - self.damageTaken ) );
		
		attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( false );
		self.attacker = attacker;
		self.direction_vec = direction_vec;
		self.damagetype = type;
		
		r = 0.0 + ( self.damageTaken / self.maxHealth );
		g = 1.0 - ( self.damageTaken / self.maxHealth );
		
		self.owner.heliHud[ 5 ].color = ( r, g, 0.0 );

		if( self.damageTaken >= self.maxHealth )
		{
			self.legalPlayerKill = true;
			attacker notify( "destroyed_helicopter" );
			break;
		}
	}
}

death()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	self waittill( "death" );
	
	self thread endHeli( 0 );
}

jumpOut()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	padalo = spawn( "script_model", self.origin );
	padalo thread deletePadalo(); // Player might disconnect during fall, terminating jumpOut() function so we need extra function without player entity which will delete the padalo in any case
	padalo setModel( "tag_origin" );
	
	self linkTo( padalo, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	
	power = ( 0, 0, 1200 );
	
	padalo MoveGravity( power, 3 );
	
	wait 2.5;
	
	self unlink();
	self setOrigin( self.oldPosition );
}

deletePadalo()
{
	wait 2.6;
	
	if( isDefined( self ) )
		self delete();
}

// TYPE:
//      0 = Crash the heli ( player dead )
//      1 = Player bailed the heli in time - Do the crashing
//      2 = Timed ending - Make heli fly away / game end
//      3 = DC end
//      --- Careful about 3. No SELF there!!! ---
endHeli( type )
{
	self endon( "disconnect" );
	
	level.mannedchopper notify( "heliEnd" );
	level.heliCockpit unLink();
	level.gunnerCockpit unLink();
	
	level.mannedchopper.playerInside = undefined;
	
	waittillframeend;
	
	if( type != 3 )
	{
		self thread code\common::restoreHP();
		if( !level.dvar[ "old_hardpoints" ] )
			self thread code\hardpoints::moneyHud();
		self thread code\common::removeInfoHUD();
		self thread code\common::restoreVisionSettings();
		self setClientDvar( "g_compassshowenemies", 0 );
		self show();
		self.inGunner = undefined;
	}
	
	if( type == 0 )
	{
		self unLink();
		
		if( isAlive( self ) )
		{
			if( isDefined( level.mannedchopper.legalPlayerKill ) )
				self thread [[level.callbackPlayerDamage]]
														(
														level.mannedchopper.attacker,
														level.mannedchopper.attacker,
														100,
														0,
														level.mannedchopper.damagetype,
														"none",
														level.mannedchopper.attacker.origin,
														level.mannedchopper.direction_vec,
														"none",
														0
														);
			else
				self suicide();
		}
		
		level.mannedchopper thread heli_crash();
	}

	else if( type == 1 )
	{	
		self unLink();
		self thread jumpOut();
		
		level.mannedchopper thread heli_crash();
		
		self enableWeapons();
	}

	else if ( type == 2 )
	{
		self unLink();
		
		self setOrigin( self.oldPosition );
		
		level.mannedchopper thread heli_leave();

		self enableWeapons();
	}
	
	else
		level.mannedchopper thread heli_leave();
	
	waittillframeend;
	
	if( isDefined( level.heliCockpit ) )
		level.heliCockpit delete();
	level.heliCockpit = undefined;
		
	if( isDefined( level.gunnerCockpit ) )
		level.gunnerCockpit delete();
	level.gunnerCockpit = undefined;
		
	if( isDefined( level.counterMeasures ) )
	{
		for( i = 0; i < 5; i++ )
		{
			if( isDefined( level.counterMeasures[ i ] ) )
				level.counterMeasures[ i ] delete();
		}
	}
	level.counterMeasures = undefined;
		
	waittillframeend;
	
	if( type == 3 )
		return;
	
	if( isDefined( self.heliHud ) )
	{
		for( i = 0; i < self.heliHud.size; i++ )
		{
			if( isDefined( self.heliHud[ i ] ) )
				self.heliHud[ i ] destroy();
		}
	}
	self.heliHud = undefined;
	
	waittillframeend;
	
	if( isDefined( self.r ) ) 
	{
		for( k = 0; k < self.r.size; k++ )
			if( isDefined( self.r[ k ] ) )
				self.r[ k ] destroy();
	}
	self.r = undefined;
	
	waittillframeend;
	
	if( isDefined( self.countdown ) )
	{
		if( isDefined( self.countdown[ 0 ] ) )
			self.countdown[ 0 ] destroy();

		if( isDefined( self.countdown[ 1 ] ) )
			self.countdown[ 1 ] destroy();
	}
	self.countdown = undefined;
}

heli_crash()
{
	// fly to crash path
	self thread maps\mp\_helicopter::heli_fly( level.heli_crash_paths[0] );
	
	// helicopter losing control and spins
	self thread maps\mp\_helicopter::heli_spin( 180 );
	
	// wait until helicopter is on the crash path
	self waittill ( "path start" );

	// body explosion fx when on crash path
	playfxontag( level.chopper_fx["explode"]["large"], self, "tag_engine_left" );
	// along with a sound
	self playSound ( level.heli_sound[self.team]["hitsecondary"] );

	self setdamagestage( 0 );
	// form fire smoke trails on body after explosion
	self thread maps\mp\_helicopter::trail_fx( level.chopper_fx["fire"]["trail"]["large"], "tag_engine_left", "stop body fire" );
	
	self waittill( "destination reached" );
	self thread heli_explode();
}

heli_explode()
{
	forward = ( self.origin + ( 0, 0, 100 ) ) - self.origin;
	playfx ( level.chopper_fx["explode"]["death"], self.origin, forward );
	
	// play heli explosion sound
	self playSound( level.heli_sound[self.team]["crash"] );
	
	self notify( "ASFsafetynet" );
	
	if( isDefined( self ) )
		self delete();
	
	level.mannedchopper = undefined;
}

heli_leave()
{
	// helicopter leaves randomly towards one of the leave origins
	random_leave_node = randomInt( level.heli_leavenodes.size );
	leavenode = level.heli_leavenodes[random_leave_node];
	
	self setspeed( 100, 45 );	
	self setvehgoalpos( leavenode.origin, 1 );
	self waittillmatch( "goal" );
	
	self notify( "ASFsafetynet" );

	if( isDefined( self ) )
		self delete();
	
	level.mannedchopper = undefined;
}

// heliCenterPoint = midpoint
// ----------------------------
// District = heliCenterPoint
// ambush = heliCenterPoint
// countdown = mapcenter
// crash = heliCenterPoint
// crossfire = heliCenterPoint
// downpour = heliCenterPoint
// overgrown = mapcenter
// pipeline = mapcenter
// showdown = mapcenter
// strike = mapcenter
// vacant = mapcenter
// backlot = mapcenter
// bloc = (1153.95, -5829.26, -23.875)
// bog = heliCenterPoint
// wetwork = heliCenterPoint
// chinatown = heliCenterPoint
// broadcast = heliCenterPoint
// killhouse = mapcenter
// shipment = mapcenter
// creek = heliCenterPoint

plotMap()
{
	count = 0;
	while( !isDefined( level.script ) || !isDefined( level.mapcenter ) )
	{
		wait .25;
		count++;
		
		if( count > 20 )
		{
			print( "\n********** ERROR **********\n" );
			print( "Heli map plot was not successful, unsuported map!\n\n" );
			return;
		}
	}
		
	longestDist = 0;
	midpoint = level.mapcenter;
	
	// axis and allies TDM first spawn?
	spawns = getEntArray( "mp_dm_spawn", "classname" );
	for( i = 0; i < spawns.size; i++ )
	{
		for( n = 0; n < spawns.size; n++ )
		{
			if( spawns[ i ] == spawns[ n ] )
				continue;
			
			dist = distance2D( spawns[ i ].origin, spawns[ n ].origin );
			if( dist > longestDist )
			{
				longestDist = dist;
				midpoint = ( spawns[ i ].origin + spawns[ n ].origin ) / 2;
			}
		}
	}
	
	switch( level.script )
	{
		case "mp_bloc":
			level.heliCenterPoint = (1154, -5829, -23);
			level.heliDistanceMax = longestDist / 1.3;
			break;
			
		case "mp_crash":
		case "mp_crash_snow":
		case "mp_citystreets":
		case "mp_broadcast":
		case "mp_carentan":
		case "mp_cargoship":
		case "mp_bog":
		case "mp_farm":
		case "mp_crossfire":
		case "mp_convoy":
			level.heliCenterPoint = midpoint;
			level.heliDistanceMax = longestDist / 1.3;
			break;
			
		case "mp_shipment":
		case "mp_killhouse":
			level.heliCenterPoint = level.mapcenter;
			level.heliDistanceMax = longestDist * 3;
			break;
			
		case "mp_pipeline":
			level.heliCenterPoint = level.mapcenter;
			level.heliDistanceMax = longestDist;
			break;
			
		default:
			level.heliCenterPoint = level.mapcenter;
			level.heliDistanceMax = longestDist / 1.3;
			break;
	}
}