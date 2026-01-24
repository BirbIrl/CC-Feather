local storage = bundle "feather.storage" ---@type feather.storage
local pp = require("cc.pretty").pretty_print

local protocol = "feather.mirrord"

local function getMirrorID()
	local mirrorID = settings.get("feather.bundle.mirrorID")
	assert(mirrorID,
		"ID of the mirror computer must be set, use \"set feather.bundle.mirrorID [mirror computer id]\" first.")
	return mirrorID
end

local function describeArg(argument, desc)
	term.setTextColor(colors.gray)
	write("\n" .. arg[0] .. " ")
	term.setTextColor(colors.yellow)
	write(argument)
	term.setTextColor(colors.white)
	print(" - " .. desc)
end
local function help()
	term.setTextColor(colors.yellow)
	write("Bundle")
	term.setTextColor(colors.white)
	print(", a FeatherOS package manager.")
	describeArg("get [pkg]", "gets a libary package from the mirror")
	describeArg("remove [pkg]", "removes a local library package")
	describeArg("install [pkg]", "installs a program from the mirror")
	describeArg("uninstall [pkg]", "uninstalls a local program")
end

---@param pkgName string
---@param pkgType "lib"|"bin"
local function install(pkgName, pkgType)
	assert(type(pkgName) == "string")
	local mirrorID = getMirrorID()
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
	rednet.send(mirrorID, request, protocol)
	local id, message
	repeat
		---@type number?, feather.mirrord.message.bundle.post
		id, message = rednet.receive(protocol) ---@diagnostic disable-line: assign-type-mismatch
		pp(message)
	until id == mirrorID and message and message.respondsTo == request.id
	storage.decode(message.contents.entry)
	print("Fetched " .. pkgName .. " successfuly")
end


local mode, pkgName = ...
if mode == "get" then
	install(pkgName, "lib")
elseif mode == "remove" then
elseif mode == "install" then
	install(pkgName, "bin")
elseif mode == "uninstall" then
else
	help()
end
peripheral.find("modem", rednet.open)
