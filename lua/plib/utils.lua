local util = util

do

	local string = string
	local file = file

	function util.IsBSP( binnary )
		return string.lower( string.sub( binnary, 1, 4 ) ) == 'vbsp'
	end

	function file.IsMap( fileName, gamePath )
		local fileClass = file.Open( fileName, 'rb', gamePath )
		if (fileClass) then
			local binnary = fileClass:Read( 4 )
			fileClass:Close()
			return util.IsBSP( binnary )
		end

		return false
	end

	function util.IsGMA( binnary )
		return string.lower( string.sub( binnary, 1, 4 ) ) == 'gmad'
	end

	function file.IsGMA( fileName, gamePath )
		local fileClass = file.Open( fileName, 'rb', gamePath )
		if (fileClass) then
			local binnary = fileClass:Read( 4 )
			fileClass:Close()
			return util.IsGMA( binnary )
		end

		return false
	end

	function util.IsPNG( binnary )
		return string.lower( string.sub( binnary, 2, 4 ) ) == 'png'
	end

	function file.IsPNG( fileName, gamePath )
		local fileClass = file.Open( fileName, 'rb', gamePath )
		if (fileClass) then
			local binnary = fileClass:Read( 4 )
			fileClass:Close()
			return util.IsPNG( binnary )
		end

		return false
	end

	function util.IsJPEG( binnary )
		local str = string.lower( string.sub( binnary, 7, 10 ) )
		return str == 'jfif' or str == 'exif'
	end

	function file.IsJPEG( fileName, gamePath )
		local fileClass = file.Open( fileName, 'rb', gamePath )
		if (fileClass) then
			local binnary = fileClass:Read( 10 )
			fileClass:Close()
			return util.IsJPEG( binnary )
		end

		return false
	end

end

do

	local isfunction = isfunction

	do

		local isnumber = isnumber

		do

			local isstring = isstring
			local isbool = isbool
			local NULL = NULL

			function util.IsValidObject( object )
				if (object == nil) then return false end
				if (object == NULL) then return false end
				if isbool( object ) then return false end

				if isnumber( object ) then return false end
				if isstring( object ) then return false end
				if isfunction( object ) then return false end

				local isValid = object.IsValid
				if isfunction( isValid ) then
					return isValid( object )
				end

				return false
			end

		end


		if (SERVER) then

			local util_BlastDamageInfo = util.BlastDamageInfo
			local util_Effect = util.Effect
			local EffectData = EffectData
			local DamageInfo = DamageInfo

			local up = Vector( 0, 0, 1 )

			function util.Explosion( pos, radius, damage )
				local dmg = DamageInfo()
				dmg:SetDamageType( DMG_BLAST )

				if isnumber( damage ) then
					dmg:SetDamage( damage )
				else
					dmg:SetDamage( 250 )
				end

				local fx = EffectData()
				fx:SetRadius( radius )
				fx:SetOrigin( pos )
				fx:SetNormal( up )

				util.NextTick(function()
					util_Effect( 'Explosion', fx )
					util_Effect( 'HelicopterMegaBomb', fx )
					util_BlastDamageInfo( dmg, pos, radius )
				end)

				return dmg, fx
			end

		end


	end

	function util.NextTick( any, func, ... )
		if util.IsValidObject( any ) then
			ArgAssert( func, 2, 'function' )
			local args = {...}
			timer.Simple(0, function()
				if IsValid( any ) then
					func( any, unpack( args ) )
				end
			end)

			return true
		elseif isfunction( any ) then
			local args = {...}
			timer.Simple(0, function()
				any( func, unpack( args ) )
			end)

			return true
		end

		return false
	end

end