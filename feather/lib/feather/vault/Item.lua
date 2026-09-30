local Router = bundl "feather.vault.Router" ---@type feather.vault.Router

---@class feather.Object
local Object = bundl("feather.Object")

---@class feather.vault.Item: feather.Object
---@field private noNbt? feather.vault.Router routes to the item without any nbt data
---@field private byNbt table<string, feather.vault.Router> routes tot he item with nbt data
---@field super feather.Object
local Item = Object:extend()
function Item:new()
	local item = Item.super.new(self) --[[@as feather.vault.Item]]
	item.byNbt = {}
	setmetatable(item, Item)
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
---@return feather.vault.Router?
function Item:getRouter(nbt)
	if nbt then
		return self.byNbt[nbt]
	else
		return self.noNbt
	end
end

---@alias feather.vault.filter fun(detail: ccTweaked.peripheral.itemDetail): boolean

---finds a routers for the matching filter (or none). Routers with no nbt are prioritized, but the rest are random
---@param filter? feather.vault.filter
---@return feather.vault.Router[]
function Item:getRouters(filter)
	local routers = {}
	if not filter or filter(self.noNbt.itemDetail) then
		routers[#routers + 1] = self.noNbt
	end
	for _, router in pairs(self.byNbt) do
		if not filter or filter(router.itemDetail) then
			routers[#routers + 1] = router
		end
	end
	return routers
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
	--- use getRouters and filter
	local count = 0
	if self.noNbt then
		count = self.noNbt.itemDetail.count
	end
	for _, router in pairs(self.byNbt) do
		count = count + router.itemDetail.count
	end
	return count
end

---Exports an item from the storage into target inventory
---@param target ccTweaked.peripheral.Inventory
---@param amount? integer default is a stack
---@param filter? feather.vault.filter
---@return integer
function Item:export(target, amount, filter)
	local routers = self:getRouters(filter)
	if not routers[1] then
		return 0
	end
	amount = amount or routers[1].itemDetail.maxCount
	local exported = 0
	for _, router in ipairs(routers) do
		exported = exported + router:export(target, amount - exported)
		if amount == exported then
			break
		end
	end
	return exported
end

---Attempts to fit a given item into existing routes' stacks
---@param source ccTweaked.peripheral.Inventory
---@param slot integer
---@param itemDetail ccTweaked.peripheral.itemDetail this sucks but it's better than querying it 5 times
---@param amount integer
function Item:fit(source, slot, itemDetail, amount)
	local router = self:getRouter(itemDetail.nbt)
	if not router then return 0 end
	return router:fit(source, slot, itemDetail, amount)
end

return Item
