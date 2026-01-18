--runs program and allows stopping it with an event

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
