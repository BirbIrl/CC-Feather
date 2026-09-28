local Item = bundl "feather.vault.Item" ---@type feather.vault.Item
local Router = bundl "feather.vault.Router" ---@type feather.vault.Router
local Route = bundl "feather.vault.Route" ---@type feather.vault.Route

---@class feather.vault
local module = {}

---@return ccTweaked.peripheral.Inventory
---@return string outputName
function module.getOutput()
	local name = assert(settings.get("feather.vault.output"), "output name isn't set! use vault setOutput")
	return
		assert(peripheral.wrap(name), "couldn't wrap the named peripheral. is it attached?") --[[@as ccTweaked.peripheral.Inventory]],
		name
end

local dirs = { bottom = true, top = true, left = true, right = true, front = true, back = true }

---@return ccTweaked.peripheral.Inventory[]
function module.getStorages()
	local candidates = table.pack(peripheral.find("inventory"))
	local outputName = peripheral.getName(module.getOutput())
	for i = #candidates, 1, -1 do
		local candidate = candidates[i]
		local name = peripheral.getName(candidate)
		if name == outputName or dirs[name] then
			table.remove(candidates, i)
		end
	end
	return candidates
end

module.locked = false

---@type table<string,feather.vault.Item>
module.cache = nil

---@type table<string,string[]>
module.tags = nil

function module.generateCache()
	module.locked = true
	---@type table<string,feather.vault.Item>
	local cache = {}
	---@type table<string,string[]>
	local tags = {}
	local invLambdas = {}
	for _, storage in ipairs(module.getStorages()) do
		invLambdas[#invLambdas + 1] = function()
			local slots = storage.list()
			for slot, item in pairs(slots) do
				if item then
					local route = Route:new(storage, slot, item)
					if not cache[item.name] then
						cache[item.name] = Item:new(route)
					else
						cache[item.name]:addRoute(route)
					end
				end
			end
		end
	end
	if #invLambdas > 100 then
		error("This system doesn't support over 100 storage peripherals yet")
	end
	parallel.waitForAll(table.unpack(invLambdas))
	module.cache = cache
	module.tags = tags
	module.locked = false
	os.queueEvent("feather.vault.unlocked")
end

---@param target integer
function module.import(routes, target)
	error("Currently broken")
	local left = target
	for _, route in ipairs(routes) do
		local _, outputName = module.getOutput()
		left = left - route.peripheral.pushItems(outputName, route.slot, left)
		if left <= 0 then
			break
		end
	end
	return target - left
end

return module
