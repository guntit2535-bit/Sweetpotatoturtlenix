--!strict
-- Hotbar icons, step 3 of 3: uploads art/export/CatIcons/<id>.png to the group (Open Cloud Assets API, as Decals)
-- and records each cat's decal id in art/export/CatIcons/ids.json (written after every upload, so a stopped run
-- carries on where it stopped). Claude then turns the decal ids into image ids in Studio (src/shared/CatIcons.luau).
--
-- The developer runs it (tools/icons/upload_icons.bat asks for the key); the API key is never saved or printed:
--   Creator Hub -> the group "Sweetpotatoturtlenix" -> Open Cloud -> API Keys -> Create: Assets API (read + write).
--
--   ROBLOX_API_KEY=... lune run tools/icons/upload.luau

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local GROUP_ID = "565190385" -- Config.GroupId
local DIR = "art/export/CatIcons"
local IDS = `{DIR}/ids.json`
local PAUSE = 1.2 -- seconds between uploads (the API allows about 60 a minute)

local key = process.env.ROBLOX_API_KEY
if key then
	key = string.gsub(key, "^[%s\"']+", "")
	key = string.gsub(key :: string, "[%s\"']+$", "")
end
if not key or key == "" then
	error("ROBLOX_API_KEY is not set (run tools/icons/upload_icons.bat)")
end

local ids: { [string]: string } = {}
if fs.isFile(IDS) then
	ids = serde.decode("json", fs.readFile(IDS))
end

local function save()
	fs.writeFile(IDS, serde.encode("json", ids, true))
end

local function upload(name: string, png: string): string?
	local boundary = "----SweetpotatoIcon" .. tostring(math.random(1e8, 9e8))
	local request = serde.encode("json", {
		assetType = "Decal",
		displayName = `Sweetpotato cat icon {name}`,
		description = "Hotbar icon (Sweetpotatoturtlenix)",
		creationContext = { creator = { groupId = GROUP_ID } },
	})
	local body = table.concat({
		`--{boundary}\r\nContent-Disposition: form-data; name="request"\r\n\r\n{request}\r\n`,
		`--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="{name}.png"\r\nContent-Type: image/png\r\n\r\n`,
		png,
		`\r\n--{boundary}--\r\n`,
	})
	local res = net.request({
		url = "https://apis.roblox.com/assets/v1/assets",
		method = "POST",
		headers = { ["x-api-key"] = key :: string, ["content-type"] = `multipart/form-data; boundary={boundary}` },
		body = body,
	})
	if not res.ok then
		print(`  {name}: upload failed {res.statusCode} {res.body}`)
		if res.statusCode == 401 or res.statusCode == 403 then
			-- the key is not accepted: every other upload would fail the same way
			print("\nThe API key was not accepted. Check: the whole key was pasted (it is long), it is the group's key,")
			print("and it has the Assets API with read + write. Then run upload_icons.bat again.")
			process.exit(1)
		end
		return nil
	end
	local op = serde.decode("json", res.body)
	for _ = 1, 30 do
		if op.done and op.response and op.response.assetId then
			return tostring(op.response.assetId)
		end
		task.wait(1)
		local id = string.match(op.path or "", "operations/(.+)$")
		if not id then
			break
		end
		local poll = net.request({
			url = `https://apis.roblox.com/assets/v1/operations/{id}`,
			method = "GET",
			headers = { ["x-api-key"] = key :: string },
		})
		if poll.ok then
			op = serde.decode("json", poll.body)
		end
	end
	print(`  {name}: no asset id yet ({serde.encode("json", op)})`)
	return nil
end

local files = {}
for _, f in fs.readDir(DIR) do
	local id = string.match(f, "^(cat%d+)%.png$")
	if id then
		table.insert(files, id)
	end
end
table.sort(files)
local done, failed = 0, 0
for i, id in files do
	if ids[id] then
		continue
	end
	local asset = upload(id, fs.readFile(`{DIR}/{id}.png`))
	if asset then
		ids[id] = asset
		save()
		done += 1
		print(`[{i}/{#files}] {id} -> {asset}`)
	else
		failed += 1
	end
	task.wait(PAUSE)
end
print(`uploaded {done}, failed {failed}, recorded {#files - failed} of {#files} in {IDS}`)
if failed > 0 then
	print("run it again: it skips the ones already uploaded")
end
