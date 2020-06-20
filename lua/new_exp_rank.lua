local _M = {}
local rankTable = require( "main_shared/lua/ranktable/ranktable" )

function _M.getRankElem( i, j )

	return rankTable[ i ][ j ]
end

function _M.isDefined( i )

	local idx = #rankTable
	
	if i < idx then
		return 1
	end
	
	return 0
end

return _M