--!strict
-- Number formatting shared by every UI (pure, tested in Lune).

local Format = {}

-- 18400 -> "18,400"; negative and fractional values are floored toward zero first.
function Format.int(value: number): string
	local n = if value < 0 then math.ceil(value) else math.floor(value)
	local text = tostring(math.abs(n))
	local out = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1,")))
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return if n < 0 then "-" .. out else out
end

-- Coin rates: whole numbers with commas, otherwise one decimal ("1.5", "6", "2,000").
function Format.rate(value: number): string
	local tenths = math.floor(value * 10 + 0.5)
	if tenths % 10 == 0 then
		return Format.int(tenths / 10)
	end
	return Format.int(math.floor(tenths / 10)) .. "." .. tostring(tenths % 10)
end

-- Big numbers short for the HUD: 950 -> "950", 1234 -> "1.2K", 395120 -> "395.1K", 2000000 -> "2M"
-- (one decimal, cut not rounded, so it never shows more than the player has).
local UNITS = { "K", "M", "B", "T", "Qa", "Qi", "Sx" }
function Format.short(value: number): string
	local n = math.floor(math.max(0, value))
	if n < 1000 then
		return tostring(n)
	end
	local unit = 0
	local scaled = n
	while scaled >= 1000 and unit < #UNITS do
		scaled /= 1000
		unit += 1
	end
	local tenths = math.floor(scaled * 10)
	local text = if tenths % 10 == 0 then tostring(tenths // 10) else string.format("%d.%d", tenths // 10, tenths % 10)
	return text .. UNITS[unit]
end

-- Seconds as a clock, rounded up: 65.2 -> "1:06", 9 -> "0:09".
function Format.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

return Format
