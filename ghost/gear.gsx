init()
{
	thread code\events::addDeathEvent( ::onDeath );
}

onDeath( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self.extraHealth = undefined;
	self.slideCooldownOverride = undefined;
}

buyAmmo()
{
	gave = false;

	current = self getCurrentWeapon();
	if( isDefined( current ) && current != "none" && current != "radar_mp" )
	{
		if( self refillWeapon( current ) )
			gave = true;
	}

	if( isDefined( self.pers[ "lastWeapon" ] ) && self.pers[ "lastWeapon" ] != "none" && self.pers[ "lastWeapon" ] != current && self.pers[ "lastWeapon" ] != "radar_mp" )
	{
		if( self refillWeapon( self.pers[ "lastWeapon" ] ) )
			gave = true;
	}

	offhand = self getCurrentOffhand();
	if( isDefined( offhand ) && offhand != "none" )
	{
		if( self refillWeapon( offhand ) )
			gave = true;
	}

	if( !gave )
	{
		self iPrintLnBold( "Ammo already full" );
		return false;
	}

	self iPrintLnBold( "Extra Ammo purchased" );
	return true;
}

refillWeapon( weap )
{
	clip = self getWeaponAmmoClip( weap );
	stock = self getWeaponAmmoStock( weap );
	self giveMaxAmmo( weap );

	if( self getWeaponAmmoClip( weap ) != clip || self getWeaponAmmoStock( weap ) != stock )
		return true;

	return false;
}

buyHealth()
{
	if( isDefined( self.extraHealth ) )
	{
		self iPrintLnBold( "Extra Health already active" );
		return false;
	}

	self.extraHealth = true;
	self.maxhealth = 150;
	self.health = 150;
	self iPrintLnBold( "Extra Health purchased" );
	return true;
}

buySmoke()
{
	weap = "smoke_grenade_mp";

	if( self hasWeapon( weap ) )
	{
		stock = self getWeaponAmmoStock( weap );
		self setWeaponAmmoStock( weap, stock + 1 );
		self iPrintLnBold( "Smoke Cover purchased" );
		return true;
	}

	self giveWeapon( weap );
	if( !self hasWeapon( weap ) )
	{
		self iPrintLnBold( "Smoke not available" );
		return false;
	}

	self setWeaponAmmoClip( weap, 1 );
	self setWeaponAmmoStock( weap, 0 );
	self iPrintLnBold( "Smoke Cover purchased" );
	return true;
}

buySlide()
{
	if( isDefined( self.slideCooldownOverride ) )
	{
		self iPrintLnBold( "Extra Slide already active" );
		return false;
	}

	self.slideCooldownOverride = 3;
	self iPrintLnBold( "Extra Slide purchased - 3s cooldown" );
	return true;
}
