#include maps\mp\gametypes\_hud_util;

init()
{
	if( level.cpOnMap > 3 || isDefined( level.cpInP ) )
	{
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "HARDPOINT_NOT_AVAILABLE" ), lua_getLocString( self.pers[ "language" ], "CP" ) );
		return false;
	}
	
	pos = self getOrigin();
	
	trace = bulletTrace( pos + ( 0, 0, 1100 ), pos, false, self );
	
	if( distanceSquared( pos, trace[ "position" ] ) > 100 )
	{
		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "CP_DEPLOY_BLOCKED" ) );
		return false;
	}
	else
		self thread startCP( trace[ "position" ] );
		
	return true;
}

startCP( pos )
{
	level.cpInP = true;
	level.cpOnMap++;
	
	end = 0;
	
	for( i = 0; i < 360; i += 20 )
	{
		angle = ( 0, i, 0 );
		
		end = pos + ( 0, 0, 1100 ) + anglesToForward( angle ) * 5000;
		trace = bulletTrace( pos + ( 0, 0, 1100 ), end, false, undefined ); 
		
		if( distanceSquared( pos, trace[ "position" ] ) < 100 )
			break;
	}
	
	waittillframeend;
	
	ang = vectorToAngles( pos - end );
	
	if ( self.team == "allies" )
	{
		chopper = spawn_helicopter( self, end, ang, "cobra_mp", "vehicle_cobra_helicopter_fly" );
		chopper playLoopSound( "mp_cobra_helicopter" );
	}
	else
	{
		chopper = spawn_helicopter( self, end, ang, "cobra_mp", "vehicle_mi24p_hind_desert" );
		chopper playLoopSound( "mp_hind_helicopter" );
	}
	
	waittillframeend;
	
	cp = spawn( "script_model", chopper.origin );
	cp setModel( "com_plasticcase_beige_big" );
	cp.angles = ang;
	
	cp.owner = self;
	cp.team = self.team;
	
	cp linkTo( chopper, "tag_ground", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	
	chopper setvehgoalpos( pos + ( 0, 0, 1100 ) , 1 );	
	chopper waittillmatch( "goal" );
	
	// DROP CP
	
	wait .25;
	
	trace = bulletTrace( cp.origin, cp.origin - ( 0, 0, 10000 ), false, cp ); 
	cp unLink();
	cp moveTo( trace[ "position" ], 1 ); // 50 units per frame
	
	cp thread watchForKill();
	
	wait .95;
	
	blocker = spawn( "script_model", trace[ "position" ] + ( 0, 0, 10 ) );
	angle = level.radioentoffset + cp.angles;
	blocker.angles = angle;
	blocker cloneBrushModelToScriptModel( level.radioent );
	
	level thread CP_Logic( cp, blocker, self );
	
	// LEAVE
	random_leave_node = randomInt( level.heli_leavenodes.size );
	leavenode = level.heli_leavenodes[ random_leave_node ];
	
	chopper setvehgoalpos( leavenode.origin, 1 );
	chopper waittillmatch( "goal" );
	
	waittillframeend;
	
	chopper delete();
	
	wait .05;
	
	level.cpInP = undefined;
}

CP_Logic( cp, b, ent )
{
	cp.reward = lua_getHardpoint();
	
	wait .1;
	
	trigg = spawn( "trigger_radius", cp.origin, 0, 64, 64 );
	trigg.loop = true;
	
	trigg thread timedDeath();
	
	if( isDefined( ent ) && isPlayer( ent ) )
		thread waypoint( cp, trigg, ent );
	
	while( trigg.loop )
	{
		trigg waittill( "trigger", player );
		
		if( !isDefined( player.cp_hint ) )
		{
			continue;
		}
	
		if( !isDefined( player.cp_bar ) && player useButtonPressed() )
		{	
			self.cp_bar = 0;
			player thread onUse( trigg, cp );
		}
		
		player.cp_hint.alpha = 1;
		player.cp_hint FadeOverTime( .05 );
		player.cp_hint.alpha = 0;
	}
	
	trigg notify( "done" );
	
	trigg delete();
	cp delete();
	b delete();
	
	level.cpOnMap--;
}

onUse( trigg, cp )
{
	self endon( "disconnect" );

	if( isDefined( cp.owner ) && self == cp.owner )
		timer = 2;
	else if( self.team == cp.team )
		timer = 4;
	else
		timer = 6;
				
	self disableWeapons();
	self freezeControls( true );
			
	self.cp_bar = self maps\mp\gametypes\_hud_util::createBar( ( 1, 1, 1 ), 128, 8 );
	self.cp_bar maps\mp\gametypes\_hud_util::setPoint( "CENTER", 0, 0, 0 );
	self.cp_bar maps\mp\gametypes\_hud_util::updateBar( 0, 1 / timer );
			
	timer *= 20;
			
	while( self useButtonPressed() && isAlive( self ) && isDefined( trigg ) )
	{				
		if( !timer )
		{
			trigg.loop = false;
			if( level.dvar[ "old_hardpoints" ] )
				self thread maps\mp\gametypes\_hardpoints::giveHardpoint( cp.reward, self.cur_kill_streak, 3 );
			else
			{
				reward = randomInt( 10 ) * 25;
				self.money += reward;
				self iPrintLnBold( "You got " + reward + "$" );
			}
			break;
		}
		
		wait .05;
		
		timer--;
	}

	
	self.cp_bar maps\mp\gametypes\_hud_util::destroyElem();
	self.cp_bar = undefined;
	self enableWeapons();
	self freezeControls( false );
}

timedDeath()
{
	self endon( "done" );
	
	while( level.cpOnMap < 3 )
		wait 1;
		
	wait 20;
	
	self.loop = false;
}

waypoint( cp, trigg, ent )
{
	ent endon( "disconnect" );
	
	cp_marker = newClientHudElem( ent );
	cp_marker.x = cp.origin[ 0 ];
	cp_marker.y = cp.origin[ 1 ];
	cp_marker.z = cp.origin[ 2 ] + 40;
			
	cp_marker setShader( "cp_mark_mp", 15, 15 );
	cp_marker setWayPoint( true, "cp_mark_mp" );
	
	trigg waittill( "done" );
	
	cp_marker destroy();
}

watchForKill( pos )
{
	wait 0.75;
	// 64x32x32
	for( i = 0; i < 4; i++ )
	{
		trace = bulletTrace( self.origin + ( 12, 0, 0 ), self.origin - ( -12, 0, 50 ), false, self );
		trace2 = bulletTrace( self.origin - ( 12, 0, 0 ), self.origin - ( 12, 0, 50 ), false, self );
		
		for( n = 0; n < level.players.size; n++ )
		{
			player = level.players[ n ];
			if( distance2D( trace[ "position" ], player.origin ) < 20 || distance2D( trace[ "position" ], player.origin ) < 20 )
				player suicide();
		}
		
		wait .05;
	}
}

spawn_helicopter( owner, origin, angles, model, targetname )
{
	chopper = spawnHelicopter( owner, origin, angles, model, targetname );
	chopper.attractor = Missile_CreateAttractorEnt( chopper, level.heli_attract_strength, level.heli_attract_range );
	chopper.currentstate = "ok";
	chopper setSpeed( 120, 20 );
	chopper setAirResistance( 160 );
	chopper setHoverParams( 0, 0, 0 );
	chopper setdamagestage( 3 );
	
	return chopper;
}


cp_init()
{
	level.cpOnMap = 0;
	
	// dvarNames = "radar;airstrike;helicopter;artillery;agm;predator;asf;ac130;mannedheli;nuke;carepackage";
	lua_addHardpoint( "radar_mp", 15 );
	lua_addHardpoint( "radar_mp", 15 );
	lua_addHardpoint( "airstrike_mp", 11 );
	lua_addHardpoint( "artillery_mp", 11 );
	lua_addHardpoint( "agm_mp", 11 );
	lua_addHardpoint( "helicopter_mp", 10 );
	lua_addHardpoint( "predator_mp", 10 ); 
	lua_addHardpoint( "ac130_mp", 8 );
	lua_addHardpoint( "mannedheli_mp", 8 ); 
	lua_addHardpoint( "nuke_mp", 1 ); 
	
	thread code\events::addConnectEvent( ::hintHud );
}

hintHud()
{
	self endon( "disconnect" );
	
	if( !isDefined( self.pers[ "language" ] ) )
		self waittill( "language_set" );
		
	self.cp_hint = createFontString( "default", level.lowerTextFontSize );
	self.cp_hint setPoint( "CENTER", level.lowerTextYAlign, 0, level.lowerTextY );
	self.cp_hint setText( lua_getLocString( self.pers[ "language" ], "CP_USE_HINT" ) );
	self.cp_hint.archived = false;
	self.cp_hint.alpha = 0;
}