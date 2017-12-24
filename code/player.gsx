#include code\file;

init()
{		
	thread code\events::addConnectEvent( ::onConnect );
	
	/#
	thread code\events::addSpawnEvent( ::waypointEditor );
	#/
}

onConnect()
{
	self endon( "disconnect" );
	
	dvar = "firstTime_" + self getEntityNumber();
	if( getDvar( dvar ) != self getPlayerID() )
	{
		self.pers[ "firstTime" ] = true;
		setDvar( dvar, self getPlayerID() );
	}
	
	if( !isDefined( self.pers[ "fullbright" ] ) )
	{
		if( level.dvar[ "mysql" ] )
		{
#if isSyscallDefined mysql_close
			self thread code\mysql::DBLookup();
#endif
		}
		else if( level.dvar[ "fs_players" ] )
			self thread FSLookup();
		else
			self thread statLookup();
	}
	
	if( !isDefined( self.pers[ "meleekills" ] ) )
	{
		self.pers[ "meleekills" ] = 0;
		self.pers[ "explosiveKills" ] = 0;
	}
	
	if( !isArray( self.pers[ "youVSfoe" ] ) )
	{
		self.pers[ "youVSfoe" ] = [];
		self.pers[ "youVSfoe" ][ "killedBy" ] = [];
		self.pers[ "youVSfoe" ][ "killed" ] = [];
	}
	
	if( self isVIP() )
		self.pers[ "vip" ] = true;
	
	self setClientDvar( "ui_ShowMenuOnly", "" ); // if admin rotates the map while in killcam
	
	if( level.dvar[ "reloadFix" ] )
		thread watchReload();
	
	/////////////////////////////////////////////////
	// Things we need to do on spawn but only once //
	/////////////////////////////////////////////////
	self waittill( "spawned_player" );
	
	if( !isDefined( self.pers[ "firstSpawnTime" ] ) )
		self.pers[ "firstSpawnTime" ] = getTime();
	
	if( !isDefined( game[ "firstPlayerSpawnTime" ] ) )
	{
		game[ "firstPlayerSpawnTime" ] = true;
		game[ "firstSpawnTime" ] = self.pers[ "firstSpawnTime" ];
	}
	
	if( level.dvar[ "welcome" ] && isDefined( self.pers[ "firstTime" ] ) )
		self thread welcome();
	
	while( !isDefined( self.pers[ "promodTweaks" ] ) )
		wait .05;
		
	waittillframeend;
	
	self thread userSettings();
	
	waittillframeend;
	
	if( level.dvar[ "gun_position" ] )
		self setClientDvars( "cg_gun_move_u", "1.5",
							 "cg_gun_move_f", "-1",
							 "cg_gun_ofs_u", "1",
							 "cg_gun_ofs_r", "-1",
							 "cg_gun_ofs_f", "-2" );
							 
	waittillframeend;
						 
	if( level.dvar[ "promod_sniper" ] )
		self setClientDvars( "player_breath_gasp_lerp", "0",
						 	 "player_breath_gasp_time", "0",
							 "player_breath_gasp_scale", "0", 
							 "cg_drawBreathHint", "0" );
							 
	waittillframeend;
							 
	if( level.dvar[ "fs_players" ] )
	{
		guid = self getGuid();
		level.FSCD[ guid ] = [];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "fullbright;" + self.pers[ "fullbright" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "fov;" + self.pers[ "fov" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "promodTweaks;" + self.pers[ "promodTweaks" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "hardpointSType;" + self.pers[ "hardpointSType" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "spec_keys;" + self.pers[ "spec_keys" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "killcamText;" + self.pers[ "killcamText" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "mu;" + self.pers[ "mu" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "sigma;" + self.pers[ "sigma" ];
	}
}

/*
Index:
	0 = Fullbright
	1 = Fov
	2 = Promod
	3 = ShopBtn
	4 = Spec Keys
	5 = Killcam text
	6 = Mean
	7 = Variance
*/
FSLookup()
{
	path = "./ne_db/players/" + self getGuid() + ".db";
	array = readFile( path );
	
	if( !isArray( array ) || array.size != 8 )
	{
		FSDefault();
		return;
	}
	
	for( i = 0; i < 8; i++ )
	{
		if( !isDefined( array[ i ] ) || array[ i ] == "" )
		{
			FSDefault();
			return;
		}
	}
	
	// Integer values
	n = 0;
	for( i = 0; i < 5; i++ )
	{
		tok = strTok( array[ i ], ";" );
		self.pers[ tok[ 0 ] ] = int( tok[ 1 ] );
		n++;
	}
	
	
	tok = strTok( array[ i ], ";" );
	self.pers[ tok[ 0 ] ] = tok[ 1 ];
	n++;
	
	
	for( i = n; i < array.size; i++ )
	{
		tok = strTok( array[ i ], ";" );
		self.pers[ tok[ 0 ] ] = float( tok[ 1 ] );
	}
	
	if( !level.dvar["cmd_fps"] )
		self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
	
	if( !level.dvar["cmd_fov"] )
		self.pers[ "fov" ] = level.dvar[ "default_fov" ];
	
	if( !level.dvar["cmd_promod"] )
		self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
	
	if( !level.dvar[ "shopbuttons_allowchange" ] )
		self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
	
	if( !level.dvar[ "cmd_spec_keys" ] )
		self.pers[ "spec_keys" ] = level.dvar[ "spec_keys_default" ];
		
	if( !level.dvar[ "kcemblem" ] )
		self.pers[ "killcamText" ] = level.dvar[ "kct_default" ];
}

FSDefault()
{
	self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
	self.pers[ "fov" ] = level.dvar[ "default_fov" ];
	self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
	self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
	self.pers[ "spec_keys" ] = level.dvar[ "spec_keys_default" ];
	self.pers[ "killcamText" ] = level.dvar[ "kct_default" ];
	// Trueskill
	self.pers[ "mu" ] = 25;
	self.pers[ "sigma" ] = 25 / 3;
}

FSSave( guid, time )
{
	waittillframeend;
	
	if( !isDefined( level.FSCD[ guid ] ) )
		return;
		
	for( i = 0; i < 8; i++ )
	{
		if( !isDefined( level.FSCD[ guid ][ i ] ) )
			return;
	}
	
#if isSyscallDefined TS_Rate
	if( isDefined( time ) && level.dvar[ "trueskill_punish" ] )
		code\trueskill::penality( guid, time );
#endif

	path = "./ne_db/players/" + guid + ".db";
	
	writeToFile( path, level.FSCD[ guid ] );
	
	wait .5;
	
	level.FSCD[ guid ] = undefined;
}

statLookup()
{
	self endon( "disconnect" );
	
	if( level.dvar["cmd_fps"] )
		self.pers[ "fullbright" ] = self getStat( 3160 );
	else
		self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
		
	wait .05;
			
	if( level.dvar["cmd_fov"] )
		self.pers[ "fov" ] = self getStat( 3161 );
	else
		self.pers[ "fov" ] = level.dvar[ "default_fov" ];
		
	wait .05;
			
	if( level.dvar["cmd_promod"] )
		self.pers[ "promodTweaks" ] = self getStat( 3162 );
	else
		self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
		
	wait .05;
	
	if( level.dvar[ "shopbuttons_allowchange" ] )
		self.pers[ "hardpointSType" ] = self getStat( 3163 );
	else
		self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
		
	wait .05;
	
	if( level.dvar[ "cmd_spec_keys" ] )
		self.pers[ "spec_keys" ] = self getStat( 3164 );
	else
		self.pers[ "spec_keys" ] = level.dvar[ "spec_keys_default" ];
		
	wait .05;
		
	if( isDefined( self.pers[ "firstTime" ] ) )
		self thread statIntegrityCheck();
}

statIntegrityCheck()
{
	if( abs( self.pers[ "fov" ] > 2 ) )
	{
		self.pers[ "fov" ] = 0;
		self setstat( 3161, 0 );
		self setClientDvar( "cg_fovscale", 1.0 );
		self setClientDvar( "cg_fov", 80 );
		self iprintlnbold( "Error: illegal fov value, setting 3161 to 0" );
	}
		
	if( self.pers[ "fullbright" ] != 1 && self.pers[ "fullbright" ] != 0 )
	{
		self setstat( 3160, 0 );
		self.pers[ "fullbright" ] = 0;
		self iprintlnbold( "Error: illegal fullbright value, setting 3160 to 0" );
	}
		
	if( self.pers[ "promodTweaks" ] != 1 && self.pers[ "promodTweaks" ] != 0 )
	{
		self setstat( 3162, 0 );
		self.pers[ "promodTweaks" ] = 0;
		self iprintlnbold( "Error: illegal promod value, setting 3162 to 0" );
	}
			
	if( self.pers[ "hardpointSType" ] != 1 && self.pers[ "hardpointSType" ] != 0 )
	{
		self setstat( 3163, 0 );
		self.pers[ "hardpointSType" ] = 0;
		self iprintlnbold( "Error: illegal shop value, setting 3163 to 0" );
	}
			
	if( self.pers[ "spec_keys" ] != 1 && self.pers[ "spec_keys" ] != 0 )
	{
		self setstat( 3164, 0 );
		self.pers[ "spec_keys" ] = 0;
		self iprintlnbold( "Error: illegal spec keys value, setting 3164 to 0" );
	}
}

userSettings()
{
	if( !isDefined( self.pers[ "fov" ] ) )
		return;

	switch( self.pers[ "fov" ] )
	{
		case 0:
			self setClientDvar( "cg_fovscale", 1.0 );
			self setClientDvar( "cg_fov", 80 );
			break;
		case 1:
			self setClientDvar( "cg_fovscale", 1.125 );
			self setClientDvar( "cg_fov", 80 );
			break;
		case 2:
		default:
			self setClientDvar( "cg_fovscale", 1.25 );
			self setClientDvar( "cg_fov", 80 );
			break;
	}

	waittillframeend;

	if( !isDefined( self.pers[ "fullbright" ] ) )
		return;
	
	if( self.pers[ "fullbright" ] == 1 )
		self setClientDvar( "r_fullbright", 1 );
	else
		self setClientDvar( "r_fullbright", 0 );
		
	waittillframeend;

	if( !isDefined( self.pers[ "promodTweaks" ] ) )
		return;
	
	if( self.pers[ "promodTweaks" ] == 1 )
		self SetClientDvars( "r_filmTweakInvert", "0",
                     	     "r_filmTweakBrightness", "0",
                     	     "r_filmusetweaks", "1",
                     	     "r_filmTweakenable", "1",
                      	     "r_filmtweakLighttint", "0.8 0.8 1",
                       	     "r_filmTweakContrast", "1.2",
                       	     "r_filmTweakDesaturation", "0",
                       	     "r_filmTweakDarkTint", "1.8 1.8 2" );
	else
		self SetClientDvars( "r_filmusetweaks", "0",
							 "r_filmTweakenable", "0" );
}

welcome()
{
	country = self getGeoLocation( 2 );
	if( !isSubStr( country, "N/" ) || !isDefined( country ) )
	{
		if( !isDefined( self.pers[ "vip" ] ) )
			exec( "say Welcome^5 " + self.name + " ^7from ^5" + country );
		else
			iprintlnbold( "Welcome ^3VIP^5 " + self.name + " ^7from ^5" + country );
	}
	else
	{
		if( !isDefined( self.pers[ "vip" ] ) )
			exec( "say Welcome^5 " + self.name );
		else
			iprintlnbold( "Welcome ^3VIP^5 " + self.name );
	}
		
	if( level.dvar[ "trueskill" ] )
	{
		self iprintlnbold( "This is a Trueskill enabled server," );
		self iprintlnbold( "Leaving early will count as a loss!" );
	}
}

isVIP()
{
	player = self getPlayerID();
	
	for( i = 0; i < 100; i++ )
	{
		vip = getDvar( "vip_" + i );
		if( vip == "" )
			break;

		else if( player == vip )
			return true;
	}
	
	return false;
}

// http://www.cod4dev.co.uk/index.php/forum/misc-scripts-coding/218-preventing-rapid-fire-keybind-cheats
watchReload()
{
	self endon( "disconnect" );

	for( ;; )
	{
		self waittill( "reload_start" );
		
		weap = self GetCurrentWeapon();
		if( weap == "none" || WeaponIsBoltAction( weap ) )
			continue;

		AmmoClip = self GetWeaponAmmoClip( weap );
		self SetWeaponAmmoClip( weap, 0 );

		if( !level.dvar[ "realReload" ] )
		{
			AmmoStock = self GetWeaponAmmoStock( weap );
			self setWeaponAmmoStock( weap,( AmmoStock + AmmoClip ) );
		}
	}
}

/#
waypointEditor()
{
	if( getDvarInt( "ending_editor" ) > 0 )
		self thread code\ending::editor();
}
#/