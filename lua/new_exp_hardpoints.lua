local _M = {}
local percent_pool = {}
local elem_pool = {}
local hardpoints = {}

local function initPool()

	for i = 1, 100, 1
	do
		percent_pool[ i ] = i
	end
end

local function pop_array( elem )

	for i, num in ipairs ( percent_pool ) do
		if num == elem then 
			percent_pool [ i ] = percent_pool [ #percent_pool ]
			percent_pool [ #percent_pool ] = nil
			break
		end
	end	
end

local function is_In_Array( name )

	for i, streak in ipairs ( elem_pool ) do
		if streak == name then 
			return true
		end
	end
	
	return false
end

function _M.addElem( name, percentage )

	if not is_In_Array( name ) then
		local temp = {}
		local pp = percentage
		
		temp[ 1 ] = name
		
		if #elem_pool > 0 then
			pp = elem_pool[ #elem_pool ][ 2 ] + percentage
		end
		
		temp[ 2 ] = pp
		
		table.insert( elem_pool, temp )
	end
end

function _M.getElem()

	if #percent_pool == 0 then
		initPool()
	end
	
	math.randomseed( os.time() )
	local elem = math.random( 1, #percent_pool )
	local pp = percent_pool[ elem ]
	
	local i = #elem_pool
	while 1
	do
		if pp <= elem_pool[ i ][ 2 ] then
			local low = 0
			if i > 1 then
				low = elem_pool[ ( i - 1 ) ][ 2 ]
			end
			if pp > low then
				break
			end
		end

		i = i - 1
	end
	
	pop_array( pp )
	
	return elem_pool[ i ][ 1 ]
end

function _M.registerHardpoint( name, index )

	if not hardpoints[ name ] then
		hardpoints[ name ] = index
	end
end

function _M.getHardpointIndex( name )

	if hardpoints[ name ] then
		return hardpoints[ name ]
	else
		return -1;
	end
end

return _M