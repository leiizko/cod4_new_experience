fullUnlock( idx )
{
	if( isDefined( idx ) )
	{
		if( self.pers[ "rankxp" ] < int( lua_getRankInfo( idx, 2 ) ) )
		{
			self.pers[ "rankxp_old" ] = self.pers[ "rankxp" ];
			self.pers[ "rankxp" ] = int( lua_getRankInfo( idx, 2 ) );
			self maps\mp\gametypes\_rank::updateRank_safe( int( lua_getRankInfo( idx, 2 ) ) );
		}
	}
	else
	{
		if( self.pers[ "rankxp" ] < int( lua_getRankInfo( 54, 2 ) ) )
		{
			self.pers[ "rankxp_old" ] = self.pers[ "rankxp" ];
			self.pers[ "rankxp" ] = int( lua_getRankInfo( 54, 2 ) );
			self maps\mp\gametypes\_rank::updateRank_safe( int( lua_getRankInfo( 54, 2 ) ) );
		}
	}
	
#if isSyscallDefined httpPostJson
	self thread code\mysql::UpdateRankXP( self.pers[ "rankxp" ] );
#endif
}

AttachCamoUnlock()
{
	self endon( "disconnect" );
	
	while( !isDefined( self.pers[ "unlocks" ] ) )
		wait .1;
	
	// init attachment
	self unlockAttachments();
	
	wait .1;
	
	// init camo
	self unlockCamos();
}

unlockAttachments()
{
	self endon( "disconnect" );

	weapons = getWeaponList( 1 );
	
	attachments = [];

	attachments[ "grip" ] = "12 13 14 15 16";
	attachments[ "acog" ] = "0 1 2 3 4 5 7 8 9 10 11 12 13 14 17 18 19 20 21";
	attachments[ "silencer" ] = "0 1 2 3 4 5 7 8 9 10 11 22 23 24";
	attachments[ "reflex" ] = "0 1 2 3 4 5 7 8 9 10 11 12 13 14 15 16";
	
	keys = getArrayKeys( attachments );
	for( i = 0; i < keys.size; i++ )
	{
		idx = strTok( attachments[ keys[ i ] ], " " );
		
		for( n = 0; n < idx.size; n++ )
		{
			refString = weapons[ int( idx[ n ] ) ] + " " + keys[ i ];
			self thread maps\mp\gametypes\_rank::unlockAttachment( refString );
			
			if( n % 5 == 0 )
				wait .1;
		}
		
		wait .05;
	}
}

unlockCamos()
{
	self endon( "disconnect" );
	
	weaponList = getWeaponList();
	
	camos = [];
	camos[ camos.size ] = "camo_blackwhitemarpat";
	camos[ camos.size ] = "camo_stagger";
	camos[ camos.size ] = "camo_tigerred";
	
	camosGold = [];
	camosGold[ camosGold.size ] = "ak47 camo_gold";
	camosGold[ camosGold.size ] = "uzi camo_gold";
	camosGold[ camosGold.size ] = "dragunov camo_gold";
	camosGold[ camosGold.size ] = "m1014 camo_gold";
	camosGold[ camosGold.size ] = "m60e4 camo_gold";

	for( i = 0; i < weaponList.size; i++ )
	{
		for( n = 0; n < camos.size; n++ )
		{
			refString = weaponList[ i ] + " " + camos[ n ];
			self thread maps\mp\gametypes\_rank::unlockCamo( refString );
		}
		
		wait .1;
	}
	
	for( i = 0; i < camosGold.size; i++ )
		self thread maps\mp\gametypes\_rank::unlockCamo( camosGold[ i ] );
}

getWeaponList( sideArm )
{
	list = [];
	
	list[ list.size ] = "m16";
	list[ list.size ] = "ak47";
	list[ list.size ] = "m4";
	list[ list.size ] = "g3";
	list[ list.size ] = "g36c";
	list[ list.size ] = "m14";
	list[ list.size ] = "mp44"; // 6
	
	list[ list.size ] = "mp5";
	list[ list.size ] = "skorpion";
	list[ list.size ] = "uzi";
	list[ list.size ] = "ak74u";
	list[ list.size ] = "p90"; // 11
	
	list[ list.size ] = "saw";
	list[ list.size ] = "rpd";
	list[ list.size ] = "m60e4"; // 14
	
	list[ list.size ] = "winchester1200";
	list[ list.size ] = "m1014"; // 16
	
	list[ list.size ] = "m40a3";
	list[ list.size ] = "m21";
	list[ list.size ] = "dragunov";
	list[ list.size ] = "remington700";
	list[ list.size ] = "barrett"; // 21
	
	if( isDefined( sideArm ) )
	{
		list[ list.size ] = "beretta";
		list[ list.size ] = "usp";
		list[ list.size ] = "colt45"; // 24
	}
	
	return list;
}