function PLib:LocalPlayerShadow(ply, bool)
	RunConsoleCommand("cl_drawownshadow", (bool == true) and 1 or 0)

	if (bool == true) then
		if not ply:HasAchievement("plib.i_see_my_shadow") then
			hook.Add("InputMouseApply", "PLib:WaitingPlyLookDown", function(cmd, x, y, ang)
				if (ang[1] > 70) then
					hook.Remove("InputMouseApply", "PLib:WaitingPlyLookDown")
					ply:GiveAchievement("plib.i_see_my_shadow")
				end
			end)
		else
			hook.Remove("InputMouseApply", "PLib:WaitingPlyLookDown")
		end
	else
		hook.Remove("InputMouseApply", "PLib:WaitingPlyLookDown")
	end
end

local player_shadow = CreateClientConVar("plib_player_shadow", "1", true, true, "PLib: Enables rendere self shadow.", 0, 1)
cvars.AddChangeCallback("plib_player_shadow", function(name, old, new)
	PLib:LocalPlayerShadow(LocalPlayer(), tobool(new))
end, "PLib")

hook.Add("PLib:PlayerInitialized", "PLib:BetterPlayer", function(ply)
	RunConsoleCommand("stopsound")
	PLib:LocalPlayerShadow(ply, player_shadow:GetBool())
	ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 3, 1)
end)

hook.Add("PostPlayerDraw", "PLib:GoodGuysCheck", function(ply)
	if (ply["PLib_IsGoodGuyChecked"] == nil) then
		if ply:IsGoodGuy() then
			LocalPlayer():GiveAchievement("plib.gg_" .. ply:SteamID64())
		end

		ply["PLib_IsGoodGuyChecked"] = true
	end
end)

hook.Add("UpdateAnimation", "PLib:UpdateAnimation", function(ply)
	ply:MouthMoveAnimation()
end)

hook.Add("PlayerFootstep", "PLib:PlayerFootstepsInWater", function(ply, pos, foot, sound, volume, filter)
	local waterLvl = ply:WaterLevel()
	if (waterLvl > 0) then
		if waterLvl == 1 then
			if CLIENT then
				ply:FireBullets({
					Src = Vector(pos[1], pos[2], ply:EyePos()[3]),
					Dir = Vector(0, 0, -1),
					Damage = 0,
					Tracer = 0,
				})
			end

			return true
		end
	elseif ply:Crouching() then
		return true
	end
end)

-- hook.Add( "PostDrawTranslucentRenderables", "BadPingDisplayDrawIcons", function( bDepth, bSkybox )
--     -- If we are drawing in the skybox, bail
--     if ( bSkybox ) then return end

--     for i, ply in ipairs(BadPing.PlayersTable) do
--         if !IsValid( ply ) or ( ply == LocalPlayer() and !ply:ShouldDrawLocalPlayer() ) then return end

--         local pos = ply:GetPos() + Vector(0,0,80) + Vector(0,0, math.abs(BadPing.SpriteFloat) )
--         local dist = EyePos():DistToSqr( pos )
--         local fade = 220
--         local maxdist = GetConVar( "badping_cl_icon_distance" ):GetFloat()

--         if not ( dist >= (maxdist^2) ) then --( dist >= (BadPing.IconFadeMin + 255*BadPing.IconFadeLength)^2 )
--             --print( "rendering" )
--             --if dist >= BadPing.IconFadeMin^2 then
--                 --dist = math.sqrt( dist )
--                 --fade = 255 - ( ( dist - BadPing.IconFadeMin ) / BadPing.IconFadeLength )
--                 --print( fade )
--             --end

--             --[[cam.Start3D2D( pos, Angle( 0,0,90 ), 1 )
--                 surface.SetMaterial( BadPing.SpriteMat )
--                 surface.DrawTexturedRect( 0,0,256,256 )
--             cam.End3D2D()]]
--             render.SetMaterial( BadPing.SpriteMat )
--             render.DrawSprite( pos, 18, 18, Color( 255, 255, 255, fade ) )
--         end
--     end

-- end )

local vgui_Create = vgui.Create
function PLib.AchievementVGUI(id)
	local achi = vgui_Create("plib_achievement")
	achi:SetAchievement(id)

	return IsValid(achi)
end

local PLAYER = FindMetaTable("Player")

local achievement_col = PLib["_C"]["achievement"]
local gmod_white = PLib["_C"]["gmod_white"]

function PLAYER:GotAchievement(id)
	chat.AddText(self, gmod_white, PLib:Translate("plib.earned_achievement"), achievement_col, PLib:GetAchievementName(id))
end

function PLAYER:PNotify(title, text, style, lifetime, image, animated)
	PLib:AddNotify(title, text, style or "default", lifetime, image, animated)
end