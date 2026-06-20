local argh = bundl "feather.argh" ---@type feather.argh

local programPath = fs.combine(feather.installPath, "bin/feather/flash/flash.lua")
local args = argh.parse(programPath, "flash", "a tool for installing featheros on other systems.",
	{
		flags = {
			force = { short = "f", description = "doesn't prompt to confirm" },
		},
		description = "installs FeatherOS to an attached disk if provided.",
		sufficient = true,
		next = {
			{
				name = "installPath",
				description = "path to install featheros in",
				argument = argh.argument.dir,
			},
			{
				name = "help",
				description = "shows this help menu",
				argument = argh.argument.name,
			},
		}
	}, ...)


local function deserialiseFile(path)
	local file = fs.open(path, "r")
	if not file then
		return {}
	end
	local result = textutils.unserialise(file.readAll() or "{}")
	assert(type(result) == "table", "Couldn't parse existing .settings file!")
	return result
end

---@param path string
local function install(path)
	local mountPath = assert(path)
	local mirrorID = settings.get("feather.bundle.mirrorID", os.getComputerID())
	local paths = {
		".feather/bin/feather/featherOS",
		".feather/bin/feather/bundle",
		".feather/lib/feather/bundle",
		".feather/lib/feather/featherd",
		".feather/bin/feather/featherd",
		".feather/lib/feather/tty",
		".feather/lib/feather/vec2d",
		".feather/lib/feather/mush",
		".feather/bin/feather/mush",
		".feather/lib/feather/storage",
		".feather/lib/feather/argh",
		".feather/lib/feather/petty",
		".feather/lib/feather/mess"
	}
	for _, packagePath in ipairs(paths) do
		local combined = fs.combine(mountPath, packagePath)
		if fs.exists(combined) then
			fs.delete(combined)
		end
		fs.copy(packagePath, combined)
	end

	shell.execute("featherOS", "install", fs.combine(mountPath, "startup.lua"))
	local settingsFilePath = fs.combine(mountPath, ".settings")
	local settings = deserialiseFile(settingsFilePath)
	settings["feather.bundle.mirrorID"] = mirrorID
	settings["bios.use_multishell"] = false
	local settingsFile = assert(fs.open(settingsFilePath, "w"), "couldn't open file")
	settingsFile.write(textutils.serialise(settings))
	settingsFile.close()
end

if args[2] and args[2].name == "help" then
	argh.help(programPath)
	return
end

local force = args[1].flags.force


---@type ccTweaked.peripheral.Drive[]
local drives = table.pack(peripheral.find("drive"))
---@type string?
local path = args[2] and args[2].argument
if drives[1] then
	assert(#drives == 1, "There must be exactly one disk drive connected or a path provided. Found " .. #drives)
	if not path then
		path = drives[1].getMountPath()
	end
end

assert(path, "Path must be provided or a disk drive must be attached.")

assert(fs.exists(path), "Given path doesn't exist: " .. path)

if force then
	install(path)
	return
end
print()
print("Do you wish to install FeatherOS at /" .. path .. " ? Y/n")
repeat
	local _, result = os.pullEvent("key")
	sleep(0.05)
	if result == keys.n then
		return
	end
until result == keys.y or result == keys.enter
install(path)
