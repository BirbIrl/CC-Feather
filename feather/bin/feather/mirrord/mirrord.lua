local storage = bundl "feather.storage" ---@type feather.storage
local featherd = bundl "feather.featherd" ---@type feather.featherd
local bundle = bundl "feather.bundle" ---@type feather.bundle

peripheral.find("modem", rednet.open)
assert(rednet.isOpen(), "Must have connected modem")
local protocol = "feather.mirrord"
rednet.host(protocol, os.getComputerLabel() or "unlabelled")

---@alias feather.mirrord.message.id number

--TODO: make a modem message library

---@class feather.mirrord.message
---@field time number -- obtained from os.time("local")
---@field id feather.mirrord.message.id -- obtained from math.random()
---@field respondsTo feather.mirrord.message.id?
---@field contents table


---@class feather.mirrord.message.bundle.get: feather.mirrord.message
---@field request_type "bundleGet"
---@field contents {packageName: string}
---@field respondsTo nil

---@class feather.mirrord.message.bundle.post: feather.mirrord.message
---@field request_type "bundlePost"
---@field contents {packageName: string, entry: feather.storage.entryStruct}
---@field respondsTo feather.mirrord.message.id
---
---@class feather.mirrord.message.bundle.failToFind: feather.mirrord.message
---@field request_type "bundleFailToFind"
---@field respondsTo feather.mirrord.message.id
---
---@class feather.mirrord.message.bundle.list.get: feather.mirrord.message
---@field request_type "bundleListGet"
---@field contents {}
---@field respondsTo nil

---@class feather.mirrord.message.bundle.list.post: feather.mirrord.message
---@field request_type "bundleListPost"
---@field contents {packages: feather.bundle.packageTable}
---@field respondsTo feather.mirrord.message.id


---@param sender number
---@param message feather.mirrord.message.bundle.get
local function handleGet(sender, message)
	local contents = message.contents
	local pkgPath = contents.packageName:gsub('%.', "/")
	local path = fs.combine(feather.installPath, pkgPath)
	if not fs.exists(path) then
		---@type feather.mirrord.message.bundle.failToFind
		local answer = {
			request_type = "bundleFailToFind",
			time = os.time("local"),
			id = math.random(),
			respondsTo = message.id,
			contents = {},
		}
		rednet.send(sender, answer, protocol)
		return false
	end

	local struct = storage.encode(path)
	---@type feather.mirrord.message.bundle.post
	local answer = {
		request_type = "bundlePost",
		time = os.time("local"),
		id = math.random(),
		respondsTo = message.id,
		contents = {
			packageName = contents.packageName,
			entry = struct,
		}
	}
	rednet.send(sender, answer, protocol)
	return true
end

---@param sender number
---@param message feather.mirrord.message.bundle.list.get
local function handleListGet(sender, message)
	---@type feather.mirrord.message.bundle.list.post
	local answer = {
		request_type = "bundleListPost",
		contents = bundle.listInstalled(),
		time = os.time("local"),
		id = math.random(),
		respondsTo = message.id
	}
	rednet.send(sender, answer, protocol)
end




featherd.log("Initiating mirrord")
while true do
	---@type integer, feather.mirrord.message.bundle.post
	local sender, message = rednet.receive(protocol) ---@diagnostic disable-line
	assert(sender and type(message) == "table")
	if message.request_type == "bundleGet" then
		if handleGet(sender, message --[[@as feather.mirrord.message.bundle.get]]) then
			featherd.log("Sent " .. message.contents.packageName .. " to computer with id=" .. sender)
		else
			featherd.log("Failed to find request package " ..
				message.contents.packageName .. " for computer with id=" .. sender)
		end
	elseif message.request_type == "bundleListGet" then
		handleListGet(sender, message --[[@as feather.mirrord.message.bundle.list.get]])
	end
end
