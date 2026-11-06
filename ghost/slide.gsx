init()
{
	if( !level.dvar[ "slide_enable" ] )
		return;

	thread code\events::addConnectEvent( ::onConnect );
	thread code\events::addSpawnEvent( ::onSpawn );
	thread code\events::addDeathEvent( ::onDeath );
}

onConnect()
{
	self.slideLastTime = 0;
	self.slideCooldownOverride = undefined;
	self.sliding = undefined;
	self.slideDenied = 0;
}

onDeath( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self.sliding = undefined;
	self.slideCooldownOverride = undefined;
	self thread destroySlideHud();
}

onSpawn()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	self.sliding = undefined;
	self thread slideWatcher();
	self thread slideHud();
}

getSlideCooldown()
{
	if( isDefined( self.slideCooldownOverride ) )
		return self.slideCooldownOverride;

	return level.dvar[ "slide_cooldown" ];
}

cooldownRemaining()
{
	cool = self getSlideCooldown() * 1000;
	passed = getTime() - self.slideLastTime;
	if( passed >= cool )
		return 0;

	return cool - passed;
}

canSlide()
{
	if( !isAlive( self ) )
		return false;

	if( isDefined( self.sliding ) )
		return false;

	if( isDefined( self.spawnprotected ) )
		return false;

	if( isDefined( self.shop ) )
		return false;

	if( isDefined( self.hardpointVision ) )
		return false;

	if( isDefined( self.killcam ) )
		return false;

	return true;
}

slideWatcher()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	wasSprinting = false;
	lastStance = self getStance();

	for( ;; )
	{
		wait .05;

		stance = self getStance();
		sprinting = false;
		if( self sprintButtonPressed() && stance == "stand" )
			sprinting = true;

		if( wasSprinting && lastStance == "stand" && stance != "stand" )
			self thread trySlide();

		wasSprinting = sprinting;
		lastStance = stance;
	}
}

trySlide()
{
	if( !self canSlide() )
		return;

	if( self cooldownRemaining() > 0 )
	{
		now = getTime();
		if( !isDefined( self.slideDeniedTime ) || now - self.slideDeniedTime > 5000 )
			self.slideDenied = 0;

		self.slideDeniedTime = now;
		self.slideDenied++;
		self notify( "slide_denied" );
		self thread flashSlideBar();
		return;
	}

	self.slideDenied = 0;
	self.slideLastTime = getTime();
	self.sliding = true;
	self thread doSlide();
}

doSlide()
{
	self endon( "disconnect" );
	self endon( "death" );

	angles = self getPlayerAngles();
	forward = anglesToForward( angles );
	forward = ( forward[ 0 ], forward[ 1 ], 0 );
	len = distance( ( 0, 0, 0 ), forward );
	if( len <= 0 )
	{
		self.sliding = undefined;
		return;
	}

	forward = ( forward[ 0 ] / len, forward[ 1 ] / len, 0 );

	duration = level.dvar[ "slide_duration" ];
	steps = int( duration / 0.05 );
	if( steps < 1 )
		steps = 1;

	distPerStep = 200 / steps;
	self setStance( "prone" );

	for( i = 0; i < steps; i++ )
	{
		if( !isAlive( self ) )
			break;

		start = self.origin + ( 0, 0, 12 );
		dest = self.origin + ( forward[ 0 ] * distPerStep, forward[ 1 ] * distPerStep, 0 );
		end = dest + ( 0, 0, 12 );
		trace = bulletTrace( start, end, false, self );

		if( trace[ "fraction" ] < 1 )
			break;

		ground = bulletTrace( dest + ( 0, 0, 20 ), dest - ( 0, 0, 64 ), false, self );
		if( ground[ "fraction" ] >= 1 )
			break;

		self setOrigin( ( dest[ 0 ], dest[ 1 ], ground[ "position" ][ 2 ] ) );
		self setStance( "prone" );
		wait .05;
	}

	self.sliding = undefined;

	if( isAlive( self ) )
	{
		self setStance( "crouch" );
		wait .05;
		if( isAlive( self ) && self getStance() == "crouch" )
			self setStance( "stand" );
	}
}

slideHud()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	self destroySlideHud();

	self.slideHud = [];
	self.slideHud[ 0 ] = newClientHudElem( self );
	self.slideHud[ 0 ].archived = false;
	self.slideHud[ 0 ].alignX = "right";
	self.slideHud[ 0 ].alignY = "bottom";
	self.slideHud[ 0 ].horzAlign = "right";
	self.slideHud[ 0 ].vertAlign = "bottom";
	self.slideHud[ 0 ].x = -20;
	self.slideHud[ 0 ].y = -28;
	self.slideHud[ 0 ].color = level.hudTheme[ "panel" ];
	self.slideHud[ 0 ].alpha = 0;
	self.slideHud[ 0 ] setShader( "white", 90, 8 );

	self.slideHud[ 1 ] = newClientHudElem( self );
	self.slideHud[ 1 ].archived = false;
	self.slideHud[ 1 ].alignX = "right";
	self.slideHud[ 1 ].alignY = "bottom";
	self.slideHud[ 1 ].horzAlign = "right";
	self.slideHud[ 1 ].vertAlign = "bottom";
	self.slideHud[ 1 ].x = -20;
	self.slideHud[ 1 ].y = -28;
	self.slideHud[ 1 ].color = level.hudTheme[ "accent" ];
	self.slideHud[ 1 ].alpha = 0;
	self.slideHud[ 1 ] setShader( "white", 90, 8 );

	self.slideHud[ 2 ] = newClientHudElem( self );
	self.slideHud[ 2 ].archived = false;
	self.slideHud[ 2 ].alignX = "right";
	self.slideHud[ 2 ].alignY = "bottom";
	self.slideHud[ 2 ].horzAlign = "right";
	self.slideHud[ 2 ].vertAlign = "bottom";
	self.slideHud[ 2 ].x = -20;
	self.slideHud[ 2 ].y = -38;
	self.slideHud[ 2 ].font = "default";
	self.slideHud[ 2 ].fontscale = 1.1;
	self.slideHud[ 2 ].color = level.hudTheme[ "muted" ];
	self.slideHud[ 2 ].alpha = 0;
	self.slideHud[ 2 ] setText( "SLIDE" );

	for( ;; )
	{
		remain = self cooldownRemaining();
		if( remain > 0 )
		{
			frac = remain * 1.0 / ( self getSlideCooldown() * 1000 );
			w = int( 90 * frac );
			if( w < 1 )
				w = 1;

			self.slideHud[ 0 ].alpha = level.hudTheme[ "panelAlpha" ];
			self.slideHud[ 1 ].alpha = 0.95;
			self.slideHud[ 1 ] setShader( "white", w, 8 );
			self.slideHud[ 2 ].alpha = 1;
		}
		else
		{
			self.slideHud[ 0 ].alpha = 0;
			self.slideHud[ 1 ].alpha = 0;
			self.slideHud[ 2 ].alpha = 0;
		}

		wait .1;
	}
}

flashSlideBar()
{
	if( !isDefined( self.slideHud ) || !isDefined( self.slideHud[ 0 ] ) )
		return;

	self.slideHud[ 0 ].color = level.hudTheme[ "deny" ];
	wait .15;
	if( isDefined( self.slideHud ) && isDefined( self.slideHud[ 0 ] ) )
		self.slideHud[ 0 ].color = level.hudTheme[ "panel" ];
}

destroySlideHud()
{
	if( !isDefined( self.slideHud ) )
		return;

	ghost\hud::destroyHudGroup( self.slideHud );
	self.slideHud = undefined;
}
