local exception = require("cc.internal.exception")
local featherd = bundl("feather.featherd") ---@type feather.featherd
local function describeArg(argument, desc)
	term.setTextColor(colors.gray)
	write("\n" .. arg[0])
	if argument then
		term.setTextColor(colors.yellow)
		write(" " .. argument)
	end
	term.setTextColor(colors.white)
	print(" - " .. desc)
end
local function help()
	term.setTextColor(colors.yellow)
	write("Comfortd")
	term.setTextColor(colors.white)
	print(
		", a daemon for the FeatherOS comfort protocol")
	describeArg(nil,
		"runs the comfortd daemon and allows other computers to connect with comfort")
end
local arg = ...
if arg == "help" then
	help()
	return
end

local cast = bundl "feather.cast" ---@type feather.cast
local protocol = "feather.comfort"
peripheral.find("modem", rednet.open)
assert(rednet.isOpen(), "Must have a modem")
rednet.host(protocol, os.getComputerLabel() or "unlabelled")



---@return feather.comfort.message.start
local function makeStartMessage()
	return
	{
		time = os.time("local"),
		id = math.random(),
	}
end

local makeStopMessage = makeStartMessage


local function runThread(thread, window, ...)
	local lastTerm = term.current()
	term.redirect(window)
	coroutine.resume(thread, ...)
	term.redirect(lastTerm)
end




featherd.log("Initiating comfortd")
while true do
	---@type number, feather.comfort.message.start
	local remoteId, message = rednet.receive(protocol .. ".start") ---@diagnostic disable-line
	rednet.send(remoteId, makeStartMessage(), protocol .. ".start")

	featherd.log("Comfortd connected with " .. remoteId)
	local remoteWindow = cast.capture(remoteId) --[[@as Window]]

	local thread = coroutine.create(function() shell.run("shell") end)

	local function processInputs()
		while true do
			---@type integer, feather.comfort.message.event
			local id, message = rednet.receive(protocol .. ".event") ---@diagnostic disable-line
			if id == remoteId then
				runThread(thread, remoteWindow, message.contents.name, table.unpack(message.contents.data))
			end
		end
	end
	local function processEvents()
		while true do
			local event = table.pack(os.pullEvent())
			if event[1] ~= "char" and event[1] ~= "key" and event[1] ~= "key_up" then
				runThread(thread, remoteWindow, table.unpack(event))
			end
		end
	end
	local function handleStop()
		repeat
			local id = rednet.receive(protocol .. ".stop", 1)
			local dead = coroutine.status(thread) == "dead"
		until id == remoteId or dead
	end

	parallel.waitForAny(handleStop, processInputs, processEvents)
	rednet.send(remoteId, makeStopMessage(), protocol .. ".stop")

	featherd.log("Comfortd disconnected from " .. remoteId)
end
