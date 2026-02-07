---@class feather.cast
local module = {}

---@class feather.cast.message: feather.mirrord.message

---@class feather.cast.message.call: feather.cast.message
---@field contents {linkId: number, key: string, args: any[]}
---@field respondsTo nil

---@class feather.cast.message.answer: feather.cast.message
---@field contents {returnValues: any[]}
---@field respondsTo number
---
---@class feather.cast.message.broadcast: feather.cast.message
---@field contents {linkId: number}
---@field respondsTo nil


---@param linkId number
---@param key any
---@param ... any
---@return feather.cast.message.call
local function makeCallMessage(linkId, key, ...)
	return
	{
		time = os.time("local"),
		id = math.random(),
		request_type = "castCall",
		contents = {
			linkId = linkId,
			key = key,
			args = table.pack(...), -- only issue is if the arg is a peripheral or some other object with functions
		}
	}
end

---@return feather.cast.message.broadcast
local function makeBroadcastMessage()
	return
	{
		time = os.time("local"),
		id = math.random(),
		request_type = "castBroadcast",
		contents = {
			linkId = math.random()
		}
	}
end

---@return feather.cast.message.answer
local function makeAnswerMessage(callId, returnValues)
	return {
		time = os.time("local"),
		id = math.random(),
		request_type = "castAnswer",
		respondsTo = callId,
		contents = { returnValues = returnValues }
	}
end


local function getCastedObject(computerId, linkId)
	---@class feather.cast.remoteAccessor
	return setmetatable({},
		{
			__index = function(_, key)
				return function(...)
					local message = makeCallMessage(linkId, key, ...)
					rednet.send(computerId,
						message,
						"feather.cast.call")
					local id, answer
					repeat
						---@type number, feather.cast.message.answer
						id, answer = rednet.receive("feather.cast.answer")
					until id == computerId and answer.respondsTo == message.id
					return table.unpack(answer.contents.returnValues)
				end
			end
		}
	)
end

---@type table<number, table>
local trackedObjects = {}

---@param object table
---@param computerId? integer
function module.broadcast(object, computerId)
	local message = makeBroadcastMessage()
	local linkId = message.contents.linkId
	if computerId then
		rednet.send(computerId, message, "feather.cast.broadcast")
	else
		rednet.broadcast(message, "feather.cast.broadcast")
	end
	trackedObjects[linkId] = object
	return object, linkId
end

function module.processBroadcastedObjects()
	while true do
		---@type number, feather.cast.message.call
		local callerId, call = rednet.receive("feather.cast.call") ---@diagnostic disable-line
		local args = call.contents.args
		local key = call.contents.key
		local linkId = call.contents.linkId
		assert(trackedObjects[linkId], "Called object that isn't being tracked") --TODO: log this stuff properly
		local returnValues = table.pack(trackedObjects[linkId][key](table.unpack(args)))
		local answer = makeAnswerMessage(call.id, returnValues)
		rednet.send(callerId, answer, "feather.cast.answer")
	end
end

---@return feather.cast.remoteAccessor
function module.capture()
	---@type number, feather.cast.message.broadcast
	local id, answer = rednet.receive("feather.cast.broadcast") ---@diagnostic disable-line
	return getCastedObject(id, answer.contents.linkId)
end

return module
