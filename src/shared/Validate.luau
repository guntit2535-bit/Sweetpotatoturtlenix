--!strict
-- Checks for values that arrive from clients (remote arguments are `unknown`).
-- Each check returns the value with its real type, or nil when it is not acceptable:
--
--   local amount = Validate.integer(raw, 1, 99)
--   if not amount then return end
--
-- No requires: limits are passed in by the caller (usually from Config), so the pure tests
-- (tests/Validate.spec.luau) can load this module.

local Validate = {}

-- A finite number (no NaN / inf) within [min, max].
function Validate.number(value: unknown, min: number, max: number): number?
	if type(value) ~= "number" then
		return nil
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	if value < min or value > max then
		return nil
	end
	return value
end

-- A whole number within [min, max].
function Validate.integer(value: unknown, min: number, max: number): number?
	local n = Validate.number(value, min, max)
	if n == nil or n ~= math.floor(n) then
		return nil
	end
	return n
end

function Validate.boolean(value: unknown): boolean?
	if type(value) ~= "boolean" then
		return nil
	end
	return value
end

-- Valid UTF-8, 1..maxLength bytes.
function Validate.string(value: unknown, maxLength: number): string?
	if type(value) ~= "string" then
		return nil
	end
	if #value == 0 or #value > maxLength or utf8.len(value) == nil then
		return nil
	end
	return value
end

-- One of the allowed strings (setting keys, language codes ...).
function Validate.oneOf(value: unknown, allowed: { string }): string?
	if type(value) ~= "string" then
		return nil
	end
	if table.find(allowed, value) == nil then
		return nil
	end
	return value
end

-- A key that exists in the given table (Config tables keyed by id).
function Validate.key<T>(value: unknown, map: { [string]: T }): string?
	if type(value) ~= "string" or map[value] == nil then
		return nil
	end
	return value
end

-- An id made by the server (cat ids): 1..32 letters, digits, "_" or "-".
function Validate.id(value: unknown): string?
	if type(value) ~= "string" then
		return nil
	end
	if #value == 0 or #value > 32 or string.find(value, "^[%w_%-]+$") == nil then
		return nil
	end
	return value
end

return Validate
