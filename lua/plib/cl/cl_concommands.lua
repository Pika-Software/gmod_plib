local vgui_GetWorldPanel = vgui.GetWorldPanel
local concommand_Add = concommand.Add
local ents_GetAll = ents.GetAll
local tostring = tostring
local IsValid = IsValid
local ipairs = ipairs

concommand_Add("plib_logo_update", function()
    PLib:UpdateLogo()
end)

local debugTag = "Debug/"
concommand_Add("plib_ent", function(ply)
    if not PLib:DebugAllowed() then return end
    local ent = ply:GetEyeTrace()["Entity"]
	PLib:Log(debugTag.."Entity", string.format("%s\n	Index: %s\n	Name: %s\n	Class: %s\n	Model: %s", ent, ent:EntIndex(), (ent["PrintName"] or (ent["GetName"] and ent:GetName()) or "none"), ent:GetClass(), ent:GetModel() or "No Model"))
end)

concommand_Add("plib_wep", function(ply)
    if not PLib:DebugAllowed() then return end
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) then
		local id = wep:GetPrimaryAmmoType()
		PLib:Log(debugTag.."Weapon", string.format("%s", tostring(wep)))
		PLib:Log("Info", string.format("\n	Index: %s\n	Name: %s\n	Class: %s\n	Model: %s", (wep:EntIndex() or 0), (wep["PrintName"] or wep["TrueName"] or (wep["GetName"] and wep:GetName()) or "nil"), (wep:GetClass() or "error"), (wep:GetModel() or "No Model")))
		PLib:Log("Ammo", string.format("\n	In Weapon: %s/%s\n	In Inventory: %s\n	[ID: %s, Name: %s, Damage: %s]", wep:Clip1(), wep:GetMaxClip1(), ply:GetAmmoCount(id), id, game.GetAmmoName(id), game.GetAmmoPlayerDamage(id)))
	end
end)

concommand_Add("plib_bounds", function(ply)
    if not PLib:DebugAllowed() then return end
	local ent = ply:GetEyeTrace()["Entity"]
	if IsValid(ent) then
		local mins, maxs, cent = ent:OBBMins():Round(2), ent:OBBMaxs():Round(2), ent:OBBCenter():Round(2)
		PLib:Log(debugTag.."Bounds", string.format("%s\nlocal mins, maxs = Vector(%s, %s, %s), Vector(%s, %s, %s)\nlocal center = Vector(%s, %s, %s)", tostring(ent), mins[1], mins[2], mins[3], maxs[1], maxs[2], maxs[3], cent[1], cent[2], cent[3]))
	else
		PLib:Log(debugTag.."Bounds", "There is no Entity!")
	end
end)

concommand_Add("plib_getpos", function(ply)
    if not PLib:DebugAllowed() then return end
	local pos, ang = ply:GetPos():Floor(), ply:GetAngles():Floor()
	PLib:Log(debugTag.."(Pos, Ang)", string.format("\nVector(%s, %s, %s)\nAngle(%s, %s, %s)", pos[1], pos[2], pos[3], ang[1], ang[2], ang[3]))
end)

concommand_Add("plib_getpos_trace", function(ply)
    if not PLib:DebugAllowed() then return end
	local tr = ply:GetEyeTrace()
	if tr["Hit"] then
		local pos, ang = tr["HitPos"]:Floor(), (tr["HitNormal"]:Angle() - Angle(0, 180)):NormalizeZero()
		PLib:Log(debugTag.."(Pos, Ang)", string.format("\nVector(%s, %s, %s)\nAngle(%s, %s, %s)", pos[1], pos[2], pos[3], ang[1], ang[2], ang[3]))
	end
end)

local achiCount = achievements.Count()
concommand_Add("plib_achievement_test", function(ply, cmd, args)
    if not PLib:DebugAllowed() then return end
    if (args[1] == "me") then
        PLib:SteamUserData(ply:SteamID64(), function(tbl)
            local achi = vgui.Create("plib_achievement")
            achi["Title"] = tbl["personaname"]
            achi["Image"] = Material(tbl["avatarfull"], PLib["MatPresets"]["Pic"])
        end)

        return
    end

    if (args[1] == "all") then
        for i = 1, achiCount do
            RunConsoleCommand(cmd, i)
        end

        return
    end

    local achi = vgui.Create("plib_achievement")
    timer.Simple(0, function()
        if IsValid(ply) and IsValid(achi) then
            ply:GotAchievement(achi["Title"])
        end
    end)

    if (args[1] != nil) then
        local num = tonumber(args[1])
        if (num != nil) then
            num = num - 1
            if (num > -1) and (num <= (achiCount + 1)) then
                achi["Title"] = PLib:GetAchievementName(num)
                achi["Image"] = PLib:GetStandardAchievementIcon(num)
                return
            end
        end

        if isstring(args[1]) then
            achi["Title"] = args[1]
            if string.isvalid(args[2]) then
                achi["Image"] = Material(args[2], PLib["MatPresets"]["Pic"])
            end

            return
        end
    end

    achi["Title"] = "Test Achievement"
end)

local blacklist = {
    ["DMenuBar"] = true,
    ["DMenu"] = true,
    ["SpawnMenu"] = true,
    ["ContextMenu"] = true,
    ["ControlPanel"] = true,
    ["CGMODMouseInput"] = true,
    ["Panel"] = true,
    ['xlib_Panel'] = true,
    ['CGMODMouseInput'] = true,
}

local whitelist = {
    "scoreboard",
    "menu",
    "f1",
    "f2",
    "f3",
    "f4",
    "playx",
    "gcompute",
}

concommand_Add("vgui_cleanup", function()
    local sum = 0
    for _, pnl in ipairs(vgui_GetWorldPanel():GetChildren()) do
        if not IsValid(pnl) then continue end
        -- local hit_blacklist = false
        local name = pnl:GetName()
        local class = pnl:GetClassName()

        if --[[blacklist[class] or ]] blacklist[name] then continue end

        -- for i = 1, #whitelist do
        --     if name:lower():match(whitelist[i]:lower()) then
        --         hit_blacklist = true
        --         continue
        --     end
        -- end

        -- if hit_blacklist then continue end
        PLib:Log(debugTag.."VGUI", "Removed " .. tostring(pnl))
        pnl:Remove()
        sum = sum + 1
    end

    PLib:Log(debugTag.."VGUI", "Total panels removed: " .. sum)
end)

concommand_Add("clentmodels_cleanup", function(ply)
    PLib:CleanUpClientSideEnts()
end)