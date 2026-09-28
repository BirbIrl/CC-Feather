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

return Route
