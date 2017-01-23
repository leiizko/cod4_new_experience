#include maps\mp\gametypes\_hud_util;

killcam(
	attackerNum, // entity number of the attacker
	killcamentity, // entity number of the attacker's killer entity aka helicopter or airstrike
	sWeapon, // killing weapon
	predelay, // time between player death and beginning of killcam
	offsetTime, // something to do with how far back in time the killer was seeing the world when he made the kill; latency related, sorta
	maxtime, // time remaining until map ends; the killcam will never last longer than this. undefined = no limit
	attacker, // entity object of attacker
	victim,  // entity object of victim
	time,
	sWeaponForKillcam
)
{
	self endon("disconnect");

	if(attackerNum < 0)
	{
		return;
	}
	
	self SetClientDvar( "ui_ShowMenuOnly", "none" );
	visionSetNaked( level.script );
		
	waittillframeend;
	
	if( isDefined( self.moneyhud ) )
		self.moneyhud destroy();

	// length from killcam start to killcam end
	if( sWeapon == "artillery_mp" )
	{
		if( isDefined( sWeaponForKillcam ) )
		{
			switch( sWeaponForKillcam )
			{
				case "ac130_105mm":
					camtime = 4;
					break;
				case "ac130_40mm":
					camtime = 3.5;
					break;
				case "ac130_25mm":
					camtime = 3;
					break;
				case "nuke_main":
					camtime = 4.5;
					break;
				case "nuke_rad":
					camtime = 3.5;
					break;
				case "agm":
					if( level.AGMLaunchTime[ attackerNum ] / 1000 < 8 )
						camtime = level.AGMLaunchTime[ attackerNum ] / 1000;
					else
						camtime = 1.5;
					break;
				case "artillery":
					camtime = 3.7;
					break;
				default:
					camtime = 1.3;
					break;
			}
		}
		else
			camtime = 1.3;
	}
	else if (sWeapon == "frag_grenade_mp")
		camtime = 4.5; // show long enough to see grenade thrown
	else
		camtime = 4;
	
	postdelay = 1.75;
	
	killcamlength = camtime + postdelay;
	
	self.killcam = true;
	self.finalcam = true;

	killcamoffset = camtime + predelay;
	
	self notify ( "begin_killcam", getTime() );
	
	self thread finalHUD( attacker, victim );
	
	self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.killcamentity = killcamentity;
		
	self.archivetime = (getTime() - time)/1000 + killcamoffset - 4.5;

	self.killcamlength = killcamlength;
	self.psoffsettime = offsetTime;

	// ignore spectate permissions
	self allowSpectateTeam("allies", true);
	self allowSpectateTeam("axis", true);
	self allowSpectateTeam("freelook", true);
	self allowSpectateTeam("none", true);
	
	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait 0.05;

	if ( self.archivetime <= predelay ) // if we're not looking back in time far enough to even see the death, cancel
	{
		self.sessionstate = "dead";
		self.spectatorclient = -1;
		self.killcamentity = -1;
		self.archivetime = 0;
		self.psoffsettime = 0;
		self SetClientDvar( "ui_ShowMenuOnly", "" );
		
		return;
	}

	self thread spawnedKillcamCleanup();
	self thread endedKillcamCleanup();
	
	self thread waitKillcamTime();

	self waittill("end_killcam");

	self endKillcam();
		
	self.sessionstate = "dead";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
}

finalHUD( attacker, victim )
{
	self endon( "disconnect" );
	
	level.randomcolour = ( randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ), randomFloatRange( 0, 1 ) );

	self.villain = createFontString( "default", level.lowerTextFontSize );
	self.villain setPoint( "CENTER", "BOTTOM", -500, -60 ); 
	self.villain.alignX = "right";
	self.villain.archived = false;
	if( isDefined( attacker ) )
		self.villain setText( attacker.name );
	else
		self.villain setText( "[Player Disconnected]" );
	self.villain.alpha = 1;
	self.villain.glowalpha = 1;
	self.villain.glowColor = level.randomcolour;
	self.villain moveOverTime( 2.5 );
	self.villain.x = -20;  

	self.versus = createFontString( "default", level.lowerTextFontSize );
	self.versus.alpha = 0;
	self.versus setPoint( "CENTER", "BOTTOM", 0, -60 );  
	self.versus.archived = false;
	self.versus setText( "vs" );
	self.versus.glowColor = level.randomcolour;
	self.versus fadeOverTime( 2.5 );
	self.versus.alpha = 1;
  
	self.victim = createFontString( "default", level.lowerTextFontSize );
	self.victim setPoint( "CENTER", "BOTTOM", 500, -60 );
	self.victim.alignX = "left";  
	self.victim.archived = false;
	if( isDefined( victim ) )
		self.victim setText( victim.name );
	else
		self.victim setText( "[Player Disconnected]" );
	self.victim.glowalpha = 1; 
	self.victim.glowColor = level.randomcolour;
	self.victim moveOverTime( 2.5 );
	self.victim.x = 20; 
	
	if( isDefined( self.kc_hud ) && isDefined( self.kc_hud[ 0 ] ) )
	{
		for( i = 0; i < 3; i++ )
		{
			if( isDefined( self.kc_hud[ i ] ) )
				self.kc_hud[ i ] destroy();
		}
	}
	
	self.kc_hud[ 0 ] = newClientHudElem( self );
	self.kc_hud[ 0 ].alpha = 1;
	self.kc_hud[ 0 ].y = 15;
	self.kc_hud[ 0 ].alignX = "center";
	self.kc_hud[ 0 ].alignY = "middle";
	self.kc_hud[ 0 ].horzAlign = "center";
	self.kc_hud[ 0 ].vertAlign = "top";
	self.kc_hud[ 0 ].archived = false;
	self.kc_hud[ 0 ].fontscale = 2.2;
	self.kc_hud[ 0 ] setText( "KILLCAM" );
	
	self.kc_hud[ 1 ] = newClientHudElem( self );
	self.kc_hud[ 1 ].alpha = 0.25;
	self.kc_hud[ 1 ] setShader( "white", 640, 30 );
	self.kc_hud[ 1 ].color	= (1, 1, 1);
	self.kc_hud[ 1 ].horzAlign = "fullscreen";
	self.kc_hud[ 1 ].vertAlign = "fullscreen";
	self.kc_hud[ 1 ].archived = false;
	
	self.kc_hud[ 2 ] = newClientHudElem( self );
	self.kc_hud[ 2 ].alpha = 0.25;
	self.kc_hud[ 2 ] setShader( "white", 640, 30 );
	self.kc_hud[ 2 ].color	= (1, 1, 1);
	self.kc_hud[ 2 ].horzAlign = "fullscreen";
	self.kc_hud[ 2 ].vertAlign = "fullscreen";
	self.kc_hud[ 2 ].archived = false;
	self.kc_hud[ 2 ].y = 450;
}

waitKillcamTime()
{
	self endon("disconnect");
	self endon("end_killcam");

	wait(self.killcamlength - 0.05);
	self notify("end_killcam");
}

waitSkipKillcamButton()
{
	self endon("disconnect");
	self endon("end_killcam");

	while(self useButtonPressed())
		wait .05;

	while(!(self useButtonPressed()))
		wait .05;

	self notify("end_killcam");
}

endKillcam()
{
	self endon( "disconnect" );
		
	if( isDefined( self.villain ) )
		self.villain destroy();
		
	if( isDefined( self.versus ) )
		self.versus destroy();
		
	if( isDefined( self.victim ) )
		self.victim destroy();
		
	waittillframeend;
		
	if( isDefined( self.kc_hud ) && isDefined( self.kc_hud[ 0 ] ) )
	{
		for( i = 0; i < 3; i++ )
		{
			if( isDefined( self.kc_hud[ i ] ) )
				self.kc_hud[ i ] destroy();
		}
	}
	
	self.killcam = undefined;
	self.finalcam = undefined;
	
	self SetClientDvar( "ui_ShowMenuOnly", "" );
	
	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

spawnedKillcamCleanup()
{
	self endon("end_killcam");
	self endon("disconnect");

	self waittill("spawned");
	self endKillcam();
	self notify("end_killcam");
}

spectatorKillcamCleanup( attacker )
{
	self endon("end_killcam");
	self endon("disconnect");
	attacker endon ( "disconnect" );

	attacker waittill ( "begin_killcam", attackerKcStartTime );
	waitTime = max( 0, (attackerKcStartTime - self.deathTime) - 50 );
	wait (waitTime);
	self endKillcam();
	self notify("end_killcam");
}

endedKillcamCleanup()
{
	self endon("end_killcam");
	self endon("disconnect");

	level waittill("game_ended");
	self endKillcam();
	self notify("end_killcam");
}