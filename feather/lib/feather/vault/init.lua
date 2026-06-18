---@class feather.vault
local module = {}


---@return ccTweaked.peripheral.Inventory
function module.getOutput()
	return assert(peripheral.wrap(
		assert(settings.get("feather.vault.output")
		, "output name isn't set! use vault setOutput")
	), "couldn't wrap the named peripheral. is it attached?") --[[@as ccTweaked.peripheral.Inventory]]
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

---@alias feather.vault.itemRoutes {peripheral: ccTweaked.peripheral.Inventory, slot: integer, item: ccTweaked.peripheral.itemDetail }[]|{total: integer, getDetails: fun():ccTweaked.peripheral.itemDetail}

---@return table<string,feather.vault.itemRoutes>
function module.list()
	---@type table<string,feather.vault.itemRoutes>
	local registry = {}
	local invLambdas = {}
	for i, storage in ipairs(module.getStorages()) do
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
	parallel.waitForAll(table.unpack(invLambdas))
	return registry
end

return module
