---@class feather.cast
local module = {}

---@class feather.cast.message: feather.mirrord.message

---@class feather.cast.message.call: feather.cast.message
---@field contents {linkId: number, key: string, args: any[]}
---@field respondsTo nil

---@class feather.cast.message.answer: feather.cast.message
---@field contents {returnValues: any[], success: boolean}
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
local function makeAnswerMessage(callId, returnValues, success)
	return {
		time = os.time("local"),
		id = math.random(),
		request_type = "castAnswer",
		respondsTo = callId,
		contents = { returnValues = returnValues, success = success }
	}
end



---@param message any
---@param callerId integer
---@param hostId integer
---@param key string
---@param ... any
local function makeErrorText(message, callerId, hostId, key, ...)
	local full = "CAST REMOTE ERROR" ..
		"\n Caller ID: " .. callerId ..
		"\n Host ID: " .. hostId ..
		"\n Key: " .. key ..
		"\n Args: "
	local args = table.pack(...)
	for i = 1, args.n, 1 do
		full = full .. tostring(args[i]) .. ", "
	end
	full = full:sub(1, -1)
	full = full .. "\nHost Error Message: \n" .. tostring(message)

	return message
end

local function onIndex(self, key)
	local hostId = rawget(self, "__hostId")
	local linkId = rawget(self, "__linkId")
	return function(...)
		local message = makeCallMessage(linkId, key, ...)
		rednet.send(hostId,
			message,
			"feather.cast.call")
		local id, answer
		repeat
			---@type number, feather.cast.message.answer
			id, answer = rednet.receive("feather.cast.answer")
		until id == hostId and answer.respondsTo == message.id
		assert(answer.contents.success,
			makeErrorText(answer.contents.returnValues[1], os.getComputerID(), hostId, key, ...))
		return table.unpack(answer.contents.returnValues)
	end
end

local function getCastedObject(hostId, linkId)
	---@class feather.cast.remoteAccessor
	return setmetatable({ __linkId = linkId, __hostId = hostId },
		{
			__index = onIndex,
		}
	)
end

---@type table<number, table>
local trackedObjects = {}

---@param object table
---@param hostId? integer
function module.broadcast(object, hostId)
	local message = makeBroadcastMessage()
	local linkId = message.contents.linkId
	if hostId then
		rednet.send(hostId, message, "feather.cast.broadcast")
	else
		rednet.broadcast(message, "feather.cast.broadcast")
	end
	trackedObjects[linkId] = object
	return object, linkId
end

local function callObjectAndCaptureError(trackedObjects, linkId, key, args)
	return table.pack(trackedObjects[linkId][key](table.unpack(args)))
end

function module.processBroadcastedObjects()
	--TODO: Handle metatables that point to a local object
	while true do
		---@type number, feather.cast.message.call
		local callerId, call = rednet.receive("feather.cast.call") ---@diagnostic disable-line
		local args = call.contents.args
		local key = call.contents.key
		local linkId = call.contents.linkId
		local success, result = pcall(callObjectAndCaptureError, trackedObjects, linkId, key, args)
		if not success then
			result = table.pack(result) -- wrap the error message in a table
		end
		local answer = makeAnswerMessage(call.id, result, success)
		rednet.send(callerId, answer, "feather.cast.answer")
	end
end

---@param targetId? integer
---@return feather.cast.remoteAccessor
function module.capture(targetId)
	local id, answer
	repeat
		---@type number, feather.cast.message.broadcast
		id, answer = rednet.receive("feather.cast.broadcast") ---@diagnostic disable-line
	until id == targetId or not targetId
	return getCastedObject(id, answer.contents.linkId)
end

return module
