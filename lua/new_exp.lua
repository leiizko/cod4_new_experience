local _M_HARDPOINTS = require( "main_shared/lua/new_exp_hardpoints" )
local _M_RANK = require( "main_shared/lua/new_exp_rank" )
local _M_ANTICAMP = require( "main_shared/lua/new_exp_anticamp" )
local _M_LOCALIZATION = require( "main_shared/lua/new_exp_localization" )
local _M_DAMAGE = require( "main_shared/lua/new_exp_damage" )

-- Localization functions
Plugin_ScrAddFunction( "lua_getLocString" )
Plugin_ScrAddFunction( "lua_listLanguages" )
Plugin_ScrAddFunction( "lua_languageExists" )
-- Rank functions
Plugin_ScrAddFunction( "lua_getRankInfo" ) 
Plugin_ScrAddFunction( "lua_isRankDefined" )
-- Anti camp functions
Plugin_ScrAddFunction( "lua_antiCamp_initPlayer" )
Plugin_ScrAddFunction( "lua_antiCamp_setMinStats" )
Plugin_ScrAddFunction( "lua_antiCamp_updatePlayer" )
-- General hardpoint functions
Plugin_ScrAddFunction( "lua_registerHardpointIndex" )
Plugin_ScrAddFunction( "lua_getHardpointIndex" )
-- Care package functions 
Plugin_ScrAddFunction( "lua_addHardpoint" )
Plugin_ScrAddFunction( "lua_getHardpoint" )
-- Weapon damage functions
Plugin_ScrAddFunction( "lua_weaponDamage" )
-- Utility functions 
Plugin_AddCommand( "lua_reloadWeaponData", 0 )
Plugin_AddCommand( "lua_reloadLocData", 0 )

----------------------------------------------------------
--                Localization functions                --
----------------------------------------------------------

function lua_getLocString ()

	local lang = Plugin_Scr_GetString( 0 )
	local ref = Plugin_Scr_GetString( 1 )
	
	local ret = _M_LOCALIZATION.getLocString( lang, ref )

	Plugin_Scr_AddString( ret )
end

function lua_listLanguages ()

	Plugin_Scr_MakeArray()
	
	local size = #_M_LOCALIZATION.keys
	for i = 1, size, 1 do
		Plugin_Scr_AddString( _M_LOCALIZATION.keys[ i ] )
		Plugin_Scr_AddArray()
	end
end

function lua_languageExists ()

	local lang = Plugin_Scr_GetString( 0 )
	
	local ret = _M_LOCALIZATION.langExists( lang )

	Plugin_Scr_AddInt( ret )
end

--------------------------------------------------
--                Rank functions                --
--------------------------------------------------

function lua_getRankInfo ()

	local i = Plugin_Scr_GetInt( 0 )
	local j = Plugin_Scr_GetInt( 1 )
	
	local result = _M_RANK.getRankElem( i, j )
	
	Plugin_Scr_AddString( result )
end

function lua_isRankDefined ()

	local i = Plugin_Scr_GetInt( 0 )
	
	local result = _M_RANK.isDefined( i )
	
	Plugin_Scr_AddInt( result )
end

-------------------------------------------------------
--                Anti Camp functions                --
-------------------------------------------------------

function lua_antiCamp_initPlayer ()

	local id = Plugin_Scr_GetInt( 0 )
	
	_M_ANTICAMP.InitPlayer( id )
end

function lua_antiCamp_setMinStats ()

	local dist = Plugin_Scr_GetInt( 0 )
	local timep = Plugin_Scr_GetFloat( 1 )
	
	_M_ANTICAMP.setMinStat( dist, timep )
end

function lua_antiCamp_updatePlayer ()

	local id = Plugin_Scr_GetInt( 0 )
	local vec3 = Plugin_Scr_GetVector( 1 )
	local stance = Plugin_Scr_GetString( 2 )
	local ads = Plugin_Scr_GetFloat( 3 )
	
	if ads < 1 then
		ads = 0
	end

	local mod = _M_ANTICAMP.updatePlayer( id, vec3, stance, ads )

	Plugin_Scr_AddFloat( mod )
end

--------------------------------------------------------------
--               General hardpoint functions                --
--------------------------------------------------------------

function lua_registerHardpointIndex ()

	local name = Plugin_Scr_GetString( 0 )
	local index = Plugin_Scr_GetInt( 1 )
	
	_M_HARDPOINTS.registerHardpoint( name, index )
end

function lua_getHardpointIndex ()

	local name = Plugin_Scr_GetString( 0 )
	local index = _M_HARDPOINTS.getHardpointIndex( name )
	Plugin_Scr_AddInt( index )
end

----------------------------------------------------------
--                Care package functions                --
----------------------------------------------------------

function lua_addHardpoint ()

	local name = Plugin_Scr_GetString( 0 )
	local percentage = Plugin_Scr_GetInt( 1 )
	
	_M_HARDPOINTS.addElem( name, percentage )
end

function lua_getHardpoint ()

	local item = _M_HARDPOINTS.getElem()
	Plugin_Scr_AddString( item )
end

-----------------------------------------------------------
--                Weapon damage functions                --
-----------------------------------------------------------

function lua_weaponDamage ()

	local weap = Plugin_Scr_GetString( 0 )
	local dmg = Plugin_Scr_GetInt( 1 )
	local shitloc = Plugin_Scr_GetString( 2 )
	local dist = Plugin_Scr_GetInt( 3 )
	
	local ret = _M_DAMAGE.weaponDamage( weap, dmg, shitloc, dist )

	Plugin_Scr_AddInt( ret )
end

-----------------------------------------------------
--                Utility functions                --
-----------------------------------------------------

function lua_reloadWeaponData ()

	package.loaded[ "main_shared/lua/new_exp_damage" ] = nil
	_M_DAMAGE = nil
	_M_DAMAGE = require( "main_shared/lua/new_exp_damage" )
end

function lua_reloadLocData ()

	local count = Plugin_Cmd_Argc()
	if count < 1 then
		Plugin_Printf( "lua_reloadLocData(): Missing param\n" )
		return
	end
	
	local target = Plugin_Cmd_Argv( 1 )
	
	_M_LOCALIZATION.reload( target )
end