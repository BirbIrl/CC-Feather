---Bundler allows you to load libraries accross _ENV's
---this is jak, dont use it
---@class feather.lib.bundle
local module = {
	_bundle = {
		mutable = true
	},
}

local path_separator = "/" -- at worst it'll unix it's way
if package and package.config then
	path_separator = package.config:sub(1, 1)
end

local paths = { "/?.lua" } -- todo: support custom paths

local function findProgram(modulePath)
	for _, path in pairs(paths) do
		local keyPos = path:find("?")                -- support \?
		local filled = path:sub(1, keyPos - 1) .. modulePath .. path:sub(keyPos + 1)
		if fs.exists(filled) and not fs.isDir(filled) then --TODO: fs is cc only
			return filled
		end
	end
end


---@param branch feather.lib.bundle.branch
local function getPath(branch)
	local path = ""
	while rawget(branch, "_up") do
		path = path_separator .. branch._key .. path
		branch = branch._up --[[@as feather.lib.bundle.branch]]
	end
	return path:sub(2)
end

local meta = {}

function meta:__index(moduleName)
	---@class feather.lib.bundle.branch: feather.lib.bundle
	---@field _key string
	---@field _up feather.lib.bundle.branch|feather.lib.bundle
	---@field _paths table<string, string>
	local branch = {
		_up = self,
		_key = moduleName,
		_paths = {},
	}
	if moduleName:find(path_separator) then
		error("don't use \"" .. path_separator .. "\" in paths, use . instead like so: Bundle.path.to.file")
	end
	self[moduleName] = setmetatable(branch, meta)
	local path = findProgram(getPath(branch))
	if path then
		self[moduleName] = dofile(path)
		self._paths[moduleName] = path --TODO: this breaks with relative paths
	end
	return self[moduleName]
end

return setmetatable(module, meta)
