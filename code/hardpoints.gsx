init()
{
	thread code\events::addConnectEvent( ::onConnected );
	thread code\events::addSpawnEvent( ::onSpawn );
	thread code\events::addDeathEvent( ::onDeath );
	
	level waittill( "game_ended" );
	
	thread code\common::clearNotify();
}

onDeath( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	level endon( "game_ended" );
	
	waittillframeend;

	if( !isDefined( attacker ) || !isDefined( attacker.money ) || sMeansOfDeath == "MOD_FALLING" )
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
		
		if( ( attacker.cur_kill_streak % 5 ) == 0 )
			attacker maps\mp\gametypes\_hardpoints::streakNotify( attacker.cur_kill_streak );
		
		if( isDefined( attacker.moneyhud ) )
			attacker.moneyhud setValue( int( attacker.money ) );
		
		// Notify the attacker for killstreaks
		
		if( attacker.money >= 20 && !isDefined( attacker.HnotifyDone[ 0 ] ) )
		{
			attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, "Press [{+actionslot 4}] to buy UAV (20 credits)", undefined, undefined, undefined, 5 );
			attacker.HnotifyDone[ 0 ] = true;
		}
		
		else if( attacker.money >= 70 && !isDefined( attacker.HnotifyDone[ 1 ] ) )
		{
			attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, "Press [{+actionslot 4}] to buy AIR/ARTY (70 credits)", undefined, undefined, undefined, 5 );
			attacker.HnotifyDone[ 1 ] = true;
		}
		
		else if( attacker.money >= 100 && !isDefined( attacker.HnotifyDone[ 2 ] ) )
		{
			attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, "Press [{+actionslot 4}] to buy AGM/ASF (100 credits)", undefined, undefined, undefined, 5 );
			attacker.HnotifyDone[ 2 ] = true;
		}
		
		else if( attacker.money >= 180 && !isDefined( attacker.HnotifyDone[ 3 ] ) )
		{
			attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, "Press [{+actionslot 4}] to buy HELICOPTER (180 credits)", undefined, undefined, undefined, 5 );
			attacker.HnotifyDone[ 3 ] = true;
		}
		
		else if( attacker.money >= 280 && !isDefined( attacker.HnotifyDone[ 4 ] ) )
		{
			attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, "Press [{+actionslot 4}] to buy PREDATOR DRONE (280 credits)", undefined, undefined, undefined, 6 );
			attacker.HnotifyDone[ 4 ] = true;
		}
		
		else if( attacker.money >= 380 && !isDefined( attacker.HnotifyDone[ 5 ] ) )
		{
			attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, "Press [{+actionslot 4}] to buy AC130 (380 credits)", undefined, undefined, undefined, 5 );
			attacker.HnotifyDone[ 5 ] = true;
		}
		
		else if( attacker.money >= 500 && !isDefined( attacker.HnotifyDone[ 6 ] ) )
		{
			attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, "Press [{+actionslot 4}] to buy MANNED HELI (500 credits)", undefined, undefined, undefined, 6 );
			attacker.HnotifyDone[ 6 ] = true;
		}
		
		else if( attacker.money >= 600 && !isDefined( attacker.HnotifyDone[ 7 ] ) )
		{
			attacker thread maps\mp\gametypes\_hud_message::oldNotifyMessage( undefined, "Press [{+actionslot 4}] to buy TACTICAL NUKE (600 credits)", undefined, undefined, undefined, 6 );
			attacker.HnotifyDone[ 7 ] = true;
		}
	}
}

onConnected()
{
	self.money = 0;
	self.HnotifyDone = [];
	
	self thread moneyHud();
}

moneyHud()
{
	self.moneyhud = newClientHudElem( self );
	self.moneyhud.archived = false;
	self.moneyhud.alignX = "right";
	self.moneyhud.alignY = "bottom";
	self.moneyhud.label = &"credits: ";
	self.moneyhud.horzAlign = "right";
	self.moneyhud.vertAlign = "bottom";
	self.moneyhud.fontscale = 1.7;
	self.moneyhud.x = -20;
	self.moneyhud.y = -50;
	
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
			self thread shop();
			self thread exitShop();
			self thread shopThink();
			
			self waittill( "destroy_shop" );
			
			wait .1;
			
			if ( self.pers[ "lastWeapon" ] != "none" )
				self switchToWeapon( self.pers[ "lastWeapon" ] );
				
			wait .25;
		}
		
		else
			self.pers[ "lastWeapon" ] = currentWeapon;
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
		else if ( self useButtonPressed() )
		{
			self thread updateHUD( 1 );
			wait .25;
		}
		else if ( self meleeButtonPressed() )
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
	
	switch( self.selectionNum )
	{
		case 0:
			if( self.money >= 20 )
			{
				self thread maps\mp\gametypes\_hardpoints::useRadarItem();
				self.money -= 20;
			}
			else if( self.money < 20 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 1:
			if( self.money >= 70 && self maps\mp\gametypes\_hardpoints::triggerHardPoint( "airstrike_mp" ) )
				self.money -= 70;
			else if( self.money < 70 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 2:
			if( self.money >= 70 )
			{
				result = self code\artillery::selectLocation();
				
				if( !isDefined( result ) || !result )
					break;
				else
					self.money -= 70;
			}
			else if( self.money < 70 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 3:
			if( self.money >= 100 && self code\asf::init() )
				self.money -= 100;
			else if( self.money < 100 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 4:
			if( self.money >= 100 && self code\agm::init() )
				self.money -= 100;
			else if( self.money < 100 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 5:
			if( self.money >= 180 && self maps\mp\gametypes\_hardpoints::triggerHardPoint( "helicopter_mp" ) )
				self.money -= 180;
			else if( self.money < 180 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 6:
			if( self.money >= 280 && self code\predator::init() )
				self.money -= 280;
			else if( self.money < 280 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 7:
			if( self.money >= 380 && self code\ac130::init() )
				self.money -= 380;
			else if( self.money < 380 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 8:
			if( self.money >= 500 && self code\heli::init() )
				self.money -= 500;
			else if( self.money < 500 )
				self iprintlnbold( "Not enough credits!" );
			break;
		case 9:
			if( self.money >= 600 )
			{
				result = self code\nuke::init();
				
				if( !isDefined( result ) || !result )
					break;
				else
					self.money -= 600;
			}
			else if( self.money < 600 )
				self iprintlnbold( "Not enough credits!" );
			break;
		
		default:
			break;
	}
	
	after = self.money;
	difference = int( after - before );
	
	if( difference != 0 )
		self thread maps\mp\gametypes\_rank::updateRankScoreHUD( difference );
	
	if( self.money < 600 && isDefined( self.HnotifyDone[ 7 ] ) )
		self.HnotifyDone[ 7 ] = undefined;
	
	else if( self.money < 500 && isDefined( self.HnotifyDone[ 6 ] ) )
		self.HnotifyDone[ 6 ] = undefined;
		
	else if( self.money < 380 && isDefined( self.HnotifyDone[ 5 ] ) )
		self.HnotifyDone[ 5 ] = undefined;
		
	else if( self.money < 280 && isDefined( self.HnotifyDone[ 4 ] ) )
		self.HnotifyDone[ 4 ] = undefined;
		
	else if( self.money < 180 && isDefined( self.HnotifyDone[ 3 ] ) )
		self.HnotifyDone[ 3 ] = undefined;
		
	else if( self.money < 100 && isDefined( self.HnotifyDone[ 2 ] ) )
		self.HnotifyDone[ 2 ] = undefined;
		
	else if( self.money < 70 && isDefined( self.HnotifyDone[ 1 ] ) )
		self.HnotifyDone[ 1 ] = undefined;
		
	else if( self.money < 20 && isDefined( self.HnotifyDone[ 0 ] ) )
		self.HnotifyDone[ 0 ] = undefined;
	
	if( isDefined( self.moneyhud ) )
		self.moneyhud setValue( int( self.money ) );
}

updateHUD( type )
{
	self endon( "destroy_shop" );
	
	if( !isDefined( self.selectionNum ) )
		self.selectionNum = 0;
		
	if( type == 1 )
	{
		if( self.selectionNum < 9 )
			self.selectionNum++;
		
		else
			self.selectionNum = 0;
	}
	
	else
	{
		if( self.selectionNum > 0 )
			self.selectionNum--;
		
		else
			self.selectionNum = 9;
	}
	

	switch( self.selectionNum )
	{
		case 0:
			self.shop[ 4 ].y = -8;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 1:
			self.shop[ 4 ].y = 9;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 2:
			self.shop[ 4 ].y = 26;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 3:
			self.shop[ 4 ].y = 42.5;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 4:
			self.shop[ 4 ].y = 59;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 5:
			self.shop[ 4 ].y = 76;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 6:
			self.shop[ 4 ].y = 93;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 7:
			self.shop[ 4 ].y = 110;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 8:
			self.shop[ 4 ].y = 126.2;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		case 9:
			self.shop[ 4 ].y = 142.5;
			self.shop[ 4 ] moveOverTime( .25 );
			break;
		default:
			break;
	}
}

shop()
{
	self endon( "destroy_shop" );

	self.shop = [];
	
	self.shop[ 0 ] = newClientHudElem( self );
	self.shop[ 0 ].archived = false;
	self.shop[ 0 ].alignX = "center";
	self.shop[ 0 ].alignY = "middle";
	self.shop[ 0 ] setText( " ^3Hardpoint:^7 \n Radar \n Airstrike \n Artillery \n Air-Air Support \n Air-Ground Missile \n Helicopter \n Predator Drone \n AC130 \n Manned Heli \n TACTICAL NUKE" );
	self.shop[ 0 ].horzAlign = "center";
	self.shop[ 0 ].vertAlign = "middle";
	self.shop[ 0 ].fontscale = 1.4;
	self.shop[ 0 ].x = -35;
	self.shop[ 0 ].y = -25;
	
	self.shop[ 1 ] = newClientHudElem( self );
	self.shop[ 1 ].archived = false;
	self.shop[ 1 ].alignX = "center";
	self.shop[ 1 ].alignY = "middle";
	self.shop[ 1 ] setText( " ^3Price:^7 \n 20 \n 70 \n 70 \n 100 \n 100 \n 180 \n 280 \n 380 \n 500 \n 600" );
	self.shop[ 1 ].horzAlign = "center";
	self.shop[ 1 ].vertAlign = "middle";
	self.shop[ 1 ].fontscale = 1.4;
	self.shop[ 1 ].x = 35;
	self.shop[ 1 ].y = -25;
	
	self.shop[ 2 ] = newClientHudElem( self );
	self.shop[ 2 ].archived = false;
	self.shop[ 2 ].alignX = "center";
	self.shop[ 2 ].alignY = "middle";
	self.shop[ 2 ] setText( "Press ^1[{+melee}] ^7or ^2[{+activate}]^7 to move ^1UP ^7or ^2DOWN" );
	self.shop[ 2 ].horzAlign = "center";
	self.shop[ 2 ].vertAlign = "top";
	self.shop[ 2 ].fontscale = 1.7;
	self.shop[ 2 ].x = 0;
	self.shop[ 2 ].y = 100;
	
	self.shop[ 3 ] = newClientHudElem( self );
	self.shop[ 3 ].archived = false;
	self.shop[ 3 ].alignX = "center";
	self.shop[ 3 ].alignY = "middle";
	self.shop[ 3 ] setText( "Press ^3[{+attack}]^7 to ^3BUY^7 the hardpoint" );
	self.shop[ 3 ].horzAlign = "center";
	self.shop[ 3 ].vertAlign = "top";
	self.shop[ 3 ].fontscale = 1.7;
	self.shop[ 3 ].x = 0;
	self.shop[ 3 ].y = 120;
	
	self.shop[ 4 ] = newClientHudElem( self );
	self.shop[ 4 ].archived = false;
	self.shop[ 4 ].alignX = "center";
	self.shop[ 4 ].alignY = "middle";
	self.shop[ 4 ] setShader( "white", 145, 15 );
	self.shop[ 4 ].alpha = 0.3;
	self.shop[ 4 ].color = ( 1, 0.2, 0.2 );
	self.shop[ 4 ].horzAlign = "center";
	self.shop[ 4 ].vertAlign = "middle";
	self.shop[ 4 ].fontscale = 1.4;
	self.shop[ 4 ].x = -20;
	self.shop[ 4 ].y = -8;
}

exitShop()
{
	self endon( "disconnect" );
	
	self waittill_any_game( "destroy_shop", "death", "weapon_change" );
	
	self notify( "destroy_shop" );
	
	for( i = 0; i < self.shop.size; i++ )
	{
		if( isDefined( self.shop[ i ] ) )
			self.shop[ i ] destroy();
	}
	
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