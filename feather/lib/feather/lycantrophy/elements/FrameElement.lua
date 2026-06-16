local vec = bundl("feather.vec2d") ---@type feather.vec2d
local Element = bundl "feather.lycantrophy.elements.Element" ---@type feather.lycantrophy.Element
---@class feather.lycantrophy.FrameElement: feather.lycantrophy.Element
---@field thickness integer
---@field color? ccTweaked.colors.color
---@field child? feather.lycantrophy.Element
---@field super feather.lycantrophy.Element
local FrameElement = Element:extend()

---@param thickness integer
---@param color? ccTweaked.colors.color
---@param child? feather.lycantrophy.Element
---@param config? feather.lycantrophy.config
function FrameElement:new(thickness, color, child, config)
	assert(thickness > 0, "thickness must be greater than 0")
	local frameElement = FrameElement.super.new(self, config)
	---@cast frameElement feather.lycantrophy.FrameElement
	frameElement.thickness = thickness
	frameElement.color = color
	frameElement.child = child
	return setmetatable(frameElement, FrameElement) --[[@as feather.lycantrophy.FrameElement]]
end

---@param size feather.vec2d
function FrameElement:resize(size)
	if not self.child then
		self.size = (vec.one * self.thickness * 2):max(self.config.minSize):min(self.config.maxSize)
		return self.size
	end
	local preferred = self.child:getSize()
	local max = (size or self.config.maxSize) - self.thickness * 2
	local target = max:min(preferred)
	if preferred ~= target then
		self.child:resize(max:min(preferred))
	end
	self.size = self.child:getSize() + self.thickness * 2
	return self.size
end

---@param pos feather.vec2d
---@param backgroundColor? ccTweaked.colors.color
function FrameElement:draw(pos, backgroundColor)
	FrameElement.super.draw(self, pos, backgroundColor)
	local size = self:getSize()
	local to = pos + size - 1
	for i = 0, self.thickness - 1, 1 do
		paintutils.drawBox(pos.x + i, pos.y + i, to.x - i, to.y - i,
			self.color or backgroundColor or self.config.backgroundColor)
	end
	if self.child then
		self.child:draw(pos + self.thickness, backgroundColor)
	end
end

return FrameElement
