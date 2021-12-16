local hook_Run = hook.Run
local team_Valid = team.Valid
local team_GetColor = team.GetColor

--[[-------------------------------------------------------------------------
	Team System Extensions
---------------------------------------------------------------------------]]

local TEAM_SPECTATOR = TEAM_SPECTATOR
local TEAM_UNASSIGNED = TEAM_UNASSIGNED

local PLAYER = FindMetaTable("Player")
local ENTITY = FindMetaTable("Entity")

local team_SetUp = PLib:Precache_G("team.SetUp", team.SetUp)

function team.SetUp(...)
	if hook_Run("PreTeamCreating", ...) then
		return
	end

	team_SetUp(...)

	hook_Run("OnTeamCreated", ...)
end

--[[-------------------------------------------------------------------------
	Player Extensions
---------------------------------------------------------------------------]]

function PLAYER:IsConnecting()
	return self:Team() == TEAM_CONNECTING
end

--[[-------------------------------------------------------------------------
	Entity Extensions
---------------------------------------------------------------------------]]

if SERVER then
	function ENTITY:SetTeam( teamID )
		self:SetNWInt("PLib.Team", team_Valid( teamID ) and teamID or TEAM_UNASSIGNED)
	end
end

function ENTITY:Team()
	return self:GetNWInt("PLib.Team", TEAM_UNASSIGNED)
end

--[[-------------------------------------------------------------------------
	Global Extensions
---------------------------------------------------------------------------]]

function ENTITY:IsSpectator()
	return self:Team() == TEAM_CONNECTING
end

function ENTITY:IsUnassigned()
	return self:Team() == TEAM_UNASSIGNED
end

function ENTITY:TeamColor()
	return team_GetColor(self:Team())
end