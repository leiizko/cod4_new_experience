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
	
	self.spawnprotected = undefined;
	self notify( "spawnProtectionDisabled" );
}

hud()
{
	if( isDefined( self.spawnprot_cntr ) ) 
		self.spawnprot_cntr destroy(); 
	if( isDefined( self.spawnprot_text ) ) 
		self.spawnprot_text destroy();

	self.spawnprot_text = newClientHudElem( self );
	self.spawnprot_text.x = 0;
	self.spawnprot_text.y = 180;
	self.spawnprot_text.alignX = "center";
	self.spawnprot_text.alignY = "middle";
	self.spawnprot_text.horzAlign = "center_safearea";
	self.spawnprot_text.vertAlign = "center_safearea";
	self.spawnprot_text.alpha = 1;
	self.spawnprot_text.archived = false;
	self.spawnprot_text.font = "default";
	self.spawnprot_text.fontscale = 1.4;
	self.spawnprot_text.color = ( 0.980, 0.996, 0.388 );
	self.spawnprot_text setText( "^1Spawn protection" );

	self.spawnprot_cntr = newClientHudElem( self );
	self.spawnprot_cntr.x = 0;
	self.spawnprot_cntr.y = 160;
	self.spawnprot_cntr.alignX = "center";
	self.spawnprot_cntr.alignY = "middle";
	self.spawnprot_cntr.horzAlign = "center_safearea";
	self.spawnprot_cntr.vertAlign = "center_safearea";
	self.spawnprot_cntr.alpha = 1;
	self.spawnprot_cntr.fontScale = 1.8;
	self.spawnprot_cntr.color = ( .99, .00, .00 );	
	self.spawnprot_cntr setTenthsTimer( level.dvar[ "prot_time" ] );	
}