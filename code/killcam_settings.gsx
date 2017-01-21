init()
{
	thread code\events::addDeathEvent( ::onPlayerKilled );
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;
	
	team = attacker.team;
	
	if( isDefined( attacker ) && self != attacker && isDefined( team ) )
	{
		level.caminfo[ team ][ "attackerNum" ] = attacker getEntityNumber();
		level.caminfo[ team ][ "attacker" ] = spawnStruct();
		level.caminfo[ team ][ "attacker" ].name = attacker.name;
		level.caminfo[ team ][ "time" ] = getTime();
		level.caminfo[ team ][ "victim" ] = spawnStruct();
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

weaponIcon( weap )
{
	icon = "";
	
	weap_dig = strTok( weap, "_" );
	weap = weap_dig[ 0 ];
	
	switch( weap )
	{
		default:
			icon = weap;
			break;
	}
	
	return icon;
}