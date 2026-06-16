local storage = bundl "feather.storage" ---@type feather.storage

---@class feather.bundle.rockspec
---@field rockspec_format "3.0" -- bundle uses the 3.0 format of luarocks
---@field package string -- unique package name
---@field version string -- version of package
---@field description feather.bundle.rockspec.description -- additional package information
---@field source feather.bundle.rockspec.source -- additional information as to where to find the package
---@field build feather.bundle.rockspec.build -- build information
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

---@alias feather.bundle.packageTable table<string, feather.bundle.rockspec>

local function getMirrorID()
	local mirrorID = settings.get("feather.bundle.mirrorID")
	assert(mirrorID,
		"ID of the mirror computer must be set, use \"set feather.bundle.mirrorID [mirror computer id]\" first.")
	assert(mirrorID ~= os.getComputerID(), "mirror id equals this computer's id. Aborting.")
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
---@return table<string, true>, table<string, true>
function module.listIncompleteDependencies(rockspec)
	local missing = {}
	local needsUpdate = {}
	if not next(rockspec.dependencies) then
		return missing, needsUpdate
	end
	local installed = module.listInstalled()
	local available = module.listAvailable()
	for _, dependencyName in pairs(rockspec.dependencies) do
		if not installed[dependencyName] then
			missing[dependencyName] = true
		elseif rockspec.version == "unstable" or available[dependencyName].version == "unstable" then
			needsUpdate[dependencyName] = true
		end
	end
	return missing, needsUpdate
end

---@return feather.bundle.packageTable
function module.listInstalled()
	local packages = {}
	local installPath = feather.installPath
	for _, typePath in pairs({ "lib", "bin" }) do
		typePath = fs.combine(installPath, typePath)
		for _, manifestName in ipairs(fs.list(typePath)) do
			local manifestPath = fs.combine(typePath, manifestName)
			for _, packageName in ipairs(fs.list(manifestPath)) do
				local rockspec = loadRockspec(fs.combine(manifestPath, packageName, ".rockspec"))
				if rockspec then
					packages[rockspec.package] = rockspec
				end
			end
		end
	end
	return packages
end

---@return feather.bundle.packageTable
function module.listAvailable()
	peripheral.find("modem", rednet.open)
	assert(rednet.isOpen(), "Must have connected modem")
	---@type feather.mirrord.message.bundle.list.get
	local request = {
		request_type = "bundleListGet",
		id = math.random(),
		time = os.time("local"),
		contents = {}
	}
	rednet.send(getMirrorID(), request, protocol)
	local id, message
	repeat
		---@type number?, feather.mirrord.message.bundle.list.post
		id, message = rednet.receive(protocol, 1)
		assert(id, "Couldn't list packages, the mirror might be down.")
	until id == getMirrorID() and message and message.respondsTo == request.id
	return message.contents
end

---@param pkgName string
---@return feather.bundle.rockspec?
function module.get(pkgName)
	local pkgPath = pkgName:gsub("%.", "/")
	return loadRockspec(fs.combine(feather.installPath, pkgPath, ".rockspec"))
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
		---@type number?, feather.mirrord.message.bundle.post|feather.mirrord.message.bundle.failToFind
		id, message = rednet.receive(protocol, 1)
		assert(id, "Couldn't install " .. pkgName .. ", the mirror might be down.")
	until id == getMirrorID() and message and message.respondsTo == request.id
	if message.request_type == "bundleFailToFind" then
		error("Couldn't find package in path: " .. pkgName)
	end
	storage.decode(message.contents.entry)
	feather.updatePath()
	return true
end

return module
