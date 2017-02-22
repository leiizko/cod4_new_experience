init()
{		
	thread code\events::addConnectEvent( ::spectating );
}

spectating()
{
	self endon( "disconnect" );
	
	wait .25; // Let server assign all required variables for this player
	
	data = spawnStruct();
	
	for( ;; )
	{
		data.fps = self.pers[ "fullbright" ];
		data.fov = self.pers[ "fov" ];
		data.promod = self.pers[ "promodTweaks" ];
		
		while( self.sessionstate == "spectator" )
		{			
			entity = self getSpectatorClient(); // Get the entity
			
			if( !isDefined( entity ) ) // Will be undefined if there is there is noone to spectate / free spec
			{
				wait 1;
				continue;
			}
			
			fps = entity getCountedFps();
			
			if( !isDefined( fps ) )
				continue;
			
			if( !isDefined( self.specFPS ) )
				showFPS();
			
			self thread visionSettingsForEnt( entity );
			
			while( isDefined( self getSpectatorClient() ) && entity == self getSpectatorClient() )
			{
				fps = entity getCountedFps();
				
				if( !isDefined( fps ) )
					break;
					
				self.specFPS setValue( int( fps ) );
				wait 1;
			}
		}
		
		if( isDefined( self.specFPS ) )
			self.specFPS destroy();
		
		self thread visionSettings( data );
		
		self common_scripts\utility::waittill_any( "joined_team", "joined_spectators" );
	}
}

visionSettings( data )
{
	self.pers[ "fullbright" ] = data.fps;
	self.pers[ "fov" ] = data.fov;
	self.pers[ "promodTweaks" ] = data.promod;
	
	self thread code\player::userSettings();
}

visionSettingsForEnt( ent )
{
	if( !isDefined( ent.pers[ "fullbright" ] ) )
		return;

	self.pers[ "fullbright" ] = ent.pers[ "fullbright" ];
	self.pers[ "fov" ] = ent.pers[ "fov" ];
	self.pers[ "promodTweaks" ] = ent.pers[ "promodTweaks" ];
	
	self thread code\player::userSettings();
}

showFPS()
{
	self.specFPS = newClientHudElem( self );
	self.specFPS.archived = false;
	self.specFPS.alignX = "center";
	self.specFPS.alignY = "top";
	self.specFPS.horzAlign = "center";
	self.specFPS.vertAlign = "top";
	self.specFPS.fontscale = 1.5;
	self.specFPS.x = -270;
	self.specFPS.y = 2;
	self.specFPS.label = &"Player FPS: ";
	self.specFPS.color = ( 0.9, 0.2, 0.2 );
	self.specFPS setValue( 0 );
}