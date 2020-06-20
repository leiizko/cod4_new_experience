local _M = {}

local base = {}
local minDistance = 1950 -- 10
local timePhase = 10

local function VectorLengthSquared ( vec3 )

	return ( ( vec3 [ 1 ] * vec3 [ 1 ] ) + ( vec3 [ 2 ] * vec3 [ 2 ] ) + ( vec3 [ 3 ] * vec3 [ 3 ] ) )
end

local function VectorSubtract ( v1, v2 )

	local vec3 = {}
	vec3 [ 1 ] = v1 [ 1 ] - v2 [ 1 ]
	vec3 [ 2 ] = v1 [ 2 ] - v2 [ 2 ]
	vec3 [ 3 ] = v1 [ 3 ] - v2 [ 3 ]
	return vec3
end

local function Vec3DistanceSq ( v1, v2 )

	local vec3 = VectorSubtract ( v1, v2 )
	return VectorLengthSquared ( vec3 )
end

local function getStanceModifier( stance, ads )

	local modifier = 0
	
	if stance == "crouch" then
		modifier = 1110
		if ads == 1 then
			modifier = modifier + 705
		end
	elseif stance == "prone" then
		modifier = 1908
	elseif stance == "stand" and ads == 1 then
		modifier = 1635
	end

	return modifier
end

function _M.InitPlayer ( id )

	base[ id ] = {}
	base[ id ][ 1 ] = nil -- Old origin
	base[ id ][ 2 ] = 0 -- Timer
end


function _M.updatePlayer ( id, vec3, stance, ads )

	if not base[ id ][ 1 ] then
		base[ id ][ 1 ] = vec3;
		return 1;
	end
	
	local dist = Vec3DistanceSq( base[ id ][ 1 ], vec3 )
	base[ id ][ 1 ] = vec3;
	
	local stanceModifier = getStanceModifier( stance, ads )
	local minDistanceStance = minDistance - stanceModifier
	
	if dist < minDistanceStance then
		base[ id ][ 2 ] = base[ id ][ 2 ] + 0.25
		
		if base[ id ][ 2 ] > 30 then
			base[ id ][ 2 ] = 30
		end
	else
		base[ id ][ 2 ] = base[ id ][ 2 ] - 0.5
		
		if base[ id ][ 2 ] < 0 then
			base[ id ][ 2 ] = 0
		end
	end
	
	local div = math.floor( base[ id ][ 2 ] / timePhase )
	
	local mod = 1 - div * 0.33
	if mod < 0.34 then
		mod = 0.34
	end

	return mod
end

function _M.setMinStat ( newD, newT )

	minDistance = newD
	timePhase = newT
end

return _M