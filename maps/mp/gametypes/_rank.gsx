#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	level.scoreInfo = [];

	precacheShader("white");

	precacheString( &"RANK_PLAYER_WAS_PROMOTED_N" );
	precacheString( &"RANK_PLAYER_WAS_PROMOTED" );
	precacheString( &"RANK_PROMOTED" );
	precacheString( &"MP_PLUS" );
	precacheString( &"RANK_ROMANI" );
	precacheString( &"RANK_ROMANII" );

	registerScoreInfo( "kill", 10 * level.dvar[ "xp_multi" ] );
	registerScoreInfo( "headshot", 10 * level.dvar[ "xp_multi" ] );
	registerScoreInfo( "assist", 5 * level.dvar[ "xp_multi" ] );
	registerScoreInfo( "suicide", 0 );
	registerScoreInfo( "teamkill", 0 );

	
	registerScoreInfo( "win", 1 );
	registerScoreInfo( "loss", 0.5 );
	registerScoreInfo( "tie", 0.75 );
	registerScoreInfo( "capture", 30 );
	registerScoreInfo( "defend", 30 );
	
	registerScoreInfo( "challenge", 250 * level.dvar[ "xp_multi" ] );

	level.maxRank = int(tableLookup( "mp/rankTable.csv", 0, "maxrank", 1 ));
	level.maxPrestige = int(tableLookup( "mp/rankIconTable.csv", 0, "maxprestige", 1 ));
	
	pId = 0;
	rId = 0;
	for ( pId = 0; pId <= level.maxPrestige; pId++ )
	{
		for ( rId = 0; rId <= level.maxRank; rId++ )
			precacheShader( tableLookup( "mp/rankIconTable.csv", 0, rId, pId+1 ) );
	}

	rankId = 0;
	rankName = tableLookup( "mp/ranktable.csv", 0, rankId, 1 );
	assert( isDefined( rankName ) && rankName != "" );
		
	while ( isDefined( rankName ) && rankName != "" )
	{
		precacheString( tableLookupIString( "mp/ranktable.csv", 0, rankId, 16 ) );

		rankId++;
		rankName = tableLookup( "mp/ranktable.csv", 0, rankId, 1 );		
	}
	
	level.maxRank = 256;
	for( i = 1; i < 6; i++ )
	{
		elem = "rank_prestige" + i;
		precacheShader( elem );
	}

	level.statOffsets = [];
	level.statOffsets["weapon_assault"] = 290;
	level.statOffsets["weapon_lmg"] = 291;
	level.statOffsets["weapon_smg"] = 292;
	level.statOffsets["weapon_shotgun"] = 293;
	level.statOffsets["weapon_sniper"] = 294;
	level.statOffsets["weapon_pistol"] = 295;
	level.statOffsets["perk1"] = 296;
	level.statOffsets["perk2"] = 297;
	level.statOffsets["perk3"] = 298;

	level.numChallengeTiers	= 10;
	
	buildChallegeInfo();
	
	level thread onPlayerConnect();
}


isRegisteredEvent( type )
{
	if ( isDefined( level.scoreInfo[type] ) )
		return true;
	else
		return false;
}

registerScoreInfo( type, value )
{
	level.scoreInfo[type]["value"] = value;
}

getScoreInfoValue( type )
{
	return ( level.scoreInfo[type]["value"] );
}

getScoreInfoLabel( type )
{
	return ( level.scoreInfo[type]["label"] );
}

getRankInfoMinXP( rankId )
{
	return int( lua_getRankInfo( rankId, 2 ) );
}

getRankInfoXPAmt( rankId )
{
	return int( lua_getRankInfo( rankId, 3 ) );
}

getRankInfoMaxXp( rankId )
{
	return int( lua_getRankInfo( rankId, 7 ) );
}

getRankInfoFull( rankId )
{
	rankId = rankId % 55;
	return tableLookupIString( "mp/ranktable.csv", 0, rankId, 16 );
}

getRankInfoIcon( rankId, prestigeId )
{
	if( rankId > 54 )
	{
		icon = "rank_prestige" + int( rankId / 55 );
		return icon;
	}
	
	return tableLookup( "mp/rankIconTable.csv", 0, rankId, prestigeId+1 );
}

getRankInfoUnlockWeapon( rankId )
{
	return tableLookup( "mp/ranktable.csv", 0, rankId, 8 );
}

getRankInfoUnlockPerk( rankId )
{
	return tableLookup( "mp/ranktable.csv", 0, rankId, 9 );
}

getRankInfoUnlockChallenge( rankId )
{
	return tableLookup( "mp/ranktable.csv", 0, rankId, 10 );
}

getRankInfoUnlockFeature( rankId )
{
	return tableLookup( "mp/ranktable.csv", 0, rankId, 15 );
}

getRankInfoUnlockCamo( rankId )
{
	return tableLookup( "mp/ranktable.csv", 0, rankId, 11 );
}

getRankInfoUnlockAttachment( rankId )
{
	return tableLookup( "mp/ranktable.csv", 0, rankId, 12 );
}

getRankInfoLevel( rankId )
{
	return rankId + 1;
	//return int( tableLookup( "mp/ranktable_io.csv", 0, rankId, 13 ) );
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		
		thread setup( player );
		level.rankxptomysql[ player getEntityNumber() ] = [];
	}
}

updateRank_safe( endXP )
{
	self endon( "disconnect" );
	
	self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "RANK_RESTORE_WAIT" ) );
	
	while( !isDefined( self.pers[ "unlocks" ] ) )
		wait .1;
	
	rankFrom = 0;
	rankTo = self getRankForXp( endXP );
	rankOg = self.pers[ "rankxp" ];
	self.pers[ "rank" ] = 0;
	
	for( rankId = rankFrom + 1; rankId <= rankTo; rankId++ )
	{
		self.pers[ "rankxp" ] = int( lua_getRankInfo( rankId, 2 ) );
		self updateRank();
		
		wait 0.1;
	}
	
	offset = 2301 + level.rankStatXPOffset;
	self.pers[ "rankxp" ] = rankOg;
	level.rankxptomysql[ self getEntityNumber() ][ 1 ] = self.pers["rankxp"];
	self setStat( offset, rankOg );
	
	waittillframeend;
	
	self.pers[ "rankxp_old" ] = endXP;
	self maps\mp\gametypes\_persistence::statSet( "rankxp", endXP );
	
	waittillframeend;

	//self updateRank();
	self.pers["rank"] = self getRank();
	self maps\mp\gametypes\_persistence::statSet( "minxp", int( lua_getRankInfo( self.pers["rank"], 2 ) ) );
	self maps\mp\gametypes\_persistence::statSet( "maxxp", int( lua_getRankInfo( self.pers["rank"], 7 ) ) );
	rankidx = 252 + level.rankStatOffset;
	self setStat( rankidx, self.pers["rank"] );
	self setRank( self.pers["rank"], 0 );
	self thread updateRankAnnounceHUD();

	wait .1;
	
	self code\rank::AttachCamoUnlock();

	waittillframeend;
	
	self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "RANK_RESTORE_DONE" ) );
}

askRankUpdate( xp )
{
	self endon( "disconnect" );
	
	self.rankUpdateInit = true; // stop spawnprotection
	
	self waittill( "spawned_player" );
	
	self.HealthProtected = true;
	
	waittillframeend;
	
	self hide();
	self freezeControls( true );
	
	wait .25;
	
	if( !isDefined( self.pers[ "language" ] ) )
		self waittill( "language_set" );
	
	self setClientDvars( "RANK_CONFIRM_RESET", lua_getLocString( self.pers[ "language" ], "RANK_CONFIRM_RESET" ),
						 "RANK_RESTORE", lua_getLocString( self.pers[ "language" ], "RANK_RESTORE" ) );
	
	self closeMenu();
	self closeInGameMenu();
	self openMenu( "rank_update" );
	
	self waittill( "rank_update_re", re );
	
	if( re )
	{
		self updateRank_safe( xp );
	}
	else
	{
		self.pers[ "rankxp" ] = self.pers[ "rankxp_old" ];
		self updateRank();
		level.rankxptomysql[ self getEntityNumber() ][ 1 ] = self.pers["rankxp"];
		
#if isSyscallDefined httpPostJson

		self thread code\mysql::UpdateRankXP( self.pers[ "rankxp" ] );
		
#endif

		self iPrintLnBold( lua_getLocString( self.pers[ "language" ], "RANK_RESTORE_RESET" ) );
	}
	
	waittillframeend;
	
	self show();
	self freezeControls( false );
	
	self.HealthProtected = undefined;
	self.rankUpdateInit = undefined;
}

/*
	Offsets required:
	- Rank ID -> 252
	- Rank XP -> 2301
	
	min, max XP and "rank" stat are reset based on ID and XP
*/
setup( player )
{
	player endon( "disconnect" );
	
#if isSyscallDefined httpPostJson

	player thread code\mysql::getRankXP();
	player waittill( "getRankXP_cb" );
	
#else

	offset = 2301 + level.rankStatXPOffset;
	player.pers["rankxp"] = player getStat( offset );
	
#endif

	player.pers["rankxp_old"] = player maps\mp\gametypes\_persistence::statGet( "rankxp" );

/*	
	if( player.pers["rankxp"] == 0 && player.pers["rankxp_old"] > 125490 )
	{
		player __debugRankSetup( "init" );
		player __debugRankSetup( "name: ", player.name );
		player __debugRankSetup( "guid: ", player getGuid() );
		player __debugRankSetup( "old_xp_start: ", player.pers["rankxp_old"] );
	}
*/
		
		// below lvl55 we don't care
		if( player.pers["rankxp"] < player.pers["rankxp_old"] )
		{
			if( player.pers["rankxp_old"] > 120280 )
			{
				player.pers["rankxp_old"] = 120280;
				player maps\mp\gametypes\_persistence::statSet( "rankxp", 120280 );
			}
			
//			if( isDefined( player.rank_debug_a ) )
//				player __debugRankSetup( "old_xp_to_dbxp: ", player.pers["rankxp_old"] );
			
			player.pers["rankxp"] = player.pers["rankxp_old"];
			offset = 2301 + level.rankStatXPOffset;
			player setStat( offset, player.pers["rankxp"] );
			
#if isSyscallDefined httpPostJson

			player thread code\mysql::updateRankXP( player.pers["rankxp"] );
			
#endif

		}
		else if( player.pers["rankxp_old"] < 120280 && player.pers["rankxp"] > player.pers["rankxp_old"] )
		{
			newxp = 120280;
			if( player.pers["rankxp"] < newxp )
				newxp = player.pers["rankxp"];
				
/*
			if( isDefined( player.rank_debug_a ) )
			{
				player __debugRankSetup( "restore_newxp: ", newxp );
				player __debugRankSetup( "restore_rankxp: ", player.pers["rankxp"] );
			}
*/
				
			player thread askRankUpdate( newxp );
		}		
		// 
		entnum = player getEntityNumber();
		level.rankxptomysql[ entnum ][ 0 ] = player getGuid();
		level.rankxptomysql[ entnum ][ 1 ] = player.pers["rankxp"];
		rankId = player getRankForXp( player.pers["rankxp"] );
		player.pers["rank"] = rankId;
		player.pers["participation"] = 0;
		
/*
		if( isDefined( player.rank_debug_a ) )
		{
			player __debugRankSetup( "final_rankxp: ", player.pers["rankxp"] );
			player __debugRankSetup( "final_rankxp_old: ", player.pers["rankxp_old"] );
			player __debugRankSetup( "final_rank_idx: ", rankId );
			player __debugRankSetup( "write" );
		}
*/

		rankidx = 252 + level.rankStatOffset;
		minxp_s = 2351 + level.rankStatMinXPOffset;
		maxxp_s = 2352 + level.rankStatMaxXPOffset;
		
		player setStat( rankidx, rankId );
		//player setStat( minxp_s, getRankInfoMinXp( rankId ) );
		//player setStat( maxxp_s, getRankInfoMaxXp( rankId ) );
		
		rankId_old = rankId;
		if( rankId_old > 54 )
			rankId_old = 54;
		player maps\mp\gametypes\_persistence::statSet( "rank", rankId_old );
		player maps\mp\gametypes\_persistence::statSet( "minxp", getRankInfoMinXp( rankId ) );
		player maps\mp\gametypes\_persistence::statSet( "maxxp", getRankInfoMaxXp( rankId ) );
		//player maps\mp\gametypes\_persistence::statSet( "lastxp", player.pers["rankxp"] );
		
		player.rankUpdateTotal = 0;
		

		player.cur_rankNum = rankId;

		if( rankId < 55 )
			player setStat( 252, player.cur_rankNum );
		else
			player setStat( 252, 54 );
		
		
		prestige = 0;
		player setRank( rankId, prestige );
		
		if( !isDefined( player.pers["prestige"] ) )
			player.pers["prestige"] = prestige;
		
		// resetting unlockable vars
		if ( !isDefined( player.pers["unlocks"] ) )
		{
			player.pers["unlocks"] = [];
			player.pers["unlocks"]["weapon"] = 0;
			player.pers["unlocks"]["perk"] = 0;
			player.pers["unlocks"]["challenge"] = 0;
			player.pers["unlocks"]["camo"] = 0;
			player.pers["unlocks"]["attachment"] = 0;
			player.pers["unlocks"]["feature"] = 0;
			player.pers["unlocks"]["page"] = 0;

			// resetting unlockable dvars
/*
			player setClientDvars( "player_unlockweapon0", "",
									"player_unlockweapon1", "",
									"player_unlockweapon2", "",
									"player_unlockweapons", "0" );

			player setClientDvars( "player_unlockcamo0a", "",
									"player_unlockcamo0b", "",
									"player_unlockcamo1a", "",
									"player_unlockcamo1b", "",
									"player_unlockcamo2a", "",
									"player_unlockcamo2b", "",
									"player_unlockcamos", "0" );
			
			player setClientDvars( "player_unlockattachment0a", "",
									"player_unlockattachment0b", "",
									"player_unlockattachment1a", "",
									"player_unlockattachment1b", "",
									"player_unlockattachment2a", "",
									"player_unlockattachment2b", "",
									"player_unlockattachments", "0" );
									
			player setClientDvars( "player_unlockperk0", "",
									"player_unlockperk1", "",
									"player_unlockperk2", "",
									"player_unlockperks", "0" );
			
			player setClientDvars( "player_unlockfeature0", "",
									"player_unlockfeature1", "",
									"player_unlockfeature2", "",
									"player_unlockfeatures", "0" );
			
			player setClientDvars( "player_unlockchallenge0", "",
									"player_unlockchallenge1", "",
									"player_unlockchallenge2", "",
									"player_unlockchallenges", "0",
									"player_unlock_page", "0" );
*/
		}
		
		if ( !isDefined( player.pers["summary"] ) )
		{
			player.pers["summary"] = [];
			player.pers["summary"]["xp"] = 0;
			player.pers["summary"]["score"] = 0;
			player.pers["summary"]["challenge"] = 0;
			player.pers["summary"]["match"] = 0;
			player.pers["summary"]["misc"] = 0;

			// resetting game summary dvars
/*
			player setClientDvars( "player_summary_xp", "0",
									"player_summary_score", "0",
									"player_summary_challenge", "0",
									"player_summary_match", "0",
									"player_summary_misc", "0" );
*/
		}


		// resetting summary vars
		
		// set default popup in lobby after a game finishes to game "summary"
		// if player got promoted during the game, we set it to "promotion"
		//player setclientdvar( "ui_lobbypopup", "" );
		
		player updateChallenges();
		player.explosiveKills[0] = 0;
		player.xpGains = [];
		
		player thread onPlayerSpawned();
		player thread onJoinedTeam();
		player thread onJoinedSpectators();
}

onJoinedTeam()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_team");
		self thread removeRankHUD();
	}
}


onJoinedSpectators()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_spectators");
		self thread removeRankHUD();
	}
}


onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		if(!isdefined(self.hud_rankscroreupdate))
		{
			self.hud_rankscroreupdate = newClientHudElem(self);
			self.hud_rankscroreupdate.horzAlign = "center";
			self.hud_rankscroreupdate.vertAlign = "middle";
			self.hud_rankscroreupdate.alignX = "center";
			self.hud_rankscroreupdate.alignY = "middle";
	 		self.hud_rankscroreupdate.x = 0;
			self.hud_rankscroreupdate.y = -60;
			self.hud_rankscroreupdate.font = "default";
			self.hud_rankscroreupdate.fontscale = 2.0;
			self.hud_rankscroreupdate.archived = false;
			self.hud_rankscroreupdate.color = (0.5,0.5,0.5);
			self.hud_rankscroreupdate maps\mp\gametypes\_hud::fontPulseInit();
		}
	}
}

roundUp( floatVal )
{
	if ( int( floatVal ) != floatVal )
		return int( floatVal+1 );
	else
		return int( floatVal );
}

giveRankXP( type, value, melee )
{
	self endon("disconnect");

	if ( level.teamBased && (!level.playerCount["allies"] || !level.playerCount["axis"]) )
		return;
	else if ( !level.teamBased && (level.playerCount["allies"] + level.playerCount["axis"] < 2) )
		return;

	if ( !isDefined( value ) )
		value = getScoreInfoValue( type );
	
	if ( !isDefined( self.xpGains[type] ) )
		self.xpGains[type] = 0;

	switch( type )
	{
		case "kill":
		case "headshot":
		case "suicide":
		case "teamkill":
		case "assist":
		case "capture":
		case "defend":
		case "return":
		case "pickup":
		case "assault":
		case "plant":
		case "defuse":
			if ( level.numLives >= 1 )
			{
				multiplier = max(1,int( 10/level.numLives ));
				value = int(value * multiplier);
			}
			break;
	}
	
	self.xpGains[type] += value;
		
	self incRankXP( value );

	if ( level.rankedMatch && updateRank() )
		self thread updateRankAnnounceHUD();

	if ( isDefined( self.enableText ) && self.enableText && level.dvar[ "showXP" ] )
	{
		if ( type == "teamkill" )
			self thread updateRankScoreHUD( 0 - getScoreInfoValue( "kill" ) );
		else
		{
			if( level.dvar["old_hardpoints"] || !level.dvar[ "shopXP" ] )
				self thread updateRankScoreHUD( value );
				
			else
			{
				switch( type )
				{
					case "headshot":
						self thread updateRankScoreHUD( value * 2 / level.dvar[ "xp_multi" ] );
						break;

					default:
						if( isDefined( melee ) )
							self thread updateRankScoreHUD( value * 3 / level.dvar[ "xp_multi" ] );
						else
							self thread updateRankScoreHUD( value / level.dvar[ "xp_multi" ] );
						break;
				}
			}
		}			
	}

	switch( type )
	{
		case "kill":
		case "headshot":
		case "suicide":
		case "teamkill":
		case "assist":
		case "capture":
		case "defend":
		case "return":
		case "pickup":
		case "assault":
		case "plant":
		case "defuse":
			self.pers["summary"]["score"] += value;
			self.pers["summary"]["xp"] += value;
			break;

		case "win":
		case "loss":
		case "tie":
			self.pers["summary"]["match"] += value;
			self.pers["summary"]["xp"] += value;
			break;

		case "challenge":
			self.pers["summary"]["challenge"] += value;
			self.pers["summary"]["xp"] += value;
			break;
			
		default:
			self.pers["summary"]["misc"] += value;	//keeps track of ungrouped match xp reward
			self.pers["summary"]["match"] += value;
			self.pers["summary"]["xp"] += value;
			break;
	}

	self setClientDvars(
			"player_summary_xp", self.pers["summary"]["xp"],
			"player_summary_score", self.pers["summary"]["score"],
			"player_summary_challenge", self.pers["summary"]["challenge"],
			"player_summary_match", self.pers["summary"]["match"],
			"player_summary_misc", self.pers["summary"]["misc"]
		);
}

updateRank()
{
	newRankId = self getRank();
	if ( newRankId == self.pers["rank"] )
		return false;

	oldRank = self.pers["rank"];
	rankId = self.pers["rank"];
	self.pers["rank"] = newRankId;
	
	while ( rankId <= newRankId )
	{	
		/*
		minxp_s = 2351 + level.rankStatMinXPOffset;
		maxxp_s = 2352 + level.rankStatMaxXPOffset;
		self setStat( minxp_s, int( lua_getRankInfo( rankId, 2 ) ) );
		self setStat( maxxp_s, int( lua_getRankInfo( rankId, 7 ) ) );
		*/
		
		self maps\mp\gametypes\_persistence::statSet( "minxp", int( lua_getRankInfo( rankId, 2 ) ) );
		self maps\mp\gametypes\_persistence::statSet( "maxxp", int( lua_getRankInfo( rankId, 7 ) ) );
		
		if( rankId < 55 )
		{
			self maps\mp\gametypes\_persistence::statSet( "rank", rankId );
			self setStat( 252, rankId );
		}
	
		// set current new rank index to stat#252
		rankidx = 252 + level.rankStatOffset;
		self setStat( rankidx, rankId );
	
		// tell lobby to popup promotion window instead
		self.setPromotion = true;
		/*
		if ( level.rankedMatch && level.gameEnded )
			self setClientDvar( "ui_lobbypopup", "promotion" );
		*/
		
		if( rankId < 55 )
		{
			// unlocks weapon =======
			unlockedWeapon = self getRankInfoUnlockWeapon( rankId );	// unlockedweapon is weapon reference string
			if ( isDefined( unlockedWeapon ) && unlockedWeapon != "" )
				unlockWeapon( unlockedWeapon );
		
			// unlock perk ==========
			unlockedPerk = self getRankInfoUnlockPerk( rankId );	// unlockedweapon is weapon reference string
			if ( isDefined( unlockedPerk ) && unlockedPerk != "" )
				unlockPerk( unlockedPerk );
				
			// unlock challenge =====
			unlockedChallenge = self getRankInfoUnlockChallenge( rankId );
			if ( isDefined( unlockedChallenge ) && unlockedChallenge != "" )
				unlockChallenge( unlockedChallenge );

			// unlock attachment ====
			unlockedAttachment = self getRankInfoUnlockAttachment( rankId );	// ex: ak47 gl	
			if ( isDefined( unlockedAttachment ) && unlockedAttachment != "" )
				unlockAttachment( unlockedAttachment );	
			
			unlockedCamo = self getRankInfoUnlockCamo( rankId );	// ex: ak47 camo_brockhaurd
			if ( isDefined( unlockedCamo ) && unlockedCamo != "" )
				unlockCamo( unlockedCamo );

			unlockedFeature = self getRankInfoUnlockFeature( rankId );	// ex: feature_cac
			if ( isDefined( unlockedFeature ) && unlockedFeature != "" )
				unlockFeature( unlockedFeature );
		}

		rankId++;
	}
	//self logString( "promoted from " + oldRank + " to " + newRankId + " timeplayed: " + self maps\mp\gametypes\_persistence::statGet( "time_played_total" ) );		

	self setRank( newRankId );
	return true;
}

updateRankAnnounceHUD()
{
	self endon("disconnect");

	self notify("update_rank");
	self endon("update_rank");

	team = self.pers["team"];
	if ( !isdefined( team ) )
		return;	
	
	self notify("reset_outcome");
	newRankName = self getRankInfoFull( self.pers["rank"] );
	
	notifyData = spawnStruct();

	notifyData.titleText = &"RANK_PROMOTED";
	notifyData.iconName = self getRankInfoIcon( self.pers["rank"], 0 );
	notifyData.sound = "mp_level_up";
	notifyData.duration = 4.0;
	rank_char = lua_getRankInfo( self.pers[ "rank" ], 1 );
	subRank = int(rank_char[rank_char.size-1]);
	
	if ( subRank == 2 )
	{
		notifyData.textLabel = newRankName;
		notifyData.notifyText = &"RANK_ROMANI";
		notifyData.textIsString = true;
	}
	else if ( subRank == 3 )
	{
		notifyData.textLabel = newRankName;
		notifyData.notifyText = &"RANK_ROMANII";
		notifyData.textIsString = true;
	}
	else
	{
		notifyData.notifyText = newRankName;
	}

	thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );

	if ( subRank > 1 )
		return;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		playerteam = player.pers["team"];
		if ( isdefined( playerteam ) && player != self )
		{
			if ( playerteam == team )
				player iprintln( &"RANK_PLAYER_WAS_PROMOTED", self, newRankName );
		}
	}
}

// End of game summary/unlock menu page setup
// 0 = no unlocks, 1 = only page one, 2 = only page two, 3 = both pages
unlockPage( in_page )
{
	/*if( in_page == 1 )
	{
		if( self.pers["unlocks"]["page"] == 0 )
		{
			self setClientDvar( "player_unlock_page", "1" );
			self.pers["unlocks"]["page"] = 1;
		}
		if( self.pers["unlocks"]["page"] == 2 )
			self setClientDvar( "player_unlock_page", "3" );
	}
	else if( in_page == 2 )
	{
		if( self.pers["unlocks"]["page"] == 0 )
		{
			self setClientDvar( "player_unlock_page", "2" );
			self.pers["unlocks"]["page"] = 2;
		}
		if( self.pers["unlocks"]["page"] == 1 )
			self setClientDvar( "player_unlock_page", "3" );	
	}	*/	
}

// unlocks weapon
unlockWeapon( refString )
{
	assert( isDefined( refString ) && refString != "" );
		
	stat = int( tableLookup( "mp/statstable.csv", 4, refString, 1 ) );
	
	assertEx( stat > 0, "statsTable refstring " + refString + " has invalid stat number: " + stat );
	
	if( self getStat( stat ) > 0 )
		return;

	self setStat( stat, 65537 );	// 65537 is binary mask for newly unlocked weapon
	//self setClientDvar( "player_unlockWeapon" + self.pers["unlocks"]["weapon"], refString );
	self.pers["unlocks"]["weapon"]++;
	//self setClientDvar( "player_unlockWeapons", self.pers["unlocks"]["weapon"] );
	
	self unlockPage( 1 );
}

// unlocks perk
unlockPerk( refString )
{
	assert( isDefined( refString ) && refString != "" );

	stat = int( tableLookup( "mp/statstable.csv", 4, refString, 1 ) );
	
	if( self getStat( stat ) > 0 )
		return;

	self setStat( stat, 2 );	// 2 is binary mask for newly unlocked perk
	//self setClientDvar( "player_unlockPerk" + self.pers["unlocks"]["perk"], refString );
	self.pers["unlocks"]["perk"]++;
	//self setClientDvar( "player_unlockPerks", self.pers["unlocks"]["perk"] );
	
	self unlockPage( 2 );
}

// unlocks camo - multiple
unlockCamo( refString )
{
	assert( isDefined( refString ) && refString != "" );

	// tokenize reference string, accepting multiple camo unlocks in one call
	Ref_Tok = strTok( refString, ";" );
	assertex( Ref_Tok.size > 0, "Camo unlock specified in datatable ["+refString+"] is incomplete or empty" );
	
	for( i=0; i<Ref_Tok.size; i++ )
		unlockCamoSingular( Ref_Tok[i] );
}

// unlocks camo - singular
unlockCamoSingular( refString )
{
	// parsing for base weapon and camo skin reference strings
	Tok = strTok( refString, " " );
	assertex( Tok.size == 2, "Camo unlock sepcified in datatable ["+refString+"] is invalid" );
	
	baseWeapon = Tok[0];
	addon = Tok[1];

	weaponStat = int( tableLookup( "mp/statstable.csv", 4, baseWeapon, 1 ) );
	addonMask = int( tableLookup( "mp/attachmenttable.csv", 4, addon, 10 ) );
	
	if ( self getStat( weaponStat ) & addonMask )
		return;
	
	// ORs the camo/attachment's bitmask with weapon's current bits, thus switching the camo/attachment bit on
	setstatto = ( self getStat( weaponStat ) | addonMask ) | (addonMask<<16) | (1<<16);
	self setStat( weaponStat, setstatto );
	
	//fullName = tableLookup( "mp/statstable.csv", 4, baseWeapon, 3 ) + " " + tableLookup( "mp/attachmentTable.csv", 4, addon, 3 );
	//self setClientDvar( "player_unlockCamo" + self.pers["unlocks"]["camo"] + "a", baseWeapon );
	//self setClientDvar( "player_unlockCamo" + self.pers["unlocks"]["camo"] + "b", addon );
	self.pers["unlocks"]["camo"]++;
	//self setClientDvar( "player_unlockCamos", self.pers["unlocks"]["camo"] );

	self unlockPage( 1 );
}

unlockAttachment( refString )
{
	assert( isDefined( refString ) && refString != "" );

	// tokenize reference string, accepting multiple camo unlocks in one call
	Ref_Tok = strTok( refString, ";" );
	assertex( Ref_Tok.size > 0, "Attachment unlock specified in datatable ["+refString+"] is incomplete or empty" );
	
	for( i=0; i<Ref_Tok.size; i++ )
		unlockAttachmentSingular( Ref_Tok[i] );
}

// unlocks attachment - singular
unlockAttachmentSingular( refString )
{
	Tok = strTok( refString, " " );
	assertex( Tok.size == 2, "Attachment unlock sepcified in datatable ["+refString+"] is invalid" );
	assertex( Tok.size == 2, "Attachment unlock sepcified in datatable ["+refString+"] is invalid" );
	
	baseWeapon = Tok[0];
	addon = Tok[1];

	weaponStat = int( tableLookup( "mp/statstable.csv", 4, baseWeapon, 1 ) );
	addonMask = int( tableLookup( "mp/attachmenttable.csv", 4, addon, 10 ) );
	
	if ( self getStat( weaponStat ) & addonMask )
		return;
	
	// ORs the camo/attachment's bitmask with weapon's current bits, thus switching the camo/attachment bit on
	setstatto = ( self getStat( weaponStat ) | addonMask ) | (addonMask<<16) | (1<<16);
	self setStat( weaponStat, setstatto );

	//fullName = tableLookup( "mp/statstable.csv", 4, baseWeapon, 3 ) + " " + tableLookup( "mp/attachmentTable.csv", 4, addon, 3 );
	//self setClientDvar( "player_unlockAttachment" + self.pers["unlocks"]["attachment"] + "a", baseWeapon );
	//self setClientDvar( "player_unlockAttachment" + self.pers["unlocks"]["attachment"] + "b", addon );
	self.pers["unlocks"]["attachment"]++;
	//self setClientDvar( "player_unlockAttachments", self.pers["unlocks"]["attachment"] );
	
	self unlockPage( 1 );
}

/*
setBaseNewStatus( stat )
{
	weaponIDs = level.tbl_weaponIDs;
	perkData = level.tbl_PerkData;
	statOffsets = level.statOffsets;
	if ( isDefined( weaponIDs[stat] ) )
	{
		if ( isDefined( statOffsets[weaponIDs[stat]["group"]] ) )
			self setStat( statOffsets[weaponIDs[stat]["group"]], 1 );
	}
	
	if ( isDefined( perkData[stat] ) )
	{
		if ( isDefined( statOffsets[perkData[stat]["perk_num"]] ) )
			self setStat( statOffsets[perkData[stat]["perk_num"]], 1 );
	}
}

clearNewStatus( stat, bitMask )
{
	self setStat( stat, self getStat( stat ) & bitMask );
}


updateBaseNewStatus()
{
	self setstat( 290, 0 );
	self setstat( 291, 0 );
	self setstat( 292, 0 );
	self setstat( 293, 0 );
	self setstat( 294, 0 );
	self setstat( 295, 0 );
	self setstat( 296, 0 );
	self setstat( 297, 0 );
	self setstat( 298, 0 );
	
	weaponIDs = level.tbl_weaponIDs;
	// update for weapons and any attachments or camo skins, bit mask 16->32 : 536805376 for new status
	for( i=0; i<149; i++ )
	{	
		if( !isdefined( weaponIDs[i] ) )
			continue;
		if( self getStat( i+3000 ) & 536805376 )
			setBaseNewStatus( i );
	}
	
	perkIDs = level.tbl_PerkData;
	// update for perks
	for( i=150; i<199; i++ )
	{
		if( !isdefined( perkIDs[i] ) )
			continue;
		if( self getStat( i ) > 1 )
			setBaseNewStatus( i );
	}
}
*/

unlockChallenge( refString )
{
	assert( isDefined( refString ) && refString != "" );

	// tokenize reference string, accepting multiple camo unlocks in one call
	Ref_Tok = strTok( refString, ";" );
	assertex( Ref_Tok.size > 0, "Camo unlock specified in datatable ["+refString+"] is incomplete or empty" );
	
	for( i=0; i<Ref_Tok.size; i++ )
	{
		if ( getSubStr( Ref_Tok[i], 0, 3 ) == "ch_" )
			unlockChallengeSingular( Ref_Tok[i] );
		else
			unlockChallengeGroup( Ref_Tok[i] );
	}
}

// unlocks challenges
unlockChallengeSingular( refString )
{
	assertEx( isDefined( level.challengeInfo[refString] ), "Challenge unlock "+refString+" does not exist." );
	tableName = "mp/challengetable_tier" + level.challengeInfo[refString]["tier"] + ".csv";
	
	if ( self getStat( level.challengeInfo[refString]["stateid"] ) )
		return;

	self setStat( level.challengeInfo[refString]["stateid"], 1 );
	
	// set tier as new
	self setStat( 269 + level.challengeInfo[refString]["tier"], 2 );// 2: new, 1: old
	
	//self setClientDvar( "player_unlockchallenge" + self.pers["unlocks"]["challenge"], level.challengeInfo[refString]["name"] );
	self.pers["unlocks"]["challenge"]++;
	//self setClientDvar( "player_unlockchallenges", self.pers["unlocks"]["challenge"] );	
	
	self unlockPage( 2 );
}

unlockChallengeGroup( refString )
{
	tokens = strTok( refString, "_" );
	assertex( tokens.size > 0, "Challenge unlock specified in datatable ["+refString+"] is incomplete or empty" );
	
	assert( tokens[0] == "tier" );
	
	tierId = int( tokens[1] );
	assertEx( tierId > 0 && tierId <= level.numChallengeTiers, "invalid tier ID " + tierId );

	groupId = "";
	if ( tokens.size > 2 )
		groupId = tokens[2];

	challengeArray = getArrayKeys( level.challengeInfo );
	
	for ( index = 0; index < challengeArray.size; index++ )
	{
		challenge = level.challengeInfo[challengeArray[index]];
		
		if ( challenge["tier"] != tierId )
			continue;
			
		if ( challenge["group"] != groupId )
			continue;
			
		if ( self getStat( challenge["stateid"] ) )
			continue;
	
		self setStat( challenge["stateid"], 1 );
		
		// set tier as new
		self setStat( 269 + challenge["tier"], 2 );// 2: new, 1: old
		
	}
	
	//desc = tableLookup( "mp/challengeTable.csv", 0, tierId, 1 );

	//self setClientDvar( "player_unlockchallenge" + self.pers["unlocks"]["challenge"], desc );		
	self.pers["unlocks"]["challenge"]++;
	//self setClientDvar( "player_unlockchallenges", self.pers["unlocks"]["challenge"] );		
	self unlockPage( 2 );
}


unlockFeature( refString )
{
	assert( isDefined( refString ) && refString != "" );

	stat = int( tableLookup( "mp/statstable.csv", 4, refString, 1 ) );
	
	if( self getStat( stat ) > 0 )
		return;

	if ( refString == "feature_cac" )
		self setStat( 200, 1 );

	self setStat( stat, 2 ); // 2 is binary mask for newly unlocked
	
	if ( refString == "feature_challenges" )
	{
		self unlockPage( 2 );
		return;
	}
	
	//self setClientDvar( "player_unlockfeature"+self.pers["unlocks"]["feature"], tableLookup( "mp/statstable.csv", 4, refString, 3 ) );
	self.pers["unlocks"]["feature"]++;
	//self setClientDvar( "player_unlockfeatures", self.pers["unlocks"]["feature"] );
	
	self unlockPage( 2 );
}


// update copy of a challenges to be progressed this game, only at the start of the game
// challenges unlocked during the game will not be progressed on during that game session
updateChallenges()
{
	self.challengeData = [];
	for ( i = 1; i <= level.numChallengeTiers; i++ )
	{
		tableName = "mp/challengetable_tier"+i+".csv";

		idx = 1;
		// unlocks all the challenges in this tier
		for( idx = 1; isdefined( tableLookup( tableName, 0, idx, 0 ) ) && tableLookup( tableName, 0, idx, 0 ) != ""; idx++ )
		{
			stat_num = tableLookup( tableName, 0, idx, 2 );
			if( isdefined( stat_num ) && stat_num != "" )
			{
				statVal = self getStat( int( stat_num ) );
				
				refString = tableLookup( tableName, 0, idx, 7 );
				if ( statVal )
					self.challengeData[refString] = statVal;
			}
		}
	}
}


buildChallegeInfo()
{
	level.challengeInfo = [];
	
	for ( i = 1; i <= level.numChallengeTiers; i++ )
	{
		tableName = "mp/challengetable_tier"+i+".csv";

		baseRef = "";
		// unlocks all the challenges in this tier
		for( idx = 1; isdefined( tableLookup( tableName, 0, idx, 0 ) ) && tableLookup( tableName, 0, idx, 0 ) != ""; idx++ )
		{
			stat_num = tableLookup( tableName, 0, idx, 2 );
			refString = tableLookup( tableName, 0, idx, 7 );

			level.challengeInfo[refString] = [];
			level.challengeInfo[refString]["tier"] = i;
			level.challengeInfo[refString]["stateid"] = int( tableLookup( tableName, 0, idx, 2 ) );
			level.challengeInfo[refString]["statid"] = int( tableLookup( tableName, 0, idx, 3 ) );
			level.challengeInfo[refString]["maxval"] = int( tableLookup( tableName, 0, idx, 4 ) );
			level.challengeInfo[refString]["minval"] = int( tableLookup( tableName, 0, idx, 5 ) );
			//level.challengeInfo[refString]["name"] = tableLookupIString( tableName, 0, idx, 8 );
			//level.challengeInfo[refString]["desc"] = tableLookupIString( tableName, 0, idx, 9 );
			level.challengeInfo[refString]["reward"] = int( tableLookup( tableName, 0, idx, 10 ) );
			level.challengeInfo[refString]["camo"] = tableLookup( tableName, 0, idx, 12 );
			level.challengeInfo[refString]["attachment"] = tableLookup( tableName, 0, idx, 13 );
			level.challengeInfo[refString]["group"] = tableLookup( tableName, 0, idx, 14 );

			//precacheString( level.challengeInfo[refString]["name"] );

			if ( !int( level.challengeInfo[refString]["stateid"] ) )
			{
				level.challengeInfo[baseRef]["levels"]++;
				level.challengeInfo[refString]["stateid"] = level.challengeInfo[baseRef]["stateid"];
				level.challengeInfo[refString]["level"] = level.challengeInfo[baseRef]["levels"];
			}
			else
			{
				level.challengeInfo[refString]["levels"] = 1;
				level.challengeInfo[refString]["level"] = 1;
				baseRef = refString;
			}
		}
	}
}
	

endGameUpdate()
{
	player = self;			
}

updateRankScoreHUD( amount )
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );

	if ( amount == 0 )
		return;

	self notify( "update_score" );
	self endon( "update_score" );

	self.rankUpdateTotal += amount;

	wait ( 0.05 );

	if( isDefined( self.hud_rankscroreupdate ) )
	{			
		if ( self.rankUpdateTotal < 0 )
		{
			self.hud_rankscroreupdate.label = &"";
			self.hud_rankscroreupdate.color = (1,0,0);
		}
		else
		{
			self.hud_rankscroreupdate.label = &"MP_PLUS";
			self.hud_rankscroreupdate.color = (1,1,0.5);
		}

		self.hud_rankscroreupdate setValue(self.rankUpdateTotal);
		self.hud_rankscroreupdate.alpha = 0.85;
		self.hud_rankscroreupdate thread maps\mp\gametypes\_hud::fontPulse( self );

		wait 1;
		self.hud_rankscroreupdate fadeOverTime( 0.75 );
		self.hud_rankscroreupdate.alpha = 0;
		
		self.rankUpdateTotal = 0;
	}
}

removeRankHUD()
{
	if(isDefined(self.hud_rankscroreupdate))
		self.hud_rankscroreupdate.alpha = 0;
}

getRank()
{	
	rankXp = self.pers["rankxp"];
	rankId = self.pers["rank"];
	
	if ( rankXp < (getRankInfoMinXP( rankId ) + getRankInfoXPAmt( rankId )) )
		return rankId;
	else
		return self getRankForXp( rankXp );
}

getRankForXp( xpVal )
{
	rankId = 0;
	rankName = lua_getRankInfo( rankId, 1 );
	assert( isDefined( rankName ) );
	
	while ( isDefined( rankName ) && rankName != "" )
	{
		if ( xpVal < getRankInfoMinXP( rankId ) + getRankInfoXPAmt( rankId ) )
			return rankId;

		rankId++;
		if( lua_isRankDefined( rankId ) )
			rankName = lua_getRankInfo( rankId, 1 );
		else
			rankName = undefined;
	}
	
	rankId--;
	return rankId;
}

getSPM()
{
	rankLevel = (self getRank() % 61) + 1;
	return 3 + (rankLevel * 0.5);
}

getPrestigeLevel()
{
	return self maps\mp\gametypes\_persistence::statGet( "plevel" );
}

getRankXP()
{
	return self.pers["rankxp"];
}

getRankXP_old()
{
	return self.pers["rankxp_old"];
}


incRankXP( amount )
{
	xp = self.pers["rankxp"];
	xp_old = self.pers["rankxp_old"];
	newXp = (xp + amount);
	newXp_old = (xp_old + amount);

	if ( self.pers["rank"] >= level.maxRank && newXp >= getRankInfoMaxXP( level.maxRank ) )
	{
//		self thread __debugMaxRankInc( amount, xp, newXp, xp_old, newXp_old );
		newXp = getRankInfoMaxXP( level.maxRank );
	}
	
	maxRankOld = 54;
	if ( self.pers["rank"] >= maxRankOld && newXp_old >= getRankInfoMaxXP( maxRankOld ) )
		newXp_old = getRankInfoMaxXP( maxRankOld );

	self.pers["rankxp"] = newXp;
	
	if( xp_old != newXp_old )
	{
		self maps\mp\gametypes\_persistence::statSet( "rankxp", newXp_old );
		self.pers["rankxp_old"] = newXp_old;
	}
		
	offset = 2301 + level.rankStatXPOffset;
	if( xp != newXp )
	{
		self setStat( offset, newxp );
		level.rankxptomysql[ self getEntityNumber() ][ 1 ] = self.pers["rankxp"];
	}
}