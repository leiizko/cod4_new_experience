init()
{
	lua_antiCamp_setMinStats( level.dvar[ "anticamp_dist" ], level.dvar[ "anticamp_time" ] );
	
	thread code\events::addConnectEvent( ::onConnect );
	
	if( getDvar( "g_gametype" ) == "war" )
		thread code\events::addConnectEvent( ::antiCamp );
}

onConnect()
{
	if( !isDefined( self.antiCampMod ) )
	{
		lua_antiCamp_initPlayer( self getEntityNumber() );
		self.antiCampMod = 1;
		self thread modHud();
	}
}

antiCamp()
{
	self endon( "disconnect" );
	
	while( 1 )
	{
		if( !isAlive( self ) )
			self waittill( "spawned_player" );
		
		if( !isDefined( self.HealthProtected ) && isDefined( self.ac_modHud ) )
		{
			old = self.antiCampMod;
			self.antiCampMod = lua_antiCamp_updatePlayer( self getEntityNumber(), self.origin, self getStance(), self PlayerAds() );

			if( old != self.antiCampMod )
				self.ac_modHud setValue( self.antiCampMod * 100 );
		}
		
		wait .25;
	}
}

modHud()
{
	self.ac_modHud = newClientHudElem( self );
	self.ac_modHud.archived = true;
	self.ac_modHud.alignX = "right";
	self.ac_modHud.alignY = "bottom";
	self.ac_modHud.label = &"DMG: &&1%";
	self.ac_modHud.horzAlign = "right";
	self.ac_modHud.vertAlign = "bottom";
	self.ac_modHud.fontscale = 1.5;
	self.ac_modHud.x = -20;
	self.ac_modHud.y = -65;
	
	self.ac_modHud setValue( self.antiCampMod * 100 );
}