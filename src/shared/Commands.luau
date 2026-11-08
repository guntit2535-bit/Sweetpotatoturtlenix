--!strict
-- Parses debug chat commands: "!coins 500" -> "coins", { "500" }. Pure (tested in Lune).

local Commands = {}

-- Returns the lower-case command name and its arguments, or nil when `message` is not a command.
function Commands.parse(message: string, prefix: string): (string?, { string })
	if string.sub(message, 1, #prefix) ~= prefix then
		return nil, {}
	end
	local words = {}
	for word in string.gmatch(string.sub(message, #prefix + 1), "%S+") do
		table.insert(words, word)
	end
	local name = table.remove(words, 1)
	if name == nil then
		return nil, {}
	end
	return string.lower(name), words
end

-- A number argument with an optional fraction and a K / M / B suffix ("1.5", "20k", "3M"), or nil.
local SUFFIX = { k = 1e3, m = 1e6, b = 1e9 }
function Commands.number(text: string?): number?
	if text == nil then
		return nil
	end
	local digits, suffix = string.match(string.lower(text), "^(%-?%d+%.?%d*)([kmb]?)$")
	if digits == nil then
		return nil
	end
	local n = tonumber(digits)
	if n == nil then
		return nil
	end
	return n * (if suffix ~= "" then SUFFIX[suffix] else 1)
end

-- A whole number argument (allows a leading "-"), or nil.
function Commands.integer(text: string?): number?
	if text == nil or string.match(text, "^%-?%d+$") == nil then
		return nil
	end
	return tonumber(text)
end

return Commands
