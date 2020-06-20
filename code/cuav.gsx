init()
{
	if( level.teambased )
	{
		level.cuav = [];
	}
	
	level.cuavwaittime = 30;
}

useCUAV()
{
	if( level.teambased )
	{
		self thread code\common::notifyTeamLn( lua_getLocString( self.pers[ "language" ], "HARDPOINT_CALLED_BY" ), lua_getLocString( self.pers[ "language" ], "CUAV" ), self.name );
		level thread useTeamCUAV( self.team );
	}
	else
		level thread usePlayerCUAV();
		
	return true;
}

usePlayerCUAV()
{
	level notify( "cuav_player_kill" );
	level endon( "cuav_player_kill" );
	
	level.cuav = true;
	
	wait level.cuavwaittime;
	
	level.cuav = undefined;
}

useTeamCUAV( team )
{
	level notify( "cuav_team_kill_" + team );
	level endon( "cuav_team_kill_" + team );
	
	level.cuav[ team ] = true;
	
	wait level.cuavwaittime;
	
	level.cuav[ team ] = undefined;
}
