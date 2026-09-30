---@class feather.Object
local Object = bundl("feather.Object")


---@class feather.vault.Router: feather.Object the router object keeps track of item routes
---@field itemDetail ccTweaked.peripheral.itemDetail the item's item detail, with the total modified on the fly
---@field routes feather.vault.Route[] the routes it keeps track of
---@field super feather.Object
local Router = Object:extend()

---@param route feather.vault.Route the router needs at least one route to be created
---@return feather.vault.Router
function Router:new(route)
	local router = Router.super.new(self) --[[@as feather.vault.Router]]
	router.routes = { route }
	router.itemDetail = route:getItemDetail()
	---@type feather.vault.Router
	return setmetatable(router, Router)
end

---@param route feather.vault.Route the route to add
function Router:addRoute(route)
	self.routes[#self.routes + 1] = route
	self.itemDetail.count = self.itemDetail.count + route.item.count
end

function Router:deleteEmptyRoutes()
	local newRoutes = {}
	for _, route in ipairs(self.routes) do
		if route.item.count > 0 then
			newRoutes[#newRoutes + 1] = route
		end
	end
	self.routes = newRoutes
end

---@param target ccTweaked.peripheral.Inventory
---@param amount? integer default is a stack
function Router:export(target, amount)
	amount = amount or self.itemDetail.maxCount
	local exported = 0
	for _, route in ipairs(self.routes) do
		exported = exported + route:export(target, amount - exported)
		if amount == exported then
			break
		end
	end
	self.itemDetail.count = self.itemDetail.count - exported
	self:deleteEmptyRoutes()
	return exported
end

---Attempts to fit a given item into the router's stacks
---@param source ccTweaked.peripheral.Inventory
---@param slot integer
---@param itemDetail ccTweaked.peripheral.itemDetail this sucks but it's better than querying it 5 times
---@param amount integer
function Router:fit(source, slot, itemDetail, amount)
	local imported = 0
	for _, route in ipairs(self.routes) do
		imported = imported + route:fit(source, slot, itemDetail, amount - imported)
		if imported == amount then
			break
		end
	end
	self.itemDetail.count = self.itemDetail.count + imported
	return imported
end

return Router
