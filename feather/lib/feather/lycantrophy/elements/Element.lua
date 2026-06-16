local Object = bundl("feather.Object") ---@type feather.Object
local vec = bundl("feather.vec2d") ---@type feather.vec2d
local defaultConfig = bundl("feather.lycantrophy.defaultConfig") ---@type feather.lycantrophy.config
---@class feather.lycantrophy.Element: feather.Object
---@field config feather.lycantrophy.config
---@field size? feather.vec2d
---@field super feather.Object
---@field pos? feather.vec2d
local Element = Object:extend()


---@param config? feather.lycantrophy.config
function Element:new(config)
	local element = Element.super.new(self)
	---@cast element feather.lycantrophy.Element
	element.config = config or defaultConfig
	return setmetatable(element, Element) --[[@as feather.lycantrophy.Element]]
end

---@param pos feather.vec2d
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

---@param size? feather.vec2d
---@return feather.vec2d size
function Element:resize(size)
	self.size = (size or vec.zero):max(self.config.minSize):min(self.config.maxSize)
	return self.size
end

function Element:getSize()
	return self.size or self:resize()
end

return Element
