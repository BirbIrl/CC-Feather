---@class feather.cast.instance
---@field trackedObjects table<number, table>
local cast = {}
cast.__index = cast

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

---@class feather.cast.message.drop: feather.cast.message.broadcast



local protocol = "feather.cast"

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

---@return feather.cast.message.drop
local function makeDropMessage(linkId)
	return {
		time = os.time("local"),
		id = math.random(),
		request_type = "castAnswer",
		contents = { linkId = linkId }
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
			id, answer = rednet.receive(protocol .. ".answer")
		until id == hostId and answer.respondsTo == message.id
		assert(answer.contents.success,
			makeErrorText(answer.contents.returnValues[1], os.getComputerID(), hostId, key, ...))
		return table.unpack(answer.contents.returnValues)
	end
end



---@param object table
---@param hostId? integer
function cast:broadcast(object, hostId)
	local message = makeBroadcastMessage()
	local linkId = message.contents.linkId
	if hostId then
		rednet.send(hostId, message, protocol .. ".broadcast")
	else
		rednet.broadcast(message, protocol .. ".broadcast")
	end
	self.trackedObjects[linkId] = object
	return object, linkId
end

local function callObjectAndCaptureError(trackedObjects, linkId, key, args)
	return table.pack(trackedObjects[linkId][key](table.unpack(args)))
end


function cast:processBroadcastedObjects()
	--TODO: Handle metatables that point to a local object
	while true do
		local callerId, call
		os.queueEvent("feather.cast.processing", true)
		callerId, call, messageProtocol = rednet.receive(nil, 1) ---@diagnostic disable-line
		if callerId and call then
			if messageProtocol == protocol .. ".call" then
				local args = call.contents.args
				local key = call.contents.key
				local linkId = call.contents.linkId
				local success, result = pcall(callObjectAndCaptureError, self.trackedObjects, linkId, key, args)
				if not success then
					result = table.pack(result) -- wrap the error message in a table
				end
				local answer = makeAnswerMessage(call.id, result, success)
				rednet.send(callerId, answer, protocol .. ".answer")
			elseif messageProtocol == protocol .. ".drop" then
				self.trackedObjects[call.contents.linkId] = nil
			end
		end
	end
end

function cast:makeParallelProcessor()
	return function()
		self:processBroadcastedObjects()
	end
end

---@param castedObject any
function cast:drop(castedObject)
	local linkId, hostId = castedObject.__linkId, castedObject.__hostId
	rednet.send(hostId, makeDropMessage(linkId), protocol .. ".drop")
end

---@class feather.cast
module = {}

---@return feather.cast.instance
function module.new()
	return setmetatable({ trackedObjects = {} }, cast)
end

local function getCastedObject(hostId, linkId)
	---@class feather.cast.remoteAccessor
	return setmetatable({ __linkId = linkId, __hostId = hostId },
		{
			__index = onIndex,
		}
	)
end

---@param targetId? integer
---@return feather.cast.remoteAccessor
function module.capture(targetId)
	local id, answer
	repeat
		---@type number, feather.cast.message.broadcast
		id, answer = rednet.receive(protocol .. ".broadcast") ---@diagnostic disable-line
	until id == targetId or not targetId
	return getCastedObject(id, answer.contents.linkId)
end

return module
