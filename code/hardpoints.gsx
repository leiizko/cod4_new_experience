/*
	ADDING CUSTOM HARDPOINTS
	
	addHardpoint( DVARNAME, NAME, CALLBACK, EXTRAPARAM )
	DVARNAME - Must be set in dvars script and must have _shop suffix ( nuke_shop )
	NAME - Hardpoint full name that will show in notify ( ex: nuke --> Thermonuclear Bomb )
	CALLBACK - callback to hardpoint script entry point ( ex: code\heli::init() )
	EXTRAPARAM - extra parameter if needed with script callback, maximum 1. Set it to undefined if not needed
	
	Add it starting at line 58!
	
	Full example:
	
	addHardpoint( "nuke", "Thermonuclear Bomb", code\nuke::init, undefined );
*/

init()
{
	makeShopArray();
	thread code\events::addConnectEvent( ::onConnected );
	thread code\events::addSpawnEvent( ::onSpawn );
	thread code\events::addDeathEvent( ::onDeath );
	
	level.radarPlayer = [];
}

makeShopArray()
{
	level.hardpointShopData = [];
	
	dvarNames = "radar;airstrike;artillery;helicopter;agm;predator;asf;ac130;mannedheli;nuke";
	dvarNames = strTok( dvarNames, ";" );
	
	names = "Radar;Airstrike;Artillery;Helicopter;Hellfire Missile;Predator Drone;Fighter Support;AC130 Gunship;Manned Helicopter;Thermonuclear Bomb";
	names = strTok( names, ";" );
	
	callbacks = [];
	callbacks[ callbacks.size ] = ::trigger;
	callbacks[ callbacks.size ] = ::trigger;
	callbacks[ callbacks.size ] = code\artillery::selectLocation;
	callbacks[ callbacks.size ] = ::trigger;
	callbacks[ callbacks.size ] = code\agm::init;
	callbacks[ callbacks.size ] = code\predator::init;
	callbacks[ callbacks.size ] = code\asf::init;
	callbacks[ callbacks.size ] = code\ac130::init;
	callbacks[ callbacks.size ] = code\heli::init;
	callbacks[ callbacks.size ] = code\nuke::init;
	
	extras = [];
	extras[ 0 ] = "radar_mp";
	extras[ 1 ] = "airstrike_mp";
	extras[ 3 ] = "helicopter_mp";
	
	for( i = 0; i < dvarNames.size; i++ )
		addHardpoint( dvarNames[ i ], names[ i ], callbacks[ i ], extras[ i ] );
		
	///////////////////////////////////////
	//    YOUR CUSTOM HARDPOINTS HERE    //
	///////////////////////////////////////
	addHardpoint( "ammo", "Extra Ammo", ghost\gear::buyAmmo, undefined );
	addHardpoint( "health", "Extra Health", ghost\gear::buyHealth, undefined );
	addHardpoint( "smoke", "Smoke Cover", ghost\gear::buySmoke, undefined );
	addHardpoint( "slide", "Extra Slide", ghost\gear::buySlide, undefined );
	
		
	for( i = 0; i < level.hardpointShopData.size; i++ )
	{
		for( n = 0; n < level.hardpointShopData.size - 1; n++ )
		{
			if( level.hardpointShopData[ n ][ 0 ] > level.hardpointShopData[ n + 1 ][ 0 ] )
			{
				temp = level.hardpointShopData[ n ];
				level.hardpointShopData[ n ] = level.hardpointShopData[ n + 1 ];
				level.hardpointShopData[ n + 1 ] = temp;
			}
		}
	}
}

addHardpoint( dvarName, name, callback, extraParam )
{
	d = dvarName + "_shop";
	i = level.hardpointShopData.size;
	
	level.hardpointShopData[ i ][ 0 ] = level.dvar[ d ];
	level.hardpointShopData[ i ][ 1 ] = name;
	level.hardpointShopData[ i ][ 2 ] = callback;
	
	if( isDefined( extraParam ) )
		level.hardpointShopData[ i ][ 3 ] = extraParam;
}

onDeath( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	streak = attacker.cur_kill_streak;
	waittillframeend;

	if( !isDefined( attacker ) || !isDefined( attacker.money ) || sMeansOfDeath == "MOD_FALLING" || level.gameEnded )
		return;

	if( attacker != self )
	{
		if( sMeansOfDeath == "MOD_HEAD_SHOT" )
			attacker.money += 20;
			
		else if( sMeansOfDeath == "MOD_MELEE" )
			attacker.money += 30;
		
		else
			attacker.money += 10;
			
		waittillframeend;
		
		if( streak > 0 && ( streak % 5 ) == 0 )
			attacker thread streakNotify( streak );
		
		if( isDefined( attacker.moneyhud ) )
			attacker.moneyhud setValue( int( attacker.money ) );
		
		// Notify the attacker for killstreaks
		for( i = 0; i < level.hardpointShopData.size; i++ )
		{
			if( attacker.money >= level.hardpointShopData[ i ][ 0 ] && !isDefined( attacker.HnotifyDone[ i ] ) )
			{
				attacker.HnotifyDone[ i ] = true;
				string = "Press [{+actionslot 4}] to buy " + level.hardpointShopData[ i ][ 1 ];

				for( n = i + 1; n < level.hardpointShopData.size; n++ )
				{
					if( level.hardpointShopData[ i ][ 0 ] < level.hardpointShopData[ n ][ 0 ] )
						break;
						
					attacker.HnotifyDone[ n ] = true;
					string += "/" + level.hardpointShopData[ n ][ 1 ];
				}
				
				string += " ($" + level.hardpointShopData[ i ][ 0 ] + ")";
				
				// The string is too long to fit on screen so just leave a generic message
				if( string.size > 80 )
					string = "New items available in shop!";
				
				attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, string, undefined, undefined, undefined, string.size * 0.1 );
			}
			
			else if( attacker.money < level.hardpointShopData[ i ][ 0 ] )
				break;
		}
		
		// Notifying the player about UAV assists may cause too much spam on full server
		if( isDefined( level.radarPlayer[ attacker.team ] ) && level.radarPlayer[ attacker.team ] != attacker )
		{
			level.radarPlayer[ attacker.team ].money++;

			if( isDefined( level.radarPlayer[ attacker.team ].moneyhud ) )
				level.radarPlayer[ attacker.team ].moneyhud setValue( int( level.radarPlayer[ attacker.team ].money ) );
		}
	}
}

streakNotify( streak )
{
	string = "" + streak + " Kill Streak!";
	self thread maps\mp\gametypes\_hud_message::oldNotifyMessage( string, undefined, undefined, undefined, undefined, string.size * 0.15 );
	
	iPrintLn( self.name + " has a killstreak of " + streak + "!" );
}

onConnected()
{
	self.money = 0;
	self.HnotifyDone = [];
	
	self thread moneyHud();
}

moneyHud()
{
	panel = self ghost\hud::createPanel( 90, 22, -16, -48, "right", "bottom", "right", "bottom" );
	self.moneyPanel = [];
	self.moneyPanel[ 0 ] = panel[ 0 ];
	self.moneyPanel[ 1 ] = panel[ 1 ];

	self.moneyhud = newClientHudElem( self );
	self.moneyhud.archived = false;
	self.moneyhud.alignX = "right";
	self.moneyhud.alignY = "bottom";
	self.moneyhud.label = &"$ ";
	self.moneyhud.horzAlign = "right";
	self.moneyhud.vertAlign = "bottom";
	self.moneyhud.font = "objective";
	self.moneyhud.fontscale = 1.5;
	self.moneyhud.color = level.hudTheme[ "primary" ];
	self.moneyhud.x = -20;
	self.moneyhud.y = -50;
	self.moneyhud.sort = 2;
	
	self.moneyhud setValue( int( self.money ) );
}

onSpawn()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self giveWeapon( "radar_mp" );
	self setWeaponAmmoClip( "radar_mp", 0 );
	self setWeaponAmmoStock( "radar_mp", 0 );
	self setActionSlot( 4, "weapon", "radar_mp" );
	
	for( ;; )
	{				
		self waittill( "weapon_change" );
		
		currentWeapon = self getCurrentWeapon();
		
		if( currentWeapon == "radar_mp" )
		{	
			if( self.pers[ "hardpointSType" ] )
				self SetMoveSpeedScale( 0 );

			self thread shop();
			self thread exitShop();
			self thread shopThink();
			
			self waittill( "destroy_shop" );
			
			if( self.pers[ "hardpointSType" ] )
				self thread restoreMoveSpeed();
			
			wait .1;
			
			if ( self.pers[ "lastWeapon" ] != "none" )
				self switchToWeapon( self.pers[ "lastWeapon" ] );
				
			wait .25;
		}
		
		else
			self.pers[ "lastWeapon" ] = currentWeapon;
	}
}

restoreMoveSpeed()
{
	switch ( self.pers[ "weaponClassPrimary" ] )
	{
		case "rifle":
			self setMoveSpeedScale( 0.95 );
			break;
		case "pistol":
			self setMoveSpeedScale( 1.0 );
			break;
		case "mg":
			self setMoveSpeedScale( 0.875 );
			break;
		case "smg":
			self setMoveSpeedScale( 1.0 );
			break;
		case "spread":
			self setMoveSpeedScale( 1.0 );
			break;
		default:
			self setMoveSpeedScale( 1.0 );
			break;
		}
}

shopThink()
{
	self endon( "destroy_shop" );
	self endon( "disconnect" );
	
	for( ;; )
	{
		if( self attackButtonPressed() )
		{
			self buy();
			self notify( "destroy_shop" );
			break;
		}
		else if ( ( self useButtonPressed() && !self.pers[ "hardpointSType" ] ) || ( self backButtonPressed() && self.pers[ "hardpointSType" ] ) )
		{
			self thread updateHUD( 1 );
			wait .25;
		}
		else if ( ( self meleeButtonPressed() && !self.pers[ "hardpointSType" ] ) || ( self forwardButtonPressed() && self.pers[ "hardpointSType" ] ) )
		{
			self thread updateHUD( 2 );
			wait .25;
		}
		
		wait .05;
	}
}

buy()
{
	self endon( "destroy_shop" );
	
	if( !isDefined( self.selectionNum ) )
		self.selectionNum = 0;
		
	before = self.money;
	
	if( self.money < level.hardpointShopData[ self.selectionNum ][ 0 ] )
	{
		dif = level.hardpointShopData[ self.selectionNum ][ 0 ] - self.money;
		self iPrintLnBold( "Missing ^1$" + dif + "^7 to buy " + level.hardpointShopData[ self.selectionNum ][ 1 ] );
		return;
	}
	else
	{
		if( isDefined( level.hardpointShopData[ self.selectionNum ][ 3 ] ) )
		{
			result = self [[level.hardpointShopData[ self.selectionNum ][ 2 ]]]( level.hardpointShopData[ self.selectionNum ][ 3 ] );

			if( !isDefined( result ) || !result )
				return;
			else
				self.money -= level.hardpointShopData[ self.selectionNum ][ 0 ];
		}
		else
		{
			result = self [[level.hardpointShopData[ self.selectionNum ][ 2 ]]]();

			if( !isDefined( result ) || !result )
				return;
			else
				self.money -= level.hardpointShopData[ self.selectionNum ][ 0 ];
		}
	}
	
	after = self.money;
	difference = int( after - before );
	
	if( difference != 0 && level.dvar[ "shopXP" ] )
		self thread maps\mp\gametypes\_rank::updateRankScoreHUD( difference );
	
	for( i = 0; i < level.hardpointShopData.size; i++ )
	{
		if( self.money < level.hardpointShopData[ i ][ 0 ] && isDefined( self.HnotifyDone[ i ] ) )
			self.HnotifyDone[ i ] = undefined;
	}
		
	if( isDefined( self.moneyhud ) )
		self.moneyhud setValue( int( self.money ) );
}

trigger( hardpointType )
{
	if ( hardpointType == "radar_mp" )
	{
		if( isDefined( level.radarPlayer[ self.team ] ) )
		{
			self iPrintLnBold( "UAV RECON NOT AVAILABLE" );
			return false;
		}

		if( level.teambased )
			level.radarPlayer[ self.team ] = self;

		self thread maps\mp\gametypes\_hardpoints::useRadarItem();
	}
	else if ( hardpointType == "airstrike_mp" )
	{
		if ( isDefined( level.airstrikeInProgress ) )
		{
			self iPrintLnBold( level.hardpointHints[hardpointType+"_not_available"] );
			return false;
		}
		else if( isDefined( self.pers[ "lastAirUse" ] ) && getTime() - self.pers[ "lastAirUse" ] < 30000 )
		{
			time = int( 30 - ( getTime() - self.pers[ "lastAirUse" ] ) / 1000 );
			self iPrintLnBold( "JETS REARMING - ETA " + time + " SECONDS" );
			return false;
		}
			
		result = self maps\mp\gametypes\_hardpoints::selectAirstrikeLocation();
		
		if ( !isDefined( result ) || !result )
			return false;
		
		self.pers[ "lastAirUse" ] = getTime();
	}
	else if ( hardpointType == "helicopter_mp" )
	{
		if( level.teambased && level.dvar[ "doubleHeli" ] )
		{
			if( isDefined( level.chopper ) && isDefined( level.chopper[ self.team ] ) || isDefined( level.mannedchopper ) )
			{
				self iPrintLnBold( level.hardpointHints[hardpointType+"_not_available"] );
				return false;
			}
		}
		else if ( isDefined( level.chopper ) || isDefined( level.mannedchopper ) )
		{
			self iPrintLnBold( level.hardpointHints[hardpointType+"_not_available"] );
			return false;
		}
		
		if( isDefined( self.pers[ "lastHeliUse" ] ) && getTime() - self.pers[ "lastHeliUse" ] < 25000 )
		{
			time = int( 25 - ( getTime() - self.pers[ "lastHeliUse" ] ) / 1000 );
			self iPrintLnBold( "HELICOPTER REARMING - ETA " + time + " SECONDS" );
			return false;
		}
		
		destination = 0;
		random_path = randomint( level.heli_paths[destination].size );
		startnode = level.heli_paths[destination][random_path];
		
		team = self.pers["team"];
		otherTeam = level.otherTeam[team];
		
		if ( level.teambased )
		{
			maps\mp\gametypes\_globallogic::leaderDialog( "helicopter_inbound", team );
			maps\mp\gametypes\_globallogic::leaderDialog( "enemy_helicopter_inbound", otherTeam );
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];
				playerteam = player.pers["team"];
				if ( isdefined( playerteam ) )
				{
					if ( playerteam == team )
						player iprintln( &"MP_HELICOPTER_INBOUND", self );
				}
			}
		}
		else
		{
			self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "helicopter_inbound" );
			selfarray = [];
			selfarray[0] = self;
			maps\mp\gametypes\_globallogic::leaderDialog( "enemy_helicopter_inbound", undefined, undefined, selfarray );
		}
		
		thread maps\mp\_helicopter::heli_think( self, startnode, self.pers["team"] );
	}
	
	return true;
}

updateHUD( type )
{
	self endon( "destroy_shop" );
	
	if( !isDefined( self.selectionNum ) )
		self.selectionNum = 0;
		
	if( type == 1 )
	{
		if( self.selectionNum < level.hardpointShopData.size - 1 )
			self.selectionNum++;
		
		else
			self.selectionNum = 0;
	}
	
	else
	{
		if( self.selectionNum > 0 )
			self.selectionNum--;
		
		else
			self.selectionNum = level.hardpointShopData.size - 1;
	}
	

	self.shop[ 4 ].y = 64 + ( self.selectionNum * 16 );
}

shop()
{
	self endon( "destroy_shop" );

	self.shop = [];
	count = level.hardpointShopData.size;
	rowH = 16;
	panelW = 240;
	panelH = 40 + ( count * rowH ) + 8;

	n = 99;
	for( i = 0; i < count; i++ )
	{
		if( self.money < level.hardpointShopData[ i ][ 0 ] )
		{
			n = i;
			break;
		}
	}

	panel = self ghost\hud::createPanel( panelW, panelH, 0, 36, "center", "top", "center", "top" );
	self.shop[ 5 ] = panel[ 0 ];
	self.shop[ 6 ] = panel[ 1 ];

	self.shop[ 7 ] = self ghost\hud::createLabel( "SHOP", "objective", 1.5, 0, 42, "center", "top", "center", "top" );
	self.shop[ 7 ].color = level.hudTheme[ "accent" ];

	nameStr = "^2";
	priceStr = "^2";
	for( i = 0; i < count; i++ )
	{
		if( i == n )
		{
			nameStr += "^1";
			priceStr += "^1";
		}

		if( i > 0 )
		{
			nameStr += "\n";
			priceStr += "\n";
		}

		nameStr += level.hardpointShopData[ i ][ 1 ];
		priceStr += "$" + level.hardpointShopData[ i ][ 0 ];
	}

	self.shop[ 0 ] = self ghost\hud::createLabel( nameStr, "default", 1.25, -108, 64, "center", "top", "left", "top" );
	self.shop[ 1 ] = self ghost\hud::createLabel( priceStr, "default", 1.25, 108, 64, "center", "top", "right", "top" );

	self.shop[ 2 ] = self ghost\hud::createLabel( "", "default", 1.25, 0, 36 + panelH + 8, "center", "top", "center", "top" );
	if( !self.pers[ "hardpointSType" ] )
		self.shop[ 2 ] setText( "Press [{+melee}] or [{+activate}] to move UP or DOWN" );
	else
		self.shop[ 2 ] setText( "Press [{+forward}] or [{+back}] to move UP or DOWN" );
	self.shop[ 2 ].color = level.hudTheme[ "muted" ];

	self.shop[ 3 ] = self ghost\hud::createLabel( "Press [{+attack}] to BUY", "default", 1.25, 0, 36 + panelH + 24, "center", "top", "center", "top" );
	self.shop[ 3 ].color = level.hudTheme[ "accent" ];

	self.shop[ 4 ] = newClientHudElem( self );
	self.shop[ 4 ].archived = false;
	self.shop[ 4 ].alignX = "center";
	self.shop[ 4 ].alignY = "top";
	self.shop[ 4 ] setShader( "white", 220, 15 );
	self.shop[ 4 ].alpha = 0.28;
	self.shop[ 4 ].color = level.hudTheme[ "highlight" ];
	self.shop[ 4 ].horzAlign = "center";
	self.shop[ 4 ].vertAlign = "top";
	self.shop[ 4 ].x = 0;
	self.shop[ 4 ].y = 64;
	self.shop[ 4 ].sort = 1;
}

exitShop()
{
	self endon( "disconnect" );
	
	self waittill_any_game( "destroy_shop", "death", "weapon_change" );
	
	self notify( "destroy_shop" );
	
	ghost\hud::destroyHudGroup( self.shop );
	self.shop = undefined;
	self.selectionNum = undefined;
}

waittill_any_game( string1, string2, string3 )
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	
	self endon( string1 );
	self endon( string2 );
	self waittill( string3 );
}