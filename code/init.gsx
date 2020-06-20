GloballogicInit()
{
	thread code\dvars::init();
	thread code\events::init();
	thread fx_cache();
	thread prestigeIcons();
	level.majorXver = 18;
	level.minorXver = 0;
	level.openFiles = [];
	level.FSCD = [];
	level.UAVinUse = [];
	level.rankStatOffset = 2915; // 3167
	level.rankStatXPOffset = 865; // 3166
	level.rankStatMinXPOffset = 817; // 3168
	level.rankStatMaxXPOffset = 817; // 3169
	thread news();
}

startGameType()
{
#if isSyscallDefined TS_Rate
	if( level.dvar[ "trueskill" ] )
		thread code\trueskill::init();
#else
	setDvar( "trueskill", 0 );
	level.dvar[ "trueskill" ] = 0;
#endif

#if isSyscallDefined httpPostJson
	if( level.dvar[ "mysql" ] )
		thread code\mysql::init();
#else
	setDvar( "mysql", 0 );
	level.dvar[ "mysql" ] = 0;
#endif

	if( level.dvar[ "mysql" ] )
		level.dvar[ "fs_players" ] = 0;
		
	if( !level.dvar[ "trueskill" ] )
		level.dvar[ "trueskill_punish" ] = 0;

	thread code\scriptcommands::init();
	thread code\heli::plotMap();

	if( !level.dvar[ "old_hardpoints" ] )
		thread code\hardpoints::init();
		
	thread code\player::init();
	//thread code\kda::init();
	
	if( level.dvar[ "final_killcam" ] )
		thread code\killcam_settings::init();
		
	if( level.killcam )	
		thread code\killcam_settings::kcCache();
	
	if( level.dvar[ "spawn_protection" ] )
		thread code\spawnprotection::init();
	
	thread serverDvars();
	thread code\ending::setstuff();
	thread code\spectating::init();
	thread code\cp::cp_init();
	thread code\cuav::init();
	
	if( level.dvar[ "dynamic_rotation_enable" ] )
		thread code\dynamic_rotation::init();
	
	if( level.dvar[ "rcon_interface" ] )
		thread code\rcon_commands::rconSupport();
	
	if( level.dvar[ "mapvote" ] && !level.dvar[ "dynamic_rotation_enable" ] )
		thread code\mapvote::init();
		
	if( level.dvar[ "strat" ] )
		thread code\strat::init();
		
	if( level.dvar[ "anticamp" ] )
		thread code\anticamp::init();
		
	if( getDvarInt( "remove_turrets" ) )
	{
		turrets = getEntArray( "misc_turret", "classname" );
		for( i = 0; i < turrets.size; i++ )
		{
			turrets[ i ] delete();
		}
	}
		
	// Dev only
	if( getDvarInt( "developer" ) > 0 )
		thread code\_dBots::init();
	
	thread setAndDeleteHQ();
	thread setBlockers();
}

fx_cache()
{
	precacheItem( "mi28_mp" );
	precacheModel( "projectile_hellfire_missile" );
	precacheModel( "projectile_cbu97_clusterbomb" );
	precacheModel( "vehicle_mi-28_flying" );
	precacheModel( "projectile_at4" );
	precacheModel( "projectile_sa6_missile_woodland" );
	precacheModel( "projectile_sidewinder_missile" );
	precacheModel( "com_plasticcase_beige_big" );
	precacheModel( "weapon_ac130_projectile" );
	precacheModel( "vehicle_ac130_low" );
	precacheModel( "vehicle_uav" );
	precacheShader( "waypoint_kill" );
	precacheShader( "killiconsuicide" );
	precacheShader( "killiconmelee" );
	precacheShader( "killiconheadshot" );
	precacheShader( "cp_mark_mp" );
	precacheShader( "ac130_overlay_25mm" );
	precacheShader( "ac130_overlay_40mm" );
	precacheShader( "ac130_overlay_105mm" );
	precacheShader( "ac130_overlay_grain" );

	level.hardEffects = [];
	level.hardEffects[ "artilleryExp" ] = loadfx("explosions/artilleryExp_dirt_brown");
	level.hardEffects[ "hellfireGeo" ] = loadfx("smoke/smoke_geotrail_hellfire");
	level.hardEffects[ "tankerExp" ] = loadfx( "explosions/tanker_explosion" );
	level.hardEffects[ "smallExp" ] = loadfx( "impacts/large_mud" );
	level.hardEffects[ "fire" ] = loadfx( "fire/tank_fire_engine" );
	level.hardEffects[ "105mm" ] = loadfx( "impacts/ac130_105mm_IR_impact" );
	level.hardEffects[ "40mm" ] = loadfx( "impacts/ac130_40mm_IR_impact" );
	level.hardEffects[ "25mm" ] = loadfx( "impacts/ac130_25mm_IR_impact" );
	level.hardEffects[ "heliTurret" ] = loadfx( "muzzleflashes/bmp_flash_wv" );
//	level.hardEffects[ "nukeAsh" ] = loadfx( "weather/ash_turb_aftermath" );
	level.hardEffects[ "nukeExp" ] = loadfx( "explosions/nuke" );
	
	/#
	level.pointEffext = loadfx( "misc/ui_pickup_unavailable" );
	#/
}

serverDvars()
{
	if( level.dvar[ "promod_sniper" ] )
	{
		setDvar( "player_breath_gasp_lerp", "0" );
		setDvar( "player_breath_gasp_time", "0" );
		setDvar( "player_breath_gasp_scale", "0" );
	}
	
	wait .05;
	
	if( level.dvar[ "fast_paced" ] )
	{
		setDvar( "player_sprinttime", 8 );
		setDvar( "g_gravity", 600 );
		setDvar( "g_speed", 210 );
		setDvar( "jump_height", 45 );
		setDvar( "player_sprintspeedscale", 1.6 );
		setDvar( "bg_bobAmplitudeDucked", "0 0" );
		setDvar( "bg_bobAmplitudeProne", "0 0" );
		setDvar( "bg_bobAmplitudeSprinting", "0 0" );
		setDvar( "bg_bobAmplitudeStanding", "0 0" );
		setDvar( "bg_bobMax", "0" );
	}
	
	wait .05;
	
	exec( "sets _mod New Experience" );
	exec( "sets _modVer 2.0.3" );
}

prestigeIcons()
{
	preCacheStatusIcon( "rank_prestige10" );
	preCacheStatusIcon( "rank_prestige9" );
	preCacheStatusIcon( "rank_prestige8" );
	preCacheStatusIcon( "rank_prestige6" );
	
	precacheShader( "rank_prestige10" );
	precacheShader( "rank_prestige9" );
	precacheShader( "rank_prestige8" );
	precacheShader( "rank_prestige6" );
}

setAndDeleteHQ()
{
	radios = getentarray( "hq_hardpoint", "targetname" );
	
	otherVisuals = getEntArray( radios[ 0 ].target, "targetname" );
	level.radioent = otherVisuals[ 2 ];
	
	pitch = getAngleOffset( otherVisuals[ 0 ].angles[ 0 ] );
	yaw = getAngleOffset( otherVisuals[ 0 ].angles[ 1 ] );
	roll = getAngleOffset( otherVisuals[ 0 ].angles[ 2 ] );
	
	level.radioentoffset = ( pitch, yaw, roll );
	
	if( getDvar( "g_gametype" ) == "koth" )
		return;
		
	for ( i = 0; i < radios.size; i++ )
	{
		radio = radios[ i ];
		
		if( i == 0 )
		{
			visuals = [];
			visuals[0] = radio;
			
			otherVisuals = getEntArray( radio.target, "targetname" );
			for ( j = 0; j < otherVisuals.size; j++ )
				visuals[ visuals.size ] = otherVisuals[ j ];
				
			for( n = 0; n < visuals.size; n++ )
			{
				if( n == 1 || n == 3 )
				{
					visuals[ n ] hide();
					if ( visuals[ n ].classname == "script_brushmodel" || visuals[ n ].classname == "script_model" )
						visuals[ n ] notsolid();
				}
				else
					visuals[ n ] delete();
			}
		}
		else
		{
			otherVisuals = getEntArray( radio.target, "targetname" );
			for ( j = 0; j < otherVisuals.size; j++ )
				otherVisuals[ j ] delete();
				
			radio delete();
		}
	}
}

getAngleOffset( ang )
{
	if ( ang == 0 )
		return 0;

	if( ang > 180 )
		ang -= 180;
		
	if( ang == 90 )
		offset = 90;
	else
	{
		if( ang > 90 )
			offset = 180 - ang;
		else			
			offset = -1 * ang;
	}
	
	return offset;
}

setBlockers()
{
	map = getDvar( "mapname" );
	level.blockers = [];
	
	switch( map )
	{
		case "mp_convoy":
			precacheModel( "mil_sandbag_desert_single_flat" );
			
			i = level.blockers.size;
			level.blockers[ i ] = spawn( "script_model", ( 640.0, 23.2, 90.2 ) );
			level.blockers[ i ] setModel( "mil_sandbag_desert_single_flat" );
			level.blockers[ i ].angles = ( 0, 60, 0 );
			break;
		default:
			break;
	}
}

news()
{
	level endon( "game_ended" );
	
	time = getDvarInt( "news_timer" );
	if( time == 0 )
		time = 240;
	
	texts = [];
	for( i = 0; i < 20; i++ )
	{
		txt = getDvar( "news_text_" + i );
		
		if( txt.size > 0 )
			texts[ i ] = txt;
		else
			break;
	}
	
	if( texts.size == 0 )
		texts[ 0 ] = "^5We are looking for server admins! ^3Visit iceops.co";
	
	for( ;; )
	{
		for( i = 0; i < texts.size; i++ )
		{
			wait time;
			
			exec( "say " + texts[ i ] );
		}
	}
}