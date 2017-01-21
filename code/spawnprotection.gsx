init()
{
	thread code\events::addSpawnEvent( ::onPlayerSpawn );
}

onPlayerSpawn()
{
	self endon( "disconnect" );
	self endon( "death" ); // Nuke
	
	if( level.inPrematchPeriod )
		level waittill( "prematch_over" );
		
	waittillframeend;
	
	self.maxHealth = 999999;
	self.health = self.maxHealth;
	self.spawnprotected = true;
		
	startPos = self.origin;
	self.protectiontime = 5;
	
	waittillframeend;

	self hide();
	self disableWeapons();
	self thread monitorAttackKey();
	
	if( isDefined( self.spawnprot_cntr ) ) 
		self.spawnprot_cntr destroy(); 
	if( isDefined( self.spawnprot_text ) ) 
		self.spawnprot_text destroy();

	if( !isDefined( self.spawnprot_text ) )
	{
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
	}

	if( !isDefined( self.spawnprot_cntr ) )
	{
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
		self.spawnprot_cntr setTenthsTimer( self.protectiontime );	
	}

	self.protectiontime = self.protectiontime * 10;
	
	while( self.protectiontime > 0 && self.spawnprotected )
	{
		if( distancesquared( startPos, self.origin ) > 160000 )
			break;

		wait .1;

		self.protectiontime--;
	}

	self enableWeapons();
	self show();
	
	self.maxHealth = 30;
	self.health = self.maxHealth;

	if( isDefined( self.spawnprot_cntr ) ) 
		self.spawnprot_cntr destroy(); 
	if( isDefined( self.spawnprot_text ) ) 
		self.spawnprot_text destroy();
	
	self.spawnprotected = undefined;
	self.protectiontime = undefined;
	self notify( "spawnProtectionDisabled" );
}

monitorAttackKey()
{
	self endon( "disconnect" );
	self endon( "spawnProtectionDisabled" );

	while( isDefined( self.spawnprotected ) )
	{
		if( self attackButtonPressed() || self meleeButtonPressed() || self fragButtonPressed() )
		{
			self.spawnprotected = false;
			break;
		}
		
		wait .05;
	}
}