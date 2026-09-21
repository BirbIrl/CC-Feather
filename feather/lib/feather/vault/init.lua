---@class feather.vault
local module = {}

module.cache = {
	byName = {},
	byDisplayName = {}, -- each one should then be split by nbt
	byNbt = {},
	byTags = {},
}

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

---@alias feather.vault.itemRoute {peripheral: ccTweaked.peripheral.Inventory, slot: integer, item: ccTweaked.peripheral.item }
---@alias feather.vault.itemRoutes feather.vault.itemRoute[]|{total: integer, getDetails: fun():ccTweaked.peripheral.itemDetail}

---@return table<string,feather.vault.itemRoutes>
function module.list()
	---@type table<string,feather.vault.itemRoutes>
	local registry = {}
	local invLambdas = {}
	for _, storage in ipairs(module.getStorages()) do
		invLambdas[#invLambdas + 1] = function()
			local slots = storage.list()
			for slot, item in pairs(slots) do
				if item then
					if not registry[item.name] then
						registry[item.name] = {
							total = 0,
							getDetails = function()
								return assert(storage.getItemDetail(slot), "item got lost")
							end
						}
					end
					table.insert(registry[item.name], { peripheral = storage, slot = slot, item = item })
					registry[item.name].total = registry[item.name].total + item.count
				end
			end
		end
	end
	if #invLambdas > 120 then
		error("This system doesn't support over 120 storage peripherals yet")
	end
	parallel.waitForAll(table.unpack(invLambdas))
	return registry
end

---@param routes feather.vault.itemRoutes
---@param target integer
function module.import(routes, target)
	local left = target
	for _, route in ipairs(routes) do
		left = left - route.peripheral.pushItems(settings.get("feather.vault.output"), route.slot, left)
		if left <= 0 then
			break
		end
	end
	return target - left
end

return module
