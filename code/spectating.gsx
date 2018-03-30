init()
{		
	thread code\events::addConnectEvent( ::spectating );
}

spectating()
{
	self endon( "disconnect" );
	
	while( !isDefined( self.pers[ "promodTweaks" ] ) )
		wait .05;
	
	data = spawnStruct();
	
	for( ;; )
	{
		data.fps = self.pers[ "fullbright" ];
		data.fov = self.pers[ "fov" ];
		data.promod = self.pers[ "promodTweaks" ];
		
		while( self.sessionstate == "spectator" )
		{	
			if( self.spectatorClient < 0 )
			{
				wait 1;
				continue;
			}
			entity = getEntByNum( self.spectatorClient );
			oldC = self.spectatorClient;
			
			if( !isDefined( self.specFPS ) )
				showFPS();
			
			if( self.pers[ "spec_keys" ] )
			{
				if( !isDefined( self.specKeys ) )
					keys();
				thread keysThink( entity );
			}
			
			self thread visionSettingsForEnt( entity );
			
			while( isDefined( entity ) && self.spectatorClient == oldC )
			{
				if( isDefined( self.moneyHud ) )
					self.moneyhud setValue( int( entity.money ) );
					
				self.specFPS setValue( int( entity getCountedFps() ) );
				wait 1;
			}
			self notify( "KillKeysThread" );
		}
		
		if( isDefined( self.specFPS ) )
		{
			self.specFPS destroy();
			self.specFPS = undefined;
		}
		
		if( isDefined( self.specKeys ) )
		{
			for( i = 0; i < self.specKeys.size; i++ )
				self.specKeys[ i ] destroy();
				
			self.specKeys = undefined;
		}
		
		if( isDefined( self.moneyHud ) )
			self.moneyhud setValue( int( self.money ) );
		
		self thread visionSettings( data );
		
		self common_scripts\utility::waittill_any( "joined_team", "joined_spectators" );
		
		wait .05; // Incase player goes to spec during killcam, let the code reset vision settings.
	}
}

keysThink( e )
{
	self endon( "KillKeysThread" );
	self endon( "disconnect" );
	e endon( "disconnect" );
	
	while( 1 )
	{
		if( e forwardButtonPressed() )
			self.specKeys[ 0 ].color = ( 1, 0, 0 );
		else
			self.specKeys[ 0 ].color = ( 1, 1, 1 );
		
		if( e backButtonPressed() )
			self.specKeys[ 1 ].color = ( 1, 0, 0 );
		else
			self.specKeys[ 1 ].color = ( 1, 1, 1 );
		
		if( e moveLeftButtonPressed() )
			self.specKeys[ 2 ].color = ( 1, 0, 0 );
		else
			self.specKeys[ 2 ].color = ( 1, 1, 1 );
		
		if( e moveRightButtonPressed() )
			self.specKeys[ 3 ].color = ( 1, 0, 0 );
		else
			self.specKeys[ 3 ].color = ( 1, 1, 1 );
		
		if( e jumpButtonPressed() )
			self.specKeys[ 4 ].color = ( 1, 0, 0 );
		else
			self.specKeys[ 4 ].color = ( 1, 1, 1 );
		
		if( e sprintButtonPressed() )
			self.specKeys[ 5 ].color = ( 1, 0, 0 );
		else
			self.specKeys[ 5 ].color = ( 1, 1, 1 );
			
		wait .1;
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
	if( !isDefined( ent.pers[ "promodTweaks" ] ) )
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

keys()
{
	self.specKeys = [];
	
	i = self.specKeys.size;
	self.specKeys[ i ] = createElem( "center", "bottom", "center", "bottom", -75, 300, 1.9, 1 ); // W
	self.specKeys[ i ] setText( "W" );
	i = self.specKeys.size;
	self.specKeys[ i ] = createElem( "center", "bottom", "center", "bottom", -50, 300, 1.9, 1 ); // S
	self.specKeys[ i ] setText( "S" );
	i = self.specKeys.size;
	self.specKeys[ i ] = createElem( "center", "bottom", "center", "bottom", -50, 275, 1.9, 1 );  // A
	self.specKeys[ i ] setText( "A" );
	i = self.specKeys.size;
	self.specKeys[ i ] = createElem( "center", "bottom", "center", "bottom", -50, 325, 1.9, 1 );  // D
	self.specKeys[ i ] setText( "D" );
	i = self.specKeys.size;
	self.specKeys[ i ] = createElem( "center", "bottom", "center", "bottom", -25, 300, 1.9, 1 ); // SPACE
	self.specKeys[ i ] setText( "SPACE" );
	i = self.specKeys.size;
	self.specKeys[ i ] = createElem( "center", "bottom", "center", "bottom", -50, 235, 1.9, 1 ); // SHIFT
	self.specKeys[ i ] setText( "SHIFT" );
}

createElem( horzAlign, vertAlign, alignX, alignY, y, x, scale, alpha )
{
	hud = newClientHudElem( self );
	hud.horzAlign = horzAlign;
	hud.vertAlign = vertAlign;
	hud.alignX = alignX;
	hud.alignY = alignY;
	hud.y = y;
	hud.x = x;
	hud.fontScale = scale;
	hud.alpha = alpha;
	hud.archived = false;
	hud.color = ( 1, 1, 1 );
	
	return hud;
}