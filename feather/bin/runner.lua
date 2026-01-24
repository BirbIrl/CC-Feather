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
	write("Runner")
	term.setTextColor(colors.white)
	print(
		", a FeatherOS utility for running programs in a parllel. It allows terminating the new program with an event.")
	describeArg("[program], [args]...",
		"starts up [program] in a new tab with the given args")
	describeArg("headless [program], [args]...", "starts up [program] in the current shell")
end
local headless, programName = ...
if headless == "headless" then
	local args = table.pack(select(3, ...))

	assert(programName, "No program provided.")
	assert(shell.resolveProgram(programName), "Program: \"" .. programName .. "\" not valid.")
	local function eventWatcher()
		os.pullEvent("featherRunnerTerminate:" .. programName)
	end

	local function executor()
		shell.execute(programName, table.unpack(args))
	end

	parallel.waitForAny(executor, eventWatcher)
elseif headless then
	programName = headless
	local args = table.pack(select(2, ...))

	assert(programName, "No program provided.")
	assert(shell.resolveProgram(programName), "Program: \"" .. programName .. "\" not valid.")

	local pid = shell.openTab("runner", "headless", programName, table.unpack(args))
	multishell.setTitle(pid, programName)

	select(2, debug.getupvalue(multishell.getCount, 1))[pid].bInteracted = true
else
	help()
end
