local storage = bundle "feather.storage" ---@type feather.storage

peripheral.find("modem", rednet.open)
assert(rednet.isOpen(), "Must have connected modem")
local protocol = "feather.mirrord"
rednet.host(protocol, os.getComputerLabel() or ("Unnamed Computer nr." .. os.getComputerID()))

---@alias feather.mirrord.message.id number

---@class feather.mirrord.message
---@field request_type string
---@field time number -- obtained from os.time("local")
---@field id feather.mirrord.message.id -- obtained from math.random()
---@field respondsTo feather.mirrord.message.id?
---@field contents table


---@class feather.mirrord.message.bundle.get: feather.mirrord.message
---@field request_type "bundleGet"
---@field contents {packageName: string, packageType: "lib"|"bin"}

---@class feather.mirrord.message.bundle.post: feather.mirrord.message
---@field request_type "bundlePost"
---@field contents {packageName: string, packageType: "lib"|"bin", entry: feather.storage.entryStruct}


---@param sender number
---@param message feather.mirrord.message.bundle.get
local function handleRequest(sender, message)
	local contents = message.contents
	---@type feather.mirrord.message.bundle.post
	local answer = {
		request_type = "bundlePost",
		time = os.time("local"),
		id = math.random(),
		respondsTo = message.id,
		contents = {
			packageName = contents.packageName,
		}
	}
	answer.contents.packageType = contents.packageType;
	local struct
	if contents.packageType == "lib" then
		local pkgPath = contents.packageName:gsub(".", "/")
		struct = storage.encode(fs.combine(feather.path(), "lib", pkgPath))
	else
		struct = storage.encode(fs.combine(feather.path(), "bin", contents.packageName .. ".lua"))
	end

	answer.contents.entry = struct
	rednet.send(sender, answer, protocol)
end



while true do
	local sender, message = rednet.receive(protocol) ---@diagnostic disable-line
	assert(sender and type(message) == "table")
	if message.request_type == "bundleGet" then
		handleRequest(sender, message --[[@as feather.mirrord.message.bundle.get]])
	end
end
