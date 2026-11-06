init()
{
	thread code\events::addSpawnEvent( ::onPlayerSpawn );
}

onPlayerSpawn()
{
	self endon( "disconnect" );
	
	if( isDefined( level.nukeInProgress ) )
		self endon( "death" );
	
	if( level.inPrematchPeriod )
		level waittill( "prematch_over" );
		
	waittillframeend;
	
	self thread code\common::godMod();
	self.spawnprotected = true;
		
	startPos = self.origin;
	time = level.dvar[ "prot_time" ] * 20;
	
	waittillframeend;

	self hide();
	self disableWeapons();
	self thread hud();
	
	while( time > 0 )
	{
		if( distancesquared( startPos, self.origin ) > 15625 ) // dist > 125
			break;
			
		if( self attackButtonPressed() || self meleeButtonPressed() || self fragButtonPressed() )
			break;

		wait .05;

		time--;
	}

	self enableWeapons();
	self show();
	
	self thread code\common::restoreHP();

	if( isDefined( self.spawnprot_cntr ) ) 
		self.spawnprot_cntr destroy(); 
	if( isDefined( self.spawnprot_text ) ) 
		self.spawnprot_text destroy();
	if( isDefined( self.spawnprot_panel ) )
		ghost\hud::destroyHudGroup( self.spawnprot_panel );
	
	self.spawnprotected = undefined;
	self notify( "spawnProtectionDisabled" );
}

hud()
{
	if( isDefined( self.spawnprot_cntr ) ) 
		self.spawnprot_cntr destroy(); 
	if( isDefined( self.spawnprot_text ) ) 
		self.spawnprot_text destroy();
	if( isDefined( self.spawnprot_panel ) )
		ghost\hud::destroyHudGroup( self.spawnprot_panel );

	self.spawnprot_panel = self ghost\hud::createPanel( 180, 40, 0, 150, "center", "center_safearea", "center", "top" );

	self.spawnprot_text = self ghost\hud::createLabel( "Spawn protection", "objective", 1.4, 0, 154, "center", "center_safearea", "center", "top" );
	self.spawnprot_text.color = level.hudTheme[ "accent" ];

	self.spawnprot_cntr = newClientHudElem( self );
	self.spawnprot_cntr.x = 0;
	self.spawnprot_cntr.y = 172;
	self.spawnprot_cntr.alignX = "center";
	self.spawnprot_cntr.alignY = "top";
	self.spawnprot_cntr.horzAlign = "center";
	self.spawnprot_cntr.vertAlign = "center_safearea";
	self.spawnprot_cntr.alpha = 1;
	self.spawnprot_cntr.archived = false;
	self.spawnprot_cntr.font = "default";
	self.spawnprot_cntr.fontScale = 1.25;
	self.spawnprot_cntr.color = level.hudTheme[ "primary" ];
	self.spawnprot_cntr.sort = 2;
	self.spawnprot_cntr setTenthsTimer( level.dvar[ "prot_time" ] );	
}