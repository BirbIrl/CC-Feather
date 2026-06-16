--- TODO: handle empty log so it wont crash
--- TODO: handle comfort screens so it doesn't drop it
local exception = require("cc.internal.exception")
---@class feather.featherd
local module = {}
module.locked = false
---@type feather.featherd.process[]
module.processesByPid = {}
---@type table<thread,feather.featherd.process>
module.processesByThread = {}
---@type table<string,feather.featherd.process[]|{locked: true}>
module.processesByName = {}

module.journal = {}
---@diagnostic disable-next-line
module.currentLogPath = ".feather/share/featherd/logs/" .. os.date("%Y-%m-%d-%T"):gsub(":", ".") .. ".txt"
local logfile = fs.open(module.currentLogPath, "w")
assert(logfile, "Couldn't open a file to save the log in")


---@alias feather.featherd.journalEntry.level "error"|"warning"|"log"
---@alias feather.featherd.process.onDeath "keep"|"restart"|"discard"
---
---@class feather.featherd.journalEntry
---@field level feather.featherd.journalEntry.level
---@field message ccTweaked.cc.pretty.Doc
---@field name string
---@field pid integer

local nextPid = 1



---A featherd unit is a configured program that will run once the pc loads, and will be kept track of.
---the name of the program is defined in the key of the featherd units table
---units use exclusive names always
---@class feather.featherd.unit
---@field command string
---@field onDeath feather.featherd.process.onDeath?
---@field useShell boolean?

---@type table<string,feather.featherd.unit>
module.units = settings.get("feather.featherd.units", {})

--- initializes featherd in it's full. should only be called by featherOS startup
function module.init()
	assert(not module.locked, "featherd is already running!")
	local mush = bundl "feather.mush" ---@type feather.mush
	mush.init()
	local argh = bundl "feather.argh" ---@type feather.argh
	argh.init()
	module.loadUnits()
	module.runProcesses()
	os.shutdown()
end

function module.loadUnits()
	for name, unit in pairs(module.units) do
		module.addProcess(name, unit.command, unit.onDeath, true)
	end
end

---@param name string name of the unit you want to define
---@param command string command ran to start the unit
---@param onDeath feather.featherd.process.onDeath thing to do when program dies/finishes
---@param useShell? boolean whether it should run with os.run or shell.run
function module.addUnit(name, command, onDeath, useShell)
	module.units[name] = { command = command, onDeath = onDeath or "keep", useShell = useShell }
	settings.set("feather.featherd.units", module.units)
	settings.save()
end

---Removes a unit from the config and saves it. returns true if it actually had to remove anything.
---@param name string name of unit you want to remove
---@return boolean
function module.removeUnit(name)
	if not module.units[name] then
		return false
	end
	module.units[name] = nil
	settings.set("feather.featherd.units", module.units)
	settings.save()
	return true
end

local inputEvents = {
	key = true,
	key_up = true,
	char = true,
	mouse_click = true,
	mouse_drag = true,
	mouse_scroll = true,
	mouse_up = true,
	paste = true,
	file_transfer = true,
}


---Cycles through featherd processes to run them. Should only ever be ran once, and never touched
function module.runProcesses()
	assert(not module.locked, "featherd is already running!")
	module.locked = true
	local event = { n = 0 }
	---@type feather.featherd.process[]
	while true do
		if not module.processesByPid[1] then
			break
		end
		---@type feather.featherd.process[]
		local toRestart = {}
		---@type ccTweaked.os.event
		local eventType = event[1]
		for pid, process in pairs(module.processesByPid) do
			local lastWindow
			local status = coroutine.status(process.thread)
			if status ~= "dead" and (process.filter == nil or process.filter == eventType) then
				if eventType == "terminate" and process.inputType ~= true then
					goto continue
				end
				if process.window then
					lastWindow = term.redirect(process.window)
					if process.window.isVisible() and process.inputType == true then
						process.window.restoreCursor()
					end
				end
				local tweakedEvent = event
				if inputEvents[eventType] and not process.inputType then
					goto continue
				end
				if process.window and process.window.getPosition and eventType and eventType:sub(1, 5) == "mouse" then
					local windowX, windowY = process.window.getPosition()
					tweakedEvent = {
						event[1],
						event[2],
						event[3] - windowX + 1,
						event[4] - windowY + 1,
					}
					if tweakedEvent[3] <= 0 or tweakedEvent[4] <= 0 then
						goto continue
					end
				end
				local ok, param = coroutine.resume(process.thread, table.unpack(tweakedEvent, 1, tweakedEvent.n))
				if process.window and process.window ~= term.current() then
					process.window = term.current()
				end


				if ok then
					process.filter = param
				elseif type(param) == "string" and exception and exception.can_wrap_errors and exception.can_wrap_errors() then
					module.log(exception.make_exception(param, process.thread), "error", pid)
				else
					module.log(param, "error", pid)
				end
			elseif coroutine.status(process.thread) == "dead" then
				if process.onDeath ~= "keep" then
					module.processesByPid[pid] = nil
					module.processesByThread[process.thread] = nil
					for i, candidate in ipairs(module.processesByName[process.name]) do
						if process == candidate then
							table.remove(module.processesByName[process.name], i)
							break
						end
					end
				end
				if process.onDeath == "restart" then
					toRestart[#toRestart + 1] = process
				end
			end
			if lastWindow then
				term.redirect(lastWindow)
			end
			::continue::
		end
		for _, process in ipairs(toRestart) do
			module.processesByName[process.name].locked = nil
			module.addProcess(process.name, process.fun, process.onDeath)
			os.queueEvent("feather.featherd.restarted", process)
		end
		event = table.pack(os.pullEventRaw())
	end
end

---@class feather.featherd.process
---@field startTime number
---@field name string
---@field filter? string used by the coroutine loop to filter out the event the process generates. don't modify.
---@field thread thread
---@field fun function
---@field pid integer
---@field window? Window|ccTweaked.term.Redirect
---@field inputType "silent"|boolean
---@field onDeath feather.featherd.process.onDeath

---@param name string name of the process
---@param fun function|thread|string function the process should run with, string the process should run as command or thread
---@param onDeath? feather.featherd.process.onDeath what to do with the process once it ends
---@param exclusive? boolean when true, featherd wont allow making more than one living process under this name
---@param window? Window if supplied, the window will be in focus whenever the window coroutine is running. mouse events are offset to match the window.
---@param inputType? "silent"|boolean whether the process should read inputs. silent will disable the cursor blink for it's window and ignores terminate events
---@return feather.featherd.process process
function module.addProcess(name, fun, onDeath, exclusive, window, inputType)
	module.processesByName[name] = module.processesByName[name] or {}
	if (exclusive and module.processesByName[name][1]) or module.processesByName[name].locked then
		error("Cannot create another exclusive process, it's already taken")
	end
	if exclusive then
		module.processesByName[name].locked = true
	end
	local pid = nextPid
	local process = {
		startTime = os.time("local"),
		pid = pid,
		name = name,
		fun = fun,
		exclusive = exclusive,
		window = window,
		inputType = inputType or false,
		onDeath = onDeath or "discard"
	}
	if type(fun) == "function" then
		process.thread = coroutine.create(fun)
	elseif type(fun) == "thread" then
		process.thread = fun
	elseif type(fun) == "string" then
		process.thread = coroutine.create(function()
			if module.units[name] and module.units[name].useShell then
				shell.run(fun)
				return
			end
			local path = shell.resolveProgram(fun)
			if path then
				loadfile(path, nil, _ENV)()
				return
			end
		end)
	else
		error("fun isn't a function. string or thread")
	end
	module.processesByPid[pid] = process
	module.processesByThread[process.thread] = process
	table.insert(module.processesByName[name], process)
	nextPid = nextPid + 1
	return process
end

---@param identifyingFactor feather.featherd.process|integer|string|thread
function module.getProcess(identifyingFactor)
	if type(identifyingFactor) == "thread" then
		return module.processesByThread[identifyingFactor]
	elseif type(identifyingFactor) == "table" then
		return identifyingFactor
	elseif type(identifyingFactor) == "string" then
		return module.getNewestByName(identifyingFactor)
	elseif type(identifyingFactor) == "number" then
		return module.processesByPid[identifyingFactor]
	end
	assert(identifyingFactor, "couldn't match pid for argument: " .. identifyingFactor)
end

---@param process feather.featherd.process
function module.killProcess(process)
	coroutine.resume(process.thread, "terminate")
end

---@param entry feather.featherd.journalEntry
local function journalEntryToPlainText(entry)
	return ">" ..
		entry.name .. " [" .. entry.pid .. "] " .. "[" .. entry.level:upper() .. "] " .. tostring(entry.message)
end

---@param message any
---@param level feather.featherd.journalEntry.level?
---@param pidOrThread? integer|thread
---@return nil
function module.log(message, level, pidOrThread)
	---@type feather.petty
	local petty = bundl("feather.petty")
	level = level or "log"
	pidOrThread = pidOrThread or coroutine.running()
	local process
	if type(pidOrThread) == "number" then
		process = module.processesByPid[pidOrThread]
	else
		process = module.processesByThread[pidOrThread]
	end
	if type(message) ~= "string" then
		message = petty.pretty(message)
	end
	---@type feather.featherd.journalEntry
	local entry = {
		level = level,
		message = message,
		name = (process and process.name) or "untracked",
		pid = (process and process.pid) or 0
	}
	module.journal[#module.journal + 1] = entry

	logfile.writeLine(journalEntryToPlainText(entry))
	logfile.flush()
end

---@param logFilePath string
---@return ccTweaked.cc.pretty.Doc.concat doc
function module.formatLog(logFilePath)
	---@type feather.petty
	local petty = bundl("feather.petty")
	local logFile = fs.open(logFilePath, "r")
	assert(logFile, "Couldn't open file")
	local contents = petty.empty
	while true do
		local line = logFile.readLine()
		if not line then break end
		local progName, pid, severity, message =
			line:match("%>(.*)%s%[(%d*)%]%s%[(.*)%]%s(.*)")

		local severityColor = colors.white
		if severity == "ERROR" then
			severityColor = colors.red
		elseif severity == "WARNING" then
			severityColor = colors.yellow
		end
		contents = contents
			.. petty.text(">", colors.yellow)
			.. progName
			.. " ["
			.. petty.text(pid, colors.yellow)
			.. "] ["
			.. petty.text(severity, severityColor)
			.. "] "
			.. message
			.. petty.space_line
	end
	return contents --[[@as ccTweaked.cc.pretty.Doc.concat]]
end

function module.getNewestByName(name)
	local list = module.processesByName[name]
	return list and list[#list]
end

return module
