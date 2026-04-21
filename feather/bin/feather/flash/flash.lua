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
	print(", installs FeatherOS onto another machine.")
	describeArg("force", "doesn't prompt to confirm")
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

---@param drive ccTweaked.peripheral.Drive
local function install(drive)
	local mountPath = assert(drive.getMountPath())
	local mirrorID = settings.get("feather.bundle.mirrorID", os.getComputerID())
	local paths = {
		".feather/bin/feather/featherOS",
		".feather/bin/feather/bundle",
		".feather/lib/feather/bundle",
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
	local settingsFile = assert(fs.open(settingsFilePath, "w"), "couldn't open file")
	settingsFile.write(textutils.serialise(settings))
	settingsFile.close()
end

local force = ... == "force"


---@type ccTweaked.peripheral.Drive[]
local drives = table.pack(peripheral.find("drive"))
assert(#drives == 1, "There must be exactly one disk drive connected. Found " .. #drives)

if force then
	install(drives[1])
	return
end
help()
print()
print("Do you wish to install FeatherOS to the attached computer? Y/n")
repeat
	local _, result = os.pullEvent("key")
	sleep(0.05)
	if result == keys.n then
		return
	end
until result == keys.y or result == keys.enter
install(drives[1])
