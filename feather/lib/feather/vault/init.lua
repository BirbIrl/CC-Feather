---@class feather.vault
local module = {}


---@return ccTweaked.peripheral.Inventory
function module.getOutput()
	return assert(peripheral.wrap(
		assert(settings.get("feather.vault.output")
		, "output name isn't set! use vault setOutput")
	), "couldn't wrap the named peripheral. is it attached?") --[[@as ccTweaked.peripheral.Inventory]]
end

---@return ccTweaked.peripheral.Inventory[]
function module.getStorages()
	local candidates = table.pack(peripheral.find("inventory"))
	local outputName = peripheral.getName(module.getOutput())
	for i = #candidates, 1, -1 do
		local candidate = candidates[i]
		if peripheral.getName(candidate) == outputName then
			table.remove(candidates, i)
			break
		end
	end
	return candidates
end

---@alias itemRoutes {peripheralName: string, slot: integer, item: ccTweaked.peripheral.item }[]|{total: integer}

---@return table<string,itemRoutes>
function module.list()
	---@type table<string,itemRoutes>
	local registry = {}
	local invLambdas = {}
	for _, storage in ipairs(module.getStorages()) do
		invLambdas[#invLambdas + 1] = function()
			local slotLambdas = {}
			for slot = 1, storage.size(), 1 do
				slotLambdas[#slotLambdas + 1] = function()
					local item = storage.getItemDetail(slot)
					if item then
						if not registry[item.name] then
							registry[item.name] = { total = 0 }
						end
						table.insert(registry[item.name], item)
						registry[item.name].total = registry[item.name].total + item.count
					end
				end
			end
			parallel.waitForAll(table.unpack(slotLambdas))
		end
	end
	parallel.waitForAll(table.unpack(invLambdas))
	return registry
end

return module
