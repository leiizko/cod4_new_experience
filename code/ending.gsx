/*
	level.bestPlayers[ 0 ] = name
	level.bestPlayers[ 1 ] = value
	level.bestPlayers[ x ][ 0 ] = kills
	level.bestPlayers[ x ][ 1 ] = deaths
	level.bestPlayers[ x ][ 2 ] = knife kills
	level.bestPlayers[ x ][ 3 ] = headshots
	
	dvar example: mp_backlot_kills "leiizko;40"
*/
init()
{
	players = getEntarray( "player", "classname" );
	sLoc = getLoc();
	sAng = getAng();
	
	waittillframeend;
	
	for( i = 0; i < players.size; i++ )
	{
		player = players[i];
		
		player thread maps\mp\gametypes\_globallogic::spawnSpectator( sLoc, sAng );
		player freezeControls( true );
	}
	
	level.bestPlayers = [];
	level.bestPlayers[ 0 ] = [];
	level.bestPlayers[ 1 ] = [];
	
	level.bestPlayers[ 0 ][ 0 ] = "";
	level.bestPlayers[ 0 ][ 1 ] = "";
	level.bestPlayers[ 0 ][ 2 ] = "";
	level.bestPlayers[ 0 ][ 3 ] = "";
	
	level.bestPlayers[ 1 ][ 0 ] = 0;
	level.bestPlayers[ 1 ][ 1 ] = 0;
	level.bestPlayers[ 1 ][ 2 ] = 0;
	level.bestPlayers[ 1 ][ 3 ] = 0;
	
	waittillframeend;
	
	players = code\common::getPlayers();
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( level.bestPlayers[ 1 ][ 0 ] < player.pers[ "kills" ] )
		{
			level.bestPlayers[ 1 ][ 0 ] = player.pers[ "kills" ];
			level.bestPlayers[ 0 ][ 0 ] = player.name;
		}
		
		if( level.bestPlayers[ 1 ][ 1 ] < player.pers[ "deaths" ] )
		{
			level.bestPlayers[ 1 ][ 1 ] = player.pers[ "deaths" ];
			level.bestPlayers[ 0 ][ 1 ] = player.name;
		}
		
		if( level.bestPlayers[ 1 ][ 2 ] < player.pers[ "meleekills" ] )
		{
			level.bestPlayers[ 1 ][ 2 ] = player.pers[ "meleekills" ];
			level.bestPlayers[ 0 ][ 2 ] = player.name;
		}
		
		if( level.bestPlayers[ 1 ][ 3 ] < player.pers[ "headshots" ] )
		{
			level.bestPlayers[ 1 ][ 3 ] = player.pers[ "headshots" ];
			level.bestPlayers[ 0 ][ 3 ] = player.name;
		}
		
		if( isDefined( player.moneyhud ) )
			player.moneyhud destroy();
			
		waittillframeend;
	}
	
	ambientStop( 1 );
	
	bestPlayers();
	credits();
}

bestPlayers()
{
	prefix = toLower( getDvar( "mapname" ) );
	
	var = [];
	var[ 0 ] = prefix + "_kills";
	var[ 1 ] = prefix + "_deaths";
	var[ 2 ] = prefix + "_knives";
	var[ 3 ] = prefix + "_headshots";
	
	data = [];
	data[ 0 ] = getDvar( var[ 0 ] );
	data[ 1 ] = getDvar( var[ 1 ] );
	data[ 2 ] = getDvar( var[ 2 ] );
	data[ 3 ] = getDvar( var[ 3 ] );
	
	// True if new record
	new = [];
	new[ 0 ] = undefined;
	new[ 1 ] = undefined;
	new[ 2 ] = undefined;
	new[ 3 ] = undefined;
	
	split = [];
	
	for( i = 0; i < data.size; i++ )
	{
		split[ i ] = strTok( data[ i ], ";" );
		
		if( data[ i ] != "" )
		{
			if( level.bestPlayers[ 0 ][ i ] != "" && int( split[ i ][ 1 ] ) < level.bestPlayers[ 1 ][ i ] )
			{
				data[ i ] = level.bestPlayers[ 0 ][ i ] + ";" + level.bestPlayers[ 1 ][ i ];
				new[ i ] = true;
				setDvar( var[ i ], data[ i ] );
			}
			else
				continue;
		}
		
		else
		{
			if( level.bestPlayers[ 0 ][ i ] != "" )
			{
				data[ i ] = level.bestPlayers[ 0 ][ i ] + ";" + level.bestPlayers[ 1 ][ i ];
				new[ i ] = true;
				setDvar( var[ i ], data[ i ] );
			}
			else
				continue;
		}
		
		waittillframeend;
	}
	
///////////////////////////////////////////////////////////////////
///////////////////////////// KILLS ///////////////////////////////
///////////////////////////////////////////////////////////////////
	
	i = 0;
	split[ i ] = strTok( data[ i ], ";" );
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "center";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "center";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = 0;
	level.ending[ i ].glowColor = ( randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ) );
	level.ending[ i ].glowAlpha = 0;
	level.ending[ i ].fontScale = 2;
	level.ending[ i ].alpha = 0;
	level.ending[ i ].archived = false;

	if( data[ i ] != "" && isDefined( new[ i ] ) && new[ i ] && int( split[ i ][ 1 ] ) > 0 )
		level.ending[ i ] setText( "( NEW! ) KILL RECORD - " + split[ i ][ 0 ] + " with " + split[ i ][ 1 ] + " kills!" );
		
	else if( data[ i ] != "" && int( split[ i ][ 1 ] ) > 0 )
		level.ending[ i ] setText( "KILL RECORD - " + split[ i ][ 0 ] + " with " + split[ i ][ 1 ] + " kills!" );
		
	else
		level.ending[ i ] setText( "No kill record ( yet! :) )" );
		
	level.ending[ i ] fadeOverTime( 1 );
	
	level.ending[ i ].alpha = 1;
	level.ending[ i ].glowAlpha = 1;
		
///////////////////////////////////////////////////////////////////
///////////////////////////// DEATHS //////////////////////////////
///////////////////////////////////////////////////////////////////
		
	i = 1;
	split[ i ] = strTok( data[ i ], ";" );
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "center";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "center";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = 30;
	level.ending[ i ].glowColor = ( randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ) );
	level.ending[ i ].glowAlpha = 0;
	level.ending[ i ].fontScale = 2;
	level.ending[ i ].alpha = 0;
	level.ending[ i ].archived = false;

	if( data[ i ] != "" && isDefined( new[ i ] ) && new[ i ] && int( split[ i ][ 1 ] ) > 0 )
		level.ending[ i ] setText( "( NEW! ) DEATHS RECORD - " + split[ i ][ 0 ] + " with " + split[ i ][ 1 ] + " deaths!" );
		
	else if( data[ i ] != "" && int( split[ i ][ 1 ] ) > 0 )
		level.ending[ i ] setText( "DEATHS RECORD - " + split[ i ][ 0 ] + " with " + split[ i ][ 1 ] + " deaths!" );
		
	else
		level.ending[ i ] setText( "No deaths record ( yet! :) )" );
		
	level.ending[ i ] fadeOverTime( 1.5 );
	
	level.ending[ i ].alpha = 1;
	level.ending[ i ].glowAlpha = 1;
		
///////////////////////////////////////////////////////////////////
////////////////////////// MELEEKILLS /////////////////////////////
///////////////////////////////////////////////////////////////////
		
	i = 2;
	split[ i ] = strTok( data[ i ], ";" );
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "center";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "center";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = 60;
	level.ending[ i ].glowColor = ( randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ) );
	level.ending[ i ].glowAlpha = 0;
	level.ending[ i ].fontScale = 2;
	level.ending[ i ].alpha = 0;
	level.ending[ i ].archived = false;

	if( data[ i ] != "" && isDefined( new[ i ] ) && new[ i ] && int( split[ i ][ 1 ] ) > 0 )
		level.ending[ i ] setText( "( NEW! ) MELEE RECORD - " + split[ i ][ 0 ] + " with " + split[ i ][ 1 ] + " melee kills!" );
		
	else if( data[ i ] != "" && int( split[ i ][ 1 ] ) > 0 )
		level.ending[ i ] setText( "MELEE RECORD - " + split[ i ][ 0 ] + " with " + split[ i ][ 1 ] + " melee kills!" );
		
	else
		level.ending[ i ] setText( "No melee record ( yet! :) )" );
		
	level.ending[ i ] fadeOverTime( 2 );
	
	level.ending[ i ].alpha = 1;
	level.ending[ i ].glowAlpha = 1;
	
///////////////////////////////////////////////////////////////////
/////////////////////////// HEADSHOTS /////////////////////////////
///////////////////////////////////////////////////////////////////
	
	i = 3;
	split[ i ] = strTok( data[ i ], ";" );
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "center";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "center";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = 90;
	level.ending[ i ].glowColor = ( randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ) );
	level.ending[ i ].glowAlpha = 0;
	level.ending[ i ].fontScale = 2;
	level.ending[ i ].alpha = 0;
	level.ending[ i ].archived = false;

	if( data[ i ] != "" && isDefined( new[ i ] ) && new[ i ] && int( split[ i ][ 1 ] ) > 0 )
		level.ending[ i ] setText( "( NEW! ) HEADSHOT RECORD - " + split[ i ][ 0 ] + " with " + split[ i ][ 1 ] + " headshots!" );
		
	else if( data[ i ] != "" && int( split[ i ][ 1 ] ) > 0 )
		level.ending[ i ] setText( "HEADSHOT RECORD - " + split[ i ][ 0 ] + " with " + split[ i ][ 1 ] + " headshots!" );
		
	else
		level.ending[ i ] setText( "No headshot record ( yet! :) )" );
		
	level.ending[ i ] fadeOverTime( 2.5 );
	
	level.ending[ i ].alpha = 1;
	level.ending[ i ].glowAlpha = 1;
		
///////////////////////////////////////////////////////////////////
/////////////////////////// SHADERS ///////////////////////////////
///////////////////////////////////////////////////////////////////

	i = 4;
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "center";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "center";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = -274;
	level.ending[ i ] setShader( "killiconheadshot", 64, 64 );
	level.ending[ i ].alpha = 1;
	level.ending[ i ].archived = false;
	
	level.ending[ i ] moveOverTime( 2 );
	
	level.ending[ i ].y = -100;
	
	i = 5;
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "left";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "left";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = 10;
	level.ending[ i ].x = -75;
	level.ending[ i ] setShader( "killiconmelee", 64, 64 );
	level.ending[ i ].alpha = 1;
	level.ending[ i ].archived = false;
	
	level.ending[ i ] moveOverTime( 2 );
	
	level.ending[ i ].x = 75;
	
	i = 6;
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "right";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "right";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = 10;
	level.ending[ i ].x = 75;
	level.ending[ i ] setShader( "killiconsuicide", 64, 64 );
	level.ending[ i ].alpha = 1;
	level.ending[ i ].archived = false;
	
	level.ending[ i ] moveOverTime( 2 );
	
	level.ending[ i ].x = -75;

	wait 7;

	for( i = 0; i < level.ending.size; i++ )
	{
		level.ending[ i ] fadeOverTime( 3 );
		level.ending[ i ].alpha = 0;
		
		waittillframeend;
	}
	
	wait 3;
	
	for( i = 0; i < level.ending.size; i++ )
	{
		level.ending[ i ] destroy();
		
		waittillframeend;
	}	
}

credits()
{
	level.ending = [];
	
	i = level.ending.size;
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "center";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "center";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = -260;
	level.ending[ i ].x = 0;
	level.ending[ i ].glowColor = ( randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ) );
	level.ending[ i ].glowAlpha = 1;
	level.ending[ i ].fontScale = 3;
	level.ending[ i ].alpha = 1;
	level.ending[ i ].archived = false;
	level.ending[ i ] setText( level.dvar[ "credit_text" ] );
	level.ending[ i ] SetPulseFX( 80, 8000, 2000 );
	
	level.ending[ i ] moveOverTime( 4 );
	
	level.ending[ i ].y = -20;
	
	i = level.ending.size;
	
	level.ending[ i ] = newHudElem();
	level.ending[ i ].horzAlign = "center";
	level.ending[ i ].vertAlign = "middle";
	level.ending[ i ].alignX = "center";
	level.ending[ i ].alignY = "middle";
	level.ending[ i ].y = 260;
	level.ending[ i ].x = 0;
	level.ending[ i ].glowColor = ( 0, 0, 1 );
	level.ending[ i ].glowAlpha = 1;
	level.ending[ i ].fontScale = 2.6;
	level.ending[ i ].alpha = 1;
	level.ending[ i ].archived = false;
	level.ending[ i ] setText( "By Leiizko" );
	level.ending[ i ] SetPulseFX( 240, 8000, 2000 );
	
	level.ending[ i ] moveOverTime( 4 );
	
	level.ending[ i ].y = 20;
	
	wait 10;
	
	for( i = 0; i < level.ending.size; i++ )
	{
		level.ending[ i ] destroy();
		
		waittillframeend;
	}
}

setup()
{
	thread code\events::addDeathEvent( ::onPlayerKilled );
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	waittillframeend;
	
	if( sMeansOfDeath == "MOD_MELEE" && isDefined( attacker ) )
		attacker.pers[ "meleekills" ]++;
}

/*
	Some of this positions and angles are a bit off
	Depending on CoD switch vs if statements performance adjust below code accordingly
	missing: Killhouse, shipment, chinatown
*/

getLoc()
{
	loc = undefined;
	
	map = getDvar( "mapname" );
	
	switch(map)
	{
		case "mp_backlot":
			loc = (656.731, 1853.1, 64.125);
			break;
		case "mp_bloc":
			loc = (-655.601, -1547.25, 571.784);
			break;
		case "mp_bog":
			loc = (-4415.65, -15.6626, 52.552);
			break;
		case "mp_cargoship":
			loc = (1838.28, 349.865, 165.437);
			break;
		case "mp_citystreets":
			loc = (5257.22, -151.651, 281.967);
			break;
		case "mp_convoy":
			loc = (4521.64, 3391.34, 109.336);
			break;
		case "mp_countdown":
			loc = (6619.84, -4082.8, 1109.13);
			break;
		case "mp_crash":
		case "mp_crash_snow":
			loc = (2179.16, 29.1966, 95.4196);
			break;
		case "mp_crossfire":
			loc = (3255.58, 305.262, -25.875);
			break;
		case "mp_downpour":
			loc = (-1463.01, -2571.35, 161.825);
			break;
		case "mp_overgrown":
			loc = (-2078.23, -5482.13, -139.344);
			break;
		case "mp_pipeline":
			loc = (2715.33, 3153.56, 291.236);
			break;
		case "mp_showdown":
			loc = (11.0894, 2090.79, -1.875);
			break;
		case "mp_strike":
			loc = (-2894.76, 1397.75, 1.63746);
			break;
		case "mp_vacant":
			loc = (2583.85, -136.047, -91.875);
			break;
		default:
			loc = loc;
			break;
	}
	
	return loc;
}

getAng()
{
	ang = undefined;
	
	map = getDvar( "mapname" );
	
	switch(map)
	{
		case "mp_backlot":
			ang = (0, 34.8267, 0);
			break;
		case "mp_bloc":
			ang = (0, -72.9053, 0);
			break;
		case "mp_bog":
			ang = (0, -144.456, 0);
			break;
		case "mp_cargoship":
			ang = (0, -22.8978, 0);
			break;
		case "mp_citystreets":
			ang = (0, -133.577, 0);
			break;
		case "mp_convoy":
			ang = (0, -127.947, 0);
			break;
		case "mp_countdown":
			ang = (0, 144.69, 0);
			break;
		case "mp_crash":
		case "mp_crash_snow":
			ang = (0, -1.57104, 0);
			break;
		case "mp_crossfire":
			ang = (0, 90.3735, 0);
			break;
		case "mp_downpour":
			ang = (0, -145.764, 0);
			break;
		case "mp_overgrown":
			ang = (0, -79.0173, 0);
			break;
		case "mp_pipeline":
			ang = (0, 55.7287, 0);
			break;
		case "mp_showdown":
			ang = (0, 90.4779, 0);
			break;
		case "mp_strike":
			ang = (0, -1.1261, 0);
			break;
		case "mp_vacant":
			ang = (0, 179.654, 0);
			break;
		default:
			ang = ang;
			break;
	}
	
	return ang;
}