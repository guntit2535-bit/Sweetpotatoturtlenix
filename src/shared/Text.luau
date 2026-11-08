--!strict
-- Every word a player sees lives here, in English and Thai.
-- English is the default for every player; Thai is picked in Settings -> Language and saved.
--
--   Text.get("LanguageEnglish", "th")
--   Text.get("SomeLine", lang, { count = 3 })   -- "{count}" in the line is replaced
--
-- No requires: this module is also loaded by the pure tests (tests/Text.spec.luau).

export type Lang = "en" | "th"
-- Values are shown with tostring. `any` (not string | number) so a literal like { count = 3 }
-- type-checks at the call site without a cast.
export type Vars = { [string]: any }

local DEFAULT: Lang = "en"

local Text = {}

Text.GameName = "Sweetpotatoturtlenix" -- same in both languages
Text.Languages = { "en", "th" } :: { Lang }
Text.Default = DEFAULT

-- [key] = { en = ..., th = ... }. Every key needs both languages with the same {placeholders}
-- (checked by tests/Text.spec.luau). Lines are added by the task that first needs them.
Text.Lines = {
	-- Settings -> Language (each language names itself)
	LanguageEnglish = { en = "English", th = "English" },
	LanguageThai = { en = "ไทย (Thai)", th = "ไทย" },

	-- Settings window (task 1.1)
	SettingsButton = { en = "Settings", th = "ตั้งค่า" },
	SettingsTitle = { en = "Settings", th = "ตั้งค่า" },
	SettingsLanguage = { en = "Language", th = "ภาษา" },
	SettingsLanguageNote = { en = "Every text in the game", th = "ข้อความทั้งหมดในเกม" },
	Close = { en = "Close", th = "ปิด" },
} :: { [string]: { en: string, th: string } }

function Text.isLang(value: unknown): boolean
	return value == "en" or value == "th"
end

-- Saved setting -> language to show. Anything unknown (old saves, bad data) -> English.
function Text.resolve(setting: unknown): Lang
	if setting == "th" then
		return "th"
	end
	return DEFAULT
end

-- Placeholder names in a line, sorted: "{a} and {b}" -> { "a", "b" }.
function Text.placeholders(line: string): { string }
	local names = {}
	for name in string.gmatch(line, "{(%w+)}") do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- A line in the given language with {placeholders} filled in. A missing key returns the key itself
-- (easy to spot in testing); a missing variable leaves its {placeholder} in place.
function Text.get(key: string, lang: Lang, vars: Vars?): string
	local line = Text.Lines[key]
	if not line then
		return key
	end
	local text = if lang == "th" then line.th else line.en
	if vars then
		text = string.gsub(text, "{(%w+)}", function(name: string): string
			local value = vars[name]
			if value == nil then
				return `\{{name}\}`
			end
			return tostring(value)
		end)
	end
	return text
end

return Text
