/*
    ____  ____  __  __ 
    |  _ \|  _ \|  \/  |
    | |_) | |_) | |\/| |
    |  __/|  __/| |  | |
    |_|   |_|   |_|  |_|

PrikolMen's Player Manager
*/
if true then return end
local PM = PLib["PM"]
PM.Commands = {}

function PM:Run(ply, cmd, ...)
    return PM.Commands[cmd](ply, ...)
end

function PM:AddCMD(name, callback)
    PM.Commands[name] = callback;
end

-- // PM Commands Start
PM:AddCMD("StopOBSM", function(ply)
    ply:UnSpectate()
end)

PM:AddCMD("Loadout", function(ply)
    hook.Call("PlayerLoadout", GAMEMODE, ply )
end)

PM:AddCMD("ClassSetup", function(ply)
    ply:SetWalkSpeed(BaseWars.Config.WalkSpeed)
	ply:SetRunSpeed(BaseWars.Config.RunSpeed)

	ply:SetCrouchedWalkSpeed(0.3)
	ply:SetDuckSpeed(0.3)
	ply:SetUnDuckSpeed(0.3)
	ply:SetJumpPower(200)
	ply:AllowFlashlight(false)
	ply:ShouldDropWeapon(false)
	ply:SetNoCollideWithTeammates(false)
	ply:SetAvoidPlayers(true)

    ply:SetHull(Vector(-16,-16,0),Vector(16,16,72))
	ply:SetHullDuck(Vector(-16,-16,0),Vector(16,16,55))

    local health = 100
    if ply:HasPMD() then
        health = ply:GetNWInt("ModelHealth") > 0 and ply:GetNWInt("ModelHealth") or 100
    end

    ply:SetMaxHealth(health)
    ply:SetHealth(health)

	ply:SetMaxArmor(100)
	ply:SetArmor(0)
end)

PM:AddCMD("BuildPlayerBody", function(ply)
    if ply:GetNWBool("CustomPM") then
        local model = PF.Model(ply:GetNWString("CustomPM")) or PMD.cfg.default.model
        ply:SetModel(model)
        PMD.RecalcHulls(ply, model)
        PMD.UpdateViewOffsets(ply)
    else
        if ply:GetNWBool("CustomPM") then ply:SetNWBool("CustomPM", false); end
        ply:SetModel(PMD.cfg.default.model)
        PMD.SetupDefaulHull(ply)
        PMD.DefaultHight(ply)
        PMD.UpdateViewOffsets(ply)
    end
    
    ply:SetupHands()
end)

PM:AddCMD("GetHandsModel", function(ply)
    local model, skin, bodygroups = PMD.cfg.default.hands, 0, 0
    if PMD and ply.handsData then
        model = ply.handsData.model
        skin = ply.handsData.skin
        bodygroups = ply.handsData.bodygroups
    end

    return {model, skin, bodygroups}
end)

PM:AddCMD("SetupHandsModel", function(ply, hands)
    if PMD then
        local tbl = PM:Run(ply, "GetHandsModel")
        hands:SetModel(tbl[1])
        hands:SetSkin(tbl[2])
        hands:SetBodyGroups(tbl[3])
    else
        local info = player_manager.RunClass( ply, "GetHandsModel" )
        if ( !info ) then
            local playermodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
            info = player_manager.TranslatePlayerHands( playermodel )
        end

        if ( info ) then
            hands:SetModel( info.model )
            hands:SetSkin( info.skin )
            hands:SetBodyGroups( info.body )
        end
    end
    hands:DrawShadow(false)
end)

-- End PM Commands //

function PM:InitializePlayer(ply)
    self:Run(ply, "StopOBSM")
    self:Run(ply, "BuildPlayerBody")
    self:Run(ply, "ClassSetup")
    self:Run(ply, "Loadout")
end