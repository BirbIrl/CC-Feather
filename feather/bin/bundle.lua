--CC-Feather module info, only runs on require()
do
	local args = table.pack(...)
	if #args == 2 and type(package.loaded[args[1]]) == "table" and next(package.loaded[args[1]]) == nil then
		return {
			_bundle = {
				depends_on = {
					{
						module = "feather.lib.bundle",
					},
				},
			}
		}
	end
end

local bundlePath = "/" .. fs.getDir(shell.getRunningProgram())
local featherPath = "/" .. fs.getDir(bundlePath)
if not _MODULE_PATHS then
	assert(fs.getName(bundlePath) == "bin", "bundle.lua must be put in a valid [bundle]/bin directory")
	_MODULE_PATHS = _MODULE_PATHS or { featherPath }
end
---@return feather.lib.bundle
local function getBundle()
	local bundle = _G.Bundle
	return assert(bundle, "Bundler must be loaded as a global, use bundle init")
end


local function joinTables(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end


---@param branch feather.lib.bundle.branch
local function getModuleType(branch)
	local path = ""
	while rawget(branch, "_up") do
		path = "." .. branch._key .. path
		branch = branch._up --[[@as feather.lib.bundle.branch]]
	end
	return path:sub(2)
end

--TODO: this is a hot mess, instead load all modules recursively and use the new _paths field to generate docs
--maybe rethink this altogether lol

---@param bundle feather.lib.bundle
---@param modulePath string
local function definitionsLoader(bundle, modulePath)
	local definitions = {}
	for _, entry in ipairs(fs.list(modulePath)) do
		local branch = bundle[entry] --[[@as feather.lib.bundle.branch]]
		if fs.isDir(entry) then
			joinTables(
				definitions,
				definitionsLoader(branch,
					modulePath .. "/" .. entry
				)
			)
		else
			definitions[#definitions + 1] = getModuleType(branch)
		end
	end
	return definitions
end



local function loadDefinitions(bundle, targetPath)
	local definitions = definitionsLoader(bundle,
		targetPath .. "/lib"
	)
	term.setTextColor(colors.yellow)
	print("Loaded " .. #definitions .. " modules for " .. fs.getName(targetPath))
	term.setTextColor(colors.white)
	return definitions
end

local function loadAllDefinitions(bundle)
	local total = 0
	for _, modulePath in ipairs(_MODULE_PATHS) do
		total = total + #loadDefinitions(bundle, modulePath)
	end
	term.setTextColor(colors.yellow)
	print("Loaded a total of " .. total .. "modules")
	term.setTextColor(colors.white)
end
local function validateModulePath(targetPath)
	assert(fs.isDir(targetPath), "Path: \"" .. targetPath .. "\" must be a valid directory")
	local libPath = fs.combine(targetPath, "lib")
	assert(fs.isDir(libPath), "module \"" .. targetPath .. "\" invalid, must contain a \"lib\" folder")
	local etcPath = fs.combine(targetPath, "etc")
	assert(fs.isDir(etcPath), "module \"" .. targetPath .. "\" invalid, must contain an \"etc\" folder")
end

if ... == "init" then
	for _, modulePath in ipairs(_MODULE_PATHS) do
		shell.setPath(shell.path() .. ":" .. modulePath .. "/bin")
	end
	_G.package = _ENV.package;
	_G.Bundle = loadfile("/" .. fs.combine(featherPath, "lib/bundle.lua"))()
elseif ... == "loadAll" then
	loadAllDefinitions(getBundle(), targetPath)
elseif ... == "generateDocs" then
	local targetPath = fs.combine(shell.dir(), (select(2, ...) or "."))
	validateModulePath(targetPath)
	term.setTextColor(colors.yellow)
	print("Generating docs for all currently loaded modules")
	term.setTextColor(colors.white)
	loadAllDefinitions(getBundle(), targetPath)
else
	local cmd = arg[0] .. " "
	term.setTextColor(colors.lightGray)
	print("Usages:")
	term.setTextColor(colors.yellow)
	print(cmd .. "init")
	term.setTextColor(colors.lightGray)
	print("loads bundle as a global variable")
	term.setTextColor(colors.yellow)
	print(cmd .. "generateDocs [path]")
	term.setTextColor(colors.lightGray)
	print("generates lua-ls docs for module in [path]")
	term.setTextColor(colors.white)
end
