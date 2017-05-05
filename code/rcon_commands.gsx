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
	
	player = getEntByNum( int( data[ 1 ] ) );
	
	if( isDefined( data[ 2 ] ) )
		args = data[ 2 ];
	else
		args = "";
	
	player thread code\scriptcommands::commandHandler( cmd, args );
}