init()
{
	precacheShader("overlay_low_health");
	
	level.healthOverlayCutoff = 0.55; 
	
	regenTime = 5;
	
	level.playerHealth_RegularRegenDelay = regenTime * 1000;
	
	level.healthRegenDisabled = (level.playerHealth_RegularRegenDelay <= 0);
	
	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		
		player thread playerHealthMonitor();
	}
}

playerHealthMonitor()
{
	self endon( "disconnect" );
	
	for( ;; )
	{
		self waittill( "damage_done" );
		
		if( self.health > 0 )
			self thread regenHealth( self.doSlowDown );
			
		self.doSlowDown = undefined;
	}
}

regenHealth( delay )
{
	self endon( "disconnect" );
	self endon( "killed_player" );
	
	self notify( "regenHealth_Thread" );
	self endon( "regenHealth_Thread" );
	
	regenInterval = 0.05; // 1 / 4 frames * 5 seconds

	regenDelay = 3;
	if( isDefined( delay ) )
		regenDelay += 2;
		
	wait regenDelay;
		
	while( self.health < self.maxHealth )
	{
		ratio = self.health / self.maxHealth;
		
		ratio += regenInterval;
		
		if( ratio > level.healthOverlayCutoff )
			ratio = 1;
			
		self setNormalHealth( ratio );
		
		wait .25;
	}
}