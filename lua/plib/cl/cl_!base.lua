cvars_Bool = cvars.Bool
PLib = PLib

PLib["CanDebug"] = {
	["superadmin"] = true,
	["developer"] = true
}

function PLib:DebugAllowed()
    return cvars_Bool"plib_debug_allow" or PLib["CanDebug"][LocalPlayer():GetUserGroup()]
end

hook.Add("RenderScene", "PLib:PlayerInitialized", function()
    hook.Remove("RenderScene", "PLib:PlayerInitialized")
    local ply = LocalPlayer()
	ply["Initialized"] = true
	ply["LastActivity"] = CurTime()
    hook.Run("PLib:PlayerInitialized", ply)
	PLib["Initialized"] = true
end)

-- Extra Chat Hooks
hook.Add("OnPlayerChat", "PLib:OnPlayerChat_Manager", function(...)
	local ret = hook.Run("PreOnPlayerChat", ...)
	if (ret != nil) then return ret end
	ret = hook.Run("PostOnPlayerChat", ...)
	if (ret != nil) then return ret end
end)

hook.Add("PLib:IsSandbox", "ReplaceSandboxSpawnmenuOptions", function()
	PLib:Precache_G("spawnmenu.AddToolMenuOption", spawnmenu.AddToolMenuOption)
	local original = PLib:Get_G("spawnmenu.AddToolMenuOption")
	function spawnmenu.AddToolMenuOption(tab, ...)
		return original(((tab == "Options") and "Utilities" or tab), ...)
	end
end)

hook.Add("OnEntityCreated", "PLib:OnEntityCreated", function( ent )
	timer.Simple(0, function()
		if IsValid(ent) then
			hook.Run("EntityCreated", ent)
		end
	end)
end)

hook.Add("NetworkEntityCreated", "PLib:NetworkEntityCreated", function(ent)
	hook.Run("EntityCreated", ent)
end)