local pretty = require("cc.pretty")
---@class lib.feather.vec2d
---@field x  number
---@field y number
local module = {}
module.__index = module


---@param x? number
---@param y? number
function module.new(x, y)
	return setmetatable({ x = x or 0, y = y or 0 }, module)
end

function module.newCCSquare(size)
	return module.new(size, math.ceil(size * 0.66))
end

function module:clone()
	return self.new(self.x, self.y)
end

---@param any lib.feather.vec2d|number
local function ensureVec(any)
	if type(any) == "number" then
		return module.new(any, any)
	end
	return any
end

function module:min(target)
	return module.new(math.min(self.x, target.x), math.min(self.y, target.y))
end

function module:max(target)
	return module.new(math.max(self.x, target.x), math.max(self.y, target.y))
end

---@param target lib.feather.vec2d
---@return lib.feather.vec2d
function module:__add(target)
	self = ensureVec(self)
	target = ensureVec(target)
	return module.new(self.x + target.x, self.y + target.y)
end

---@param target lib.feather.vec2d
---@return lib.feather.vec2d
function module:__sub(target)
	self = ensureVec(self)
	target = ensureVec(target)
	return module.new(self.x - target.x, self.y - target.y)
end

---@param target lib.feather.vec2d
---@return lib.feather.vec2d
function module:__mul(target)
	self = ensureVec(self)
	target = ensureVec(target)
	return module.new(self.x * target.x, self.y * target.y)
end

---@param target lib.feather.vec2d
---@return lib.feather.vec2d
function module:__div(target)
	self = ensureVec(self)
	target = ensureVec(target)
	return module.new(self.x / target.x, self.y / target.y)
end

---@param target lib.feather.vec2d
function module:__eq(target)
	return self.x == target.x and self.y == target.y
end

function module:__tostring()
	return "{" .. self.x .. "," .. self.y .. "}"
end

module.zero = module.new()
module.one = module.new(1, 1)
module.huge = module.new(math.huge, math.huge)
return module
