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
	describeArg("install [customInstallPath?]",
		"adds FeatherOS to the top of the startup.lua file, path can be overriden with customPath, which will also prevent the auto-restart.")
	describeArg("startup", "don't run this manually, the startup file calls this on boot and sets up the environment")
end

local function bundl(path)
	local oldPath = package.path
	package.path = package.path .. ";/.feather/lib/?/init.lua" .. ";/.feather/lib/?.lua"
	local module = require(path)
	package.path = oldPath
	return module
end

---@class feather.featherOS.featherGlobal
local feather = {}


function feather.getVersion()
	return "FeatherOS " .. version
end

-- path of the current feather installation
function feather.installPath()
	return fs.getDir(fs.getDir(fs.getDir(fs.getDir(debug.getinfo(1).source:sub(2, -1))))) -- yep.
end

local staticPath = shell.path()

--- allows adding entries to the PATH without it getting overriden
function feather.addToPath(path)
	staticPath = staticPath .. ":" .. path
	feather.updatePath()
end

function feather.updatePath()
	shell.setPath(staticPath)

	local binPath = fs.combine(feather.installPath(), "bin")
	for _, manifest in ipairs(fs.list(binPath)) do
		local manifestPath = fs.combine(binPath, manifest)
		for _, entry in ipairs(fs.list(manifestPath)) do
			local programPath = fs.combine(manifestPath, entry)
			if fs.isDir(programPath) then
				shell.setPath(shell.path() .. ":/" .. programPath)
			end
		end
	end
end

local argument, customPath = ...
if argument == "install" then
	local startupPath = customPath or "startup.lua"
	local startup
	if not fs.exists(startupPath) or fs.isDir(startupPath) then
		startup = assert(fs.open(startupPath, "w+"))
	else
		startup = assert(fs.open(startupPath, "r+"))
	end
	local snippet = 'shell.run(".feather/bin/feather/featherOS/featherOS", "startup") --don\'t touch'
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
		if not customPath then
			os.reboot()
		end
	else
		startup.close()
		term.setTextColor(colors.red)
		print("featherOS already installed.")
	end
elseif argument == "startup" then
	_G.os.version = feather.getVersion
	_G.feather = feather
	_G.bundl = bundl
	feather.updatePath()
	local featherd = bundl("feather.featherd") --[[@as feather.featherd]]
	featherd.init()
	os.shutdown()
elseif argument == nil then
	help()
end
