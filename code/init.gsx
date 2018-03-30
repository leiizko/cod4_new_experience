GloballogicInit()
{
	thread code\dvars::init();
	thread code\events::init();
	thread fx_cache();
	thread prestigeIcons();
	level.openFiles = [];
	level.FSCD = [];
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

#if isSyscallDefined mysql_close
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
	
	if( level.dvar[ "final_killcam" ] )
		thread code\killcam_settings::init();
		
	if( level.killcam )	
		thread code\killcam_settings::kcCache();
	
	if( level.dvar[ "spawn_protection" ] )
		thread code\spawnprotection::init();
	
	thread serverDvars();
	thread code\ending::setstuff();
	thread code\spectating::init();
	
	if( level.dvar[ "rcon_interface" ] )
		thread code\rcon_commands::rconSupport();
	
	if( level.dvar[ "mapvote" ] )
		thread code\mapvote::init();
		
	if( level.dvar[ "strat" ] )
		thread code\strat::init();
		
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
		
	if( level.dvar[ "dynamic_rotation_enable" ] )
		thread code\dynamic_rotation::init();
}

fx_cache()
{
	precacheModel( "projectile_hellfire_missile" );
	precacheModel( "projectile_cbu97_clusterbomb" );
	PreCacheShellShock( "radiation_low" );
	PreCacheShellShock( "radiation_med" );
	PreCacheShellShock( "radiation_high" );
	precacheShader( "waypoint_kill" );
	precacheShader( "killiconsuicide" );
	precacheShader( "killiconmelee" );
	precacheShader( "killiconheadshot" );

	level.hardEffects = [];
	level.hardEffects[ "artilleryExp" ] = loadfx("explosions/artilleryExp_dirt_brown");
	level.hardEffects[ "hellfireGeo" ] = loadfx("smoke/smoke_geotrail_hellfire");
	level.hardEffects[ "tankerExp" ] = loadfx( "explosions/tanker_explosion" );
	level.hardEffects[ "smallExp" ] = loadfx( "impacts/large_mud" );
	level.hardEffects[ "fire" ] = loadfx( "fire/tank_fire_engine" );
	
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
	
	if( level.dvar[ "fast_paced" ] )
	{
		setDvar( "player_sprinttime", 8 );
		setDvar( "g_gravity", 600 );
		setDvar( "g_speed", 210 );
		setDvar( "jump_height", 45 );
		setDvar( "player_sprintspeedscale", 1.6 );
	}
	
	exec( "sets _mod New Experience" );
	exec( "sets _modVer 1.2.5" );
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