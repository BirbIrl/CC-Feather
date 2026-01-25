local storage = bundle "feather.storage" ---@type feather.storage

local function getMirrorID()
	local mirrorID = settings.get("feather.bundle.mirrorID")
	assert(mirrorID,
		"ID of the mirror computer must be set, use \"set feather.bundle.mirrorID [mirror computer id]\" first.")
	return mirrorID
end

---@class feather.bundleUtil
local module = {}
local protocol = "feather.mirrord"

--TODO implement this
function module.list()
	local lib = {}
	for index, value in ipairs(t) do

	end
	local bin = {}
	return { lib = lib, bin = bin }
end

---@param pkgName string
---@param pkgType "lib"|"bin"
function module.install(pkgName, pkgType)
	assert(type(pkgName) == "string")
	peripheral.find("modem", rednet.open)
	assert(rednet.isOpen(), "Must have connected modem")
	---@type feather.mirrord.message.bundle.get
	local request = {
		request_type = "bundleGet",
		id = math.random(),
		time = os.time("local"),
		contents = {
			packageName = pkgName,
			packageType = pkgType
		}
	}
	rednet.send(getMirrorID(), request, protocol)
	local id, message
	repeat
		---@type number?, feather.mirrord.message.bundle.post
		id, message = rednet.receive(protocol, 5) ---@diagnostic disable-line: assign-type-mismatch
		if not id then
			return false
		end
	until id == getMirrorID() and message and message.respondsTo == request.id
	storage.decode(message.contents.entry, feather.installPath())
	return true
end

return module
