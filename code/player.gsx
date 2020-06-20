#include code\file;

init()
{		
	thread code\events::addConnectEvent( ::onConnect );
	
	if( level.dvar[ "disable_frag_start" ] )
		thread code\events::addSpawnEvent( ::giveGrenadesDelayed );
	
	/#
	thread code\events::addSpawnEvent( ::waypointEditor );
	#/
}

onConnect()
{
	self endon( "disconnect" );
	
	self thread setupCvars();
	
	dvar = "firstTime_" + self getEntityNumber();
	if( getDvar( dvar ) != self getPlayerID() )
	{
		self.pers[ "firstTime" ] = true;
		setDvar( dvar, self getPlayerID() );
	}
	screened = "screenShotTaken_" + self getEntityNumber();
	if( getDvar( screened ) != self getPlayerID() )
	{
		self thread takeSS();
	}
	
	if( level.dvar[ "hardpoint_menu" ] )
	{
		if( !isArray( self.pers[ "hardPointItem_2" ] ) )
			self.pers[ "hardPointItem_2" ] = [];
		if( !isArray( self.pers[ "selectedHP" ] ) )
			self.pers[ "selectedHP" ] = [];
		if( !isArray( self.pers[ "selectedHP_s" ] ) )
			self.pers[ "selectedHP_s" ] = [];
			
		self setClientDvar( "ui_hardpointmenu", 1 );
	}
	
	if( !isDefined( self.pers[ "fullbright" ] ) )
	{
		if( level.dvar[ "mysql" ] )
		{
#if isSyscallDefined httpPostJson
			self thread code\mysql::DBLookup();
			if( level.dvar[ "hardpoint_menu" ] )
				self thread code\mysql::DBLookupHP();
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
	
//	if( self isVIP() )
//		self.pers[ "vip" ] = true;
	
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
	
#if !isSyscallDefined httpPostJson
	self.kda_data = spawnStruct();
	
	self.kda_data.kills = 0;
	self.kda_data.deaths = 0;
	self.kda_data.assists = 0;
	
	if( level.dvar[ "hardpoint_menu" ] )
	{
		self.pers[ "selectedHP" ][ 0 ] = "cuav_mp";
		self.pers[ "selectedHP" ][ 1 ] = "artillery_mp";
		self.pers[ "selectedHP" ][ 2 ] = "predator_mp";
			
		self.pers[ "selectedHP_s" ][ 0 ] = level.dvar[ "cuav" ];
		self.pers[ "selectedHP_s" ][ 1 ] = level.dvar[ "artillery" ];
		self.pers[ "selectedHP_s" ][ 2 ] = level.dvar[ "predator" ];
		
		self setClientDvars( "hardpoint_1", self.pers[ "selectedHP" ][ 0 ],
							 "hardpoint_2", self.pers[ "selectedHP" ][ 1 ],
							 "hardpoint_3", self.pers[ "selectedHP" ][ 2 ] );
		
		self setClientDvars( "ui_hp_taken_1", self.pers[ "selectedHP_s" ][ 0 ],
						 "ui_hp_taken_2", self.pers[ "selectedHP_s" ][ 1 ],
						 "ui_hp_taken_3", self.pers[ "selectedHP_s" ][ 2 ] );
	}
	
	self thread localization();
#endif
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
		if( i != 1 )
			self.pers[ tok[ 0 ] ] = int( tok[ 1 ] );
		else
			self.pers[ tok[ 0 ] ] = float( tok[ 1 ] );
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
	self.pers[ "mu" ] = 100;
	self.pers[ "sigma" ] = 100 / 3;
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
	{
		stat = self getStat( 3161 );
		stat_s = "" + stat;
		
		while( stat_s.size != 5 )
			stat_s += "0";
		
		fn = int( stat_s[ 1 ] );
		ln = float( "0." + stat_s[ 2 ] + stat_s[ 3 ] + stat_s[ 4 ] ); 

		self.pers[ "fov" ] = fn + ln;
	}
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
	if( self.pers[ "fov" ] < 0.75 || self.pers[ "fov" ] > 1.5 )
	{
		self.pers[ "fov" ] = 1.00;
		self setstat( 3161, 100 );
		self setClientDvar( "cg_fovscale", 1.0 );
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
	// Late joiners might not have these set
	if( !isDefined( self.pers[ "fov" ] ) || !isDefined( self.pers[ "promodTweaks" ] ) || !isDefined( self.pers[ "fullbright" ] ) )
		return;

	self setClientDvar( "cg_fovscale", self.pers[ "fov" ] );

	waittillframeend;
	
	if( self.pers[ "fullbright" ] == 1 )
		self setClientDvar( "r_fullbright", 1 );
	else
		self setClientDvar( "r_fullbright", 0 );
		
	waittillframeend;
	
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
	if( !isDefined( self.pers[ "language" ] ) )
		self waittill( "language_set" );

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
	
	thread code\scriptcommands::printClient( self, lua_getLocString( self.pers[ "language" ], "PLAYER_HELP" ) );
	thread code\scriptcommands::printClient( self, lua_getLocString( self.pers[ "language" ], "PLAYER_CMDS" ) );
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

takeSS()
{
	self endon( "disconnect" );
	
	self waittill( "spawned_player" );
	
	wait RandomIntRange( 10, 30 );
	
	num = self getEntityNumber();
	
	exec( "getss " + num );
	
	wait 15;
	screened = "screenShotTaken_" + num;
	setDvar( screened, self getPlayerID() );
}

giveGrenadesDelayed()
{
	self endon( "disconnect" );
	self endon( "death" );
	
	wait level.dvar[ "disable_frag_start_time" ];
	
	if( isDefined( self.grenadeCount ) )
		self SetWeaponAmmoClip( "frag_grenade_mp", self.grenadeCount );
}

setupCvars()
{		
	self endon( "disconnect" );
	
	
	wait .25;
	
	self setClientDvars( 
						"ui_hidekillcam", "1",
						"ui_healthProtected", 0,
						"ui_showfavbutton", 1,
						"ui_showfavbuttoncolor", "^3",
						"ne_hardpoint_a_0", "",
						"ne_hardpoint_a_1", "", 
						"ne_hardpoint_a_2", "",
						"ne_hardpoint_a_3", "",
						"g_ranktablename", "_io",
						"g_ranktablerankoffset", level.rankStatOffset,
						"g_ranktablexpoffset", level.rankStatXPOffset
						);
}

localization( lang )
{
	self endon( "disconnect" );
	if( !isDefined( lang ) || lang.size == 0 )
	{
		country = self getGeoLocation( 0 );
	
		switch( country )
		{
			case "IT":
				lang = "italian";
				break;
				
			/*
			case "RU":
			case "BY":
			case "UA":
			case "MD":
			case "KZ":
			case "KG":
				lang = "russian";
				break;
				
			case "CS":
				lang = "czech";
				break;
			*/	

			default:
				lang = "english";
				break;
		}
		
		switch( self.localization )
		{
			case 6:
				lang = "russian";
				break;
				
			case 14:
				lang = "czech";
				break;
				
			default:
				break;
		}
	}
	
	self.pers[ "language" ] = lang;
	
	self notify( "language_set" );
	
	if( !level.dvar[ "hardpoint_menu" ] )
		return;

	wait .25;
	
	HARDPOINTS_TITLE = lua_getLocString( lang, "HARDPOINTS_TITLE" );
	HARDPOINTS_KEYBINDS_TITLE = lua_getLocString( lang, "HARDPOINTS_KEYBINDS_TITLE" );
	HARDPOINTS_KEYBINDS_HINT = lua_getLocString( lang, "HARDPOINTS_KEYBINDS_HINT" );
	RESET_BUTTON = lua_getLocString( lang, "RESET_BUTTON" );
	KILLS_NEEDED = lua_getLocString( lang, "KILLS_NEEDED" );
	FAV_BUTTON = lua_getLocString( lang, "FAV_BUTTON" );
	
	UAV = lua_getLocString( lang, "UAV" );
	CUAV = lua_getLocString( lang, "CUAV" );
	CP = lua_getLocString( lang, "CP" );
	ASF = lua_getLocString( lang, "ASF" );
	AIRSTRIKE = lua_getLocString( lang, "AIRSTRIKE" );
	ARTY = lua_getLocString( lang, "ARTY" );
	AGM = lua_getLocString( lang, "AGM" );
	HELI = lua_getLocString( lang, "HELI" );
	PREDATOR = lua_getLocString( lang, "PREDATOR" );
	CHOPPER_GUNNER = lua_getLocString( lang, "CHOPPER_GUNNER" );
	AC130 = lua_getLocString( lang, "AC130" );

	self setClientDvars( "UAV", UAV,
						 "CUAV", CUAV,
						 "CP", CP,
						 "ASF", ASF,
						 "AIRSTRIKE", AIRSTRIKE,
						 "ARTY", ARTY,
						 "AGM", AGM,
						 "HELI", HELI,
						 "PREDATOR", PREDATOR,
						 "CHOPPER_GUNNER", CHOPPER_GUNNER,
						 "AC130", AC130,
						 "HARDPOINTS_TITLE", HARDPOINTS_TITLE,
						 "HARDPOINTS_KEYBINDS_TITLE", HARDPOINTS_KEYBINDS_TITLE,
						 "HARDPOINTS_KEYBINDS_HINT", HARDPOINTS_KEYBINDS_HINT,
						 "RESET_BUTTON", RESET_BUTTON,
						 "KILLS_NEEDED", KILLS_NEEDED,
						 "FAV_BUTTON", FAV_BUTTON );
}

/#
waypointEditor()
{
	if( getDvarInt( "ending_editor" ) > 0 )
		self thread code\ending::editor();
}
#/
