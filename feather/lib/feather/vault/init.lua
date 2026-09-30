local Item = bundl "feather.vault.Item" ---@type feather.vault.Item
local Router = bundl "feather.vault.Router" ---@type feather.vault.Router
local Route = bundl "feather.vault.Route" ---@type feather.vault.Route

---@class feather.vault
local module = {}


---TODO: get rid of this. we don't need to specify an output within vault
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
	if #candidates > 100 then
		-- this is due to the 128 event stack limit, we use lambdas for scanning each inventory at once
		error("Vault doesn't support over 100 storage peripherals yet")
	end
	return candidates
end

module.locked = false

---@type table<string,feather.vault.Item>
module.cache = nil

---@type [ccTweaked.peripheral.Inventory, integer]
module.emptySlots = {}

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
			local list = storage.list()
			for slot = 1, storage.size(), 1 do
				local item = list[slot]
				if item then
					local route = Route:new(storage, slot, item)
					if not cache[item.name] then
						cache[item.name] = Item:new()
					end
					cache[item.name]:addRoute(route)
				else
					module.emptySlots[#module.emptySlots + 1] = { storage, slot }
				end
			end
		end
	end
	parallel.waitForAll(table.unpack(invLambdas))
	module.cache = cache
	module.tags = tags
	module.locked = false
	os.queueEvent("feather.vault.unlocked")
end

---takes out an item from the vault cache and puts it in an outside inventory
---@param target ccTweaked.peripheral.Inventory
---@param itemName string
---@param amount? integer default is stack
---@param filter? feather.vault.filter
---@return integer amount of items exported
function module.export(target, itemName, amount, filter)
	local item = assert(module.cache[itemName], "couldn't find any items called \"" .. itemName .. "\"")
	return item:export(target, amount, filter)
end

---takes an item from an outside inventory and puts it in the vault cache
---@param source ccTweaked.peripheral.Inventory
---@param slot integer
---@param amount? integer default is all
function module.import(source, slot, amount)
	local itemDetail = source.getItemDetail(slot)
	if not itemDetail then return 0 end
	amount = amount or itemDetail.count
	local item = module.cache[itemDetail.name] or Item:new()
	module.cache[itemDetail.name] = item
	local imported = item:fit(source, slot, itemDetail, amount)
	if imported == amount then
		return imported
	end
	local destination, emptySlot = table.unpack(table.remove(module.emptySlots))
	if destination and emptySlot then
		imported = imported + source.pushItems(peripheral.getName(destination), slot, nil, emptySlot)
		item:addRoute(Route:new(destination, emptySlot, destination.list()[emptySlot]))
	end
	return imported
end

---@param itemName string
---@return feather.vault.Item?
function module.getItem(itemName)
	return module.cache[itemName]
end

return module
