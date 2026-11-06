init()
{
	if( !level.dvar[ "anticheat_enable" ] )
		return;

	thread code\events::addConnectEvent( ::onConnect );
	thread code\events::addSpawnEvent( ::onSpawn );
	thread code\events::addDamageEvent( ::onDamage );
}

onConnect()
{
	self.acScore = 0;
	self.acFlags = [];
	self.acWarned = undefined;
	self.acHits = [];
	self.acShots = 0;
	self.acShotWindow = 0;
	self.acLastOrigin = undefined;
	self.acLastSample = 0;
}

onSpawn()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	self.acLastOrigin = self.origin;
	self.acLastSample = getTime();
	self.acShots = 0;
	self.acShotWindow = getTime();

	self thread speedMonitor();
	self thread fireMonitor();
	self thread slideSpamMonitor();
}

skipSample()
{
	if( isDefined( self.sliding ) )
		return true;

	if( isDefined( self.spawnprotected ) )
		return true;

	if( isDefined( self.hardpointVision ) )
		return true;

	if( isDefined( self.killcam ) )
		return true;

	return false;
}

speedMonitor()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	gSpeed = getDvarFloat( "g_speed" );
	if( gSpeed <= 0 )
		gSpeed = 190;

	sprintScale = getDvarFloat( "player_sprintspeedscale" );
	if( sprintScale <= 0 )
		sprintScale = 1.5;

	maxSpeed = gSpeed * sprintScale * 1.35;
	maxDist = maxSpeed * 0.1;
	maxDistSq = maxDist * maxDist;

	for( ;; )
	{
		wait .1;

		if( self skipSample() )
		{
			self.acLastOrigin = self.origin;
			self.acLastSample = getTime();
			continue;
		}

		if( !isDefined( self.acLastOrigin ) )
		{
			self.acLastOrigin = self.origin;
			continue;
		}

		delta = self.origin - self.acLastOrigin;
		horizSq = ( delta[ 0 ] * delta[ 0 ] ) + ( delta[ 1 ] * delta[ 1 ] );
		vert = delta[ 2 ];

		self.acLastOrigin = self.origin;
		self.acLastSample = getTime();

		if( vert < -20 )
			continue;

		if( horizSq > maxDistSq )
			self addFlag( "speed", 15 );
	}
}

fireMonitor()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	wasAttack = false;

	for( ;; )
	{
		wait .05;

		if( self skipSample() )
		{
			wasAttack = false;
			continue;
		}

		pressed = self attackButtonPressed();
		if( pressed && !wasAttack )
		{
			now = getTime();
			if( now - self.acShotWindow > 1000 )
			{
				self.acShots = 0;
				self.acShotWindow = now;
			}

			self.acShots++;
			if( self.acShots > 18 )
				self addFlag( "firerate", 10 );
		}

		wasAttack = pressed;
	}
}

onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	if( !isDefined( eAttacker ) || !isPlayer( eAttacker ) )
		return;

	if( eAttacker == self )
		return;

	if( eAttacker skipSample() )
		return;

	now = getTime();
	if( !isDefined( eAttacker.acHits ) )
		eAttacker.acHits = [];

	eAttacker.acHits[ eAttacker.acHits.size ] = now;

	trimmed = [];
	for( i = 0; i < eAttacker.acHits.size; i++ )
	{
		if( now - eAttacker.acHits[ i ] <= 1000 )
			trimmed[ trimmed.size ] = eAttacker.acHits[ i ];
	}
	eAttacker.acHits = trimmed;

	if( eAttacker.acHits.size > 10 )
		eAttacker addFlag( "damage", 10 );
}

slideSpamMonitor()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	for( ;; )
	{
		self waittill( "slide_denied" );

		if( isDefined( self.slideDenied ) && self.slideDenied > 3 )
			self addFlag( "slidespam", 8 );
	}
}

addFlag( name, score )
{
	if( !isDefined( self.acScore ) )
		self.acScore = 0;

	now = getTime();
	if( isDefined( self.acLastFlagTime ) && isDefined( self.acLastFlagName ) && self.acLastFlagName == name && now - self.acLastFlagTime < 2000 )
		return;

	self.acLastFlagTime = now;
	self.acLastFlagName = name;
	self.acScore += score;

	if( !isDefined( self.acFlags ) )
		self.acFlags = [];

	entry = name + " +" + score;
	if( self.acFlags.size >= 8 )
	{
		trimmed = [];
		for( i = 1; i < self.acFlags.size; i++ )
			trimmed[ trimmed.size ] = self.acFlags[ i ];
		self.acFlags = trimmed;
	}
	self.acFlags[ self.acFlags.size ] = entry;

	self thread checkThresholds();
}

checkThresholds()
{
	if( self.acScore >= level.dvar[ "anticheat_kick" ] )
	{
		exec( "kick " + self getEntityNumber() + " Anti-cheat suspicion threshold" );
		return;
	}

	if( self.acScore >= level.dvar[ "anticheat_warn" ] && !isDefined( self.acWarned ) )
	{
		self.acWarned = true;
		self thread warnBanner();
	}
}

warnBanner()
{
	self endon( "disconnect" );

	self destroyWarnHud();

	self.acHud = [];
	panel = self ghost\hud::createPanel( 280, 28, 0, 70, "center", "top", "center", "top" );
	self.acHud[ 0 ] = panel[ 0 ];
	self.acHud[ 1 ] = panel[ 1 ];
	self.acHud[ 2 ] = self ghost\hud::createLabel( "Movement / fire pattern flagged", "objective", 1.4, 0, 76, "center", "top", "center", "top" );
	self.acHud[ 2 ].color = level.hudTheme[ "deny" ];

	wait 4;

	self destroyWarnHud();
}

destroyWarnHud()
{
	if( !isDefined( self.acHud ) )
		return;

	ghost\hud::destroyHudGroup( self.acHud );
	self.acHud = undefined;
}

printFlags( toPlayer )
{
	score = 0;
	if( isDefined( self.acScore ) )
		score = self.acScore;

	line = self.name + " score:" + score;
	if( isDefined( self.acFlags ) && self.acFlags.size > 0 )
	{
		line += " flags:";
		for( i = 0; i < self.acFlags.size; i++ )
			line += " " + self.acFlags[ i ];
	}

	exec( "tell " + toPlayer getEntityNumber() + " " + line );
}
