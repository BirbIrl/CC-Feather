---@class feather.comfort.message.event: feather.cast.message
---@field respondsTo nil
---@field contents {name: string, data: any[]}

---@class feather.comfort.message.start: feather.cast.message
---@field respondsTo nil
---@field contents  nil
---
---@class feather.comfort.message.stop: feather.cast.message
---@field respondsTo nil
---@field contents  nil

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
	write("Comfort")
	term.setTextColor(colors.white)
	print(
		", a FeatherOS utility for accessing other computers remotely. Use ctrl+c to detach once attached.")
	describeArg("[computerId]",
		"opens the shell of the computer with the given id")
end


---@return feather.comfort.message.start
local function makeStartMessage()
	return
	{
		time = os.time("local"),
		id = math.random(),
	}
end


---@return feather.comfort.message.stop
local makeStopMessage = makeStartMessage

---@return feather.comfort.message.event
local function makeEventMessage(packedEvent)
	return
	{
		time = os.time("local"),
		id = math.random(),
		contents = {
			name = packedEvent[1],
			data = table.pack(select(2, table.unpack(packedEvent)))
		}
	}
end

local function makeFullScreenWindow()
	local width, height = term.getSize()
	return window.create(term.native(), 1, 1, width, height, true)
end


local computerId = tonumber(...)
local protocol = "feather.comfort"

local function handleStop()
	repeat
		local id = rednet.receive(protocol .. ".stop")
	until id == computerId
end

local function sendInputs()
	assert(computerId)
	while true do
		local packedEvent = table.pack(os.pullEvent())
		local eventName = packedEvent[1] ---@type ccTweaked.os.event
		if eventName == "key" or eventName == "key_up" or eventName == "char" then
			rednet.send(computerId, makeEventMessage(packedEvent), protocol .. ".event")
		end
	end
end


local cast = bundl "feather.cast" ---@type feather.cast
local castInstance = cast.new()

if computerId then
	rednet.send(computerId, makeStartMessage(), protocol .. ".start")
	local id = rednet.receive(protocol .. ".start", 1)
	assert(id, "Computer didn't respond")
	assert(id == computerId, "A Computer with the id: " .. id .. " seems to be intercepting the connection")

	local win = makeFullScreenWindow()
	castInstance:broadcast(win)
	parallel.waitForAny(sendInputs, handleStop, castInstance:makeParallelProcessor())
	term.setCursorPos(1, 1)
	term.clear()
	rednet.send(computerId, makeStopMessage(), protocol .. ".stop")
else
	help()
end
