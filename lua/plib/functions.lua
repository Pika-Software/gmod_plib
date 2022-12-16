local string_format = string.format
local string_sub = string.sub
local tonumber = tonumber

-- Argument checker by Retr0 & PrikolMen:-b (From atmoshpere with love <3)
do

	local debug_getinfo = debug.getinfo
	local string_lower = string.lower
	local error = error
	local type = type

	function ArgAssert( value, argNum, argType, errorlevel )
		local valueType = string_lower( type( value ) )
		if (valueType == argType) then return end

		local dinfo = debug_getinfo( 2, 'n' )
		local fname = dinfo and dinfo.name or 'func'
		error( string_format( 'bad argument #%d to \'%s\' (%s expected, got %s)', argNum, fname, argType, valueType ), errorlevel or 3)
	end

end

-- Yesss, i created this :.
function isnil( any )
	return any == nil
end

-- Path Builder
do
	local table_concat = table.concat
	function file.Path( ... )
		return table_concat( {...}, '/' )
	end
end

--- .NET like string formatting
-- @see https://wiki.facepunch.com/gmod/Patterns
do
	local string_gsub = string.gsub
	function string.NetFormat( fmt, ... )
		local args = { ... }
		return string_gsub(fmt, '{(%d+)}', function( i )
			return tostring( args[ tonumber(i) + 1 ] )
		end)
	end
end

-- Version formatter
function string.Version( number )
	local version = string_format( '%06d', number )
	return string_format( '%d.%d.%d', tonumber( string_sub( version, 0, 2 ) ), tonumber( string_sub( version, 3, 4 ) ), tonumber( string_sub( version, 5 ) ) )
end

-- ScreenResolutionChanged
hook.Add('OnScreenSizeChanged', 'ScreenResolutionChanged', function( oldWidth, oldHeight )
	hook.Run( 'ScreenResolutionChanged', ScrW(), ScrH(), oldWidth, oldHeight )
end)

-- AddCSLuaFolder
do

	local AddCSLuaFile = AddCSLuaFile
	local file_Find = file.Find
	local file_Path = file.Path
	local ipairs = ipairs

	if (SERVER) then
		function AddCSLuaFolder( folder )
			local files, folders = file_Find( file_Path( folder, '*' ), 'LUA' )
			for _, fl in ipairs( files ) do
				AddCSLuaFile( file_Path( folder, fl ) )
			end

			for _, fol in ipairs( folders ) do
				AddCSLuaFolder( file_Path( folder, fol ) )
			end
		end
	end

	if (CLIENT) then
		function AddCSLuaFolder()
		end
	end

end