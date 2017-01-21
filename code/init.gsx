GloballogicInit()
{
	thread code\dvars::init();
	thread code\events::init();
	thread fx_cache();
}

startGameType()
{
	thread code\scriptcommands::init();
	thread code\heli::plotMap();

	if( !level.dvar[ "old_hardpoints" ] )
		thread code\hardpoints::init(); 
		
	thread code\player::init();
	thread code\killcam_settings::init();
	
	if( level.dvar[ "spawn_protection" ] )
		thread code\spawnprotection::init();
	
	thread serverDvars();
	thread code\ending::setup();
	thread code\spectating::init();
	
	if( level.dvar[ "rcon_interface" ] )
		thread code\rcon_commands::rconSupport();
		
		
	// Dev only
	//thread code\_dBots::init();
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
	}
}