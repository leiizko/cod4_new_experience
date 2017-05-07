#include maps\mp\gametypes\_hud_util;

init()
{
	level.stratInProgress = true;
	
	thread code\events::addSpawnEvent( ::onSpawn );
	
	waittillframeend;
	
	if( level.inPrematchPeriod )
		level waittill( "prematch_over" );
	
	matchStartText = createServerFontString( "objective", 1.5 );
	matchStartText setPoint( "CENTER", "CENTER", 0, -55 );
	matchStartText.sort = 1001;
	matchStartText setText( level.dvar[ "strat_text" ] );
	matchStartText.foreground = false;
	matchStartText.hidewheninmenu = false;
	matchStartText.glowcolor = ( 0, 0, 1 );
	matchStartText.glowAlpha = 1;

	for( i = 0; i < level.dvar[ "strat_time" ]; i++ )
	{
		matchStartTimer = createElem( "center", "middle", "center", "middle", 0, -30, 2.8, 1 );
		matchStartTimer setText( level.dvar[ "strat_time" ] - i );
		matchStartTimer.glowcolor = ( 0, 0, 1 );
		matchStartTimer.glowAlpha = 1;
		matchStartTimer SetPulseFX( 5, 800, 200 );
		wait 1;
		matchStartTimer destroy();
	}
	
	
	matchStartText destroy();
	
	level.stratInProgress = undefined;
	waittillframeend;
	level notify( "endStratTimer" );
}

onSpawn()
{
	self endon( "disconnect" );
	self endon( "death" );
	
	if( level.inPrematchPeriod )
		level waittill( "prematch_over" );
	
	reset = false;
	
	if( isDefined( level.stratInProgress ) )
	{
		self disableWeapons();
		self AllowSprint( false );
		self SetMoveSpeedScale( 0 );
		self AllowJump( false );
		reset = true;
		
		level waittill( "endStratTimer" );
	}
	
	if( reset )
	{
		self enableWeapons();
		self AllowSprint( true );
		self makeSpeed();
		self AllowJump( true );
	}
}

makeSpeed()
{
	switch( self.pers[ "weaponClassPrimary" ] )
	{
		case "rifle":
			self setMoveSpeedScale( 0.95 );
			break;
		case "pistol":
			self setMoveSpeedScale( 1.0 );
			break;
		case "mg":
			self setMoveSpeedScale( 0.875 );
			break;
		case "smg":
			self setMoveSpeedScale( 1.0 );
			break;
		case "spread":
			self setMoveSpeedScale( 1.0 );
			break;
		default:
			self setMoveSpeedScale( 1.0 );
			break;
	}
}

createElem( horzAlign, vertAlign, alignX, alignY, x, y, scale, alpha )
{
	hud = newHudElem();
	hud.horzAlign = horzAlign;
	hud.vertAlign = vertAlign;
	hud.alignX = alignX;
	hud.alignY = alignY;
	hud.y = y;
	hud.x = x;
	hud.fontScale = scale;
	hud.alpha = alpha;
	hud.archived = false;
	
	return hud;
}