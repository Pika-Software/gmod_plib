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