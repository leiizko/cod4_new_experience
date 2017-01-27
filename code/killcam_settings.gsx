init()
{
	thread code\events::addDeathEvent( ::onPlayerKilled );
	
	level.caminfo = [];
	level.caminfo[ "allies" ] = [];
	level.caminfo[ "allies" ][ "attacker" ] = spawnStruct();
	level.caminfo[ "allies" ][ "victim" ] = spawnStruct();
	level.caminfo[ "axis" ] = [];
	level.caminfo[ "axis" ][ "attacker" ] = spawnStruct();
	level.caminfo[ "axis" ][ "victim" ] = spawnStruct();
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;
	
	team = attacker.team;
	
	if( isDefined( attacker ) && self != attacker && isDefined( team ) )
	{
		level.caminfo[ team ][ "attackerNum" ] = attacker getEntityNumber();
		level.caminfo[ team ][ "attacker" ].name = attacker.name;
		level.caminfo[ team ][ "time" ] = getTime();
		level.caminfo[ team ][ "victim" ].name = self.name;
		level.caminfo[ team ][ "victim" ].team = self.team;
		level.caminfo[ team ][ "sWeapon" ] = sWeapon;
		level.caminfo[ team ][ "predelay" ] = 4;
		level.caminfo[ team ][ "psOffsetTime" ] = psOffsetTime;

		if( isDefined( eInflictor ) && eInflictor != attacker )
			level.caminfo[ team ][ "killcamentity" ] = eInflictor getEntityNumber();
		else
			level.caminfo[ team ][ "killcamentity" ] = -1;
		
		if( isDefined( self.sWeaponForKillcam ) )
			level.caminfo[ team ][ "sWeaponForKillcam" ] = self.sWeaponForKillcam;
		else
			level.caminfo[ team ][ "sWeaponForKillcam" ] = undefined;
	}
}

kcCache()
{
	precacheShader( "compass_objpoint_airstrike_busy" );
	precacheShader( "compass_objpoint_helicopter_busy" );
	precacheShader( "compassping_explosion" );
	precacheShader( "compass_objpoint_flak" );
	precacheShader( "death_airstrike" );
	precacheShader( "weapon_fraggrenade" );
	precacheShader( "weapon_concgrenade" );
	precacheShader( "weapon_flashbang" );
	precacheShader( "weapon_smokegrenade" );
	precacheShader( "weapon_rpg7" );
	precacheShader( "death_car" );
	precacheShader( "weapon_miniuzi" );
	precacheShader( "weapon_usp_45" );
	precacheShader( "weapon_m4carbine" );
	precacheShader( "weapon_aks74u" );
	precacheShader( "weapon_m203" );
	precacheShader( "weapon_barrett50cal" );
	precacheShader( "weapon_m9beretta" );
	precacheShader( "weapon_benelli_m4" );
	precacheShader( "weapon_colt_45" );
	precacheShader( "weapon_desert_eagle" );
	precacheShader( "weapon_desert_eagle_gold" );	
	precacheShader( "weapon_dragunovsvd" );
	precacheShader( "weapon_m16a4" );
	precacheShader( "weapon_m249saw" );
	precacheShader( "weapon_ak47" );
	precacheShader( "weapon_g3" );
	precacheShader( "weapon_g36c" );
	precacheShader( "weapon_m14" );
	precacheShader( "weapon_m40a3" );
	precacheShader( "weapon_m60e4" );
	precacheShader( "weapon_mp44" );
	precacheShader( "weapon_mp5" );
	precacheShader( "weapon_p90" );
	precacheShader( "weapon_remington700" );
	precacheShader( "weapon_rpd" );
	precacheShader( "weapon_skorpion" );
	precacheShader( "weapon_winchester1200" );
	precacheShader( "weapon_c4" );
	precacheShader( "weapon_claymore" );
	
	
	// These two are already precached but keeping them here if this is to be used stand-alone
	//precacheShader( "killiconsuicide" );
	//precacheShader( "killiconmelee" );
}

killcamData( weap, means )
{
	data = spawnStruct();
	
	if( !isDefined( means ) )
		means = "";
	
	if( means == "MOD_MELEE" )
	{
		data.icon = "killiconmelee";
		data.name = "Knife";
		return data;
	}
	else if( means == "MOD_EXPLOSIVE" && weap == "none" )
	{
		data.icon = "killiconsuicide";
		data.name = "Explosive barrel";
		return data;
	}
	
	weap_dig = strTok( weap, "_" );
	weap = weap_dig[ 0 ];
	
	switch( weap )
	{
		case "artillery":
			if( isDefined( self.sWeaponForKillcam ) )
			{
				switch( self.sWeaponForKillcam )
				{
					case "ac130_105mm":
						data.icon = "compass_objpoint_airstrike_busy";
						data.name = "AC130 105mm";
						break;
					case "ac130_40mm":
						data.icon = "compass_objpoint_airstrike_busy";
						data.name = "AC130 40mm";
						break;
					case "ac130_25mm":
						data.icon = "compass_objpoint_airstrike_busy";
						data.name = "AC130 25mm";
						break;
					case "nuke_main":
						data.icon = "compassping_explosion";
						data.name = "Tactical nuke";
						break;
					case "nuke_rad":
						data.icon = "killiconsuicide";
						data.name = "Radiation";
						break;
					case "agm":
						data.icon = "compassping_explosion";
						data.name = "Air-Ground missile";
						break;
					case "artillery":
						data.icon = "compass_objpoint_flak";
						data.name = "Artillery";
						break;
					default:
						data.icon = "death_airstrike";
						data.name = "Airstrike";
						break;
				}
			}
			else
				data.icon = "death_airstrike";
				data.name = "Airstrike";
			break;
			
		case "cobra":
		case "hind":
			data.icon = "compass_objpoint_helicopter_busy";
			data.name = "Helicopter";
			break;
			
		case "claymore":
			data.icon = "weapon_claymore";
			data.name = "Claymore";
			break;
			
		case "frag":
			data.icon = "weapon_fraggrenade";
			data.name = "Frag Grenade";
			break;
			
		case "concussion":
			data.icon = "weapon_concgrenade";
			data.name = "Stun Grenade";
			break;
		
		case "flash":
			data.icon = "weapon_flashbang";
			data.name = "Flashbang";
			break;
			
		case "smoke":
			data.icon = "weapon_smokegrenade";
			data.name = "Smoke Grenade";
			break;
			
		case "rpg":
			data.icon = "weapon_rpg7";
			data.name = "RPG7";
			break;
			
		case "destructible":
			data.icon = "death_car";
			data.name = "Car explosion";
			break;
			
		case "uzi":
			data.icon = "weapon_mini" + weap;
			data.name = "Mini Uzi";
			break;
			
		case "usp":
			data.icon = "weapon_" + weap + "_45";
			data.name = "USP 45";
			break;
		
		case "m4":
			data.icon = "weapon_" + weap + "carbine";
			data.name = "M4 Carbine";
			break;
			
		case "ak74u":
			data.icon = "weapon_aks74u";
			data.name = "AK47u";
			break;
			
		case "gl":
			data.icon = "weapon_m203";
			data.name = "Grenade Launcher";
			break;
			
		case "barrett":
			data.icon = "weapon_" + weap + "50cal";
			data.name = "M107 Barrett 50cal";
			break;
			
		case "beretta":
			data.icon = "weapon_m9" + weap;
			data.name = "M9 Beretta";
			break;
			
		case "m1014":
			data.icon = "weapon_benelli_m4";
			data.name = "M1014";
			break;
			
		case "m21":
			data.icon = "weapon_m14_scoped";
			data.name = "M21";
			break;
			
		case "skorpion":
			data.icon = "weapon_skorpion";
			data.name = "Skorpion";
			break;
		
		case "colt45":
			data.icon = "weapon_colt_45";
			data.name = "Colt 45";
			break;
			
		case "deserteagle":
			data.icon = "weapon_desert_eagle";
			data.name = "Desert Eagle";
			break;
			
		case "deserteaglegold":
			data.icon = "weapon_desert_eagle_gold";
			data.name = "Golden Desert Eagle";
			break;
			
		case "dragunov":
			data.icon = "weapon_dragunovsvd";
			data.name = "Dragunov";
			break;
			
		case "m16":
			data.icon = "weapon_m16a4";
			data.name = "M16A4";
			break;
			
		case "saw":
			data.icon = "weapon_m249saw";
			data.name = "M249 SAW";
			break;
			
		default:
			data.icon = "weapon_" + weap;
			data.name = weaponName( weap );
			break;
	}
	
	return data;
}

weaponName( weap )
{
	new = "";
	for( i = 0; i < weap.size; i++ )
	{
		if( !int( weap[ i ] ) )
			new += toUpper( weap[ i ] );
		else
			new += weap[ i ];
	}
	
	return new;
}

// TODO: Move this later to utils
toUpper( letter )
{
	upper = letter;
	
	switch( letter )
	{
		case "a":
			upper = "A";
			break;
			
		case "b":
			upper = "B";
			break;
			
		case "c":
			upper = "C";
			break;
			
		case "d":
			upper = "D";
			break;
			
		case "e":
			upper = "E";
			break;
			
		case "f":
			upper = "F";
			break;
			
		case "g":
			upper = "G";
			break;
			
		case "h":
			upper = "H";
			break;
			
		case "i":
			upper = "I";
			break;
			
		case "j":
			upper = "J";
			break;
			
		case "k":
			upper = "K";
			break;
			
		case "l":
			upper = "L";
			break;
			
		case "m":
			upper = "M";
			break;
			
		case "n":
			upper = "N";
			break;
			
		case "o":
			upper = "A";
			break;
			
		case "p":
			upper = "P";
			break;
			
		case "q":
			upper = "Q";
			break;
			
		case "r":
			upper = "R";
			break;
			
		case "s":
			upper = "S";
			break;
			
		case "t":
			upper = "T";
			break;
			
		case "u":
			upper = "U";
			break;
			
		case "v":
			upper = "V";
			break;
			
		case "w":
			upper = "W";
			break;
			
		case "x":
			upper = "X";
			break;
			
		case "y":
			upper = "Y";
			break;
			
		case "z":
			upper = "Z";
			break;
			
		default:
			break;
	}
	
	return upper;
}