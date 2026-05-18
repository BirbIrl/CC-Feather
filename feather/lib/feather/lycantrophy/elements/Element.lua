local Object = bundl("feather.Object") ---@type lib.feather.Object
local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d
local defaultConfig = bundl("feather.lycantrophy.defaultConfig") ---@type lib.feather.lycantrophy.config
---@class lib.feather.lycantrophy.Element: lib.feather.Object
---@field config lib.feather.lycantrophy.config
---@field size? lib.feather.vec2d
---@field super lib.feather.Object
---@field pos? lib.feather.vec2d
local Element = Object:extend()


---@param config? lib.feather.lycantrophy.config
function Element:new(config)
	local element = Element.super.new(self)
	---@cast element lib.feather.lycantrophy.Element
	element.config = config or defaultConfig
	return setmetatable(element, Element) --[[@as lib.feather.lycantrophy.Element]]
end

---@param pos lib.feather.vec2d
---@param backgroundColor? ccTweaked.colors.color
function Element:draw(pos, backgroundColor)
	backgroundColor = backgroundColor or self.config.backgroundColor
	local to = pos + self:getSize() - vec.one
	if pos:max(to) ~= pos then
		paintutils.drawFilledBox(pos.x, pos.y, to.x, to.y,
			backgroundColor)
	end
	term.setBackgroundColor(backgroundColor)
	self.pos = pos
end

function Element:redraw()
	assert(self.pos, "First an element needs to be drawn before being redrawn")
	self:draw(self.pos)
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
