--opens program in multishell and allows stopping it with an event

--CC-Feather module info, only runs on require()
do
	local args = table.pack(...)
	if #args == 2 and type(package.loaded[args[1]]) == "table" and next(package.loaded[args[1]]) == nil then
		return {
			_bundle = {
				depends_on = {
					{
						module = "feather.bin.runner-headless",
					},
				},
			}
		}
	end
end

local programName = ...
local args = table.pack(select(2, ...))

assert(programName, "No program provided.")
assert(shell.resolveProgram(programName), "Program: \"" .. programName .. "\" not valid.")


local pid = shell.openTab("runner-headless", programName, table.unpack(args))
multishell.setTitle(pid, programName)

select(2, debug.getupvalue(multishell.getCount, 1))[pid].bInteracted = true
