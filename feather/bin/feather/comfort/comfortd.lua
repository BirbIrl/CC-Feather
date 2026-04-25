--TODO
--this is kind of terrible, we shouldn't be using multishell for this. there's gotta be a better way to do this. i need to study multishell for it tho.
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


local function runShell()
	shell.execute("shell")
end


print("Running the Comfortd daemon...")
while true do
	---@type number, feather.comfort.message.start
	local remoteId, message = rednet.receive(protocol .. ".start") ---@diagnostic disable-line
	rednet.send(remoteId, makeStartMessage(), protocol .. ".start")
	local remoteWindow = cast.capture(remoteId) --[[@as Window]]
	local lastTerm = term.current()



	local function processInputs()
		while true do
			---@type integer, feather.comfort.message.event
			local id, message = rednet.receive(protocol .. ".event") ---@diagnostic disable-line
			if id == remoteId then
				multishell.setFocus(multishell.getCurrent())
				os.queueEvent(message.contents.name, table.unpack(message.contents.data))
			end
		end
	end
	local function handleStop()
		repeat
			local id = rednet.receive(protocol .. ".stop")
		until id == remoteId
	end

	term.redirect(remoteWindow)
	parallel.waitForAny(runShell, handleStop, processInputs)
	rednet.send(remoteId, makeStopMessage(), protocol .. ".stop")
	term.redirect(lastTerm)
end
