--runs program and allows stopping it with an event

--CC-Feather module info, only runs on require()
do
	local args = table.pack(...)
	if #args == 2 and type(package.loaded[args[1]]) == "table" and next(package.loaded[args[1]]) == nil then
		return {
			_bundle = {
			}
		}
	end
end

---@type string
local programName = ...
local args = table.pack(select(2, ...))

assert(programName, "No program provided.")
assert(shell.resolveProgram(programName), "Program: \"" .. programName .. "\" not valid.")
local function eventWatcher()
	os.pullEvent("featherRunnerTerminate:" .. programName)
end

local function executor()
	shell.execute(programName, table.unpack(args))
end

parallel.waitForAny(executor, eventWatcher)
