init()
{
	tier = getDvarInt( "dynamic_tier" );
	switch( tier )
	{
		case 1:
			setDvar( "dynamic_low_current", getDvar( "sv_mapRotationCurrent" ) );
			break;
			
		case 2:
			setDvar( "dynamic_med_current", getDvar( "sv_mapRotationCurrent" ) );
			break;
			
		case 3:
			setDvar( "dynamic_high_current", getDvar( "sv_mapRotationCurrent" ) );
			break;
			
		default:
			break;
	}
}

checkTier()
{
	players = level.players;
	
	if( players.size < level.dvar[ "dynamic_med" ] )
	{
		if( getDvarInt( "dynamic_tier" ) != 1 )
		{
			setDvar( "sv_mapRotation", level.dvar[ "dynamic_low_maps" ] );
			if( getDvar( "dynamic_low_current" ).size < 2 )
				setDvar( "sv_mapRotationCurrent", level.dvar[ "dynamic_low_maps" ] );
			else
				setDvar( "sv_mapRotationCurrent", getDvar( "dynamic_low_current" ) );
		}
		setDvar( "dynamic_tier", 1 );
	}
	
	else if( players.size >= level.dvar[ "dynamic_med" ] && players.size < level.dvar[ "dynamic_high" ] )
	{
		if( getDvarInt( "dynamic_tier" ) != 2 )
		{
			setDvar( "sv_mapRotation", level.dvar[ "dynamic_med_maps" ] );
			if( getDvar( "dynamic_med_current" ).size < 2 )
				setDvar( "sv_mapRotationCurrent", level.dvar[ "dynamic_med_maps" ] );
			else
				setDvar( "sv_mapRotationCurrent", getDvar( "dynamic_med_current" ) );
		}
		setDvar( "dynamic_tier", 2 );
	}
	
	else if( players.size >= level.dvar[ "dynamic_high" ] )
	{
		if( getDvarInt( "dynamic_tier" ) != 3 )
		{
			setDvar( "sv_mapRotation", level.dvar[ "dynamic_high_maps" ] );
			if( getDvar( "dynamic_high_current" ).size < 2 )
				setDvar( "sv_mapRotationCurrent", level.dvar[ "dynamic_high_maps" ] );
			else
				setDvar( "sv_mapRotationCurrent", getDvar( "dynamic_high_current" ) );
		}
		setDvar( "dynamic_tier", 3 );
	}
}