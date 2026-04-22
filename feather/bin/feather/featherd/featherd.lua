local featherd = bundl "feather.featherd" ---@type feather.featherd
local pretty = require("cc.pretty")

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
	write("Featherd")
	term.setTextColor(colors.white)
	print(", a FeatherOS process manager.")
	describeArg("list", "lists all processes")
	describeArg("clearLogs", "deletes all logs")
	describeArg("thisLog", "opens the current log file")
	describeArg("lastLog", "opens last boot's log file")
	describeArg("status [name]", "gets the status of a named process")
end


local mode, proc = ...
if mode == "list" then
	pretty.pretty_print(featherd.processesByPid)
else
	help()
end
