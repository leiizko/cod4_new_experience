planeSetup( modelName )
{
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	level.planePos = getPosition();
	level.plane = [];
	level.plane[ "plane" ] = spawn( "script_model", ( level.planePos[ 0 ] + 1150, level.planePos[ 1 ], level.planePos[ 2 ] ) );
//	level.plane[ "plane" ] setModel( "vehicle_mig29_desert" );
	level.plane[ "plane" ] setModel( "tag_origin" );
	level.plane[ "plane" ] hide();
	
	if( modelName == "vehicle_ac130_low" )
		self linkTo( level.plane[ "plane" ], "tag_origin", ( 120, -60, -20 ), ( 0, 0, 0 ) );
	else
		self linkTo( level.plane[ "plane" ], "tag_origin", ( 140, 0, -35 ), ( 0, 0, 0 ) );
	
	level.plane[ "model" ] = spawn( "script_model", ( level.planePos[ 0 ] + 1150, level.planePos[ 1 ], level.planePos[ 2 ] ) );
	level.plane[ "model" ] setModel( modelName );
	level.plane[ "model" ] linkTo( level.plane[ "plane" ], "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	
	thread destroyPlane();
	
	for( ;; )
	{
		for( k = 0; k < 360; k += 1 )
		{
			location = ( level.planePos[ 0 ] + ( 1150 * cos( k ) ), level.planePos[ 1 ] + ( 1150 * sin( k ) ), level.planePos[ 2 ] );
			angles = vectorToAngles( location - level.plane[ "plane" ].origin );
			level.plane[ "plane" ] moveTo( location, .1 );
			
			if( modelName == "vehicle_ac130_low" )
				angles = ( angles[ 0 ], angles[ 1 ] + 90, angles[ 2 ] );
				
			level.plane[ "plane" ].angles = angles;
			wait .1;
		}
	}
}

initialVisionSettings()
{
	self.hardpointVision = true;
	
	self setClientDvars( "r_FilmTweakInvert", "1",
						 "r_FilmTweakBrightness", "0.37", 
						 "r_FilmTweakDesaturation", "1",
						 "r_FilmTweakEnable", "1",
					 	 "r_FilmUseTweaks", "1",
						 "r_FullBright", "0",
						 "cg_fovscale", "1.25",
						 "waypointiconheight", 15,
						 "waypointiconwidth", 15 );
}

restoreVisionSettings()
{
	self endon( "disconnect" );
	
	self setClientDvar( "waypointiconheight", 36 );
	self setClientDvar( "waypointiconwidth", 36 );
	
	self thread code\player::userSettings();
	
	wait .05; // Let the onPlayerKilled code catch up
	
	self.hardpointVision = undefined;
}

destroyPlane()
{
	level waittill( "flyOver" );
	
	if( isDefined( self ) )
		self waitProjectiles();
	
	waittillframeend;
	
	if( isDefined( level.plane[ "plane" ] ) )
		level.plane[ "plane" ] delete();
		
	if( isDefined( level.plane[ "model" ] ) )
		level.plane[ "model" ] delete();
	
	if( isDefined( level.plane[ "missile" ] ) )
		level.plane[ "missile" ] delete();
		
	waittillframeend;
	
	if( isDefined( level.plane[ "105mm" ] ) )
		level.plane[ "105mm" ] delete();
		
	waittillframeend;
	
	if( isDefined( level.plane[ "40mm" ] ) )
	{
		for( i = 0; i < level.plane[ "40mm" ].size; i++ )
		{
			if( isDefined( level.plane[ "40mm" ][ i ] ) )
				level.plane[ "40mm" ][ i ] delete();
		}
	}
	
	waittillframeend;
	
	if( isDefined( level.plane[ "25mm" ] ) )
	{
		for( i = 0; i < level.plane[ "25mm" ].size; i++ )
		{
			if( isDefined( level.plane[ "25mm" ][ i ] ) )
				level.plane[ "25mm" ][ i ] delete();
		}
	}
		
	level.plane = undefined;
}

waitProjectiles()
{
	self endon( "disconnect" );
	
	while( isArray( self.fireTimes ) && getTime() - self.fireTimes[ "105mm" ] < 2050 )
		wait .1;
		
	while( isArray( self.fireTimes ) && getTime() - self.fireTimes[ "40mm" ] < 1850 )
		wait .1;
		
	while( isArray( self.fireTimes ) && getTime() - self.fireTimes[ "25mm" ] < 800 )
		wait .1;
}

removeInfoHUD()
{
	if( isDefined( self.info ) )
	{
		for( i = 0; i < self.info.size; i++ )
			self.info[ i ] destroy();
	}
	
	self.info = undefined;
}

/*
	Type:
		 extended: 105, 40 and 25 mm
		 basic: 105mm only
*/
hudLogic( type )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	
	if( type == "extended" )
	{
		gun = 0;
		self thread setHUD( gun );
		
		while( isDefined( level.flyingPlane ) )
		{
			if( self useButtonPressed() )
			{
				if( gun < 2 )
					gun++;
				else
					gun = 0;
				
				self thread setHUD( gun );
				self.currentCannon = gun;
				
				wait .5;
			}
			wait .05;
		}
	}
	
	else
	{
		self thread setHUD( 0 );
	}
}

setHUD( type )
{
	shader = "";
	switch( type )
	{
		case 0:
			shader = "ac130_overlay_105mm";
			self setClientDvar( "cg_fovscale", 1.25 );
			break;
		
		case 1:
			shader = "ac130_overlay_40mm";
			self setClientDvar( "cg_fovscale", 1 );
			break;
		
		case 2:
			shader = "ac130_overlay_25mm";
			self setClientDvar( "cg_fovscale", 0.75 );
			break;
	}
	
	if( !isDefined( self.ACOverlay ) )
	{
		self.ACOverlay = newClientHudElem( self );
		self.ACOverlay.sort = 100;
		self.ACOverlay.archived = true;
		self.ACOverlay.alpha = .9;
		self.ACOverlay.x = 0;
		self.ACOverlay.y = 0;
		self.ACOverlay.hideWhenInMenu = true;
		self.ACOverlay.foreground = true;
		self.ACOverlay.alignX = "left";
		self.ACOverlay.alignY = "top";
		self.ACOverlay.horzAlign = "fullscreen";
		self.ACOverlay.vertAlign = "fullscreen";
		self.ACOverlay setShader( shader, 640, 480 );
	}
	else
		self.ACOverlay setShader( shader, 640, 480 );
	
	if( !isDefined( self.ACOverlayGrain ) )
	{
		self.ACOverlayGrain = newClientHudElem( self );
		self.ACOverlayGrain.archived = true;
		self.ACOverlayGrain.alpha = .5;
		self.ACOverlayGrain.x = 0;
		self.ACOverlayGrain.y = 0;
		self.ACOverlayGrain.hideWhenInMenu = true;
		self.ACOverlayGrain.foreground = true;
		self.ACOverlayGrain.alignX = "left";
		self.ACOverlayGrain.alignY = "top";
		self.ACOverlayGrain.horzAlign = "fullscreen";
		self.ACOverlayGrain.vertAlign = "fullscreen";
		self.ACOverlayGrain setShader( "ac130_overlay_grain", 640, 480 );
	}
}

clearHUD()
{
	if( isDefined( self.ACOverlay ) ) 
	{
		self.ACOverlay destroy();
		self.ACOverlayGrain destroy();
		self.ACOverlay = undefined;
		self.ACOverlayGrain = undefined;
	}
	
	if( isDefined( self.info ) )
	{
		for( i = 0; i < self.info.size; i++ )
			self.info[ i ] destroy();
			
		self.info = undefined;
	}
	
	if( isDefined( self.targetMarker ) )
	{
		for( k = 0; k < self.targetMarker.size; k++ ) 
				self.targetMarker[ k ] destroy();
				
		self.targetMarker = undefined;
	}
	
}

onPlayerDisconnect( player )
{
	level endon( "game_ended" );
	level endon( "flyOverDC" );
	
	player waittill( "disconnect" );
	
	level notify( "flyOver" );
	thread resetVariables(); // wait for other functions to terminate before reseting the variables used in them
}

resetVariables()
{
	wait .25;
	
	level.flyingPlane = undefined;
	level.missileLaunched = undefined;
}

onGameEnd( endFunction )
{
	self endon( "disconnect" );
	level endon( "flyOver" );
	
	level waittill( "game_ended" );
	
	self thread [[endFunction]]();
}

onPlayerDeath( endFunction )
{
	self endon("disconnect");
	level endon("flyOver");
	level endon("game_ended");
	
	self waittill( "death" );
	
	self thread [[endFunction]]();
}

getPosition()
{
	map = getDvar( "mapname" );
	
	switch( map )
	{
		case "mp_bloc":
			location = ( 1100, -5836, 2500 );
			break;
		case "mp_crossfire":
			location = ( 4566, -3162, 2300 );
			break;
		case "mp_citystreets":
			location = ( 4384, -469, 2100 );
			break;
		case "mp_creek":
			location = ( -1595, 6528, 2500 );
			break;
		case "mp_bog":
			location = ( 3767, 1332, 2300 );
			break;
		case "mp_overgrown":
			location = ( 267, -2799, 2600 );
			break;
		default:
			location = ( 0, 0, 2100 );
			break;
	}
		
	return location;
}

targetMarkers()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	wait .1;

	self.targetMarker = [];

	j = 0;
	
	players = getPlayers();
	
	for( i = 0; i < players.size; i++ )
	{
		if( j == 15 )
			break;

		if( players[ i ] == self )
			continue;
			
		if( ( players[ i ].pers[ "team" ] == self.pers[ "team" ] && level.teambased ) || players[ i ].pers[ "team" ] == "spectator" )
			continue;

		self.targetMarker[ j ] = newClientHudElem( self );
		self.targetMarker[ j ].x = players[ i ].origin[ 0 ];
		self.targetMarker[ j ].y = players[ i ].origin[ 1 ];
		self.targetMarker[ j ].z = players[ i ].origin[ 2 ];
		
		if( !isAlive( players[ i ] ) || players[ i ] hasPerk( "specialty_gpsjammer" ) )
			self.targetMarker[ j ].alpha = 0;
		else
			self.targetMarker[ j ].alpha = 1;
			
		self.targetMarker[ j ] setShader( "waypoint_kill", 15, 15 );
		self.targetMarker[ j ] setWayPoint( true, "waypoint_kill" );
		self.targetMarker[ j ] setTargetEnt( players[ i ] );
		
		players[ i ] thread targetMarkerEvent( self, j );
		players[ i ] thread targetMarkerDisconnect( self, j );
			
		j++;
		
		waittillframeend;
	}
}

targetMarkerDisconnect( owner, j )
{
	level endon( "flyOver" );
	owner endon( "disconnect" );
	
	self waittill( "disconnect" );
	
	if( isDefined( owner.targetMarker[ j ] ) )
		owner.targetMarker[ j ] destroy();
		
	waittillframeend;
	
	owner.targetMarker[ j ] = newClientHudElem( owner ); // we have to keep it defined as hud elem or cleanup function gets fucked up
	owner.TargetMarker[ j ].alpha = 0;
	owner.TargetMarker[ j ].baseAlpha = 0;
}

targetMarkerEvent( owner, j )
{
	owner endon( "disconnect" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );

	while( isDefined( level.flyingPlane ) )
	{
		self common_scripts\utility::waittill_any( "death", "spawnProtectionDisabled" );

		if( !isReallyAlive( self ) || self hasPerk( "specialty_gpsjammer" ) )
		{
			owner.TargetMarker[ j ].alpha = 0;
			owner.TargetMarker[ j ].baseAlpha = 0;
		}
		else
		{
			owner.TargetMarker[ j ].alpha = 1;
			owner.TargetMarker[ j ].baseAlpha = 1;
		}
	}
}

getPlayers()
{
	return level.players;
}

isReallyAlive( player )
{
	if( isAlive( player ) && player.sessionstate == "playing" )
		return true;
	else
		return false;
}

notifyTeam( string, glow, duration )
{
	if( !level.teambased )
		return;
	
	players = getPlayers();
	
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( player.pers[ "team" ] == self.pers[ "team" ] )
			player thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, string, undefined, glow, undefined, duration );
	}
}

notifyTeamLn( string, arg, arg2 )
{
	if( !level.teambased )
		return;

	players = level.players;
	
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( player.pers[ "team" ] == self.pers[ "team" ] )
		{
			if( isDefined( arg2 ) )
				player iPrintLn( string, arg, arg2 );
			else
				player iPrintLn( string );
		}
	}
}

notifyTeamBig( string, glow, duration )
{
	if( !level.teambased )
		return;

	players = getPlayers();
	
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( player.pers[ "team" ] == self.pers[ "team" ] )
			player thread maps\mp\gametypes\_hud_message::oldNotifyMessage( string, undefined, undefined, glow, undefined, duration );
	}
}

clearNotify()
{
	players = getPlayers();
	
	for( i = 0; i < players.size; i++ )
	{
		if( isDefined( players[ i ].notifyQueue ) )
		{
			for( a = 0; a < players[ i ].notifyQueue.size; a++ )
				if( isDefined( players[ i ].notifyQueue[ a ] ) )
					players[ i ].notifyQueue[ a ] = undefined;
		}

		if( isDefined( players[ i ].doingNotify ) && players[ i ].doingNotify )
			players[ i ] thread maps\mp\gametypes\_hud_message::resetNotify();
	}
}

playSoundinSpace( alias, origin )
{
	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias );
	wait 10; 
	org delete();
}

godMod()
{
	self setClientDvar( "ui_healthProtected", 1 );
	self.HealthProtected = true;
}

restoreHP()
{
	self.HealthProtected = undefined;
	
	self setClientDvars( "ui_hud_hardcore", level.hardcoreMode,
						 "ui_healthProtected", 0 );
}

toUpper_old( letter )
{
	upper = letter;
	
	switch( letter )
	{
		case "a":
			upper = "A";
			break;
			
		case "b":
			upper = "B";
			break;
			
		case "c":
			upper = "C";
			break;
			
		case "d":
			upper = "D";
			break;
			
		case "e":
			upper = "E";
			break;
			
		case "f":
			upper = "F";
			break;
			
		case "g":
			upper = "G";
			break;
			
		case "h":
			upper = "H";
			break;
			
		case "i":
			upper = "I";
			break;
			
		case "j":
			upper = "J";
			break;
			
		case "k":
			upper = "K";
			break;
			
		case "l":
			upper = "L";
			break;
			
		case "m":
			upper = "M";
			break;
			
		case "n":
			upper = "N";
			break;
			
		case "o":
			upper = "O";
			break;
			
		case "p":
			upper = "P";
			break;
			
		case "q":
			upper = "Q";
			break;
			
		case "r":
			upper = "R";
			break;
			
		case "s":
			upper = "S";
			break;
			
		case "t":
			upper = "T";
			break;
			
		case "u":
			upper = "U";
			break;
			
		case "v":
			upper = "V";
			break;
			
		case "w":
			upper = "W";
			break;
			
		case "x":
			upper = "X";
			break;
			
		case "y":
			upper = "Y";
			break;
			
		case "z":
			upper = "Z";
			break;
			
		default:
			break;
	}
	
	return upper;
}