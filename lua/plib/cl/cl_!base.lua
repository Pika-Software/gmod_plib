hook.Add("RenderScene", "PLib:PlayerInitialized", function()
    hook.Remove("RenderScene", "PLib:PlayerInitialized")
    local ply = LocalPlayer()
	ply["Initialized"] = true
	ply["LastActivity"] = CurTime() + 300
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

if (PLib["_G"]["spawnmenu.AddToolMenuOption"] == nil) then
    PLib["_G"]["spawnmenu.AddToolMenuOption"] = spawnmenu.AddToolMenuOption
    local original = PLib["_G"]["spawnmenu.AddToolMenuOption"]
    function spawnmenu.AddToolMenuOption(tab, ...)
        return original(((tab == "Options") and "Utilities" or tab), ...)
    end
end

function PLib:SpawnMenuReload()
	if not GAMEMODE["IsSandboxDerived"] then return end
	if not hook.Run("SpawnMenuEnabled") then return end

	-- If we have an old spawn menu remove it.
	if IsValid(g_SpawnMenu) then
		g_SpawnMenu:Remove()
		g_SpawnMenu = nil
	end

	hook.Run("PreReloadToolsMenu")

	-- Start Fresh
	spawnmenu.ClearToolMenus()

	-- Add defaults for the gamemode. In sandbox these defaults
	-- are the Main/Postprocessing/Options tabs.
	-- They're added first in sandbox so they're always first
	hook.Run("AddGamemodeToolMenuTabs")

	-- Use this hook to add your custom tools
	-- This ensures that the default tabs are always
	-- first.
	hook.Run("AddToolMenuTabs")

	-- Use this hook to add your custom tools
	-- We add the gamemode tool menu categories first
	-- to ensure they're always at the top.
	hook.Run("AddGamemodeToolMenuCategories")
	hook.Run("AddToolMenuCategories")

	-- Add the tabs to the tool menu before trying
	-- to populate them with tools.
	hook.Run("PopulateToolMenu")

	g_SpawnMenu = vgui.Create("SpawnMenu")

	if IsValid(g_SpawnMenu) then
		g_SpawnMenu:SetVisible( false )
		hook.Run("SpawnMenuCreated", g_SpawnMenu)
	end

	CreateContextMenu()

	hook.Run("PostReloadToolsMenu")
end