AddCSLuaFile()

ENT.Base = "base_anim"
ENT.PrintName = "Sound Shooter"
ENT.Spawnable = true
ENT.DisableDuplicator = true

function ENT:GetMusicTag()
    return util.CRC(tostring(self))
end

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "URL")
    self:NetworkVar("Int", 1, "Score")

    if SERVER then
        self:SetScore(0)
    end
end

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/hunter/plates/plate05x05.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:SetURL("")

        if (self["SetUnbreakable"] == nil) then return end
        self:SetUnbreakable(true)
    end
end

hook.Add("EntityEmitSound", "Sound Shooter", function(data)
    if isvector(data["Pos"]) then
         if data.OriginalSoundName != data.SoundName then

            for k, ent in ipairs(ents.FindInSphere(data["Pos"], 128)) do
                if ent:GetClass() == "plib_sound_shooter" then
                    return false
                end
            end
        end
    end

    -- local ent = data["Entity"]
    -- if IsValid(ent) then
    --     print(ent)
    --     return false
    -- end
    -- return CLIENT and !IsValid(data["Entity"])

end)

if SERVER then
	function ENT:OnTakeDamage(dmginfo)
		if dmginfo:IsBulletDamage() then
			local att = dmginfo:GetAttacker()
            if IsValid(att) then
                timer.Simple(att:Ping() / 1000, function()
                    self:EmitSound("buttons/button15.wav")

                    net.Start("PLib.SoundShooter")
                        net.WriteEntity(self)
                        net.WriteUInt(0, 2)
                    net.Broadcast()
                end)

                self:RemoveAllDecals()
            end
		end
	end

    function ENT:AddScore(amt)
        local new = self:GetScore() + amt
        self:SetScore(new)
        return new
    end

	function ENT:Use()
		local time = CurTime()
		if ((self["UseTimeout"] or 0) < time) then
                self:EmitSound("buttons/lightswitch2.wav")
                net.Start("PLib.SoundShooter")
                    net.WriteEntity(self)
                    net.WriteUInt(1, 2)
                net.Broadcast()

			self["UseTimeout"] = time + 1
		end
	end

    util.AddNetworkString("PLib.SoundShooter")
else
    function ENT:Play()
		PLib:PlayURL(self:GetMusicTag(), self:GetURL(), self, 100, 200)
    end

    function ENT:Station()
        local tbl = PLib["URL_Sound_List"][self:GetMusicTag()]
        if (tbl == nil) then return false end
        return tbl[1]
    end

	local color_white = color_white
	local color_red = Color(255, 0, 0)

    ENT["LastHit"] = 0

    local actions = {
        [0] = function(ent)
            ent["LastHit"] = CurTime()
        end,
        [1] = function(ent)
            ent:Play()
        end
    }

    net.Receive("PLib.SoundShooter", function()
        local ent = net.ReadEntity()
        if IsValid(ent) then
            local action = actions[net.ReadUInt(2)]
            if action then
                action(ent)
            end
        end
    end)

    ENT["Score"] = 0
    ENT["Active"] = false
    function ENT:UpdateColor(active)
        if (active == self["Active"]) then
            return
        end

		if active then
            self:SetColor(color_red)
		else
            self:SetColor(color_white)
		end

        self["Active"] = active
    end

	local circles = {}
	local function addCircle()
		table.insert( circles, {0,0,0,Color(255,0,255)} )
	end

	local audio = nil
	local oldsample = 0
    local delay = 0
    local state = 0

    ENT["EndColor"] = ColorRand()
    function ENT:Think()
        local isPressed = (CurTime() - self["LastHit"]) < 0.2
        self:UpdateColor(isPressed)

		if isPressed then
			audio = self:Station()

            -- print(audio)
		end

		if IsValid(audio) then
            local fft = {0}
            audio:FFT(fft, -1)

            local sample = math.max(unpack(fft)) * 100

            self["EndColor"] = PLib:BassColor(sample, 10)

            local newState = audio:GetState()
            if newState != state then
                -- print("state update:", state, "to", newState)
                state = newState
            end

            local dist = math.abs(sample - oldsample)

            -- if dist > 1 then
				-- oldsample = sample
                -- addCircle()
            -- end

            if isPressed and (delay < CurTime()) then
    			if dist > 1 then

                    self["Score"] = math.floor(self["Score"] + dist)

                    addCircle()

                    delay = CurTime() + 0.25

                else
                    self["Score"] = self["Score"] - 0.5

                    delay = CurTime() + 0.1
                end

                -- chat.AddText(ColorRand(), tostring(CurTime()), " ", color_white, tostring(math.Round(sample, 4))," bool: ", tostring(dist > 0.5), " dist: ", tostring(dist))
            end

            oldsample = sample
		end
	end

    -- for k, v in ipairs(file.Find("sound/buttons/*", "GAME")) do
    --     print(k, v)
    -- end

    surface.CreateFont("SoundShooter", {
        font        = "Tahoma",
        size        = 64,
        extended    = true
    })

    local pos3d2d = Vector(0, 0, 1.7)
    local ang3d2d = Angle(0, 0, 0)

    local scale = 225
    local half_scale = scale / 2

    local col_1 = Color(34, 34, 34)

	function ENT:Draw(fl)
		self:DrawModel(fl)

		cam.Start3D2D(self:LocalToWorld(pos3d2d), self:LocalToWorldAngles(ang3d2d), 0.1)
            surface.SetFont("SoundShooter")

            local score = self["Score"]
            local w, h = surface.GetTextSize(score)
            surface.SetTextColor(color_white)
            surface.SetTextPos(-w / 2, -half_scale - h - 10)
            surface.DrawText(score)

            draw.SimpleLinearGradient(-half_scale, -half_scale, scale, scale, col_1, self["EndColor"])

            for num, circle in ipairs(circles) do
				circle[3] = circle[3] + 4
				surface.DrawCircle(circle[1], circle[2], circle[3], circle[4])

				if circle[3] > 115 then
					table.remove(circles , num)
				end
			end
		cam.End3D2D()

	end
end

-- hook.Add("PlayerPostThink", "InfAmmo", function(ply)
--     if ply:Alive() then
--         local wep = ply:GetActiveWeapon()
--         if IsValid(wep) then
--             local max = wep:GetMaxClip1()
--             if (max > 0) and (wep:Clip1() == max) then
--                 return
--             end

--             wep:SetClip1(max)
--         end
--     end
-- end)