init()
{
    setDvar( "add_bots", 0 );
    
    thread precache();
    thread onPlayerConnect();

    for(;;)
    {
        if(getdvarInt("add_bots") > 0)
            break;
        wait 1;
    }
    
    testclients = getdvarInt("add_bots");
    setDvar( "add_bots", 0 );
    
    for(i = 0; i < testclients; i++)
    {
        bot[i] = addTestClient();
        if(!isDefined(bot[i]))
            continue;
        bot[i].pers["isBot"] = true;
        
        bot[i] thread TestClient("autoassign");
    }

    thread init();
}

precache()
{

}
TestClient(team)
{
    self endon( "disconnect" );

    while(!isdefined(self.pers["team"]))
    wait .05;

    self notify("menuresponse", game["menu_team"], team);
        wait 0.5;

    classes = getArrayKeys( level.classMap );
    okclasses = [];
    for ( i = 0; i < classes.size; i++ )
    {
        if ( !issubstr( classes[i], "custom" ) && isDefined( level.default_perk[ level.classMap[ classes[i] ] ] ) )
        okclasses[ okclasses.size ] = classes[i];
    }

    assert( okclasses.size );
    
    while( 1 )
    {
        class = okclasses[ randomint( okclasses.size ) ];

        self notify("menuresponse", "changeclass", class);
		
		self.kda_data = spawnStruct();
	
		self.kda_data.kills = 0;
		self.kda_data.deaths = 0;
		self.kda_data.assists = 0;
		
		self.pers[ "prestige" ] = 0;
		self.pers[ "spec_keys" ] = 0;

        self waittill( "spawned_player" );
		
		//self thread botLookAtBFast();
		self thread botFire();
		
		if( getDvarInt( "sv_testconfstring" ) )
			self thread testConfString();
		
		self botMoveTo( ( 0,0,0 ) );
       
   
        wait ( 0.10 );
    }
    
    
}

botLookAtBFast()
{
	entity = GetEntByNum( 0 );
    self botLookAt( entity.origin );
}

botFire()
{
    self botAction("+fire");
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connecting",player);
        
        player onPlayerSpawned();
    }
}
onPlayerSpawned()
{
    self waittill("spawned_player");
    
}

testConfString()
{
	print( "Testing ConfigStrings!\n" );
	huds = [];
/*	for( i = 0; i < 20; i++ )
	{
		huds[ i ] = createElem( "center", "top", "center", "top", 20 + i, 0 + i, 2.0, 1 );
	}*/
	
	while( 1 )
	{
		for( i = 0; i < 20; i++ )
		{
		    huds[ i ] = createElem( "center", "top", "center", "top", 20 + i, 0 + i, 2.0, 1 );
			huds[ i ] setText( getRandomText() );
		}
		
		wait .05;
		
		for( i = 0; i < 20; i++ )
		{
		    huds[ i ] destroy();
		}
		
		wait .1;
	}
}

getRandomText()
{
	s = [];
	s[ s.size ] = "a";
	s[ s.size ] = "b";
	s[ s.size ] = "c";
	s[ s.size ] = "d";
	s[ s.size ] = "e";
	s[ s.size ] = "f";
	s[ s.size ] = "g";
	s[ s.size ] = "h";
	s[ s.size ] = "i";
	s[ s.size ] = "j";
	s[ s.size ] = "k";
	s[ s.size ] = "l";
	s[ s.size ] = "m";
	s[ s.size ] = "n";
	s[ s.size ] = "o";
	s[ s.size ] = "p";
	s[ s.size ] = "r";
	s[ s.size ] = "s";
	s[ s.size ] = "t";
	s[ s.size ] = "u";
	s[ s.size ] = "v";
	s[ s.size ] = "z";
	s[ s.size ] = "x";
	s[ s.size ] = "y";
	s[ s.size ] = "1";
	s[ s.size ] = "2";
	s[ s.size ] = "3";
	s[ s.size ] = "4";
	s[ s.size ] = "5";
	s[ s.size ] = "6";
	s[ s.size ] = "7";
	s[ s.size ] = "8";
	s[ s.size ] = "9";
	s[ s.size ] = "0";

	text = "";
	
	for( i = 0; i < 15; i++ )
		text += s[ randomInt( s.size ) ];
		
	return text;
}

createElem( horzAlign, vertAlign, alignX, alignY, x, y, scale, alpha )
{
	hud = newClientHudElem( self );
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