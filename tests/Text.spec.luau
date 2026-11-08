--!strict
-- Every player-facing line exists in English and Thai with the same placeholders, and the English
-- has no Thai letters (except lines that name the Thai language itself).
-- Run by scripts/check.luau (lune). Fails by raising an error.

local Text = require("../src/shared/Text")

local THAI_ALLOWED_IN_EN: { [string]: boolean } = {
	LanguageThai = true,
}

local failures = 0
local function check(ok: boolean, message: string)
	if not ok then
		failures += 1
		print(`FAIL Text: {message}`)
	end
end

local function same(a: { string }, b: { string }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

local function hasThai(s: string): boolean
	for _, code in utf8.codes(s) do
		if code >= 0x0E00 and code <= 0x0E7F then
			return true
		end
	end
	return false
end

local count = 0
for key, line in Text.Lines do
	count += 1
	for _, lang in Text.Languages do
		local value = (line :: any)[lang]
		check(type(value) == "string" and #value > 0, `{key} has no {lang} text`)
		check(type(value) ~= "string" or utf8.len(value) ~= nil, `{key} {lang} is not valid UTF-8`)
	end
	check(same(Text.placeholders(line.en), Text.placeholders(line.th)), `{key}: EN and TH placeholders differ`)
	check(THAI_ALLOWED_IN_EN[key] or not hasThai(line.en), `{key}: English line has Thai letters`)
end
check(count > 0, "no lines")

check(Text.Default == "en", "English is the default")
check(Text.resolve(nil) == "en", "no setting -> en")
check(Text.resolve("th") == "th", "saved th -> th")
check(Text.resolve("en") == "en", "saved en -> en")
check(Text.resolve("auto") == "en", "unknown setting -> en")
check(Text.resolve(5) == "en", "bad type -> en")
check(Text.isLang("th") and Text.isLang("en") and not Text.isLang("fr"), "isLang")

check(Text.get("NoSuchKey", "th") == "NoSuchKey", "missing key shows the key")
check(Text.get("LanguageThai", "th") ~= Text.get("LanguageThai", "en"), "Thai and English differ")

-- Placeholder filling, on a temporary line.
Text.Lines.__TestLine = { en = "{count} of {name}", th = "{name} {count} ตัว" }
check(Text.get("__TestLine", "en", { count = 3, name = "Mochi" }) == "3 of Mochi", "fills EN vars")
check(Text.get("__TestLine", "th", { count = 3, name = "Mochi" }) == "Mochi 3 ตัว", "fills TH vars")
check(Text.get("__TestLine", "en", { count = 3 }) == "3 of {name}", "missing var stays visible")
check(same(Text.placeholders("{b} {a} {b}"), { "a", "b", "b" }), "placeholders sorted")
local lines: any = Text.Lines
lines.__TestLine = nil

if failures > 0 then
	error(`Text: {failures} failure(s)`)
end
print(`PASS Text ({count} lines)`)
