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
	write("Flash")
	term.setTextColor(colors.white)
	print(" installs FeatherOS onto another machine.")
	describeArg("", "installs featheros to computer or disk in drive")
	describeArg("force", "doesn't prompt to confirm")
	describeArg("[path]", "installs featheros to given path")
	describeArg("[path] force", "doesn't prompt to confirm")
end

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
		".feather/lib/feather/windex",
		".feather/lib/feather/tty",
		".feather/lib/feather/vec2d",
		".feather/lib/feather/mush",
		".feather/bin/feather/mush",
		".feather/lib/feather/storage"
	}
	for _, path in ipairs(paths) do
		local combined = fs.combine(mountPath, path)
		if fs.exists(combined) then
			fs.delete(combined)
		end
		fs.copy(path, combined)
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

help()

local force = ... == "force"
if select(2, ...) then
	force = select(2, ...) == force
end


---@type ccTweaked.peripheral.Drive[]
local drives = table.pack(peripheral.find("drive"))
local path = ...
if drives[1] then
	assert(#drives == 1, "There must be exactly one disk drive connected or a path provided. Found " .. #drives)
	if not path then
		path = drives[1].getMountPath()
	end
end
assert(path, "Path must be provided")

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
