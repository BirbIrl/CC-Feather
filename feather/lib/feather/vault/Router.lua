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

return Router
