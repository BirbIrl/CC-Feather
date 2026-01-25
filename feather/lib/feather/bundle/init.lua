local storage = bundl "feather.storage" ---@type feather.storage

---@class feather.bundle.rockspec
---@field rockspec_format "3.0" -- bundle uses the 3.0 format of luarocks
---@field package string -- unique package name
---@field version string -- version of package
---@field description feather.bundle.rockspec.description -- additional package information
---@field source feather.bundle.rockspec.source -- additional information as to where to find the package
---@field build feather.bundle.rockspec.build
---@field dependencies string[] -- list of dependent packages by name

---@class feather.bundle.rockspec.description
---@field summary string -- short summary
---@field detailed string -- detailed description
---@field labels string[] -- list of tags
---@field homepage string -- link to website related to package
---@field license string -- license

---@class feather.bundle.rockspec.source
---@field url string -- link to the .git file
---@field dir string -- path where package is saved

---@class feather.bundle.rockspec.build
---@field type "lib"|"bin" -- indicates whether the package is a library or binary



local function getMirrorID()
	local mirrorID = settings.get("feather.bundle.mirrorID")
	assert(mirrorID,
		"ID of the mirror computer must be set, use \"set feather.bundle.mirrorID [mirror computer id]\" first.")
	return mirrorID
end

---@class feather.bundle
local module = {}
local protocol = "feather.mirrord"

---@param path string -- path, with no "/" at the start. It's added automatically
---@return feather.bundle.rockspec?
local function loadRockspec(path)
	local config = {}
	local rockspec = loadfile("/" .. path, nil, config)
	if not rockspec then
		return
	end
	rockspec()
	return config
end

---@param rockspec feather.bundle.rockspec
---@param list? feather.bundle.rockspec[] -- optionally list cached list of installed packages to prevent re-checking
---@return string[] -- names of missing dependencies
local function listMissingDependencies(rockspec, list)

end


---@return feather.bundle.rockspec[]
function module.listInstalled()
	local packages = {}
	local libPath = fs.combine(feather.installPath(), "lib")
	for _, manifestName in ipairs(fs.list(libPath)) do
		local manifestPath = fs.combine(libPath, manifestName)
		for _, packageName in ipairs(fs.list(manifestPath)) do
			local rockspec = loadRockspec(fs.combine(manifestPath, packageName, ".rockspec"))
			packages[#packages + 1] = rockspec
		end
	end
	local binPath = fs.combine(feather.installPath(), "bin")
	for _, packageName in ipairs(fs.list(binPath)) do
		local rockspec = loadRockspec(fs.combine(binPath, packageName, ".rockspec"))
		packages[#packages + 1] = rockspec
	end
	return packages
end

---@param pkgName string
function module.install(pkgName)
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
	storage.decode(message.contents.entry)
	feather.updatePath()
	return true
end

return module
