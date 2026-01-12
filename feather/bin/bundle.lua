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

local path = shell.getRunningProgram():match("(.*/)")
if not _BUNDLE_PATHS then
	assert(path:sub(-4, -2) == "bin", "bundle.lua must be put in a valid [bundle]/bin directory")
	_BUNDLE_PATHS = _BUNDLE_PATHS or { path .. ".." }
end


if ... == "init" then
	for _, bundlePath in ipairs(_BUNDLE_PATHS) do
		shell.setPath(shell.path() .. ":" .. bundlePath .. "/bin")
	end
	_G.package = _ENV.package;
	_G.Bundle = loadfile(path .. "../lib/bundle.lua")()
end
