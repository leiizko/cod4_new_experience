local _M = {}
local openConvs = {}
_M.keys = {}

local locStrings = {
	[ "english" ] 	= require( "main_shared/lua/localizedstrings/english"	 ),
	[ "russian" ] 	= require( "main_shared/lua/localizedstrings/russian"	 ),
	[ "czech" ] 	= require( "main_shared/lua/localizedstrings/czech"		 ),
	[ "italian" ] 	= require( "main_shared/lua/localizedstrings/italian"	 )
}

local function initConv( to )

	if openConvs[ to ] then
		return
	end
	
	openConvs[ to ] = Plugin_iconv_open( to, "UTF-8" )
end

local function doConv( to, text )

	if openConvs[ to ] == nil then
		Plugin_Printf( "****************** Lua Error ******************\n\n" )
		Plugin_Printf( "Conversion to " .. to .. " is not initialized!\n" )
		Plugin_Printf( "****************** Lua Error ******************\n" )
		return text
	end
	
	local ret = Plugin_iconv( openConvs[ to ], text )
	
	return ret
end

local function closeConv( to )

	if openConvs[ to ] then
		Plugin_iconv_close( openConvs[ to ] )
		openConvs[ to ] = nil
	end
end

local function cirilicEncode()

	initConv( "cp1251" )
	
	local array = locStrings[ "russian" ]
	
	for k,v in pairs( array ) do
		locStrings[ "russian" ][ k ] = doConv( "cp1251", locStrings[ "russian" ][ k ] )
	end
	
	closeConv( "cp1251" )
end
cirilicEncode()

local function getArrayKeys( array )

	for k,v in pairs( array ) do
		_M.keys[ #_M.keys + 1 ] = k
	end
end
getArrayKeys( locStrings )

function _M.getLocString( lang, ref )

	if locStrings[ lang ][ ref ] then
		return locStrings[ lang ][ ref ]
	else
		if locStrings[ "english" ][ ref ] then
			return locStrings[ "english" ][ ref ]
		else
			Plugin_Printf( "getLocString: Localized string for reference: " .. ref .. " -not found!\n" )
			return ""
		end
	end		
end

function _M.langExists( lang )

	if locStrings[ lang ] then
		return 1
	else
		return 0
	end
end

function _M.reload( lang )

	if lang == nil then
		Plugin_Printf( "lua_reloadLocData(): Missing param\n" )
		return
	elseif locStrings[ lang ] == nil then
		Plugin_Printf( "lua_reloadLocData(): Language " .. lang .. " does not exist\n" )
		return
	end
	
	target = "main_shared/lua/localizedstrings/" .. lang
	
	package.loaded[ target ] = nil
	locStrings[ lang ] = nil
	locStrings[ lang ] = require( target )
	
	if( lang == "russian" ) then
		cirilicEncode()
	end
end

return _M