--opens program in multishell and allows stopping it with an event
--
--should refactor this into just runner, but have a --headless arg

local programName = ...
local args = table.pack(select(2, ...))

assert(programName, "No program provided.")
assert(shell.resolveProgram(programName), "Program: \"" .. programName .. "\" not valid.")


local pid = shell.openTab("runner-headless", programName, table.unpack(args))
multishell.setTitle(pid, programName)

select(2, debug.getupvalue(multishell.getCount, 1))[pid].bInteracted = true
