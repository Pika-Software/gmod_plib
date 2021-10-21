local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_CreateFont = surface.CreateFont
local surface_SetTexture = surface.SetTexture
local mesh_AdvanceVertex = mesh.AdvanceVertex
local table_SortByMember = table.SortByMember
local render_SetMaterial = render.SetMaterial
local surface_DrawRect = surface.DrawRect
local draw_SimpleText = draw.SimpleText
local system_IsLinux = system.IsLinux
local mesh_Position = mesh.Position
local validStr = string["isvalid"]
local math_striving_for = math["striving_for"]
local table_insert = table.insert
local hook_Remove = hook.Remove
local ScreenScale = ScreenScale
local color_white = color_white
local math_Clamp = math.Clamp
local math_Round = math.Round
local mesh_Begin = mesh.Begin
local mesh_Color = mesh.Color
local mesh_End = mesh.End
local hook_Run = hook.Run
local math_max = math.max
local isnumber = isnumber
local tostring = tostring
local istable = istable
local CurTime = CurTime
local Vector = Vector
local pairs = pairs
local Error = Error
local Color = Color
local ScrW = ScrW
local ScrH = ScrH
local Msg = Msg

PLib["Fonts"] = {
    {
        ["name"] = "Main1",
        ["font"] = "Roboto",
        ["size"] = 6,
    },
    {
        ["font"] = "Comfortaa",
        ["size"] = {8, 12},
    }
}

local util_TableToJSON = util.TableToJSON
local util_CRC = util.CRC

function PLib:FontInit(name, font, size, tbl)
    local title = ""
    if validStr(name) then
        title = name
    else
        title = font.."_"..size
        if (#tbl > 2) then
            title = title .. "_#" .. util_CRC(util_TableToJSON(tbl))
        end
    end

    surface_CreateFont(title, {
        font = font,
        size = ScreenScale(size),
        extended = isbool(tbl["extended"]) and tbl["extended"] or true,
        additive = isbool(tbl["additive"]) and tbl["additive"] or false,
        weight = isnumber(tbl["weight"]) and tbl["weight"] or 500,
        blursize = isnumber(tbl["blursize"]) and tbl["blursize"] or 0,
        scanlines = isnumber(tbl["scanlines"]) and tbl["scanlines"] or 0,
        antialias = isbool(tbl["antialias"]) and tbl["antialias"] or true,
        underline = isbool(tbl["underline"]) and tbl["underline"] or false,
        italic = isbool(tbl["italic"]) and tbl["italic"] or false,
        strikeout = isbool(tbl["strikeout"]) and tbl["strikeout"] or false,
        symbol = isbool(tbl["symbol"]) and tbl["symbol"] or false,
        rotary = isbool(tbl["rotary"]) and tbl["rotary"] or false,
        shadow = isbool(tbl["shadow"]) and tbl["shadow"] or false,
        outline = isbool(tbl["outline"]) and tbl["outline"] or false,
    })

    self:Log("Fonts", "[", table_insert(self["GeneratedFonts"], title), "] Added: ", self["_C"]["print"], title)
end

function PLib:AddFont(tbl)
    if not istable(tbl) or not validStr(tbl["font"]) or (tbl["size"] == nil) then
        Error("[Fonts] "..self:Translate("plib.invalid_font_args"))
    end

    table_insert(self["Fonts"], tbl)
    self:ReBuildFonts()
end

function PLib:ReBuildFonts()
    Msg("\n")
    self["GeneratedFonts"] = {}
    local fonts = self["Fonts"]
    for i = 1, #fonts do
        local tbl = fonts[i]
        if not istable(tbl) then continue end

        local font = tbl["font"]
        if not validStr(font) then continue end

        local size = tbl["size"]
        if istable(size) then
            for i = 1, #size do
                self:FontInit(tbl["name"], font, size[i], tbl)
            end
        elseif isnumber(size) then
            self:FontInit(tbl["name"], font, size, tbl)
        end
    end

    hook_Run("PLib:FontsUpdated", self["GeneratedFonts"])
end

local mat_white = Material("vgui/white")
function draw.SimpleLinearGradient(x, y, w, h, startColor, endColor, horizontal)
	draw.LinearGradient(x, y, w, h, { {offset = 0, color = startColor}, {offset = 1, color = endColor} }, horizontal)
end

local MATERIAL_QUADS = MATERIAL_QUADS
function draw.LinearGradient(x, y, w, h, stops, horizontal)
	if #stops == 0 then
		return
	elseif #stops == 1 then
		surface_SetDrawColor(stops[1].color)
		surface_DrawRect(x, y, w, h)
		return
	end

	table_SortByMember(stops, "offset", true)

	render_SetMaterial(mat_white)
	mesh_Begin(MATERIAL_QUADS, #stops - 1)
	for i = 1, #stops - 1 do
		local offset1 = math_Clamp(stops[i].offset, 0, 1)
		local offset2 = math_Clamp(stops[i + 1].offset, 0, 1)
		if offset1 == offset2 then continue end

		local deltaX1, deltaY1, deltaX2, deltaY2

		local color1 = stops[i].color
		local color2 = stops[i + 1].color

		local r1, g1, b1, a1 = color1.r, color1.g, color1.b, color1.a
		local r2, g2, b2, a2
		local r3, g3, b3, a3 = color2.r, color2.g, color2.b, color2.a
		local r4, g4, b4, a4

		if horizontal then
			r2, g2, b2, a2 = r3, g3, b3, a3
			r4, g4, b4, a4 = r1, g1, b1, a1
			deltaX1 = offset1 * w
			deltaY1 = 0
			deltaX2 = offset2 * w
			deltaY2 = h
		else
			r2, g2, b2, a2 = r1, g1, b1, a1
			r4, g4, b4, a4 = r3, g3, b3, a3
			deltaX1 = 0
			deltaY1 = offset1 * h
			deltaX2 = w
			deltaY2 = offset2 * h
		end

		mesh_Color(r1, g1, b1, a1)
		mesh_Position(Vector(x + deltaX1, y + deltaY1))
		mesh_AdvanceVertex()

		mesh_Color(r2, g2, b2, a2)
		mesh_Position(Vector(x + deltaX2, y + deltaY1))
		mesh_AdvanceVertex()

		mesh_Color(r3, g3, b3, a3)
		mesh_Position(Vector(x + deltaX2, y + deltaY2))
		mesh_AdvanceVertex()

		mesh_Color(r4, g4, b4, a4)
		mesh_Position(Vector(x + deltaX1, y + deltaY2))
		mesh_AdvanceVertex()
	end
	mesh_End()
end

local w, h = 0, 0
function PLib:Draw2D(func)
    func(w, h);
end

local function ScreenSizeChanged()
    w, h = ScrW(), ScrH()
    PLib:ReBuildFonts()

    PLib:UpdateLogo()

    hook.Run("PLib:ResolutionChanged", w, h)
    hook.Remove("PLib:PlayerInitialized", "PLib:2D_RE")
end

if (PLib["Loaded"] == true) then
    ScreenSizeChanged()
end

hook.Add("OnScreenSizeChanged", "PLib:2D_RE", ScreenSizeChanged)
hook.Add("PLib:PlayerInitialized", "PLib:2D_RE", ScreenSizeChanged)

local logo, logo_w, logo_h, ssw, ssh
function PLib:UpdateLogo(path)
    if (self["ServerLogo"] == nil) then
        local cvarLogo = GetConVar("plib_logo_url"):GetString()
        local path = self:isURL(path) and path or (self:isURL(cvarLogo) and cvarLogo or "https://i.imgur.com/j5DjzQ1.png")
        if (path != nil) then
            Material(path, PLib["MatPresets"]["Pic"], function(mat)
                logo = mat
                logo_w, logo_h = self:MaterialSize(mat)
                ssw, ssh = (w - logo_w)/2, (h - logo_h)/2
                self:Log(nil, "Logo updated!")
            end)
        end
    else
        logo = self["ServerLogo"]
        logo_w, logo_h = logo:GetSize()
        ssw, ssh = (w - logo_w)/2, (h - logo_h)/2

        timer.Simple(0, function()
            UpdateLogoState(true)
        end)
    end
end

PLib:UpdateLogo(CreateClientConVar("plib_logo_url", "https://i.imgur.com/j5DjzQ1.png", true, false, "Url to your logo :p (Need 1x0.25, example 190x65)"):GetString())
cvars.AddChangeCallback("plib_logo_url", function(name, old, new)
    PLib:UpdateLogo(new)
end, "PLib")

local offset = CreateClientConVar("plib_logo_offset", "25", true, false, "Logo offset from the top right corner..."):GetInt()
cvars.AddChangeCallback("plib_logo_offset", function(name, old, new)
    offset = tonumber(new)
end, "PLib")

local col = PLib["_C"]["logo"]
local function UpdateLogoState(bool)
    if (bool == false) and (PLib["ServerLogo"] == nil) then
        hook.Remove("HUDPaint", "PLib:DrawLogo")
        return
    end

    hook.Add("HUDPaint", "PLib:DrawLogo", function()
        PLib:Draw2D(function(w, h)
            surface_SetDrawColor(col)
            surface_SetMaterial(logo)
            surface_DrawTexturedRect(w - logo_w - offset, offset, logo_w, logo_h)
        end)
    end)
end

UpdateLogoState(CreateClientConVar("plib_logo", "0", true, false, "Displays the logo in the upper right corner. (0/1)", 0, 1):GetBool())
cvars.AddChangeCallback("plib_logo", function(name, old, new)
    UpdateLogoState(tobool(new))
end, "PLib")

function PLib:StandbyScreen()
    surface_SetDrawColor(color_white)
    surface_SetMaterial(logo)
    surface_DrawTexturedRect(ssw, ssh, logo_w, logo_h)
end

function PLib:ReplaceDefaultFont(new, sizeMult, underline)
    if system_IsLinux() then
        surface_CreateFont("DermaDefault", {
            font		= new or "DejaVu Sans",
            size		= 14 * (sizeMult or 1),
            weight		= 500,
            extended	= true
        })
    
        surface_CreateFont("DermaDefaultBold", {
            font		= new or "DejaVu Sans",
            size		= 14 * (sizeMult or 1),
            weight		= 800,
            extended	= true
        })
    else
        surface_CreateFont("DermaDefault", {
            font		= new or "Tahoma",
            size		= 13 * (sizeMult or 1),
            weight		= 500,
            extended	= true
        })
    
        surface_CreateFont("DermaDefaultBold", {
            font		= new or "Tahoma",
            size		= 13 * (sizeMult or 1),
            weight		= 800,
            extended	= true
        })
    end

    surface_CreateFont("DermaLarge", {
        font		= new or "Roboto",
        size		= 32 * (sizeMult or 1),
        weight		= 500,
        extended	= true
    })

    self:SpawnMenuReload()
end

function PLib:ResetDefaultFonts()
    self:ReplaceDefaultFont()
end

-- PLib:ReplaceDefaultFont("Bender")
-- PLib:ReplaceDefaultFont("Circular Std Bold")

-- PLib:ReplaceDefaultFont("Codename Coder Free 4F", 1.2)

-- PLib:ReplaceDefaultFont("GTA Russian", 1.2)
-- PLib:ReplaceDefaultFont("HACKED", 1.2)