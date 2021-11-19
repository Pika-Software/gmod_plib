local scrw, scrh = ScrW(), ScrH()
local function ScreenInit()
	scrw, scrh = ScrW(), ScrH()
end

hook.Add("OnScreenSizeChanged", "PLib:Notify", ScreenInit)
ScreenInit()

PLib["Notifications"] = PLib["Notifications"] or {}
PLib["NotifyStyles"] = PLib["NotifyStyles"] or {}

function PLib:AddNotifyPreset(name, tbl)
	PLib["NotifyStyles"][name] = tbl
end

local PANEL = {}

local bg = Color(42, 46, 51)
local green = Color(0, 161, 65)

function PANEL:SetStyle(tbl)
	for key, value in pairs(tbl) do
		if (key == "colors") then continue end
		self[key] = value
	end

	if (tbl["colors"] != nil) then
		self["mainColor"] = tbl["colors"]["main"] or green
		self["bgColor"] = tbl["colors"]["bg"] or bg
		self["descColor"] = tbl["colors"]["desc"] or self:GetDescColor()
	else
		self["mainColor"] = green
		self["bgColor"] = bg
		self["descColor"] = self:GetDescColor()
	end

	if (tbl["Icon"] != nil) then
		self:SetIcon(tbl["Icon"], tbl["IconAnim"])
	end

	self["halfLifetime"] = self["lifetime"] / 2
	self["AlphaLessSpeed"] = self["lifetime"] * 100
end

function PANEL:Init()
	self["Alpha"] = 255
	self["IconW"], self["IconH"] = 0, 0
	for num, pnl in ipairs(PLib["Notifications"]) do
		if not IsValid(pnl) or (math.floor(CurTime() - pnl["created"]) > pnl["halfLifetime"]) then
			self["ID"] = num
			PLib["Notifications"][num] = self
			return
		end
	end

	self["ID"] = table.insert(PLib["Notifications"], self)
end

function PANEL:GetDescColor()
	return Color(self["bgColor"]["r"] + 60, self["bgColor"]["g"] + 60, self["bgColor"]["b"] + 60)
end

local getFontSize = PLib["GetFontSize"]
function PANEL:Setup(title, msg, color, lifetime, animSpeed)
	self["title"] = title or "Title"
	self["msg"] = msg or "Text"

	if istable(color) and not IsColor(color) then
		self["mainColor"] = color["main"] or green
		self["bgColor"] = color["bg"] or bg
		self["descColor"] = color["desc"] or self:GetDescColor()
	else
		self["mainColor"] = IsColor(color) and color or green
		self["bgColor"] = bg
		self["descColor"] = self:GetDescColor()
	end

	self["created"] = CurTime()
	self["lifetime"] = (lifetime or 5)
	self["halfLifetime"] = self["lifetime"] / 2
	self["AlphaLessSpeed"] = self["lifetime"] * 100

	self["animSpeed"] = animSpeed or 0.25

	if isstring(color) then
		local style = PLib["NotifyStyles"][color]
		if (style != nil) then
			self:SetStyle(style)
		end
	end

	self["lifetime"] = self["lifetime"] or lifetime

	local tw, th = getFontSize(self["title"], "DermaLarge")
	local mw, mh = getFontSize(self["msg"], "DermaDefault")
	self["wSize"] = math.max(tw, mw) + 25
	self["hSize"] = 15 + mh + 10 + th + 5

	self["xPos"] = self["wSize"] + 5
	self["yPos"] = scrh - (self["hSize"] + 5)

	self:FinishAnim()

	local lastPnl = PLib["Notifications"][self["ID"] - 1]
	if IsValid(lastPnl) then
		self["yPos"] = lastPnl["yPos"] - (self["hSize"] + 5)
	end
end

function PANEL:PerformLayout()
	self:SetSize(self["wSize"], self["hSize"])
end

function PANEL:Think()
	if (self["created"] == nil) then return end
	local time = math.floor(CurTime() - self["created"])
	if (time > self["halfLifetime"]) then
		self["Alpha"] = math.max(0, self["Alpha"] - self["AlphaLessSpeed"] * FrameTime())
	end

	if (time > self["lifetime"]) then
		self:Remove()
	end
end

function PANEL:SetIcon(material, animated)
	self["Icon"] = material
	self["IconW"], self["IconH"] = material:GetSize()
	self["IconAnim"] = animated
	self:NoClipping(true)
end

local color_white = color_white
function PANEL:Paint(w, h)
	surface.SetAlphaMultiplier(self["Alpha"] / 255)

	if (self["Icon"] == nil) then
		draw.RoundedBoxEx(10, 10, 0, w - 10 , h, self["bgColor"], false, true, false, true)
		draw.RoundedBoxEx(10, 0, 0, 10, h, self["mainColor"], true, false, true, false)
	else
		draw.RoundedBoxEx(10, 10, 0, w - 10 , h, self["bgColor"], false, true, false, true)
		draw.RoundedBoxEx(10, -self["IconW"], 0, self["IconW"] + 10, h, self["mainColor"], true, false, true, false)

		surface.SetDrawColor(color_white)
		surface.SetMaterial(self["Icon"])
		surface.DrawTexturedRect((5 + self["IconW"]) / -2, (h - self["IconH"]) / 2 - ((self["IconAnim"] == true) and (TimedSin(1.2, -1, 1, 0) - 1) or 0), self["IconW"], self["IconH"])
	end

	draw.DrawText( self["title"], "DermaLarge", 20, 5, self["mainColor"], TEXT_ALIGN_LEFT )
	draw.DrawText( self["msg"], "DermaDefault", 20, 40, self["descColor"], TEXT_ALIGN_LEFT )
end

function PANEL:FinishAnim()
	local anim = self:NewAnimation(self["animSpeed"], 0, 1)
	function anim:Think(pnl, frac)
		pnl:SetPos(scrw - (pnl["xPos"] * frac), pnl["yPos"])
	end
end

vgui.Register("plib_notify", PANEL)

local vgui_Create = vgui.Create
function PLib:AddNotify(title, text, color, lifetime, image, animated)
	local notify = vgui_Create("plib_notify")

	if (color != nil) then
		if isstring(color) then
			if (color == "") then
				color = "default"
			end
		elseif not istable(color) then
			color = nil
		end
	end

	notify:Setup(title, text, color, lifetime)

	return notify
end

PLib:AddNotifyPreset("default", {
	lifetime = 10,
	colors = {
		main = PLib["_C"]["sv"],
		bg = PLib["_C"]["grey"],
	},
})

PLib:AddNotifyPreset("warn", {
	lifetime = 10,
	colors = {
		main = PLib["_C"]["warn"],
		bg = PLib["_C"]["grey"],
	},
})
