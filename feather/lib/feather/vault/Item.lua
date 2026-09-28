local Router = bundl "feather.vault.Router" ---@type feather.vault.Router

---@class feather.Object
local Object = bundl("feather.Object")

---@class feather.vault.Item: feather.Object
---@field private noNbt? feather.vault.Router routes to the item without any nbt data
---@field private byNbt table<string, feather.vault.Router> routes tot he item with nbt data
---@field super feather.Object
local Item = Object:extend()
function Item:new(route)
	local item = Item.super.new(self) --[[@as feather.vault.Item]]
	item.byNbt = {}
	setmetatable(item, Item)
	item:addRoute(route)
	return item
end

---Adds a new route to whatever router fits it's nbt
---@param route feather.vault.Route
function Item:addRoute(route)
	local nbt = route.item.nbt
	local router = self:getRouter(nbt)
	if router then
		router:addRoute(route)
	elseif nbt then
		self.byNbt[nbt] = Router:new(route)
	else
		self.noNbt = Router:new(route)
	end
end

---finds a router for the matching nbt (or none), nil if none found
---@param nbt? string
---@return feather.vault.Router
function Item:getRouter(nbt)
	if nbt then
		return self.byNbt[nbt]
	else
		return self.noNbt
	end
end

---@param nbt? string
function Item:getItemDetail(nbt)
	local router = self:getRouter(nbt)
	if router then
		return router.itemDetail
	end
end

---Returns the number of ALL instances of the item, regardless of nbt. to get the number of items without nbt, use Item:getItemDetail()
---@return integer
function Item:getCount()
	local count = 0
	if self.noNbt then
		count = self.noNbt.itemDetail.count
	end
	for _, router in pairs(self.byNbt) do
		count = count + router.itemDetail.count
	end
	return count
end

return Item
