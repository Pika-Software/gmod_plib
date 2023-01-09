local string = string
local file = file
local util = util

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

function util.Explosion( pos, radius, damage )
	local dmg = DamageInfo()
	dmg:SetDamageType( DMG_BLAST )

	if isnumber( damage ) then
		dmg:SetDamage( damage )
	else
		dmg:SetDamage( 250 )
	end

	local fx = EffectData()
	fx:SetNormal( Vector( 0, 0, 1 ) )
	fx:SetRadius( radius )
	fx:SetOrigin( pos )

	timer.Simple(0, function()
		util.Effect( 'Explosion', fx )
		util.Effect( 'HelicopterMegaBomb', fx )
		util.BlastDamageInfo( dmg, pos, radius )
	end)

	return dmg, fx
end