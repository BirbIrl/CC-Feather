local version = "0.1"

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
	write("FeatherOS")
	term.setTextColor(colors.white)
	print(", a CraftOS distro.")
	describeArg("install", "adds FeatherOS to the top of the startup.lua file")
	describeArg("startup", "don't run this manually, the startup file calls this on boot and sets up the environment")
end

local function bundle(path)
	local oldPath = package.path
	package.path = package.path .. ";/.feather/lib/?/init.lua"
	local module = require(path)
	package.path = oldPath
	return module
end

local feather = {}

function feather.getVersion()
	return "FeatherOS " .. version
end

function feather.path()
	return fs.getDir(fs.getDir(debug.getinfo(1).source:sub(2, -1))) -- yep.
end

local argument = ...
if argument == "install" then
	local startupPath = "startup.lua"
	local startup
	if not fs.exists(startupPath) or fs.isDir(startupPath) then
		startup = assert(fs.open(startupPath, "w+"))
	else
		startup = assert(fs.open(startupPath, "r+"))
	end
	local snippet = 'shell.run(".feather/bin/featherOS", "startup") --don\'t touch'
	local line = startup.readLine()
	if line ~= snippet then
		startup.seek("set")
		local all = startup.readAll()
		startup.seek("set")
		startup.write(snippet .. "\n" .. all)
		startup.close()
		settings.set("motd.enable", false)
		settings.set("list.show_hidden", true)
		settings.save()
		os.reboot()
	end
	startup.close()
	term.setTextColor(colors.red)
	print("featherOS already installed.")
elseif argument == "startup" then
	_G.os.version = feather.getVersion
	_G.feather = feather
	_G.bundle = bundle
	shell.setPath(shell.path() .. ":.feather/bin")
	term.setCursorPos(1, 1)
	term.clear()
	term.setTextColor(colors.yellow)
	print(feather.getVersion())
	term.setTextColor(colors.white)
	write("Computer ID: ")
	term.setTextColor(colors.yellow)
	write(tostring(os.getComputerID()))

	local label = os.getComputerLabel()
	if label then
		term.setTextColor(colors.white)
		write(' - "')
		term.setTextColor(colors.yellow)
		write(label)
		term.setTextColor(colors.white)
		write('"')
	end

	print()
elseif argument == nil then
	help()
end
