local storage = bundl "feather.storage" ---@type feather.storage
local featherd = bundl "feather.featherd" ---@type feather.featherd

peripheral.find("modem", rednet.open)
--TODO: in featherd this doesn't log it outward, just prints to stdout
assert(rednet.isOpen(), "Must have connected modem")
local protocol = "feather.mirrord"
rednet.host(protocol, os.getComputerLabel() or "unlabelled")

---@alias feather.mirrord.message.id number

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
	local path = contents.packageName:gsub('%.', "/")
	local struct = storage.encode(fs.combine(feather.installPath(), path))
	answer.contents.entry = struct
	rednet.send(sender, answer, protocol)
end




featherd.log("Initiating mirrord")
while true do
	local sender, message = rednet.receive(protocol) ---@diagnostic disable-line
	assert(sender and type(message) == "table")
	if message.request_type == "bundleGet" then
		featherd.log(message)
		handleRequest(sender, message --[[@as feather.mirrord.message.bundle.get]])
	end
end
