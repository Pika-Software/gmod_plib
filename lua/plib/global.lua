local tonumber = tonumber
local string = string
local file = file
local hook = hook

-- Argument checker by Retr0 & PrikolMen:-b (From atmoshpere with love <3)
do

	local debug_getinfo = debug.getinfo
	local error = error
	local type = type

	function ArgAssert( value, argNum, argType, errorlevel )
		local valueType = string.lower( type( value ) )
		if (valueType == argType) then return end

		local dinfo = debug_getinfo( 2, 'n' )
		local fname = dinfo and dinfo.name or 'func'
		error( string.format( 'bad argument #%d to \'%s\' (%s expected, got %s)', argNum, fname, argType, valueType ), errorlevel or 3)
	end

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
	local version = string.format( '%06d', number )
	return string.format( '%d.%d.%d', tonumber( string.sub( version, 0, 2 ) ), tonumber( string.sub( version, 3, 4 ) ), tonumber( string.sub( version, 5 ) ) )
end

-- GM:ScreenResolutionChanged( w, h, oldW, oldH )
hook.Add('OnScreenSizeChanged', 'PLib - Global', function( oldWidth, oldHeight )
	hook.Run( 'ScreenResolutionChanged', ScrW(), ScrH(), oldWidth, oldHeight )
end)

if (CLIENT) then

	-- GM:SystemFocusChanged( isInFocus )
	do

		local system_HasFocus = system.HasFocus
		local isInFocus = system_HasFocus()

		hook.Add('Think', 'PLib - System focus is changed', function()
			if (isInFocus == system_HasFocus()) then return end
			isInFocus = system_HasFocus()
			hook.Run( 'SystemFocusChanged', isInFocus )
		end)

	end

	local vmin, vmax = 0, 0
	local vh, vw = 0, 0

	local function updateNumbers( w, h )
		vh = h / 100
		vw = w / 100

		if (vh > vw) then
			vmin = vw
			vmax = vh
		else
			vmin = vh
			vmax = vw
		end
	end

	hook.Add('ScreenResolutionChanged', 'PLib - Global', updateNumbers)
	updateNumbers( ScrW(), ScrH() )

	local function getPercent( number, percent )
		if (percent) then
			return number * percent
		end

		return number
	end

	-- vh, vw, vmin, vmax like in CSS
	function ScreenPercentHeight( percent )
		return getPercent( vh, percent )
	end

	function ScreenPercentWidth( percent )
		return getPercent( vw, percent )
	end

	function ScreenPercentMin( percent )
		return getPercent( vmin, percent )
	end

	function ScreenPercentMax( percent )
		return getPercent( vmax, percent )
	end

end

do

	local ipairs = ipairs

	-- AddCSLuaFolder
	do

		local AddCSLuaFile = AddCSLuaFile

		if (SERVER) then
			function AddCSLuaFolder( folder )
				local files, folders = file.Find( file.Path( folder, '*' ), 'LUA' )
				for _, fl in ipairs( files ) do
					AddCSLuaFile( file.Path( folder, fl ) )
				end

				for _, fol in ipairs( folders ) do
					AddCSLuaFolder( file.Path( folder, fol ) )
				end
			end
		end

		if (CLIENT) then
			function AddCSLuaFolder()
			end
		end

	end

	-- includeFolder
	function includeFolder( filePath )
		local files, folders = file.Find( file.Path( filePath, '*' ), 'LUA' )
		for _, fl in ipairs( files ) do
			include( file.Path( filePath, fl ) )
		end

		for _, fol in ipairs( folders ) do
			includeFolder( file.Path( filePath, fol ) )
		end
	end

end
