#include code\file;

init()
{
	level.movingEnding = spawn( "script_model", level.endingPoints[ 0 ][ 0 ] );
	level.movingEnding.angles = level.endingPoints[ 0 ][ 1 ];
	level.movingEnding setModel( "tag_origin" );
	level.movingEnding hide();
	
	time = 20;
	if( level.dvar[ "mapvote" ] )
		time += level.dvar[ "mapvote_time" ] + 4.25;
	if( level.dvar[ "gametypeVote" ] )
		time += level.dvar[ "mapvote_time" ];
	
	waittillframeend;
	
	players = level.players;
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		player thread spawnEnding();
		player thread endingAngles();
		player setClientDvars( "ui_hud_hardcore", 1,
							   "cg_drawSpectatorMessages", 0,
							   "g_compassShowEnemies", 0 );
							   
		if( isDefined( player.moneyHud ) )
			player.moneyHud destroy( );
	}
	
	if( level.dvar[ "mysql" ] )
		level thread bestPlayersMySQL();
	else
		level thread bestPlayers();
	
	if( level.endingPoints.size < 2 )
		return;
		
	fullDist = 0;
	for( i = 1; i < level.endingPoints.size; i++ )
		fullDist += distance( level.endingPoints[ i - 1 ][ 0 ], level.endingPoints[ i ][ 0 ] );
	
	level.endingMoveSpeed = fullDist / time;
	
	for( i = 1; i < level.endingPoints.size; i++ )
	{
		duration = distance( level.endingPoints[ i - 1 ][ 0 ], level.endingPoints[ i ][ 0 ] ) / level.endingMoveSpeed;
		level.movingEnding moveTo( level.endingPoints[ i ][ 0 ], duration );
		level.movingEnding rotateTo( level.endingPoints[ i ][ 1 ], duration );
		
		wait duration;
	}
}

/*
	0 = kills
	1 = deaths
	2 = melee
	3 = headshot
	4 = explosives
*/
bestPlayers()
{
	filename = "./ne_db/mapstats/" + toLower( getDvar( "mapname" ) ) + ".db";
	array = 0;
	if( level.dvar[ "fs_ending" ] )
	{
		array = readFile( filename );
		
		if( isArray( array ) )
		{
			for( i = 0; i < array.size; i++ )
				array[ i ] = strTok( array[ i ], ";" );
		}
	}

	if( !isArray( array ) )
	{
		array = [];
		for( i = 0; i < 5; i++ )
		{
			array[ i ] = getDvar( "mapstat_" + i + "_" + toLower( getDvar( "mapname" ) ) );
			array[ i ] = strTok( array[ i ], ";" );
		}
	}
	
	for( i = 0; i < array.size; i++ )
	{
		if( !isDefined( array[ i ][ 0 ] ) )
			array[ i ][ 0 ] = "";

		if( !isDefined( array[ i ][ 1 ] ) || array[ i ][ 1 ] == "" )
			array[ i ][ 1 ] = 0;
		else
			array[ i ][ 1 ] = int( array[ i ][ 1 ] );
	}
	
	players = level.players;
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( array[ 0 ][ 1 ] < player.pers[ "kills" ] )
		{
			array[ 0 ][ 1 ] = player.pers[ "kills" ];
			array[ 0 ][ 0 ] = "Terminator Record goes to " + player.name + " with " + player.pers[ "kills" ] + " kills!";
			 
			array[ 0 ][ 2 ] = true;
		}
		
		if( array[ 1 ][ 1 ] < player.pers[ "deaths" ] )
		{
			array[ 1 ][ 1 ] = player.pers[ "deaths" ];
			array[ 1 ][ 0 ] = "Poor guy " + player.name + " has a record of " + player.pers[ "deaths" ] + " deaths!";
			
			array[ 1 ][ 2 ] = true;
		}
		
		if( array[ 2 ][ 1 ] < player.pers[ "meleekills" ] )
		{
			array[ 2 ][ 1 ] = player.pers[ "meleekills" ];
			array[ 2 ][ 0 ] = "Ninja " + player.name + " has sliced and diced a record of " + player.pers[ "meleekills" ] + " enemies!";
			
			array[ 2 ][ 2 ] = true;
		}
		
		if( array[ 3 ][ 1 ] < player.pers[ "headshots" ] )
		{
			array[ 3 ][ 1 ] = player.pers[ "headshots" ];
			array[ 3 ][ 0 ] = "Headhunter " + player.name + " has a record of " + player.pers[ "headshots" ] + " shots right between the eyes!";
			
			array[ 3 ][ 2 ] = true;
		}
		
		if( array[ 4 ][ 1 ] < player.pers[ "explosiveKills" ] )
		{
			array[ 4 ][ 1 ] = player.pers[ "explosiveKills" ];
			array[ 4 ][ 0 ] = "Pyromaniac " + player.name + " has had his record fix with " + player.pers[ "explosiveKills" ] + " fireballs!";
			
			array[ 4 ][ 2 ] = true;
		}
	}
	
	saveArray = [];
	for( i = 0; i < array.size; i++ )
		saveArray[ i ] = array[ i ][ 0 ] + ";" + array[ i ][ 1 ];
		
	if( level.dvar[ "fs_ending" ] )
		writeToFile( filename, saveArray );
	else
	{
		for( i = 0; i < saveArray.size; i++ )
			setDvar( "mapstat_" + i + "_" + toLower( getDvar( "mapname" ) ), saveArray[ i ] );
	}
	
	rollPlayers( array );
		
	thread credits();
}

bestPlayersMySQL()
{
	data = [];
	mapname = "'" + toLower( getDvar( "mapname" ) ) + "'";
#if isSyscallDefined mysql_close
	data = code\mysql::getData( level.dvar[ "mysql_mapstats_table" ], mapname );
#endif
	
	array = [];
	if( isDefined( data ) )
	{
		array[ 0 ] = data[ "kills" ];
		array[ 1 ] = data[ "deaths" ];
		array[ 2 ] = data[ "meleekills" ];
		array[ 3 ] = data[ "headshots" ];
		array[ 4 ] = data[ "explosivekills" ];
	
		for( i = 0; i < array.size; i++ )
		{
			array[ i ] = strTok( array[ i ], ";" );
			array[ i ][ 1 ] = int( array[ i ][ 1 ] );
		}
	}
	else
	{
		for( i = 0; i < 5; i++ )
		{
			array[ i ][ 0 ] = "nope";
			array[ i ][ 1 ] = -1;
		}
	}
	
	players = level.players;
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		
		if( array[ 0 ][ 1 ] < player.pers[ "kills" ] )
		{
			 array[ 0 ][ 1 ] = player.pers[ "kills" ];
			 array[ 0 ][ 0 ] = player.name;
			 
			 array[ 0 ][ 2 ] = true;
		}
		
		if( array[ 1 ][ 1 ] < player.pers[ "deaths" ] )
		{
			array[ 1 ][ 1 ] = player.pers[ "deaths" ];
			array[ 1 ][ 0 ] = player.name;
			
			array[ 1 ][ 2 ] = true;
		}
		
		if( array[ 2 ][ 1 ] < player.pers[ "meleekills" ] )
		{
			array[ 2 ][ 1 ] = player.pers[ "meleekills" ];
			array[ 2 ][ 0 ] = player.name;
			
			array[ 2 ][ 2 ] = true;
		}
		
		if( array[ 3 ][ 1 ] < player.pers[ "headshots" ] )
		{
			array[ 3 ][ 1 ] = player.pers[ "headshots" ];
			array[ 3 ][ 0 ] = player.name;
			
			array[ 3 ][ 2 ] = true;
		}
		
		if( array[ 4 ][ 1 ] < player.pers[ "explosiveKills" ] )
		{
			array[ 4 ][ 1 ] = player.pers[ "explosiveKills" ];
			array[ 4 ][ 0 ] = player.name;
			
			array[ 4 ][ 2 ] = true;
		}
	}
	
	q[ 0 ] = "id=" + mapname;
	q[ 1 ] = "kills='" + array[ 0 ][ 0 ] + ";" + array[ 0 ][ 1 ] + "'";
	q[ 2 ] = "deaths='" + array[ 1 ][ 0 ] + ";" + array[ 1 ][ 1 ] + "'";
	q[ 3 ] = "meleekills='" + array[ 2 ][ 0 ] + ";" + array[ 2 ][ 1 ] + "'";
	q[ 4 ] = "headshots='" + array[ 3 ][ 0 ] + ";" + array[ 3 ][ 1 ] + "'";
	q[ 5 ] = "explosivekills='" + array[ 4 ][ 0 ] + ";" + array[ 4 ][ 1 ] + "'";
	
#if isSyscallDefined mysql_close
	data = code\mysql::sendData( level.dvar[ "mysql_mapstats_table" ], q );
#endif

	a = [];
	
	a[ 0 ][ 0 ] = "Terminator Record goes to " + array[ 0 ][ 0 ] + " with " + array[ 0 ][ 1 ] + " kills!";
	a[ 0 ][ 1 ] = array[ 0 ][ 1 ];
	if( isDefined( array[ 0 ][ 2 ] ) )
		a[ 0 ][ 2 ] = true;
	
	a[ 1 ][ 0 ] = "Poor guy " + array[ 1 ][ 0 ] + " has a record of " + array[ 1 ][ 1 ] + " deaths!";
	a[ 1 ][ 1 ] = array[ 1 ][ 1 ];
	if( isDefined( array[ 1 ][ 2 ] ) )
		a[ 1 ][ 2 ] = true;
		
	a[ 2 ][ 0 ] = "Ninja " + array[ 2 ][ 0 ] + " has sliced and diced a record of " + array[ 2 ][ 1 ] + " enemies!";
	a[ 2 ][ 1 ] = array[ 2 ][ 1 ];
	if( isDefined( array[ 2 ][ 2 ] ) )
		a[ 2 ][ 2 ] = true;
	
	a[ 3 ][ 0 ] = "Headhunter " + array[ 3 ][ 0 ] + " has a record of " + array[ 3 ][ 1 ] + " shots right between the eyes!";
	a[ 3 ][ 1 ] = array[ 3 ][ 1 ];
	if( isDefined( array[ 3 ][ 2 ] ) )
		a[ 3 ][ 2 ] = true;
	
	a[ 4 ][ 0 ] = "Pyromaniac " + array[ 4 ][ 0 ] + " has had his record fix with " + array[ 4 ][ 1 ] + " fireballs!";
	a[ 4 ][ 1 ] = array[ 4 ][ 1 ];
	if( isDefined( array[ 4 ][ 2 ] ) )
		a[ 4 ][ 2 ] = true;
	
	rollPlayers( a );
		
	thread credits();
}

rollPlayers( array )
{
	huds = [];
	y = 120;
	time = 1;
	for( i = 0; i < array.size; i++ )
	{
		huds[ i ] = createElem( "center", "top", "center", "top", 330, 0, 2.0, 1 );
		huds[ i ].color = ( randomFloat( 1 ), randomFloat( 1 ), randomFloat( 1 ) );
		
		if( array[ i ][ 1 ] > 0 )
		{
			if( isDefined( array[ i ][ 2 ] ) )
				huds[ i ] setText( "NEW! - " + array[ i ][ 0 ] );
			else
				huds[ i ] setText( array[ i ][ 0 ] );
		}
		else
			huds[ i ] setText( "This record hasn't been set yet :(" );
			
		huds[ i ] moveOverTime( time + ( i * 0.50 ) );
		huds[ i ].x = 0;
		huds[ i ].y = y + ( i * 40 );
	}
	
	wait 10;
	
	for( i = 0; i < array.size; i++ )
	{
		huds[ i ] fadeOverTime( 1 );
		huds[ i ].alpha = 0;
	}
	
	wait 1;
	
	for( i = 0; i < huds.size; i++ )
		huds[ i ] destroy();
}

credits()
{
	credits[ 0 ] = createElem( "center", "top", "center", "top", 0, -50, 2.6, 1 );
	credits[ 0 ] setText( level.dvar[ "credit_text" ] );
	credits[ 0 ].color = ( randomFloat( 1 ), randomFloat( 1 ), randomFloat( 1 ) );
	credits[ 0 ] moveOverTime( 2 );
	credits[ 0 ].y = 210;
	
	credits[ 1 ] = createElem( "center", "bottom", "center", "bottom", 0, 50, 1.8, 1 );
	credits[ 1 ] setText( "New Experience by Leiizko" );
	credits[ 1 ].color = ( randomFloat( 1 ), randomFloat( 1 ), randomFloat( 1 ) );
	credits[ 1 ] moveOverTime( 2 );
	credits[ 1 ].y = -210;
	
	wait 8;
	
	credits[ 0 ] moveOverTime( 1 );
	credits[ 0 ].x = -1000;
	
	credits[ 1 ] moveOverTime( 1 );
	credits[ 1 ].x = 1000;
	
	wait 1;
	
	for( i = 0; i < credits.size; i++ )
		credits[ i ] destroy();
}

/*
	level.endingPoints[ i ][ 0 ] = coordinates
	level.endingPoints[ i ][ 1 ] = angles
*/
setStuff()
{
	thread code\events::addDeathEvent( ::onPlayerKilled );
	
	
	array = 0;
	filename = "./ne_db/waypoints/" + toLower( getDvar( "mapname" ) ) + ".db";
	if( level.dvar[ "fs_ending" ] )
	{
		array = readFile( filename );
		
		if( isArray( array ) )
		{
			for( i = 0; i < array.size; i++ )
			{
				array[ i ] = toVector( array[ i ] );
			}
		}
	}
	
	if( !isArray( array ) || ( isArray( array ) && array.size < 2 ) )
	{
		array = [];
		switch( toLower( getDvar( "mapname" ) ) )
		{
			case "mp_backlot":
				array[ array.size ] = ( 632.152, -259.681, 436.125 );
				array[ array.size ] = ( 24.5038, 33.23, 0 );
				array[ array.size ] = ( 230.328, -221.462, 436.125 );
				array[ array.size ] = ( 28.2556, 125.751, 0 );
				array[ array.size ] = ( 196.716, -532.554, 436.125 );
				array[ array.size ] = ( 25.119, -143.09, 0 );
				array[ array.size ] = ( 599.905, -579.745, 436.125 );
				array[ array.size ] = ( 20.7959, -56.4569, 0 );
				array[ array.size ] = ( 636.121, -256.483, 436.125 );
				array[ array.size ] = ( 23.2623, 36.3446, 0 );
				break;
			
			case "mp_bloc":
				array[ array.size ] = ( 532.617, -5824.3, 103.279 );
				array[ array.size ] = ( 0.218506, 0.258179, 0 );
				array[ array.size ] = ( 1106.63, -6332.14, 126.074 );
				array[ array.size ] = ( 2.89917, 90.39, 0 );
				array[ array.size ] = ( 1678.21, -5823.98, 126.074 );
				array[ array.size ] = ( 2.0752, 179.901, 0 );
				array[ array.size ] = ( 1103.39, -5316.33, 126.074 );
				array[ array.size ] = ( 2.0752, -89.5551, 0 );
				array[ array.size ] = ( 534.407, -5826.23, 126.074 );
				array[ array.size ] = ( 2.27844, 0.362549, 0 );
				break;
			
			case "mp_bog":
				array[ array.size ] = ( 6443.11, -14.6996, 395.141 );
				array[ array.size ] = ( 16.2543, 150.236, 0 );
				array[ array.size ] = ( 6092.53, 1425.36, 395.141 );
				array[ array.size ] = ( 14.6118, -172.52, 0 );
				array[ array.size ] = ( 5713.52, 3250.76, 395.141 );
				array[ array.size ] = ( 14.8151, -131.157, 0 );
				break;
			
			case "mp_cargoship":
				array[ array.size ] = ( 4557.29, 9.42193, 373.427 );
				array[ array.size ] = ( 5.56885, 179.349, 0 );
				array[ array.size ] = ( 2968.04, -1219.76, 373.427 );
				array[ array.size ] = ( 15.2423, 88.6015, 0 );
				array[ array.size ] = ( -2506.21, -1329, 708.939 );
				array[ array.size ] = ( 15.2423, 88.6015, 0 );
				array[ array.size ] = ( -4583.84, -2.36443, 629.941 );
				array[ array.size ] = ( 9.68872, -1.94238, 0 );
				break;
				
			case "mp_citystreets":
				array[ array.size ] = ( 2843.61, 785.444, 867.3 );
				array[ array.size ] = ( 85, -89.3573, 0 );
				array[ array.size ] = ( 2843.61, 785.444, 100.108 );
				array[ array.size ] = ( 14.2151, -89.1541, 0 );
				array[ array.size ] = ( 2990.22, -1305.69, 100.108 );
				array[ array.size ] = ( 14.2151, -89.1541, 0 );
				array[ array.size ] = ( 2990.22, -1305.69, 862.094 );
				array[ array.size ] = ( 85, -90.1813, 0 );
				break;
			
			case "mp_convoy":
				array[ array.size ] = ( 177.527, -6598.66, 240.932 );
				array[ array.size ] = ( 8.84949, 87.7149, 0 );
				array[ array.size ] = ( 387.23, -4538.82, 240.932 );
				array[ array.size ] = ( 8.02551, 94.2957, 0 );
				array[ array.size ] = ( 139.045, -1630.3, 62.5052 );
				array[ array.size ] = ( 0.615234, 89.3573, 0 );
				array[ array.size ] = ( 509.655, -1103.21, 143.653 );
				array[ array.size ] = ( 15.8423, 136.994, 0 );
				array[ array.size ] = ( 710.67, 299.978, 143.653 );
				array[ array.size ] = ( 17.699, -175.062, 0 );
				array[ array.size ] = ( 303.027, 1728.93, 143.653 );
				array[ array.size ] = ( 22.8406, -142.344, 0 );
				array[ array.size ] = ( 46.7493, 2680.65, 143.653 );
				array[ array.size ] = ( 11.5247, -90.2857, 0 );
				break;
			
			case "mp_countdown":
				array[ array.size ] = ( 6730.02, -4214.44, 3002.4 );
				array[ array.size ] = ( 23.8678, 135.505, 0 );
				array[ array.size ] = ( 3866, -1420.36, 2008.56 );
				array[ array.size ] = ( 29.4269, 146.201, 0 );
				array[ array.size ] = ( 3652.95, 1684.36, 2008.56 );
				array[ array.size ] = ( 34.3652, -170.793, 0 );
				array[ array.size ] = ( 4339.54, 8499.13, 2072.76 );
				array[ array.size ] = ( 22.2253, -117.081, 0 );
				break;
			
			case "mp_crash":
			case "mp_crash_snow":
				array[ array.size ] = ( -642.1, -1707.08, 194.526 );
				array[ array.size ] = ( 11.5344, 21.4288, 0 );
				array[ array.size ] = ( -177.69, -1555.56, 194.526 );
				array[ array.size ] = ( 7.42004, 97.7728, 0 );
				array[ array.size ] = ( 1225.59, -1401.48, 194.526 );
				array[ array.size ] = ( 10.0952, 90.3626, 0 );
				array[ array.size ] = ( 1152.95, -407.898, 194.526 );
				array[ array.size ] = ( 10.304, -178.478, 0 );
				array[ array.size ] = ( 247.417, -312.382, 194.526 );
				array[ array.size ] = ( 8.24402, 75.7562, 0 );
				array[ array.size ] = ( 224.095, 895.877, 194.526 );
				array[ array.size ] = ( 13.1824, -46.6809, 0 );
				break;
			
			case "mp_crossfire":
				array[ array.size ] = ( 3321.89, 514.317, 37.2527 );
				array[ array.size ] = ( 1.23596, -80.4864, 0 );
				array[ array.size ] = ( 3416.83, -43.3893, 37.2527 );
				array[ array.size ] = ( 1.23596, -80.2832, 0 );
				array[ array.size ] = ( 3538.09, -864.219, 37.2527 );
				array[ array.size ] = ( 1.02722, -27.1973, 0 );
				array[ array.size ] = ( 4945.05, -1360.77, 37.2527 );
				array[ array.size ] = ( -0.609733, -33.1683, 0 );
				array[ array.size ] = ( 5604.05, -1594.81, 37.2527 );
				array[ array.size ] = ( 5.35034, -124.937, 0 );
				array[ array.size ] = ( 4389.02, -3482.88, -42.3672 );
				array[ array.size ] = ( 13.5791, -117.939, 0 );
				array[ array.size ] = ( 4342.17, -4279.88, -42.3672 );
				array[ array.size ] = ( 7.81677, -6.41662, 0 );
				array[ array.size ] = ( 6106.74, -4543.84, -42.3672 );
				array[ array.size ] = ( 6.78955, 87.2144, 0 );
				break;
			
			case "mp_farm":
				array[ array.size ] = ( -2096.64, -3049.86, 328.129 );
				array[ array.size ] = ( 16.051, 39.9761, 0 );
				array[ array.size ] = ( -1511.03, -2611.61, 248.074 );
				array[ array.size ] = ( 16.2543, 39.9761, 0 );
				array[ array.size ] = ( -962.843, -2309.48, 311.388 );
				array[ array.size ] = ( 4.93835, 93.4795, 0 );
				array[ array.size ] = ( 345.992, -1878.42, 494.546 );
				array[ array.size ] = ( 10.7007, 117.144, 0 );
				array[ array.size ] = ( 1510.39, -370.159, 1120.78 );
				array[ array.size ] = ( 20.1654, 145.95, 0 );
				array[ array.size ] = ( 2103.88, 2447.26, 1120.78 );
				array[ array.size ] = ( 27.1637, -161.37, 0 );
				array[ array.size ] = ( -493.637, 4290.04, 1120.78 );
				array[ array.size ] = ( 27.9877, -80.9175, 0 );
				array[ array.size ] = ( -1389.55, 1232.61, 1120.78 );
				array[ array.size ] = ( 25.3125, 42.3436, 0 );
				break;
			
			case "mp_overgrown":
				array[ array.size ] = ( -16.5178, -5465.88, -206.136 );
				array[ array.size ] = ( 8.4375, 89.0974, 0 );
				array[ array.size ] = ( 82.4006, -4747.45, -206.136 );
				array[ array.size ] = ( 8.4375, 89.0974, 0 );
				array[ array.size ] = ( 37.3323, -4138.58, -262.467 );
				array[ array.size ] = ( 6.17432, 89.3007, 0 );
				array[ array.size ] = ( 40.559, -3874.23, -262.467 );
				array[ array.size ] = ( 6.17432, 89.3007, 0 );
				array[ array.size ] = ( -53.9731, -3307.49, -262.467 );
				array[ array.size ] = ( 4.32312, 65.8449, 0 );
				array[ array.size ] = ( 123.281, -2556.41, -262.467 );
				array[ array.size ] = ( 3.70239, 45.8827, 0 );
				array[ array.size ] = ( 709.135, -2034.44, -262.467 );
				array[ array.size ] = ( 4.52637, 46.7067, 0 );
				array[ array.size ] = ( 1059.96, -1873.86, -262.467 );
				array[ array.size ] = ( 4.93835, 85.5983, 0 );
				array[ array.size ] = ( 1152.57, -1246.02, -325.786 );
				array[ array.size ] = ( 4.93835, 87.4495, 0 );
				array[ array.size ] = ( 1169.23, -871.875, -325.786 );
				array[ array.size ] = ( 4.93835, 87.4495, 0 );
				array[ array.size ] = ( 1302.98, -420.272, 44.1015 );
				array[ array.size ] = ( 16.051, 161.322, 0 );
				array[ array.size ] = ( 1285.35, 596.12, 44.1015 );
				array[ array.size ] = ( 10.7007, -94.3468, 0 );
				break;
			
			case "mp_pipeline":
				array[ array.size ] = ( -1971.42, -3803.22, 393.039 );
				array[ array.size ] = ( 6.78955, 51.9177, 0 );
				array[ array.size ] = ( -1616.51, -3356.01, 393.039 );
				array[ array.size ] = ( 5.35034, 37.1027, 0 );
				array[ array.size ] = ( -925.629, -2952.66, 393.039 );
				array[ array.size ] = ( 3.91113, 60.9705, 0 );
				array[ array.size ] = ( -278.803, -2395.52, 325.961 );
				array[ array.size ] = ( 5.1471, 103.57, 0 );
				array[ array.size ] = ( -415.593, -1858.83, 274.622 );
				array[ array.size ] = ( 9.05273, 113.65, 0 );
				array[ array.size ] = ( -657.629, -1254.81, 250.034 );
				array[ array.size ] = ( 10.9039, 85.871, 0 );
				array[ array.size ] = ( -715.399, -996.219, 223.231 );
				array[ array.size ] = ( 13.5791, 62.2064, 0 );
				array[ array.size ] = ( -696.217, -717.81, 223.231 );
				array[ array.size ] = ( 15.8423, 48.0066, 0 );
				array[ array.size ] = ( -520.505, -460.484, 163.269 );
				array[ array.size ] = ( 16.463, 36.6907, 0 );
				array[ array.size ] = ( -157.214, -188.487, 69.5334 );
				array[ array.size ] = ( 21.8134, 15.4981, 0 );
				array[ array.size ] = ( 256.96, -108.291, 302.724 );
				array[ array.size ] = ( 18.7262, 91.0181, 0 );
				array[ array.size ] = ( 1140.21, 460.786, 933.795 );
				array[ array.size ] = ( 36.0132, 139.166, 0 );
				array[ array.size ] = ( 134.717, 3816.68, 933.795 );
				array[ array.size ] = ( 33.9532, -88.1085, 0 );
				break;
			
			case "mp_showdown":
				array[ array.size ] = ( 9.64074, 2656.92, 30.7767 );
				array[ array.size ] = ( 1.64795, -89.3024, 0 );
				array[ array.size ] = ( 14.5538, 2151.75, 30.7767 );
				array[ array.size ] = ( 2.05994, -89.5056, 0 );
				array[ array.size ] = ( 21.1956, 1382.05, 30.7767 );
				array[ array.size ] = ( 2.05994, -89.5056, 0 );
				array[ array.size ] = ( -32.3971, 862.197, 30.7767 );
				array[ array.size ] = ( 2.05994, -89.5056, 0 );
				array[ array.size ] = ( 9.84008, 466.521, 30.7767 );
				array[ array.size ] = ( 2.05994, -89.5056, 0 );
				array[ array.size ] = ( 10.6912, 360.79, 267.417 );
				array[ array.size ] = ( 4.73511, -89.0936, 0 );
				array[ array.size ] = ( -214.496, 306.882, 267.417 );
				array[ array.size ] = ( 3.91113, -44.4397, 0 );
				array[ array.size ] = ( -340.982, 63.2711, 267.417 );
				array[ array.size ] = ( 2.26318, 3.7024, 0 );
				array[ array.size ] = ( -219.591, -158.814, 267.417 );
				array[ array.size ] = ( 2.87842, 50.2075, 0 );
				array[ array.size ] = ( 0.762029, -246.711, 267.417 );
				array[ array.size ] = ( 2.67517, 92.807, 0 );
				array[ array.size ] = ( 273.374, -133.146, 267.417 );
				array[ array.size ] = ( 2.87842, 145.278, 0 );
				array[ array.size ] = ( 350.21, 90.8337, 267.417 );
				array[ array.size ] = ( 2.67517, -175.831, 0 );
				break;
			
			case "mp_strike":
				array[ array.size ] = ( -2133.64, -2193.82, 272.616 );
				array[ array.size ] = ( -3.90563, -0.670166, 0 );
				array[ array.size ] = ( -1317.45, -2203.37, 272.616 );
				array[ array.size ] = ( -3.90563, -0.670166, 0 );
				array[ array.size ] = ( -948.751, -2206.48, 272.616 );
				array[ array.size ] = ( 5.96558, 93.988, 0 );
				array[ array.size ] = ( -800.608, -1754.59, 169.404 );
				array[ array.size ] = ( 11.3159, 105.919, 0 );
				array[ array.size ] = ( -1104.83, -1077.87, 76.8076 );
				array[ array.size ] = ( 9.26147, 88.6377, 0 );
				array[ array.size ] = ( -1091.78, -528.887, 76.8076 );
				array[ array.size ] = ( 9.26147, 88.6377, 0 );
				array[ array.size ] = ( -1117.51, -263.412, 76.8076 );
				array[ array.size ] = ( 10.9039, 27.9327, 0 );
				array[ array.size ] = ( -613.228, -153.65, 76.8076 );
				array[ array.size ] = ( 10.4919, 94.1913, 0 );
				array[ array.size ] = ( -637.193, 280.21, 76.8076 );
				array[ array.size ] = ( -17.8967, 91.3129, 0 );
				array[ array.size ] = ( -640.219, 450.725, 76.8076 );
				array[ array.size ] = ( -32.5085, 90.4889, 0 );
				array[ array.size ] = ( -364.131, 513.468, 76.8076 );
				array[ array.size ] = ( -29.2126, 136.582, 0 );
				array[ array.size ] = ( -395.497, 789.293, 76.8076 );
				array[ array.size ] = ( 11.7279, 92.1314, 0 );
				array[ array.size ] = ( -351.209, 1145.37, 76.8076 );
				array[ array.size ] = ( 12.7606, -175.062, 0 );
				array[ array.size ] = ( -646.226, 1100.72, 76.8076 );
				array[ array.size ] = ( 14.1998, 91.7194, 0 );
				array[ array.size ] = ( -653.256, 1979.08, 76.8076 );
				array[ array.size ] = ( 16.875, 89.2529, 0 );
				break;
			
			case "mp_vacant":
				array[ array.size ] = ( 2436.32, 1557.28, 45.6645 );
				array[ array.size ] = ( 14.8151, -120.168, 0 );
				array[ array.size ] = ( 2493.06, 971.953, 45.6645 );
				array[ array.size ] = ( 14.6118, -133.748, 0 );
				array[ array.size ] = ( 2452.35, -185.273, 45.6645 );
				array[ array.size ] = ( 15.2271, 178.72, 0 );
				array[ array.size ] = ( 2437.1, -960.567, 45.6645 );
				array[ array.size ] = ( 15.0238, 147.03, 0 );
				array[ array.size ] = ( 2148.31, -1307.77, 45.6645 );
				array[ array.size ] = ( 13.9911, 127.271, 0 );
				break;
			
			case "mp_killhouse":
				array[ array.size ] = ( -7310.85, -360.813, 228.35 );
				array[ array.size ] = ( 14.6118, 1.43921, 0 );
				array[ array.size ] = ( -3696.63, -270.007, 228.35 );
				array[ array.size ] = ( 14.6118, 1.43921, 0 );
				array[ array.size ] = ( -1951.17, -301.137, 228.35 );
				array[ array.size ] = ( 13.1671, -1.02172, 0 );
				array[ array.size ] = ( -1368.33, -243.579, 228.35 );
				array[ array.size ] = ( 13.1671, -47.9388, 0 );
				array[ array.size ] = ( 612.329, -177.555, 228.35 );
				array[ array.size ] = ( 13.5791, -91.9775, 0 );
				array[ array.size ] = ( 609.545, -1341.39, -31.1749 );
				array[ array.size ] = ( 5.35034, -91.1536, 0 );
				break;
			
			case "mp_shipment":
				array[ array.size ] = ( 7380.19, 838.15, 257.574 );
				array[ array.size ] = ( 7.20154, -179.089, 0 );
				array[ array.size ] = ( 2275.92, 829.074, 257.574 );
				array[ array.size ] = ( 7.20154, -179.089, 0 );
				array[ array.size ] = ( 1710.06, 936.453, 257.574 );
				array[ array.size ] = ( 1.43921, -144.521, 0 );
				array[ array.size ] = ( 834.206, 853.26, 208.961 );
				array[ array.size ] = ( 4.11438, -85.0574, 0 );
				array[ array.size ] = ( 882.852, -484.497, 208.961 );
				array[ array.size ] = ( 4.11438, -88.1445, 0 );
				array[ array.size ] = ( 811.288, -671.743, 208.961 );
				array[ array.size ] = ( 7.61353, -176.623, 0 );
				array[ array.size ] = ( -706.043, -694.496, 208.961 );
				array[ array.size ] = ( 3.08716, -177.238, 0 );
				array[ array.size ] = ( -840.594, -686.777, 208.961 );
				array[ array.size ] = ( 9.26147, 90.9821, 0 );
				array[ array.size ] = ( -827.539, -141.223, 208.961 );
				array[ array.size ] = ( 5.76233, 125.759, 0 );
				break;
				
			case "mp_broadcast":
				array[ array.size ] = ( -3652.66, 4129.85, 23.9365 );
				array[ array.size ] = ( -4.93285, 4.1272, 0 );
				array[ array.size ] = ( -1889.94, 4195.61, 23.9365 );
				array[ array.size ] = ( -4.93285, 4.1272, 0 );
				array[ array.size ] = ( -1673.67, 4214.46, 23.9365 );
				array[ array.size ] = ( -2.05443, -32.9132, 0 );
				array[ array.size ] = ( -1202.97, 4195.73, 23.9365 );
				array[ array.size ] = ( 0.203247, -58.8409, 0 );
				array[ array.size ] = ( -373.003, 3972.64, 23.9365 );
				array[ array.size ] = ( 0.615234, -90.531, 0 );
				array[ array.size ] = ( 534.309, 3097.05, 23.9365 );
				array[ array.size ] = ( 3.70239, -115.844, 0 );
				array[ array.size ] = ( 1228.5, 1952.26, 23.9365 );
				array[ array.size ] = ( 4.32312, -145.474, 0 );
				array[ array.size ] = ( 1806.42, 1133.17, -65.9299 );
				array[ array.size ] = ( 3.49915, -104.731, 0 );
				array[ array.size ] = ( 2368.5, -430.923, -65.9299 );
				array[ array.size ] = ( 3.49915, -104.731, 0 );
				break;
			
			case "mp_creek":
				array[ array.size ] = ( 280.451, 14121.1, 399.056 );
				array[ array.size ] = ( -0.411987, -161.677, 0 );
				array[ array.size ] = ( -186.117, 13966.6, 399.056 );
				array[ array.size ] = ( -0.411987, -161.677, 0 );
				array[ array.size ] = ( -223.105, 13950.6, 399.056 );
				array[ array.size ] = ( 2.26318, -154.476, 0 );
				array[ array.size ] = ( -697.003, 13724.3, 399.056 );
				array[ array.size ] = ( 2.26318, -154.476, 0 );
				array[ array.size ] = ( -729.625, 13703.3, 399.056 );
				array[ array.size ] = ( 3.2959, -145.632, 0 );
				array[ array.size ] = ( -1600.14, 13108, 347.668 );
				array[ array.size ] = ( 3.08716, -140.897, 0 );
				array[ array.size ] = ( -1828.37, 12931.8, 329.393 );
				array[ array.size ] = ( 4.73511, -137.606, 0 );
				array[ array.size ] = ( -1993.27, 12809.6, 329.393 );
				array[ array.size ] = ( 4.93835, -93.161, 0 );
				array[ array.size ] = ( -2532.32, 12348.8, 329.393 );
				array[ array.size ] = ( 5.1471, -46.6559, 0 );
				array[ array.size ] = ( -3576.87, 11362.9, 329.393 );
				array[ array.size ] = ( 5.1471, -46.6559, 0 );
				array[ array.size ] = ( -2967.26, 10721.7, 329.393 );
				array[ array.size ] = ( 5.1471, -46.4471, 0 );
				array[ array.size ] = ( -2606.52, 10323.9, 329.393 );
				array[ array.size ] = ( 4.32312, -53.8574, 0 );
				array[ array.size ] = ( -2355.86, 10007.1, 329.393 );
				array[ array.size ] = ( 4.53186, -62.0862, 0 );
				array[ array.size ] = ( -2146.64, 9664.97, 329.393 );
				array[ array.size ] = ( 4.53186, -63.9374, 0 );
				array[ array.size ] = ( -1877.98, 9083.12, 329.393 );
				array[ array.size ] = ( 4.53186, -66.2006, 0 );
				array[ array.size ] = ( -1678.91, 8608.15, 329.393 );
				array[ array.size ] = ( 4.73511, -68.4637, 0 );
				array[ array.size ] = ( -1668.78, 8556.82, 329.393 );
				array[ array.size ] = ( 8.23425, -152.009, 0 );
				array[ array.size ] = ( -2889.77, 7907.88, 329.393 );
				array[ array.size ] = ( 8.23425, -152.009, 0 );
				array[ array.size ] = ( -2984.57, 7849.96, 329.393 );
				array[ array.size ] = ( 8.02551, -143.16, 0 );
				array[ array.size ] = ( -4011.45, 6926.23, 329.393 );
				array[ array.size ] = ( 6.5863, -128.553, 0 );
				array[ array.size ] = ( -4011.45, 6926.23, 2181.42 );
				array[ array.size ] = ( 50.0043, -25.6665, 0 );
				break;
			
			default:
				array[ array.size ] = ( 0, 0, 0 );
				array[ array.size ] = ( 0, 0, 0 );
				break;
		}
	}
	
	n = 0;
	points = array.size / 2;
	for( i = 0; i < points; i++ )
	{
		level.endingPoints[ i ][ 0 ] = array[ n ];
		level.endingPoints[ i ][ 1 ] = array[ n + 1 ];
		n += 2;
	}
}

spawnEnding()
{
	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	
	self.statusicon = "";
	
	waittillframeend;
	self hide();
	self disableWeapons();
	self freezeControls( true );
	
	self linkTo( level.movingEnding, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	self setPlayerAngles( level.movingEnding.angles );
}

endingAngles()
{
	self endon( "disconnect" );
	
	for( ;; )
	{
		self setPlayerAngles( level.movingEnding.angles );
		wait .05;
	}
}

toVector( string )
{
	cleanedString = "";
	for( i = 1; i < string.size - 1; i++ )
		cleanedString += string[ i ];
	
	vec3 = strTok( cleanedString, ", " );
	
	return ( float( vec3[ 0 ] ), float( vec3[ 1 ] ), float( vec3[ 2 ] ) );
}

createElem( horzAlign, vertAlign, alignX, alignY, x, y, scale, alpha )
{
	hud = newHudElem();
	hud.horzAlign = horzAlign;
	hud.vertAlign = vertAlign;
	hud.alignX = alignX;
	hud.alignY = alignY;
	hud.y = y;
	hud.x = x;
	hud.fontScale = scale;
	hud.alpha = alpha;
	hud.archived = false;
	
	return hud;
}


onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	waittillframeend;
	
	if( !isDefined( attacker ) || attacker == self || !isPlayer( attacker ) )
		return;
	
	if( sMeansOfDeath == "MOD_MELEE" )
		attacker.pers[ "meleekills" ]++;
	
	else if( isExplosive( sMeansOfDeath ) )
		attacker.pers[ "explosiveKills" ]++;
}

isExplosive( s )
{
	return ( isSubStr( s, "_PROJECTILE" ) || isSubStr( s, "_GRENADE" ) || isSubStr( s, "_EXPLOSIVE" ) );
}

//////////////////////////////////////////////////////////////////////////
//							SIMPLE WAYPOINT EDITOR						//
//				REQUIRES DEVELOPER SCRIPT 1 AND ENDING_EDITOR 1			//
//----------------------------------------------------------------------//
//				USE UFO / NOCLIP MODE TO GET BETTER RESULT				//
//----------------------------------------------------------------------//
//	USE(F) - SAVE POINT, SPAWN FX AND MODEL TO SHOW ORIGIN AND ANGLE	//
//				MELEE(V) - REMOVE POINT, REMOVE FX AND MODEL			//
//					 RELOAD(R) - SAVE POINTS TO FILE					//
//			ONCE SAVED SERVER WILL READ THE FILE FOR WAYPOINTS			//
//////////////////////////////////////////////////////////////////////////
/#
editor()
{
	array = [];
	
	while( isAlive( self ) )
	{
		if( self useButtonPressed() )
		{
			array[ array.size ] = self GetEye() + ( 0, 0, 20 );
			array[ array.size ] = self getPlayerAngles();
			addSth( array[ array.size - 2 ], array[ array.size - 1 ], array.size - 2 );
			iPrintLnBold( "Point Added!" );
			wait .5;
		}
		
		if( self meleeButtonPressed() )
		{
			if( array.size < 1 )
				iPrintLnBold( "All points have been removed!" );
			else
			{
				remSth( array.size - 2 );
				array[ array.size - 1 ] = undefined;
				array[ array.size - 1 ] = undefined;
				iPrintLnBold( "Point Removed!" );
				if( array.size < 1 )
					iPrintLnBold( "All points have been removed!" );
			}
			
			wait .5;
		}
		
		if( self reloadButtonPressed() )
		{
			filename = "./ne_db/waypoints/" + toLower( getDvar( "mapname" ) ) + ".db";
			writeToFile( filename, array );
			iPrintLnBold( "Points have been saved to file!" );
			break;
		}
		
		wait .05;
	}
}

addSth( origin, angle, num )
{
	level.editorPoint[ num ] = spawn( "script_model", origin );
	level.editorPoint[ num ].angles = angle;
	level.editorPoint[ num ] setModel( "projectile_cbu97_clusterbomb" );
	level.editorFX[ num ] = addFX( origin );
}

remSth( num )
{
	if( isDefined( level.editorPoint[ num ] ) )
		level.editorPoint[ num ] delete();
	
	if( isDefined( level.editorFX[ num ] ) )
		level.editorFX[ num ] delete();
}

addFX( origin )
{
	effect = spawnFx( level.pointEffext, origin - ( 0, 0, 60 ), (0,0,1), (1,0,0) );
	triggerFx( effect );
	
	return effect;
}
#/