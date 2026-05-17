local Object = bundl("feather.Object") ---@type lib.feather.Object
local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d
local defaultConfig = bundl("feather.lycantrophy.defaultConfig") ---@type lib.feather.lycantrophy.config
---@class lib.feather.lycantrophy.Element: lib.feather.Object
---@field config lib.feather.lycantrophy.config
---@field size? lib.feather.vec2d
---@field super lib.feather.Object
local Element = Object:extend()

---@param config? lib.feather.lycantrophy.config
function Element:new(config)
	local element = Element.super.new(self)
	---@cast element lib.feather.lycantrophy.Element
	element.config = config or defaultConfig
	return setmetatable(element, Element) --[[@as lib.feather.lycantrophy.Element]]
end

---@param pos lib.feather.vec2d
function Element:draw(pos)
	local to = pos + self:getSize() - vec.one
	paintutils.drawFilledBox(pos.x, pos.y, to.x, to.y,
		self.config.backgroundColor)
	term.setBackgroundColor(self.config.backgroundColor)
end

---@param size? lib.feather.vec2d
---@return lib.feather.vec2d size
function Element:resize(size)
	self.size = (size or vec.zero):max(self.config.minSize):min(self.config.maxSize)
	return self.size
end

function Element:getSize()
	return self.size or self:resize()
end

return Element
