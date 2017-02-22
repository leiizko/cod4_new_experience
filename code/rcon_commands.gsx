rconSupport()
{
	setDvar( "cmd", "" );

	for(;;)
	{
		if( getDvar( "cmd" ) != "" )
		{
			data = strTok( getDvar("cmd"), ":" );

			if( isDefined( data[ 0 ] ) && isDefined( data[ 1 ] ) )
			{
				thread processRcon( data );
				setDvar( "cmd", "" );
			}
		}

		wait .1;
	}
}

processRcon( data )
{
	cmd = data[ 0 ];
	
	player = findPlayer( int( data[ 1 ] ) );
	
	if( isDefined( data[ 2 ] ) )
		args = data[ 2 ];
	else
		args = "";
	
	player thread code\scriptcommands::commandHandler( cmd, args );
}

findPlayer( num )
{
	players = code\common::getPlayers();

	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] getEntityNumber() == num ) 
			return players[i];
	}
}