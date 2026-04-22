local pretty = require("cc.pretty")
---@class feather.featherd
local module = {}
module.running = false
---@type feather.featherd.process[]
module.processesByPid = {}
---@type table<thread,feather.featherd.process>
module.processesByThread = {}
---@type table<string,feather.featherd.process[]|{locked: true}>
module.processesByName = {}

module.journal = {}
local logfile = fs.open(
	".feather/share/featherd/logs/" .. os.date("%Y-%m-%d-%T") --[[@as string]]:gsub(":", ".") .. ".txt", "w")
assert(logfile, "Couldn't open a file to save the log in")


---@alias feather.featherd.journalEntry.level "error"|"warning"|"message"
---
---@class feather.featherd.journalEntry
---@field level feather.featherd.journalEntry.level
---@field message ccTweaked.cc.pretty.Doc
---@field name string
---@field pid integer


local nextPid = 1

local exception = dofile("rom/modules/main/cc/internal/tiny_require.lua")("cc.internal.exception")

function module.init()
	assert(not module.running, "featherd is already running!")
	term.clear()
	term.setCursorPos(1, 1)
	term.setTextColor(colors.yellow)
	print(feather.getVersion())
	term.setTextColor(colors.white)
	write("Computer ID: ")
	term.setTextColor(colors.yellow)
	write(tostring(os.getComputerID()))

	local label = os.getComputerLabel()
	if label then
		term.setTextColor(colors.white)
		write(' - "')
		term.setTextColor(colors.yellow)
		write(label)
		term.setTextColor(colors.white)
		write('"')
	end

	print()
	module.addProcess("mainShell", function()
		term.setCursorPos(-30, 2)
		shell.execute("shell")
	end)
	module.runProcesses()
end

function module.runProcesses()
	assert(not module.running, "featherd is already running!")
	assert(#module.processesByPid > 0, "featherd must have at least one task assigned")
	module.running = true
	local event = { n = 0 }
	---@type feather.featherd.process[]
	while true do
		local toRestart = {}
		for pid, process in pairs(module.processesByPid) do
			if process.filter == nil or process.filter == event[1] or process.filter == "terminate" then
				local ok, param = coroutine.resume(process.thread, table.unpack(event, 1, event.n))
				if ok then
					process.filter = param
				elseif type(param) == "string" and exception.can_wrap_errors() then
					module.log(exception.make_exception(param, process.thread), "error", pid)
				else
					module.log(param, "error", pid)
				end
			end

			if coroutine.status(process.thread) == "dead" then
				if not process.keepAfterDead then
					module.processesByPid[pid] = nil
					module.processesByThread[process.thread] = nil
					for i, candidate in ipairs(module.processesByName[process.name]) do
						if process == candidate then
							table.remove(module.processesByName[process.name], i)
							break
						end
					end
				end
				if process.autoRestart then
					toRestart[#toRestart + 1] = process
				end
			end
		end
		for _, process in ipairs(toRestart) do
			module.processesByName[process.name].locked = nil
			module.addProcess(process.name, process.fun, process.keepAfterDead, process.autoRestart)
			os.queueEvent("feather.featherd.restarted", process)
		end
		if not module.processesByPid[1] then
			return
		end
		event = table.pack(os.pullEventRaw())
	end
end

---@class feather.featherd.process
---@field startTime number
---@field name string
---@field filter string?
---@field thread thread
---@field sharedObject any
---@field fun function
---@field pid integer
---@field keepAfterDead true?
---@field autoRestart true?

---@param name string name of the process
---@param fun function function the process should run with
---@param keepAfterDeath true? when nil or false, the function will be removed from the pid tracking list when dead
---@param autoRestart true? when true, once the process ends or dies, it will be ran again
---@param exclusive true? when true, featherd wont allow making more than one living process under this name
function module.addProcess(name, fun, keepAfterDeath, autoRestart, exclusive)
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
		thread = coroutine.create(fun),
		fun = fun,
		exclusive = exclusive,
		keepAfterDeath = keepAfterDeath,
		autoRestart = autoRestart,
	}
	module.processesByPid[pid] = process
	module.processesByThread[process.thread] = process
	table.insert(module.processesByName[name], process)
	nextPid = nextPid + 1
end

---@param entry feather.featherd.journalEntry
local function journalEntryToPlainText(entry)
	local concat = ">" .. entry.name .. " [" .. entry.pid .. "] "
	if entry.level ~= "message" then
		concat = concat .. "[" .. entry.level:upper() .. "] "
	end
	return concat .. tostring(entry.message)
end

---@param message any
---@param level feather.featherd.journalEntry.level?
---@param pidOrThread? integer|thread
---@return nil
function module.log(message, level, pidOrThread)
	level = level or "message"
	pidOrThread = pidOrThread or coroutine.running()
	local process
	if type(pidOrThread) == "number" then
		process = module.processesByPid[pidOrThread]
	else
		process = module.processesByThread[pidOrThread]
	end
	if type(message) ~= "string" then
		message = pretty.pretty(message)
	end
	---@type feather.featherd.journalEntry
	local entry = {
		level = level,
		message = message,
		name = process.name,
		pid = process.pid
	}
	module.journal[#module.journal + 1] = entry

	logfile.writeLine(journalEntryToPlainText(entry))
end

---sets the given `sharedValue` as this process's sharedValue field
---@param sharedValue any
function module.share(sharedValue)
	module.processesByThread[coroutine.running()].sharedObject = sharedValue
end

function module.getNewestByName(name)
	local list = module.processesByName[name]
	return list and list[#list]
end

return module
