rconSupport()
{
	setDvar( "cmd", "" );

	for(;;)
	{
		if( getDvar( "cmd" ) != "" )
		{
			data = strTok( getDvar("cmd"), ":" );

			if( isDefined( data[0] ) && isDefined( data[1] ) )
			{
				thread processRcon( data );
				setDvar( "cmd", "" );
			}
		}

		wait .15;
	}
}

processRcon( data )
{
	cmd = data[ 0 ];
	
	player = findPlayer( int( data[ 1 ] ) );
	
	switch( cmd )
		{
			case "fps":
				if( !level.dvar["cmd_fps"] )
					break;

				if( self.pers["fullbright"] == 0 )
				{
					self iPrintlnBold( "Fullbright ^2ON ^7" );
					self setClientDvar( "r_fullbright", 1 );
					self setstat(3160,1);
					self.pers["fullbright"] = 1;
					
					if( self.pers["promodTweaks"] == 1 )
					{
						self iPrintlnBold( "Promod vision ^1OFF" );
						self SetClientDvars( "r_filmusetweaks", "0",
											 "r_filmTweakenable", "0" );
						self setstat(3162,0);
						self.pers["promodTweaks"] = 0;
					}
				}
				else
				{
					self iPrintlnBold( "Fullbright ^1OFF" );
					self setClientDvar( "r_fullbright", 0 );
					self setstat(3160,0);
					self.pers["fullbright"] = 0;
				}
				break;

			case "fov":
				if( !level.dvar["cmd_fov"] )
					break;
				
				if(player.pers["fov"] == 1 )
				{
					player iPrintlnBold( "Field of View Scale: ^11.0" );
					player setClientDvar( "cg_fovscale", 1.0 );
					player setClientDvar( "cg_fov", 80 );
					player setstat(3161,0);
					player.pers["fov"] = 0;
				}
				else if(player.pers["fov"] == 0)
				{
					player iPrintlnBold( "Field of View Scale: ^11.25" );
					player setClientDvar( "cg_fovscale", 1.25 );
					player setClientDvar( "cg_fov", 80 );
					player setstat(3161,2);
					player.pers["fov"] = 2;
				}
				else if(player.pers["fov"] == 2)
				{
					player iPrintlnBold( "Field of View Scale: ^11.125" );
					player setClientDvar( "cg_fovscale", 1.125 );
					player setClientDvar( "cg_fov", 80 );
					player setstat(3161,1);
					player.pers["fov"] = 1;
				}
				break;
			
			case "promod":
				if( !level.dvar["cmd_promod"] )
					break;

				if( self.pers["promodTweaks"] == 0 )
				{
					self iPrintlnBold( "Promod vision ^2ON ^7" );
					self SetClientDvars( "r_filmTweakInvert", "0",
										 "r_filmTweakBrightness", "0",
										 "r_filmusetweaks", "1",
										 "r_filmTweakenable", "1",
										 "r_filmtweakLighttint", "0.8 0.8 1",
										 "r_filmTweakContrast", "1.2",
										 "r_filmTweakDesaturation", "0",
										 "r_filmTweakDarkTint", "1.8 1.8 2" );

					self setstat(3162,1);
					self.pers["promodTweaks"] = 1;
					
					if( self.pers[ "fullbright" ] == 1 )
					{
						self iPrintlnBold( "Fullbright ^1OFF" );
						self setClientDvar( "r_fullbright", 0 );
						self setstat(3160,0);
						self.pers["fullbright"] = 0;
					}
				}
				else
				{
					self iPrintlnBold( "Promod vision ^1OFF" );
					self SetClientDvars( "r_filmusetweaks", "0",
										 "r_filmTweakenable", "0" );
					self setstat(3162,0);
					self.pers["promodTweaks"] = 0;
				}
				break;
			
			case "help":
				player iprintlnBold( "This server is using ^1custom ^7server side ^1modification \n^7with ^5NEW ^7killstreaks, shop, spawn protection and more" );
				wait 2;
				player iprintlnBold( "To ^5buy ^7hardpoints^7(^5killstreaks^7) press ^1[{+actionslot 4}]^7. \n^5Kill ^7players to earn credits!" );
				wait 2;
				player iprintlnBold( "Type ^1$fov^7, ^2$fps ^7or ^3$promod ^7to change your ^5vision settings" );
				break;
				
			default:
				break;
		}
}

findPlayer( num )
{
	level endon( "game_ended" );
	
	players = code\common::getPlayers();

	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] getEntityNumber() == num ) 
			return players[i];
	}
}