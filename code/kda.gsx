init()
{
	thread code\events::addConnectEvent( ::onConnect );
}

onConnect()
{
	self endon( "disconnect" );
	
	/*
	waittillframeend;
	
	kills = "" + self getStat( 3170 );
	if( isSubStr( getSubStr( kills, 0, 3 ), "-73" ) )
		kills = int( getSubStr( kills, 3 ) );
	else
	{
		kills = 0;
		self setStat( 3170, -730 );
	}
	
	waittillframeend;
	
	deaths = "" + self getStat( 3171 );
	if( isSubStr( getSubStr( deaths, 0, 3 ), "-47" ) )
		deaths = int( getSubStr( deaths, 3 ) );
	else
	{
		deaths = 0;
		self setStat( 3171, -470 );
	}
	
	waittillframeend;
	
	assists = "" + self getStat( 3172 );
	if( isSubStr( getSubStr( assists, 0, 3 ), "-26" ) )
		assists = int( getSubStr( assists, 3 ) );
	else
	{
		assists = 0;
		self setStat( 3172, -260 );
	}
	
	self.kda_data.kills = kills;
	self.kda_data.deaths = deaths;
	self.kda_data.assists = assists;
	*/
}

incKDA( s, i )
{
	switch( s )
	{
		case "kills":
			self.kda_data.kills += i;
			/*
			newStat = int( "-73" + self.kda_data.kills );
			self setStat( 3170, newStat );
			*/
			break;
			
		case "deaths":
			self.kda_data.deaths += i;
			/*
			newStat = int( "-47" + self.kda_data.deaths );
			self setStat( 3171, newStat );
			*/
			break;
			
		case "assists":
			self.kda_data.assists += i;
			/*
			newStat = int( "-26" + self.kda_data.assists );
			self setStat( 3172, newStat );
			*/
			break;
	
		default:
			break;
	}
}