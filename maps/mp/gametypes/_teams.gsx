init()
{
	precacheShader("mpflag_american");
	precacheShader("mpflag_russian");
	precacheShader("mpflag_spectator");

	game["strings"]["autobalance"] = &"MP_AUTOBALANCE_NOW";
	precacheString( &"MP_AUTOBALANCE_NOW" );
	precacheString( &"MP_AUTOBALANCE_NEXT_ROUND" );
	precacheString( &"MP_AUTOBALANCE_SECONDS" );

	setdvar("scr_teambalance", "1");
	level.teamBalance = 1;
	level.maxClients = getDvarInt( "sv_maxclients" );
	level.teamLimit = level.maxclients / 2;
	level.balanceTeamNum = [];
	level.balanceTeamEnt = [];
	
	setPlayerModels();
	
	if( level.teambased )
	{
		thread code\events::addConnectEvent( ::onPlayerConnect );
		thread code\events::addDisconnectEvent( ::onPlayerDisconnect ); // LEVEL THREAD
		thread code\events::addDeathEvent( ::onPlayerKilled );
	}
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if( isDefined( level.balanceTeamNum[ self.team ] ) && isDefined( self.pers[ "teamTime" ] ) )
	{
		for( i = 0; i < level.balanceTeamNum[ self.team ]; i++ )
		{
			if( level.balanceTeamEnt[ self.team ][ i ] == self getEntityNumber() )
			{
				changeTeam( level.otherTeam[ self.team ] );
				level thread getTeamBalance();
				self iPrintLnBold( "You have been autobalanced." );
				break;
			}
		}
	}
}

onPlayerDisconnect()
{
	level thread getTeamBalance();
}

onPlayerConnect()
{
	self thread onJoinedTeam();
	self thread onJoinedSpectators();
}

onJoinedTeam()
{
	self endon( "disconnect" );
	
	for( ;; )
	{
		self waittill( "joined_team" );
		
		self logString( "joined team: " + self.pers[ "team" ] );
		
		self.pers[ "teamTime" ] = getTime();
			
		level thread getTeamBalance();
	}
}

onJoinedSpectators()
{
	self endon( "disconnect" );
	
	for( ;; )
	{
		self waittill( "joined_spectators" );
		self.pers[ "teamTime" ] = undefined;
		level thread getTeamBalance();
	}
}

getTeamBalance()
{
	level notify( "getTeamBalance_one" );
	level endon( "getTeamBalance_one" );
	
	level.team["allies"] = 0;
	level.team["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if( !isDefined( players[ i ].pers[ "team" ] ) )
			continue;
			
		if( players[i].pers["team"] == "allies" )
			level.team["allies"]++;
		else if( players[i].pers["team"] == "axis" )
			level.team["axis"]++;
	}
	
	if( abs( level.team["allies"] - level.team["axis"] ) > 1 )
		thread balanceTeams();
	else
	{
		level.balanceTeamNum[ "allies" ] = undefined;
		level.balanceTeamNum[ "axis" ] = undefined;
		level.balanceTeamEnt[ "allies" ] = undefined;
		level.balanceTeamEnt[ "axis" ] = undefined;
	}
}

balanceTeams()
{
	diff = level.team[ "allies" ] - level.team[ "axis" ];
	
	if( diff > 0 )
	{
		team = "allies";
		num = int( ( diff / 2 ) );
	}
	else
	{
		team = "axis";
		num = int( ( abs( diff ) / 2 ) );
	}
		
	level.balanceTeamNum[ team ] = num;
	level.balanceTeamNum[ level.otherTeam[ team ] ] = undefined;
	
	players = level.players;
	teamArr = [];
	
	for( i = 0; i < players.size; i++ )
	{
		p = players[ i ];
		
		if( !isDefined( p.team ) || !isDefined( p.pers[ "teamTime" ] ) || ( isDefined( p.pers[ "vip" ] ) && !level.dvar[ "vip_balance" ] ) )
			continue;
			
		if( p.team == team )
			teamArr[ teamArr.size ] = p;
	}
	
	for( i = 0; i < teamArr.size; i++ )
	{
		for( n = i + 1; n < teamArr.size; n++ )
		{
			if( teamArr[ i ].pers[ "teamTime" ] < teamArr[ n ].pers[ "teamTime" ] )
			{
				tmp = teamArr[ i ];
				teamArr[ i ] = teamArr[ n ];
				teamArr[ n ] = tmp;
			}
		}
	}
	
	for( i = 0; i < teamArr.size; i++ )
	{
		num = teamArr[ i ] getEntityNumber();
		teamArr[ i ] = num;
	}
	
	level.balanceTeamEnt[ team ] = teamArr;
	level.balanceTeamEnt[ level.otherTeam[ team ] ] = undefined;
}

changeTeam( team )
{
	self.pers["team"] = team;
	self.team = team;
	self.sessionteam = team;
	
	self maps\mp\gametypes\_globallogic::updateObjectiveText();
	self maps\mp\gametypes\_spectating::setSpectatePermissions();
	
	self.pers["teamTime"] = getTime();
}


setPlayerModels()
{
	game["allies_model"] = [];

	alliesCharSet = tableLookup( "mp/mapsTable.csv", 0, getDvar( "mapname" ), 1 );
	if ( !isDefined( alliesCharSet ) || alliesCharSet == "" )
	{
		if ( !isDefined( game["allies_soldiertype"] ) || !isDefined( game["allies"] ) )	
		{
			game["allies_soldiertype"] = "desert";
			game["allies"] = "marines";
		}
	}
	else
		game["allies_soldiertype"] = alliesCharSet;

	axisCharSet = tableLookup( "mp/mapsTable.csv", 0, getDvar( "mapname" ), 2 );
	if ( !isDefined( axisCharSet ) || axisCharSet == "" )
	{
		if ( !isDefined( game["axis_soldiertype"] ) || !isDefined( game["axis"] ) )
		{
			game["axis_soldiertype"] = "desert";
			game["axis"] = "arab";
		}
	}
	else
		game["axis_soldiertype"] = axisCharSet;
	

	if ( game["allies_soldiertype"] == "desert" )
	{
		assert( game["allies"] == "marines" );
		
		mptype\mptype_ally_cqb::precache();
		mptype\mptype_ally_sniper::precache();
		mptype\mptype_ally_engineer::precache();
		mptype\mptype_ally_rifleman::precache();
		mptype\mptype_ally_support::precache();

		game["allies_model"]["SNIPER"] = mptype\mptype_ally_sniper::main;
		game["allies_model"]["SUPPORT"] = mptype\mptype_ally_support::main;
		game["allies_model"]["ASSAULT"] = mptype\mptype_ally_rifleman::main;
		game["allies_model"]["RECON"] = mptype\mptype_ally_engineer::main;
		game["allies_model"]["SPECOPS"] = mptype\mptype_ally_cqb::main;

		// custom class defaults
		game["allies_model"]["CLASS_CUSTOM1"] = mptype\mptype_ally_cqb::main;
		game["allies_model"]["CLASS_CUSTOM2"] = mptype\mptype_ally_cqb::main;
		game["allies_model"]["CLASS_CUSTOM3"] = mptype\mptype_ally_cqb::main;
		game["allies_model"]["CLASS_CUSTOM4"] = mptype\mptype_ally_cqb::main;
		game["allies_model"]["CLASS_CUSTOM5"] = mptype\mptype_ally_cqb::main;
	}
	else if ( game["allies_soldiertype"] == "urban" )
	{
		assert( game["allies"] == "sas" );

		mptype\mptype_ally_urban_sniper::precache();
		mptype\mptype_ally_urban_support::precache();
		mptype\mptype_ally_urban_assault::precache();
		mptype\mptype_ally_urban_recon::precache();
		mptype\mptype_ally_urban_specops::precache();

		game["allies_model"]["SNIPER"] = mptype\mptype_ally_urban_sniper::main;
		game["allies_model"]["SUPPORT"] = mptype\mptype_ally_urban_support::main;
		game["allies_model"]["ASSAULT"] = mptype\mptype_ally_urban_assault::main;
		game["allies_model"]["RECON"] = mptype\mptype_ally_urban_recon::main;
		game["allies_model"]["SPECOPS"] = mptype\mptype_ally_urban_specops::main;
		
		// custom class defaults
		game["allies_model"]["CLASS_CUSTOM1"] = mptype\mptype_ally_urban_assault::main;
		game["allies_model"]["CLASS_CUSTOM2"] = mptype\mptype_ally_urban_assault::main;
		game["allies_model"]["CLASS_CUSTOM3"] = mptype\mptype_ally_urban_assault::main;
		game["allies_model"]["CLASS_CUSTOM4"] = mptype\mptype_ally_urban_assault::main;
		game["allies_model"]["CLASS_CUSTOM5"] = mptype\mptype_ally_urban_assault::main;
	}
	else
	{
		assert( game["allies"] == "sas" );

		mptype\mptype_ally_woodland_assault::precache();
		mptype\mptype_ally_woodland_recon::precache();
		mptype\mptype_ally_woodland_sniper::precache();
		mptype\mptype_ally_woodland_specops::precache();
		mptype\mptype_ally_woodland_support::precache();

		game["allies_model"]["SNIPER"] = mptype\mptype_ally_woodland_sniper::main;
		game["allies_model"]["SUPPORT"] = mptype\mptype_ally_woodland_support::main;
		game["allies_model"]["ASSAULT"] = mptype\mptype_ally_woodland_assault::main;
		game["allies_model"]["RECON"] = mptype\mptype_ally_woodland_recon::main;
		game["allies_model"]["SPECOPS"] = mptype\mptype_ally_woodland_specops::main;
		
		// custom class defaults
		game["allies_model"]["CLASS_CUSTOM1"] = mptype\mptype_ally_woodland_recon::main;
		game["allies_model"]["CLASS_CUSTOM2"] = mptype\mptype_ally_woodland_recon::main;
		game["allies_model"]["CLASS_CUSTOM3"] = mptype\mptype_ally_woodland_recon::main;
		game["allies_model"]["CLASS_CUSTOM4"] = mptype\mptype_ally_woodland_recon::main;
		game["allies_model"]["CLASS_CUSTOM5"] = mptype\mptype_ally_woodland_recon::main;
	}
	
	if ( game["axis_soldiertype"] == "desert" )
	{
		assert( game["axis"] == "opfor" || game["axis"] == "arab" );

		mptype\mptype_axis_cqb::precache();
		mptype\mptype_axis_sniper::precache();
		mptype\mptype_axis_engineer::precache();
		mptype\mptype_axis_rifleman::precache();
		mptype\mptype_axis_support::precache();

		game["axis_model"] = [];

		game["axis_model"]["SNIPER"] = mptype\mptype_axis_sniper::main;
		game["axis_model"]["SUPPORT"] = mptype\mptype_axis_support::main;
		game["axis_model"]["ASSAULT"] = mptype\mptype_axis_rifleman::main;
		game["axis_model"]["RECON"] = mptype\mptype_axis_engineer::main;
		game["axis_model"]["SPECOPS"] = mptype\mptype_axis_cqb::main;
		
		// custom class defaults
		game["axis_model"]["CLASS_CUSTOM1"] = mptype\mptype_axis_cqb::main;
		game["axis_model"]["CLASS_CUSTOM2"] = mptype\mptype_axis_cqb::main;
		game["axis_model"]["CLASS_CUSTOM3"] = mptype\mptype_axis_cqb::main;
		game["axis_model"]["CLASS_CUSTOM4"] = mptype\mptype_axis_cqb::main;
		game["axis_model"]["CLASS_CUSTOM5"] = mptype\mptype_axis_cqb::main;
	}
	else if ( game["axis_soldiertype"] == "urban" )
	{
		assert( game["axis"] == "opfor" );

		mptype\mptype_axis_urban_sniper::precache();
		mptype\mptype_axis_urban_support::precache();
		mptype\mptype_axis_urban_assault::precache();
		mptype\mptype_axis_urban_engineer::precache();
		mptype\mptype_axis_urban_cqb::precache();

		game["axis_model"]["SNIPER"] = mptype\mptype_axis_urban_sniper::main;
		game["axis_model"]["SUPPORT"] = mptype\mptype_axis_urban_support::main;
		game["axis_model"]["ASSAULT"] = mptype\mptype_axis_urban_assault::main;
		game["axis_model"]["RECON"] = mptype\mptype_axis_urban_engineer::main;
		game["axis_model"]["SPECOPS"] = mptype\mptype_axis_urban_cqb::main;
		
		// custom class defaults
		game["axis_model"]["CLASS_CUSTOM1"] = mptype\mptype_axis_urban_assault::main;
		game["axis_model"]["CLASS_CUSTOM2"] = mptype\mptype_axis_urban_assault::main;
		game["axis_model"]["CLASS_CUSTOM3"] = mptype\mptype_axis_urban_assault::main;	
		game["axis_model"]["CLASS_CUSTOM4"] = mptype\mptype_axis_urban_assault::main;
		game["axis_model"]["CLASS_CUSTOM5"] = mptype\mptype_axis_urban_assault::main;
	}
	else
	{
		assert( game["axis"] == "opfor" );

		mptype\mptype_axis_woodland_rifleman::precache();
		mptype\mptype_axis_woodland_cqb::precache();
		mptype\mptype_axis_woodland_sniper::precache();
		mptype\mptype_axis_woodland_engineer::precache();
		mptype\mptype_axis_woodland_support::precache();

		game["axis_model"]["SNIPER"] = mptype\mptype_axis_woodland_sniper::main;
		game["axis_model"]["SUPPORT"] = mptype\mptype_axis_woodland_support::main;
		game["axis_model"]["ASSAULT"] = mptype\mptype_axis_woodland_rifleman::main;
		game["axis_model"]["RECON"] = mptype\mptype_axis_woodland_engineer::main;
		game["axis_model"]["SPECOPS"] = mptype\mptype_axis_woodland_cqb::main;
		
		// custom class defaults
		game["axis_model"]["CLASS_CUSTOM1"] = mptype\mptype_axis_woodland_cqb::main;
		game["axis_model"]["CLASS_CUSTOM2"] = mptype\mptype_axis_woodland_cqb::main;
		game["axis_model"]["CLASS_CUSTOM3"] = mptype\mptype_axis_woodland_cqb::main;	
		game["axis_model"]["CLASS_CUSTOM4"] = mptype\mptype_axis_woodland_cqb::main;
		game["axis_model"]["CLASS_CUSTOM5"] = mptype\mptype_axis_woodland_cqb::main;	
	}
}

playerModelForWeapon( weapon )
{
	self detachAll();
	
	weaponClass = tablelookup( "mp/statstable.csv", 4, weapon, 2 );
	
	switch ( weaponClass )
	{
		case "weapon_smg":
			[[game[self.pers["team"]+"_model"]["SPECOPS"]]]();
			break;
		case "weapon_assault":
			[[game[self.pers["team"]+"_model"]["ASSAULT"]]]();
			break;
		case "weapon_sniper":
			[[game[self.pers["team"]+"_model"]["SNIPER"]]]();
			break;
		case "weapon_shotgun":
			[[game[self.pers["team"]+"_model"]["RECON"]]]();
			break;
		case "weapon_lmg":
			[[game[self.pers["team"]+"_model"]["SUPPORT"]]]();
			break;
		default:
			[[game[self.pers["team"]+"_model"]["ASSAULT"]]]();
			break;
	}
}	

CountPlayers()
{
	//chad
	players = level.players;
	allies = 0;
	axis = 0;
	for(i = 0; i < players.size; i++)
	{
		if ( players[i] == self || !isdefined( players[i].pers["team"] ) )
			continue;
			
		if( players[i].pers["team"] == "allies" )
			allies++;
		else if( players[i].pers["team"] == "axis" )
			axis++;
	}
	players["allies"] = allies;
	players["axis"] = axis;
	return players;
}

getJoinTeamPermissions( team )
{
	teamcount = 0;
	
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		
		if((isdefined(player.pers["team"])) && (player.pers["team"] == team))
			teamcount++;
	}
	
	if( teamCount < level.teamLimit )
		return true;
	else
		return false;
}