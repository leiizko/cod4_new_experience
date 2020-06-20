#include maps\mp\_utility;

init()
{
	if( isDefined( level.chopper ) || isDefined( level.mannedchopper ) )
	{
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "HARDPOINT_NOT_AVAILABLE" ), lua_getLocString( self.pers[ "language" ], "CHOPPER_GUNNER" ) );
		return false;
	}
	
	if( isDefined( level.tacticalNuke ) )
	{
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "HARDPOINT_NOT_AVAILABLE" ), lua_getLocString( self.pers[ "language" ], "CHOPPER_GUNNER" ) );
		return false;
	}
	
	if( self isProning() )
	{
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "HARDPOINT_MUST_STAND" ) );
		return false;
	}
	
	self thread setup();
	
	if( isDefined( self.moneyhud ) )
		self.moneyhud destroy();
	
	return true;
}

spawn_helicopter( owner, origin, angles, model, targetname )
{
	chopper = spawnHelicopter( owner, origin, angles, model, targetname );
	chopper.attractor = Missile_CreateAttractorEnt( chopper, level.heli_attract_strength, level.heli_attract_range );
	return chopper;
}

setup()
{
	self endon( "disconnect" );
	
	thread code\common::notifyTeam( lua_getLocString( self.pers[ "language" ], "CHOPPER_GUNNER_FRIENDLY" ), ( 0.1, 0.1, 1 ), 3 );
	self thread code\common::notifyTeamLn( lua_getLocString( self.pers[ "language" ], "HARDPOINT_CALLED_BY" ), lua_getLocString( self.pers[ "language" ], "CHOPPER_GUNNER" ), self.name );

	random_path = randomint( level.heli_paths[ 0 ].size );
	startnode = level.heli_paths[ 0 ][ random_path ];
	
	heliOrigin = startnode.origin;
	heliAngles = startnode.angles;
	
	chopper = spawn_helicopter( self, heliOrigin, heliAngles, "cobra_mp", "vehicle_mi-28_flying" );
	chopper playLoopSound( "mp_hind_helicopter" );
	
	cockpit = spawn( "script_model", chopper.origin );
	cockpit setModel( "projectile_m203grenade" );
	cockpit hide();
	
	gunner = spawn( "script_model", chopper.origin );
	gunner setModel( "projectile_m203grenade" );
	gunner hide();

	cockpit linkTo( chopper, "tag_gunner", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	/*
		tag_gunner
		tag_player
		tag_turret
		tag_pilot
	*/
	gunner linkTo( chopper, "tag_turret", ( 35, 0, -65 ), ( 0, 0, 0 ) );
	
	self.oldPosition = self.origin;
	
	chopper.maxHealth = 2000 + ( level.players.size * 200 );
	chopper.health_low = 800;
	chopper.currentstate = "ok";
	chopper.evasive = false;
	chopper.health_evasive = false;
	chopper.damageTaken = 0;
	
	chopper.missile_ammo = 8; // Clip size, gotta reload after depleted
	chopper.flares = 1;
	chopper.playerInside = true;
	chopper.owner = self;
	
	chopper setSpeed( 100, 20 );
	chopper setAirResistance( 160 );
	chopper setHoverParams( 0, 0, 0 );
	
	chopper.team = self.team;
	chopper.pers[ "team" ] = self.team;
	chopper.loopcount = 0; 
	chopper.attacker = undefined;
	chopper.waittime = level.heli_dest_wait;
	chopper.nodeJumps = 0;
	chopper.timeLeft = 120;
	
	self linkTo( cockpit, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	
	level.heliCockpit = cockpit;
	level.gunnerCockpit = gunner;
	
	level.mannedchopper = chopper;
	
	self thread HudStuff();
	
	self disableWeapons();
	self thread code\common::godMod();	
	
	chopper thread playerDC( self );
	chopper thread onGameEnd();
	chopper thread damageMonitor();
	chopper thread heliHealth();
	
	self thread flyControls( startnode );
	self thread yawAndTime();
	self thread fireControls();
	self thread death();
	self thread emergency();
	self thread gunnerView();
	
	self setClientDvars( "cg_fovscale", 1.25,
						 "g_compassshowenemies", 1,
						 "ui_hud_hardcore", 1 );
}

HudStuff()
{
	n = 0;
	
	self.heliHud[ n ] = newClientHudElem( self );
	self.heliHud[ n ].archived = false;
	self.heliHud[ n ].alignX = "right";
	self.heliHud[ n ].alignY = "bottom";
	self.heliHud[ n ] setText( lua_getLocString( self.pers[ "language" ], "CHOPPER_AGM" ) + level.mannedchopper.missile_ammo ); 
	self.heliHud[ n ].horzAlign = "right";
	self.heliHud[ n ].vertAlign = "bottom";
	self.heliHud[ n ].fontscale = 1.7;
	self.heliHud[ n ].x = -20;
	self.heliHud[ n ].y = -40;
	self.heliHud[ n ].archived = 0;
	
	n = 1;
	
	self.heliHud[ n ] = newClientHudElem( self );
	self.heliHud[ n ].archived = false;
	self.heliHud[ n ].alignX = "right";
	self.heliHud[ n ].alignY = "bottom";
	self.heliHud[ n ] setText( lua_getLocString( self.pers[ "language" ], "CHOPPER_HEALTH" ) + level.mannedchopper.maxHealth );
	self.heliHud[ n ].horzAlign = "right";
	self.heliHud[ n ].vertAlign = "bottom";
	self.heliHud[ n ].fontscale = 1.7;
	self.heliHud[ n ].x = -20;
	self.heliHud[ n ].y = -20;
	self.heliHud[ n ].color = ( 0.0, 1, 0.0 );
	self.heliHud[ n ].archived = 0;
	
	n = 2;
	
	self.heliHud[ n ] = newClientHudElem(self);
	self.heliHud[ n ].elemType = "font";
	self.heliHud[ n ].x = -32;
	self.heliHud[ n ].y = -45;
	self.heliHud[ n ].alignX = "center";
	self.heliHud[ n ].alignY = "bottom";
	self.heliHud[ n ].horzAlign = "center";
	self.heliHud[ n ].vertAlign = "bottom";
	self.heliHud[ n ] setText( lua_getLocString( self.pers[ "language" ], "CHOPPER_TIME_LEFT" ) );
	self.heliHud[ n ].color = (0.0, 0.8, 0.0);
	self.heliHud[ n ].fontscale = 1.4;
	self.heliHud[ n ].archived = 0;
	
	n = 3;
	
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
			self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CHOPPER_CONFIRM_EJECT" ) );
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
	
	self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CHOPPER_MISSILE_LOCK" ) );
	if( level.mannedchopper.flares )
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CHOPPER_POP_FLARES" ) );
	else
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CHOPPER_EJECT" ) );
	
	waittillframeend;
	
	while( isDefined( level.missileLaunched ) )
	{
		self PlayLocalSound( "ui_mp_suitcasebomb_timer" );
		
		wait .2;
	}
}

gunnerView()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	wait 3;
	
	self hide();
	
	waittillframeend;
	
	self unlink();
	self linkto( level.gunnerCockpit, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	
	self setClientDvar( "cg_fovscale", 0.75 );
	
	self.ACOverlay = newClientHudElem( self );
	self.ACOverlay.sort = 100;
	self.ACOverlay.archived = true;
	self.ACOverlay.alpha = .9;
	self.ACOverlay setShader( "ac130_overlay_25mm", 640, 480 );
	self.ACOverlay.x = 0;
	self.ACOverlay.y = 0;
	self.ACOverlay.hideWhenInMenu = true;
	self.ACOverlay.alignX = "center";
	self.ACOverlay.alignY = "middle";
	self.ACOverlay.horzAlign = "center";
	self.ACOverlay.vertAlign = "middle";
}

fireT( trace )
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	level.gunnerCockpit playSound( "chopper_25mm_fire" );
	playFXOnTag( level.hardEffects[ "heliTurret" ], level.mannedchopper, "tag_flash" );
	
	wait .05;

	PlayFX( level.hardEffects[ "25mm" ], trace[ "position" ] );

	ents = maps\mp\gametypes\_weapons::getDamageableents( trace[ "position" ], 50 );
	for( n = 0; n < ents.size; n++ )
	{
		if ( !ents[ n ].isPlayer || isAlive( ents[ n ].entity ) )
		{
			if( !isDefined( ents[ n ] ) )
				continue;

			if( ents[ n ].entity sightConeTrace( trace[ "position" ], ents[ n ].entity ) < 0.1 )
				continue;

			ents[ n ] maps\mp\gametypes\_weapons::damageEnt(
															level.mannedchopper, 
															self, 
															250, 
															"MOD_PROJECTILE_SPLASH", 
															"helicopter_mp", 
															trace[ "position" ], 
															vectornormalize( trace[ "position" ] - ents[ n ].entity.origin ) 
															);
		}
	}
}

getRandomTag()
{
	tags = [];
	tags[ tags.size ] = "tag_store_l_1_a";
	tags[ tags.size ] = "tag_store_l_1_d";
	tags[ tags.size ] = "tag_store_l_2_a";
	tags[ tags.size ] = "tag_store_l_2_d";
	tags[ tags.size ] = "tag_store_r_1_a";
	tags[ tags.size ] = "tag_store_r_1_d";
	tags[ tags.size ] = "tag_store_r_2_a";
	tags[ tags.size ] = "tag_store_r_2_d";
	
	return tags[ randomInt( tags.size ) ];
}

fireAGM( trace )
{
	self endon( "disconnect" );
	
	tag = getRandomTag();
	speed = 90;
	
	org = level.mannedchopper getTagOrigin( tag );
	ang = level.mannedchopper getTagAngles( tag );
	
	missile = spawn( "script_model", org );	
	missile.angles = ang;
	missile setModel( "projectile_hellfire_missile" );
	
	self thread trailFX( missile );
	
	waittillframeend;
	
	/#
	self linkTo( missile, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	#/
	
	self thread removeOnDC( missile );
	
	//missile playSound( "agm_burst" );
	missile playSound( "weap_cobra_missile_fire" );
	
	pos = org + anglesToForward( missile.angles ) * ( speed * 8 );
	missile moveTo( pos, 0.4 );
	
	wait .4;
	
	for( i = 0; i < 220; i++ )
	{
		angles = vectorToAngles( trace[ "position" ] - missile.origin );
		
		ma = missile.angles[ 1 ];
		maxdiff = 7;
		
		if( abs( angles[ 1 ] - ma ) > maxdiff )
		{
			if( abs( angles[ 1 ] - ma ) > 180 )
			{
				if( angles[ 1 ] > ma )
					angles = ( angles[ 0 ], int( ma - maxdiff + 360 ) % 360, angles[ 2 ] );
				else
					angles = ( angles[ 0 ], int( ma + maxdiff ) % 360, angles[ 2 ] );
			}
			else
			{
				if( angles[ 1 ] > ma )
					angles = ( angles[ 0 ], int( ma + maxdiff ) % 360, angles[ 2 ] );
				else
					angles = ( angles[ 0 ], int( ma - maxdiff + 360 ) % 360, angles[ 2 ] );
			}
		}
		
		ma = missile.angles[ 0 ];
		
		if( abs( angles[ 0 ] - ma ) > maxdiff )
		{
			if( abs( angles[ 0 ] - ma ) > 180 )
			{
				if( angles[ 0 ] > ma )
					angles = ( int( ma - maxdiff + 360 ) % 360, angles[ 1 ], angles[ 2 ] );
				else
					angles = ( int( ma + maxdiff ) % 360, angles[ 1 ], angles[ 2 ] );
			}
			else
			{
				if( angles[ 0 ] > ma )
					angles = ( int( ma + maxdiff ) % 360, angles[ 1 ], angles[ 2 ] );
				else
					angles = ( int( ma - maxdiff + 360 ) % 360, angles[ 1 ], angles[ 2 ] );
			}
		}

		missile.angles = angles;
		
		if( missile.angles[ 0 ] < 2 )
			missile.angles = ( 2, missile.angles[ 1 ], missile.angles[ 2 ] );
		
		vector = anglesToForward( missile.angles );
		forward = missile.origin + ( vector[ 0 ] * speed, vector[ 1 ] * speed, vector[ 2 ] * speed );
		collision = bulletTrace( missile.origin, forward, false, level.mannedchopper );
		missile moveTo( forward, .05 );
		
		if( collision[ "surfacetype" ] != "default" && collision[ "fraction" ] < 1 ) 
		{
			target = collision[ "position" ];
			
			/#
			self linkTo( level.gunnerCockpit, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
			#/

			thread code\common::playSoundinSpace( "agm_exp", target );
			PlayFX( level.hardEffects[ "tankerExp" ], target );
			
			ents = maps\mp\gametypes\_weapons::getDamageableents( target, 400 );
			for( i = 0; i < ents.size; i++ )
			{
				if ( !ents[ i ].isPlayer || isAlive( ents[ i ].entity ) )
				{
					if( !isDefined( ents[ i ] ) )
						continue;
						
					if( isDefined( ents[ i ].entity ) && ents[ i ].entity sightConeTrace( target, ents[ i ].entity ) < 0.1 )
						continue;

					ents[ i ] maps\mp\gametypes\_weapons::damageEnt(
																	missile, 
																	self, 
																	2500, 
																	"MOD_PROJECTILE_SPLASH", 
																	"cobra_FFAR_mp", 
																	target, 
																	vectornormalize( target - ents[ i ].entity.origin ) 
																	);
				}
			}
			
			earthquake( 3, 1.2, target, 700 );

			break;
		}
		
		wait .05;
	}

	missile notify( "heli_agm_end" );
	missile delete();
}

trailFX( missile )
{
	self endon( "disconnect" );
	missile endon( "heli_agm_end" );
	
	wait .05;
	
	while( isDefined( missile ) )
	{
		playFxonTag( level.hardEffects[ "hellfireGeo" ], missile, "tag_fx" );
		
		wait 2;
	}
}

removeOnDC( missile )
{
	missile endon( "heli_agm_end" );
	
	self waittill( "disconnect" );
	
	if( isDefined( missile ) )
		missile delete();
}

fireControls()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
		
	wait 3.1;
	
	lastRT = 0;
	lastMT = 0;
	
	self iprintlnbold( lua_getLocString( self.pers[ "language" ], "CHOPPER_FIRE_HINT" ) );
	
	while( 1 )
	{
		trace = BulletTrace( self getEye() + ( 0, 0, 20 ) , self getEye() + ( 0, 0, 20 ) + anglesToForward( self getPlayerAngles() ) * 10000, false, level.mannedchopper );
		level.mannedchopper SetTurretTargetVec( trace[ "position" ] );
		
		if( self attackButtonPressed() && getTime() - lastMT > 100 )
		{
			/*
			org = level.mannedchopper getTagOrigin( "tag_flash" );
			ang = level.mannedchopper getTagAngles( "tag_flash" );
			
			trace = BulletTrace( org , org + anglesToForward( ang ) * 10000, false, level.mannedchopper );
			
			self thread fireT( trace );
			*/
				
			level.mannedchopper setVehWeapon( "mi28_mp" );
			//level.gunnerCockpit playSound( "chopper_25mm_fire" );
			level.gunnerCockpit playSound( "weap_m197_cannon_fire" );
			miniGun = level.mannedchopper fireWeapon( "tag_flash" );
			lastMT = getTime();
		}
		
		else if( self aimButtonPressed() && getTime() - lastRT > 1500 )
		{
			if( !level.mannedchopper.missile_ammo )
			{

				self iprintlnbold( lua_getLocString( self.pers[ "language" ], "CHOPPER_AGM_DRY" ) );
			}
			else
			{
				self thread fireAGM( trace );
				level.mannedchopper.missile_ammo--;
				self.heliHud[ 0 ] setText( lua_getLocString( self.pers[ "language" ], "CHOPPER_AGM" ) + level.mannedchopper.missile_ammo ); 
			}
			lastRT = getTime();
		}
			
		wait .05;
	}
}

flyControls( currentnode )
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	chopper = level.mannedchopper;
	chopper.enRoute = true;
	
	chopper heli_reset();
	
	nextNode = getEnt( currentnode.target, "targetname" );
	pos = nextNode.origin + ( 0, 0, 30 );
	
	chopper setGoalYaw( nextNode.angles[ 1 ] );
	chopper setVehGoalPos( pos, 1 );
	
	chopper waittillmatch( "goal" );
	
	chopper.enRoute = undefined;
	chopper.nodeJumps++;

	if( chopper.nodeJumps > 3 )
	{
		self iprintlnbold( lua_getLocString( self.pers[ "language" ], "CHOPPER_MOVE" ) );
		while( !self jumpButtonPressed() )
			wait .05;
	}
	
	if( !isDefined( nextNode.target ) )
		nextNode = level.heli_loop_paths[ 0 ];	
	
	self thread flyControls( nextNode );
}

heli_reset()
{
	self clearTargetYaw();
	self clearGoalYaw();
	self setspeed( 60, 25 );	
	self setyawspeed( 75, 45, 45 );
	self setmaxpitchroll( 30, 30 );
	self setneargoalnotifydist( 256 );
	self setturningability( 1 );
}

yawAndTime()
{
	level.mannedchopper endon( "heliEnd" );
	self endon( "disconnect" );
	
	chopper = level.mannedchopper;
	
	waittillframeend;
	
	chopper.timeLeft *= 10;

	while( 1 )
	{
		if( !isDefined( chopper.enRoute ) )
		{
			angles = self getPlayerAngles();
			chopper SetGoalYaw( angles[ 1 ] );
		}
		
		wait .1;
		
		if( chopper.timeLeft <= 0 )
		{
			self thread endHeli( 2 );
			break;
		}
		
		chopper.timeLeft--;
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
	
	lightHP = int( self.maxHealth / 100 ) * 75;
	heavyHP = int( self.maxHealth / 100 ) * 90;
	
	for ( ;; )
	{
		hpleft = self.maxHealth - self.damageTaken;
		
		if ( hpleft <= lightHP )
			self.currentstate = "light smoke";
		else if ( hpleft <= heavyHp )
			self.currentstate = "heavy smoke";
			
		if ( self.currentstate == "light smoke" && self.laststate != "light smoke" )
		{
			self setdamagestage( 2 );
			self.laststate = self.currentstate;
			self.owner iprintlnbold( lua_getLocString( self.owner.pers[ "language" ], "CHOPPER_DAMAGE_HEAVY" ) );
		}
		if ( self.currentstate == "heavy smoke" && self.laststate != "heavy smoke" )
		{
			self setdamagestage( 1 );
			self notify ( "stop body smoke" );
			self.laststate = self.currentstate;
			self.owner iprintlnbold( lua_getLocString( self.owner.pers[ "language" ], "CHOPPER_DAMAGE_CRITICAL" ) );
			self.owner iPrintLnBold( lua_getLocString( self.owner.pers[ "language" ], "CHOPPER_EJECT" ) );
		}
		
		if( self.damageTaken >= self.maxhealth )
		{
			self.owner thread endHeli( 0 );
				
			break;
		}
		
		wait 0.25;
	}
}

damageMonitor()
{
	self endon( "heliEnd" );
	
	self.damageTaken = 0;
	self.lastHudUpdate = getTime();
	
	for( ;; )
	{
		self waittill( "damage", damage, attacker, direction_vec, P, type );
		
		if( !isdefined( attacker ) || !isplayer( attacker ) || attacker == self )
			continue;
			
		if ( level.teamBased )
			isValidAttacker = ( isdefined( attacker.pers[ "team" ] ) && attacker.pers[ "team" ] != self.team );
		else
			isValidAttacker = true;

		if ( !isValidAttacker )
			continue;
			
		self.damageTaken += damage;
		
		if( self.damageTaken > self.maxHealth )
			self.damageTaken = self.maxHealth;
			
		if( getTime() - self.lastHudUpdate > 250 ) // 5 frames
		{
			self.owner.heliHud[ 1 ] setText( lua_getLocString( self.owner.pers[ "language" ], "CHOPPER_HEALTH" ) + ( self.maxHealth - self.damageTaken ) );
			self.lastHudUpdate = getTime();
		}
		
		attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( false );
		self.attacker = attacker;
		self.direction_vec = direction_vec;
		self.damagetype = type;
		
		r = 0.0 + ( self.damageTaken / self.maxHealth );
		g = 1.0 - ( self.damageTaken / self.maxHealth );
		
		self.owner.heliHud[ 1 ].color = ( r, g, 0.0 );

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
	
	padalo MoveGravity( ( 0, 0, 1200 ), 3 );
	
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
	
	waittillframeend;
	
	if( type != 3 )
	{
		self thread code\common::restoreHP();
		if( !level.dvar[ "old_hardpoints" ] )
			self thread code\hardpoints::moneyHud();
		self thread code\common::restoreVisionSettings();
		self setClientDvar( "g_compassshowenemies", 0 );
		self show();
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
	
	if( isDefined( self.ACOverlay ) ) 
	{
		self.ACOverlay destroy();
		self.ACOverlay = undefined;
	}
	
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
	playfxontag( level.chopper_fx["explode"]["large"], self, "tag_engine_rear_left" );
	// along with a sound
	self playSound ( level.heli_sound[self.team]["hitsecondary"] );

	self setdamagestage( 0 );
	// form fire smoke trails on body after explosion
	self thread maps\mp\_helicopter::trail_fx( level.chopper_fx["fire"]["trail"]["large"], "tag_engine_rear_left", "stop body fire" );
	
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