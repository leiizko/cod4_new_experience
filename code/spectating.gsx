init()
{		
	thread code\events::addConnectEvent( ::spectating );
}

spectating()
{
	self endon( "disconnect" );
	
	for( ;; )
	{		
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
				
			self thread visionSettings( entity );
			
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
		
		self thread visionSettings( self );
		
		self common_scripts\utility::waittill_any( "joined_team", "joined_spectators", "death" );
	}
}

showFPS()
{
	self endon( "disconnect" );
	
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

visionSettings( entity )
{
	self endon( "disconnect" );
	entity endon( "disconnect" );
	
	if( !isDefined( entity.pers[ "fov" ] ) )
		return;
	
	switch( entity.pers[ "fov" ] )
	{
		case 0:
			self setClientDvar( "cg_fovscale", 1.0 );
			self setClientDvar( "cg_fov", 80 );
			break;
		case 1:
			self setClientDvar( "cg_fovscale", 1.125 );
			self setClientDvar( "cg_fov", 80 );
			break;
		case 2:
			self setClientDvar( "cg_fovscale", 1.25 );
			self setClientDvar( "cg_fov", 80 );
			break;
		default:
			break;
	}
	
	if( entity.pers[ "fullbright" ] == 1 )
		self setClientDvar( "r_fullbright", 1 );
	else
		self setClientDvar( "r_fullbright", 0 );
	
	if( entity.pers[ "promodTweaks" ] == 1 )
		self SetClientDvars( "r_filmTweakInvert", "0",
                     	     "r_filmTweakBrightness", "0",
                     	     "r_filmusetweaks", "1",
                     	     "r_filmTweakenable", "1",
                      	     "r_filmtweakLighttint", "0.8 0.8 1",
                       	     "r_filmTweakContrast", "1.2",
                       	     "r_filmTweakDesaturation", "0",
                       	     "r_filmTweakDarkTint", "1.8 1.8 2" );
	else
		self SetClientDvars( "r_filmusetweaks", "0",
                     	     "r_filmTweakenable", "0" );
}

keyOverlay( entity )
{
	self endon( "disconnect" );
	entity endon( "disconnect" );
	
	self notify( "newEntity" ); // only 1 thread
	self endon( "newEntity" );
	
	while( 1 )
	{
		if( entity forwardButtonPressed() )
			self iprintlnbold( "W" );
			
		if( entity moveLeftButtonPressed() )
			self iprintlnbold( "A" );
		
		if( entity backButtonPressed() )
			self iprintlnbold( "S" );
		
		if( entity moveRightButtonPressed() )
			self iprintlnbold( "D" );
		
		if( entity sprintButtonPressed() )
			self iprintlnbold( "SHIFT" );
			
		if( entity jumpButtonPressed() )
			self iprintlnbold( "SPACE" );
		
		if( entity isCrouching() )
			self iprintlnbold( "C" );
			
		wait .05;
	}
}
