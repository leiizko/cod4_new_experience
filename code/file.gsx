// Write a single string or an array of strings to file,
// if file already exists it will overwrite it.
// Returns FALSE on failure, TRUE on success
// File will close after writing.
writeToFile( path, w )
{
	checkQueue();
	
	file = FS_FOpen( path, "write" );
	
	if( !isDefined( file ) )
		return false;
	
	level.openFiles[ file ] = true;
		
	if( isArray( w ) )
		writeArray( file, w );
	else
		FS_WriteLine( file, w );
	
	FS_FClose( file );
	
	level.openFiles[ file ] = undefined;
	
	return true;
}

// Read all lines in a file and return them as array of strings.
// If reading failes/file doesn't exist it returns boolean FALSE.
// File will close after reading.
readFile( path )
{
	checkQueue();
	
	if( !FS_TestFile( path ) )
		return false;

	file = FS_FOpen( path, "read" );
	
	if( !isDefined( file ) )
		return false;
		
	level.openFiles[ file ] = true;
		
	lines = readAll( file );
	
	FS_FClose( file );
	
	level.openFiles[ file ] = undefined;
	
	if( !isArray( lines ) || lines.size < 1 )
		return false;
	
	return lines;
}

writeArray( handle, array )
{
	for( i = 0; i < array.size; i++ )
		FS_WriteLine( handle, array[ i ] );
}

readAll( handle )
{
	array = [];
	for( ;; )
	{
		line = FS_ReadLine( handle );
		if( isDefined( line ) )
			array[ array.size ] = line;
		else
			break;
	}
	
	return array;
}

checkQueue()
{
	while( level.openFiles.size > 8 )
		wait .05;
}