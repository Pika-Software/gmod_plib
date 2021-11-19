local language_GetPhrase = CLIENT and language.GetPhrase
local language_Add = CLIENT and language.Add
local string_StartWith = string.StartWith
local string_Split = string.Split
local string_sub = string.sub
local pairs = pairs

PLib["phrases"] = {
	["ru"] = {
		["plib.title"] = "PLib - Большая GLua библиотека",
		["plib.version"] = "Версия",
		["plib.yes"] = "Да",
		["plib.no"] = "Нет",
		["plib.commands"] = "Команды",
		["plib.ugg"] = "Ты молодец?",
		["plib.achievement"] = "Получено достижение!",
		["plib.earned_achievement"] = " получает достижение ",
		["plib.i_see_my_shadow"] = "У меня есть тень!?",
		["plib.get_error"] = "Возникла ошибка при выполнении GET запроса!",
		["plib.creators"] = "Создатели",
		["plib.invalid_font_args"] = "Неверные аргументы функции, должно быть строка[1] и (таблица или номер)[2]",
		["plib.invalid_logo_url"] = "Логотип сервера отсутствует или содержит ошибку в url адресе! (Используйте plib_server_logo на сервере, что бы установить его)",
		["plib.meet_the"] = "Встречайте,",
	},
	["en"] = {
		["plib.title"] = "PLib - Powerful GLua Library",
		["plib.version"] = "Version",
		["plib.yes"] = "Yes",
		["plib.no"] = "No",
		["plib.commands"] = "Commands",
		["plib.ugg"] = "You Cool?",
		["plib.achievement"] = "Achievement Unlocked!",
		["plib.earned_achievement"] = " earned the achievement ",
		["plib.i_see_my_shadow"] = "I have a shadow!?",
		["plib.get_error"] = "An error occured while executing GET request!",
		["plib.creators"] = "Creators",
		["plib.invalid_font_args"] = "Invalid function arguments should be string[1] and (table or number)[2]",
		["plib.invalid_logo_url"] = "The server logo is missing or contains an error in the url address! (Use plib_server_logo in your server console for install logo)",
		["plib.meet_the"] = "Meet the",
	}
}

if CLIENT then
	for tag, text in pairs(PLib["phrases"]["en"]) do
		language_Add(tag, text)
	end
end

hook.Add("LanguageChanged", "PLib:Phrases", function(_, lang)
	local tbl = PLib["phrases"][lang]
	if (tbl != nil) then
		for tag, text in pairs(tbl) do
			PLang:AddPhrase(text, lang, tag)
		end
	end
end)

function PLib:Translate(tag)
	local PLang = PLang
	if (PLang == nil) then
		if CLIENT then
			return language_GetPhrase(tag) or self["phrases"]["en"][tag] or tag
		else
			return self["phrases"]["en"][tag] or tag
		end
	else
		local phrase = PLang:GetPhrase(nil, tag)
		return istable(phrase) and phrase[1] or self["phrases"]["en"][tag] or tag
	end
end

local space = " "
local tag = "#"

function PLib:TranslateText(name)
	local tbl = string_Split(name, space)
	local output = ""
	for i = 1, #tbl do
		local str = tbl[i]

		if (string_StartWith(str, tag) == true) then
			str = string_sub(str, 2, #str)
		end

		output = output .. self:Translate(str) .. space
	end

	return output
end