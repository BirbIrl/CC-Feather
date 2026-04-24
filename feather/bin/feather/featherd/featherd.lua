local featherd = bundl "feather.featherd" ---@type feather.featherd
local expect = require("cc.expect").expect
local c = colors

local function describeArg(argument, desc)
	term.setTextColor(colors.gray)
	write(arg[0] .. " ")
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
	--describeArg("status [name]", "gets the status of a named process")
	describeArg("listUnits", "lists all units")
	describeArg("addUnit", "add a unit")
	describeArg("delUnit", "delete a unit")
	--describeArg("delLogs", "deletes all logs")
	--describeArg("currLog", "opens the current log file")
	--describeArg("lastLog", "opens last boot's log file")
end


local mode, name = ...
if mode == "list" then
	for pid, process in pairs(featherd.processesByPid) do
		term.setTextColor(c.yellow)
		term.write(process.name)
		term.setTextColor(c.white)
		term.write(" [" .. pid .. "]: ")
		local status = coroutine.status(process.thread)
		if status == "dead" then
			term.setTextColor(c.red)
			print("Dead")
		elseif status == "normal" then
			term.setTextColor(c.green)
			print("Running")
		else
			print("In background")
		end
	end
elseif mode == "listUnits" then
	for name, _ in pairs(featherd.units) do
		term.setTextColor(c.yellow)
		term.write(name)
		term.setTextColor(c.white)
		local process = featherd.processesByName[name] and featherd.processesByName[name][1]
		if not process then
			term.write(": ")
			term.setTextColor(c.red)
			print("Lost")
			goto continue
		end
		term.write(" [" .. process.pid .. "]: ")
		local status = coroutine.status(process.thread)
		if status == "dead" then
			term.setTextColor(c.red)
			print("Dead")
		elseif status == "normal" then
			term.setTextColor(c.green)
			print("Running")
		else
			print("In background")
		end
		::continue::
	end
elseif mode == "addUnit" then
	expect(2, name, "string")
	---@type string
	local command = arg[3]
	expect(3, command, "string")
	---@type featherd.featherd.process.onDeath
	local onDeath = arg[4]
	assert(onDeath == nil or onDeath == "keep" or onDeath == "restart" or onDeath == "discard",
		'onDeath must either be "keep", "restart", "discard" or not specified')
	featherd.addUnit(name, command, onDeath or "keep")
	term.setTextColor(colors.green)
	print("Success!")
elseif mode == "delUnit" then
	assert(name, "Must provide a name")
	if featherd.removeUnit(name) then
		term.setTextColor(colors.green)
		print("Success!")
	else
		term.setTextColor(colors.red)
		print("Couldn't find the unit")
	end
else
	help()
end
