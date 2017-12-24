#include code\common;

init()
{
	if( isDefined( level.flyingPlane ) || isDefined( level.flyingPlane ) )
	{
		self iPrintLnBold( "AC130 not available" );
		return false;
	}
	else if( isDefined( self.pers[ "lastACUse" ] ) && getTime() - self.pers[ "lastACUse" ] < 25000 )
	{
		time = int( 25 - ( getTime() - self.pers[ "lastACUse" ] ) / 1000 );
		self iPrintLnBold( "AC130 REARMING - ETA " + time + " SECONDS" );
		return false;
	}
	
	if( self isProning() )
	{
		self iPrintLnBold( "You must stand to use this killstreak!" );
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
	thread notifyTeam( "FRIENDLY AC130 INBOUND!", ( 0.1, 0.1, 1 ), 3 );
	self thread notifyTeamLn( "Friendly AC130 called by^1 " + self.name );
	
	waittillframeend;
	
	self hide();
	
	waittillframeend;
	
	thread onPlayerDisconnect( self );
	self thread onGameEnd( ::endHardpoint );
	self thread onPlayerDeath( ::endHardpoint );
	self thread initialVisionSettings();
	
	waittillframeend;
	
	self thread godMod();
	self setClientDvar( "ui_hud_hardcore", 1 );
	
	waittillframeend;
	
	self.oldPosition = self getOrigin();
	self thread planeSetup();
	self thread infoHUD();
	
	waittillframeend;
	
	self thread planeTimer();
	self thread hudLogic( "extended" );
	self thread launcher();
	self disableWeapons();
	
	waittillframeend;
	
	self thread targetMarkers();
}

infoHUD()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	self.info = [];
	
	self.info[ 0 ] = newClientHudElem( self );
	self.info[ 0 ].elemType = "font";
	self.info[ 0 ].x = 0;
	self.info[ 0 ].y = 60;
	self.info[ 0 ].alignX = "center";
	self.info[ 0 ].alignY = "top";
	self.info[ 0 ].horzAlign = "center";
	self.info[ 0 ].vertAlign = "top";
	self.info[ 0 ] setText( "Press ^1[{+attack}] ^7to ^1fire^7, press ^2[{+activate}] ^7to ^2cycle weapons^7, press ^3[{+melee}] ^7to ^3simplify HUD" );
	//self.info[ 0 ].color = ( 0.0, 0.8, 0.0 );
	self.info[ 0 ].fontscale = 1.4;
	self.info[ 0 ].archived = 0;
	
	self.info[ 1 ] = newClientHudElem(self);
	self.info[ 1 ].elemType = "font";
	self.info[ 1 ].x = -32;
	self.info[ 1 ].y = -45;
	self.info[ 1 ].alignX = "center";
	self.info[ 1 ].alignY = "bottom";
	self.info[ 1 ].horzAlign = "center";
	self.info[ 1 ].vertAlign = "bottom";
	self.info[ 1 ] setText("^1Fly time left:");
	self.info[ 1 ].color = (0.0, 0.8, 0.0);
	self.info[ 1 ].fontscale = 1.4;
	self.info[ 1 ].archived = 0;
			
	self.info[ 2 ] = newClientHudElem( self );
	self.info[ 2 ].elemType = "font";
	self.info[ 2 ].x = 32;
	self.info[ 2 ].y = -45;
	self.info[ 2 ].alignX = "center";
	self.info[ 2 ].alignY = "bottom";
	self.info[ 2 ].horzAlign = "center";
	self.info[ 2 ].vertAlign = "bottom";
	self.info[ 2 ] setTimer( 30 );
	self.info[ 2 ].color = ( 1.0, 0.0, 0.0 );
	self.info[ 2 ].fontscale = 1.4;
	self.info[ 2 ].archived = 0;
}

planeTimer()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	wait 30;
	
	thread endHardpoint();
}

launcher()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "flyOver" );
	
	wait .5;
	
	if( !isDefined( self.currentCannon ) )
		self.currentCannon = 0;
	
	if( !isDefined( self.fireTimes ) )
	{
		self.fireTimes = [];
		self.fireTimes[ "105mm" ] = 0;
		self.fireTimes[ "40mm" ] = 0;
		self.fireTimes[ "25mm" ] = 0;
	}
	
	if( !isDefined( self.gun40Proj ) )
		self.gun40Proj = 0;
		
	if( !isDefined( self.gun25Proj ) )
		self.gun25Proj = 0;

	while( isDefined( level.flyingPlane ) )
	{
		if( self attackButtonPressed() )
		{
			self thread gunLogic();
		}
		wait .05;
	}
}

fire( gun )
{
	self endon( "disconnect" );
	
	trace = BulletTrace( self getEye() + ( 0, 0, 20 ) , self getEye() + ( 0, 0, 20 ) + anglesToForward( self getPlayerAngles() ) * 10000, false, self );
	
	switch( gun )
	{
		// 10 RPM = 6 sec
		case 0:
			self playSound("mp_lose_flag");
			level.plane[ "105mm" ] = spawn( "script_model", self.origin );
			level.plane[ "105mm" ] setModel( "projectile_hellfire_missile" );
			level.plane[ "105mm" ].angles = self getPlayerAngles();
			level.plane[ "105mm" ] moveTo( trace[ "position" ], 2 );
			
			level.plane[ "105mm" ] playSound( "fast_artillery_round" );
			
			wait 2;
			
			thread playSoundinSpace( "exp_suitcase_bomb_main", trace[ "position" ] );
			PlayFX( level.hardEffects[ "tankerExp" ], trace[ "position" ] );

			ents = maps\mp\gametypes\_weapons::getDamageableents( trace[ "position" ], 400 );
			for( i = 0; i < ents.size; i++ )
			{
				if ( !ents[ i ].isPlayer || isAlive( ents[ i ].entity ) )
				{
					if( !isDefined( ents[ i ] ) )
						continue;
					
					if( isPlayer( ents[ i ].entity ) )
						ents[ i ].entity.sWeaponForKillcam = "ac130_105mm";

					ents[ i ] maps\mp\gametypes\_weapons::damageEnt(
																	level.plane[ "105mm" ], 
																	self, 
																	10000, 
																	"MOD_PROJECTILE_SPLASH", 
																	"artillery_mp", 
																	trace[ "position" ], 
																	vectornormalize( trace[ "position" ] - ents[ i ].entity.origin ) 
																	);
				}
			}
			earthquake( 3, 1.4, trace[ "position" ], 700 );
			if( isDefined( level.plane[ "105mm" ] ) )
				level.plane[ "105mm" ] delete();
			break;
		
		// 100 RPM = 0.6 sec
		case 1:
			if( !isDefined( level.plane[ "40mm" ] ) )
				level.plane[ "40mm" ] = [];
			
			i = self.gun40Proj;
			
			if( i > 4 )
			{
				self.gun40Proj = 0;
				i = 0;
			}
			
			if( isDefined( level.plane[ "40mm" ][ i ] ) )
				level.plane[ "40mm" ][ i ] delete();
				
			waittillframeend;
			
			self playSound("mp_lose_flag");
			level.plane[ "40mm" ][ i ] = spawn( "script_model", self.origin );
			level.plane[ "40mm" ][ i ] setModel( "projectile_rpg7" );
			level.plane[ "40mm" ][ i ].angles = self getPlayerAngles();
			level.plane[ "40mm" ][ i ] moveTo( trace[ "position" ], 1.8 );
			
			level.plane[ "40mm" ][ i ] playSound( "fast_artillery_round" );
			
			self.gun40Proj++;
			
			wait 1.8;
			
			thread playSoundinSpace( "artillery_impact", trace[ "position" ] );
			PlayFX( level.hardEffects[ "artilleryExp" ], trace[ "position" ] );
			
			ents = maps\mp\gametypes\_weapons::getDamageableents( trace[ "position" ], 240 );
			for( n = 0; n < ents.size; n++ )
			{
				if ( !ents[ n ].isPlayer || isAlive( ents[ n ].entity ) )
				{
					if( !isDefined( ents[ n ] ) )
						continue;
						
					if( isPlayer( ents[ n ].entity ) )
						ents[ n ].entity.sWeaponForKillcam = "ac130_40mm";

					ents[ n ] maps\mp\gametypes\_weapons::damageEnt(
																	level.plane[ "40mm" ][ i ], 
																	self, 
																	10000, 
																	"MOD_PROJECTILE_SPLASH", 
																	"artillery_mp", 
																	trace[ "position" ], 
																	vectornormalize( trace[ "position" ] - ents[ n ].entity.origin ) 
																	);
				}
			}
			
			earthquake( 2.5, 1.2, trace[ "position" ], 500 );
			if( isDefined( level.plane[ "40mm" ][ i ] ) )
				level.plane[ "40mm" ][ i ] delete();
			break;
		
		// 1800 RPM = 0.033 sec
		// stupid 20 fps makes that 50 msec
		case 2:
			if( !isDefined( level.plane[ "25mm" ] ) )
				level.plane[ "25mm" ] = [];
			
			i = self.gun25Proj;
			
			if( i > 16 )
			{
				self.gun25Proj = 0;
				i = 0;
			}
			
			if( isDefined( level.plane[ "25mm" ][ i ] ) )
				level.plane[ "25mm" ][ i ] delete();
				
			waittillframeend;
			
			level.plane[ "25mm" ][ i ] = spawn( "script_model", self.origin );
			level.plane[ "25mm" ][ i ] setModel( "projectile_m203grenade" );
			level.plane[ "25mm" ][ i ].angles = self getPlayerAngles();
			level.plane[ "25mm" ][ i ] moveTo( trace[ "position" ], .75 );
			
			level.plane[ "25mm" ][ i ] playSound( "weap_m197_cannon_fire" );
			
			self.gun25Proj++;
			
			wait .75;
			
			PlayFX( level.hardEffects[ "smallExp" ], trace[ "position" ] );
			
			ents = maps\mp\gametypes\_weapons::getDamageableents( trace[ "position" ], 50 );
			for( n = 0; n < ents.size; n++ )
			{
				if ( !ents[ n ].isPlayer || isAlive( ents[ n ].entity ) )
				{
					if( !isDefined( ents[ n ] ) )
						continue;
						
					if( isPlayer( ents[ n ].entity ) )
						ents[ n ].entity.sWeaponForKillcam = "ac130_25mm";

					ents[ n ] maps\mp\gametypes\_weapons::damageEnt(
																	level.plane[ "25mm" ][ i ], 
																	self, 
																	10000, 
																	"MOD_PROJECTILE_SPLASH", 
																	"artillery_mp", 
																	trace[ "position" ], 
																	vectornormalize( trace[ "position" ] - ents[ n ].entity.origin ) 
																	);
				}
			}
			
			if( isDefined( level.plane[ "25mm" ][ i ] ) )
				level.plane[ "25mm" ][ i ] delete();
			
			break;
	}
}

gunLogic()
{
	self endon( "disconnect" );
	
	switch( self.currentCannon )
	{
		case 0:
			if( getTime() - self.fireTimes[ "105mm" ] < 6000 )
				break;
			
			self.fireTimes[ "105mm" ] = getTime();
			self thread fire( self.currentCannon );
			break;
		
		case 1:
			if( getTime() - self.fireTimes[ "40mm" ] < 600 )
				break;
			
			self.fireTimes[ "40mm" ] = getTime();
			self thread fire( self.currentCannon );
			break;
			
		case 2:
			if( getTime() - self.fireTimes[ "25mm" ] < 33 )
				break;
				
			self.fireTimes[ "25mm" ] = getTime();
			self thread fire( self.currentCannon );
			break;
			
		default:
			iPrintLnBold( "Weapon ERR: " + self.currentCannon );
			break;
	}
}

endHardpoint()
{
	self endon( "disconnect" );
	level notify( "flyOver" );
	
	self unLink();
	self setOrigin( self.oldPosition );
	
	waittillframeend;
	
	self.pers[ "lastACUse" ] = getTime();
	
	self.oldPosition = undefined;
	if( !level.dvar[ "old_hardpoints" ] )
		self thread code\hardpoints::moneyHud();
	
	waittillframeend;
	
	self thread restoreHP();
	self show();
	self enableWeapons();
	
	waittillframeend;
	
	if( isDefined( self.r ) ) 
	{
		for( k = 0; k < self.r.size; k++ ) 
			if( isDefined( self.r[ k ] ) )
				self.r[ k ] destroy();
	}
	
	self.r = undefined;
	
	if( isDefined( self.info ) )
	{
		for( i = 0; i < self.info.size; i++ )
			self.info[ i ] destroy();
	}
	
	self.info = undefined;
	self.currentCannon = undefined;
	self.gun40Proj = undefined;
	self.gun25Proj = undefined;
	
	waittillframeend;
	
	self thread restoreVisionSettings();
	
	waittillframeend;
	
	if( isDefined( self.targetMarker ) )
	{
		for( k = 0; k < self.targetMarker.size; k++ ) 
				self.targetMarker[ k ] destroy();
	}
	
	self.targetMarker = undefined;
	
	if( isArray( self.fireTimes ) )
	{
		while( isDefined( self.fireTimes[ "105mm" ] ) && getTime() - self.fireTimes[ "105mm" ] < 2050 )
			wait .1;
		
		while( isDefined( self.fireTimes[ "40mm" ] ) && getTime() - self.fireTimes[ "40mm" ] < 1850 )
			wait .1;
		
		while( isDefined( self.fireTimes[ "25mm" ] ) && getTime() - self.fireTimes[ "25mm" ] < 800 )
			wait .1;
	}
	
	wait .25;
	
	self.fireTimes[ "105mm" ] = undefined;
	self.fireTimes[ "40mm" ] = undefined;
	self.fireTimes[ "25mm" ] = undefined;
	self.fireTimes = undefined;
	
	level.flyingPlane = undefined;
	level notify( "flyOverDC" );
}