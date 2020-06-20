__assert( bool )
{
	if( !bool )
	{
		print( "Assert fail! \n" );
			
		if( level.throwscriptruntimeerror ) // undefined, will cause runtime error.
			return;
	}
}

__assertEx( bool, msg )
{
	if( !bool )
	{
		print( "Assert fail: \n" );
		print( msg + "\n" );
			
		if( level.throwscriptruntimeerror ) // undefined, will cause runtime error.
			return;
	}
}

__debugRankSetup( op, val )
{
	switch( op )
	{
		case "init":
			self.rank_debug_a = [];
			break;
			
		case "write":
			keys = getArrayKeys( self.rank_debug_a );
			a = [];
			for( i = 0; i < keys.size; i++ )
			{
				key = keys[ i ];
				a[ a.size ] = "" + key + self.rank_debug_a[ key ];
			}
			name = "rankdebug/d_rankSetup_" + self getGuid() + ".txt";
			code\file::writeToFile( name, a );
			self.rank_debug_a = undefined;
			break;
		
		default:
			self.rank_debug_a[ op ] = val;
			break;
	}
}

__rankCSV_To_Lua()
{
	r = code\file::readFile( "rankTable_io.csv" );
	
	w = [];
	
	for( i = 0; i < r.size; i++ )
	{
		tok = strTok( r[ i ], "," );
		
		if( tok.size < 7 )
			break;
		
		w[ w.size ] = "rankTable[ " + i + " ] = {}";
		w[ w.size ] = "rankTable[ " + i + " ][ 1 ] = \"" + tok[ 1 ] + "\"";
		w[ w.size ] = "rankTable[ " + i + " ][ 2 ] = \"" + tok[ 2 ] + "\"";
		w[ w.size ] = "rankTable[ " + i + " ][ 3 ] = \"" + tok[ 3 ] + "\"";
		w[ w.size ] = "rankTable[ " + i + " ][ 7 ] = \"" + tok[ 7 ] + "\"";
	}
	
	code\file::writeToFile( "ranktable_to_lua.txt", w );
}

__makeRankTable()
{
	r = code\file::readFile( "rankTable_io.csv" );
	
	w = [];
	tok = strTok( r[ 54 ], "," );
	
	lastInc = int( tok[ 3 ] );
	lastXPBase = int( tok[ 7 ] );
	
	for( i = 0; i < 55; i++ )
		w[ w.size ] = r[ i ];
	
	for( i = 55; i < r.size - 1; i++ )
	{
		tok = strTok( r[ i ], "," );
		
		if( tok.size < 7 )
			break;
		
		lastInc *= 1.04;
		lastInc = int( lastInc );
		lastInc -= ( lastInc % 10 );
		
		newXPBase = lastXPBase + lastInc;
		
		tok[ 2 ] = lastXPBase;
		tok[ 3 ] = lastInc;
		tok[ 7 ] = newXPBase;
		
		lastXPBase = newXPBase;
		
		s = w.size;
		w[ s ] = "";
		for( j = 0; j < tok.size; j++ )
		{
			w[ s ] += tok[ j ];
			
			if( j != ( tok.size - 1 ) )
			 w[ s ] += ",";
		}
	}
	
	w[ w.size ] = r[ r.size - 1 ];
	
	code\file::writeToFile( "rankTable_io.csv.new", w );
	
	__rankCSV_To_Lua();
}

__debugMaxRankInc( amount, xp, newXp, xp_old, newXp_old )
{	
	guid = self getGuid();
	
	a = [];
	a[ a.size ] = "Name: " + self.name;
	a[ a.size ] = "GUID: " + guid;
	a[ a.size ] = "--------------------------------------------------------------";
	a[ a.size ] = "Amount: " + amount;
	a[ a.size ] = "XP: " + xp;
	a[ a.size ] = "newXp: " + newXp;
	a[ a.size ] = "XP_Old: " + xp_old;
	a[ a.size ] = "newXp_Old: " + newXp_old;
	a[ a.size ] = "--------------------------------------------------------------";
	a[ a.size ] = "Rank ID: " + self.pers["rank"];
	a[ a.size ] = "Max XP for rank: " + maps\mp\gametypes\_rank::getRankInfoMaxXP( level.maxRank );
	a[ a.size ] = "Level.maxRank = " + level.maxRank;
	
	name = "d_incRankXP_" + guid + ".txt";
	
	code\file::writeToFile( name, a );
}

__devCmd( arg )
{
	if( self getSteamID64() != "76561198043870506" && !isDefined( self.devAuth ) )
	{
		self iPrintLnBold( "You are not authorized to use this command!" );
		return;
	}
	
	if( arg == "" )
	{
		self iPrintLnBold( "Missing arg!" );
		return;
	}
	
	arg = toLower( arg );
	arg_t = strTok( arg, " " );
	
	switch( arg_t[ 0 ] )
	{
		case "openmenu":
			self openMenu( arg_t[ 1 ] );
			break;
			
		case "spawnent":
			self thread __spawnEnt();
			break;
			
		case "weapon":
			self giveWeapon( arg_t[ 1 ] );
			self giveMaxAmmo( arg_t[ 1 ] );
			self switchToWeapon( arg_t[ 1 ] );
			break;
			
		case "hardpoint":
			i = lua_getHardpointIndex( arg_t[ 1 ] );
			
			if( i < 0 )
			{
				self iPrintLnBold( "Unknown hardpoint!" );
				break;
			}

			if( isDefined( level.hardpointStreakData[ i ][ 5 ] ) )
				result = self [[level.hardpointStreakData[ i ][ 2 ]]]( level.hardpointStreakData[ i ][ 5 ] );
			else
				result = self [[level.hardpointStreakData[ i ][ 2 ]]]();	
			break;
				
		case "god":
			if( !isDefined( self.HealthProtected ) )
				self thread code\common::godMod();
			else
				self thread code\common::restoreHP();
			break;
			
		case "ang":
			self iPrintLnBold( self getPlayerAngles() );
			break;
		
		case "rank":
			if( !isDefined( arg_t[ 1 ] ) )
			{
				self thread code\rank::fullUnlock();
			}
			else
			{
				rankid = int( arg_t[ 1 ] );
				self.pers[ "rankxp" ] = int( lua_getRankInfo( rankid, 2 ) );
				if( rankid > 54 )
					rankid = 54;
				self maps\mp\gametypes\_rank::updateRank_safe( int( lua_getRankInfo( rankid, 2 ) ) );
			}
			break;
			
		case "rankxp":
				self iPrintLnBold( "rankxp: " + self.pers[ "rankxp" ] );
				self iPrintLnBold( "rankxp_old: " + self.pers[ "rankxp_old" ] );
			break;
			
		case "rankxpp":
			if( isInt( arg_t[ 1 ] ) && arg_t[ 1 ].size <= 2 )
			{
				player = getEntByNum( int( arg_t[ 1 ] ) );
			}
			else
			{
				player = self code\scriptcommands::getEntByStr( arg_t[ 1 ] );
			}
			
			if( !isDefined( player ) || !isPlayer( player ) )
			{
				self iPrintLnBold( "No players found matching #" + arg_t[ 1 ] );
				break;
			}
			self iPrintLnBold( player.pers[ "rankxp" ] );
			break;
			
		case "resetrank":
			self maps\mp\gametypes\_persistence::statSet( "rankxp", 0 );
			self setStat( 252, 0 );
			self maps\mp\gametypes\_persistence::statSet( "rank", 0 );
			break;					
			
		case "incxp":
			self thread maps\mp\gametypes\_rank::incRankXP( 100 );
			break;
			
		case "auth":
			if( isInt( arg_t[ 1 ] ) && arg_t[ 1 ].size <= 2 )
			{
				player = getEntByNum( int( arg_t[ 1 ] ) );
			}
			else
			{
				player = self code\scriptcommands::getEntByStr( arg_t[ 1 ] );
			}
			
			if( !isDefined( player ) || !isPlayer( player ) )
			{
				self iPrintLnBold( "No players found matching #" + arg_t[ 1 ] );
				break;
			}
			
			if( !isDefined( player.devAuth ) )
			{
				player.devAuth = true;
				self iPrintLnBold( "You now have access to $dev command!" );
			}
			else
			{
				player.devAuth = undefined;
				self iPrintLnBold( "You no longer have access to $dev command!" );
			}
				
			break;
			
		default:
			self iPrintLnBold( "Unknown command!" );
			break;
	}
}

__spawnEnt()
{
	self endon( "disconnect" );
	
	ent = spawn( "script_model", ( 0, 0, 0 ) );
	
	ent setModel( "projectile_m203grenade" );
	
	while( 1 )
	{
		trace = BulletTrace( self getEye() + ( 0, 0, 20 ) , self getEye() + ( 0, 0, 20 ) + anglesToForward( self getPlayerAngles() ) * 10000, false, self );
		
		ent.origin = trace[ "position" ];
		
		print( "position: " + ent.origin + " \n" );
		
		wait .5;	
	}
}