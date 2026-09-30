---@class feather.Object
local Object = bundl("feather.Object")

---@class feather.vault.Route: feather.Object
---@field peripheral ccTweaked.peripheral.Inventory
---@field slot integer
---@field item ccTweaked.peripheral.item
---@field super feather.Object
local Route = Object:extend()

---@param peripheral ccTweaked.peripheral.Inventory
---@param slot integer
---@param item ccTweaked.peripheral.item
---@return feather.vault.Route
function Route:new(peripheral, slot, item)
	local route = Route.super.new(self) --[[@as feather.vault.Route]]
	route.peripheral = peripheral
	route.item = item
	route.slot = slot
	---@type feather.vault.Route
	return setmetatable(route, Route)
end

function Route:getItemDetail()
	return assert(self.peripheral.getItemDetail(self.slot),
		"Item cannot find itself when attempting to get it's own details")
end

---@param target ccTweaked.peripheral.Inventory
---@param amount integer
function Route:export(target, amount)
	local exported = self.peripheral.pushItems(peripheral.getName(target), self.slot, amount)
	assert(exported == math.min(amount, self.item.count),
		"Couldn't push all the items from this route into target inventory, maybe it's full?")
	self.item.count = self.item.count - exported
	return exported
end

function Route:fit(source, slot, itemDetail, amount)
	if self.item.count == itemDetail.maxCount then
		return 0
	end
	local imported = self.peripheral.pullItems(peripheral.getName(source), slot, amount, self.slot)
	self.item.count = self.item.count + imported
	return imported
end

return Route
