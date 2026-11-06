init()
{
	level.hudTheme = [];
	level.hudTheme[ "panel" ] = ( 0.05, 0.05, 0.07 );
	level.hudTheme[ "panelAlpha" ] = 0.72;
	level.hudTheme[ "accent" ] = ( 1.0, 0.55, 0.12 );
	level.hudTheme[ "primary" ] = ( 1, 1, 1 );
	level.hudTheme[ "muted" ] = ( 0.7, 0.7, 0.7 );
	level.hudTheme[ "afford" ] = ( 0.45, 0.85, 0.45 );
	level.hudTheme[ "deny" ] = ( 0.85, 0.25, 0.25 );
	level.hudTheme[ "highlight" ] = ( 1.0, 0.55, 0.12 );
}

createPanel( width, height, x, y, horzAlign, vertAlign, alignX, alignY )
{
	group = [];

	bg = newClientHudElem( self );
	bg.archived = false;
	bg.sort = 0;
	bg.alignX = alignX;
	bg.alignY = alignY;
	bg.horzAlign = horzAlign;
	bg.vertAlign = vertAlign;
	bg.x = x;
	bg.y = y;
	bg.color = level.hudTheme[ "panel" ];
	bg.alpha = level.hudTheme[ "panelAlpha" ];
	bg setShader( "white", width, height );
	group[ 0 ] = bg;

	accent = newClientHudElem( self );
	accent.archived = false;
	accent.sort = 1;
	accent.alignX = alignX;
	accent.alignY = alignY;
	accent.horzAlign = horzAlign;
	accent.vertAlign = vertAlign;
	accent.x = x;
	accent.y = y;
	accent.color = level.hudTheme[ "accent" ];
	accent.alpha = 1;
	if( alignX == "left" )
		accent setShader( "white", 2, height );
	else
		accent setShader( "white", width, 2 );
	group[ 1 ] = accent;

	return group;
}

createLabel( text, font, scale, x, y, horzAlign, vertAlign, alignX, alignY )
{
	elem = newClientHudElem( self );
	elem.archived = false;
	elem.sort = 2;
	elem.alignX = alignX;
	elem.alignY = alignY;
	elem.horzAlign = horzAlign;
	elem.vertAlign = vertAlign;
	elem.x = x;
	elem.y = y;
	elem.font = font;
	elem.fontscale = scale;
	elem.color = level.hudTheme[ "primary" ];
	elem.alpha = 1;
	if( isDefined( text ) )
		elem setText( text );

	return elem;
}

createBar( width, height, x, y, horzAlign, vertAlign, alignX, alignY )
{
	elem = newClientHudElem( self );
	elem.archived = false;
	elem.sort = 2;
	elem.alignX = alignX;
	elem.alignY = alignY;
	elem.horzAlign = horzAlign;
	elem.vertAlign = vertAlign;
	elem.x = x;
	elem.y = y;
	elem.color = level.hudTheme[ "accent" ];
	elem.alpha = 0.9;
	elem setShader( "white", width, height );

	return elem;
}

destroyHudGroup( group )
{
	if( !isDefined( group ) )
		return;

	if( isArray( group ) )
	{
		for( i = 0; i < group.size; i++ )
		{
			if( isDefined( group[ i ] ) )
				group[ i ] destroy();
		}
	}
}
