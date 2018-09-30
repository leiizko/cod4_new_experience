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

		wait .05;
	}
}

processRcon( data )
{
	cmd = data[ 0 ];
	
	if( !code\scriptcommands::isInt( data[ 1 ] ) )
		return;
	
	player = getEntByNum( int( data[ 1 ] ) );
	
	if( !isPlayer( player ) )
		return;
	
	if( isDefined( data[ 2 ] ) )
		args = data[ 2 ];
	else
		args = "";
	
	player thread code\scriptcommands::commandHandler( cmd, args );
}