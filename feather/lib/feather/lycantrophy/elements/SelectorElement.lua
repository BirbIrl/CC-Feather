local Element = bundl "feather.lycantrophy.elements.Element" ---@type feather.lycantrophy.Element
---@class feather.lycantrophy.SelectorElement: feather.lycantrophy.Element
---@field thickness integer
---@field highlightColor? ccTweaked.colors.color
---@field child? feather.lycantrophy.Element
---@field focused boolean
---@field super feather.lycantrophy.Element
local SelectorElement = Element:extend()

---@param hightlightColor? ccTweaked.colors.color
---@param child? feather.lycantrophy.Element
---@param config? feather.lycantrophy.config
function SelectorElement:new(hightlightColor, child, config)
	local selectorElement = SelectorElement.super.new(self, config)
	---@cast selectorElement feather.lycantrophy.SelectorElement
	selectorElement.highlightColor = hightlightColor
	selectorElement.child = child
	selectorElement.focused = false
	return setmetatable(selectorElement, SelectorElement) --[[@as feather.lycantrophy.SelectorElement]]
end

---@param pos feather.vec2d
function SelectorElement:draw(pos)
	local color = (self.focused and self.highlightColor) or nil
	self.super.draw(self, pos, color)
	if self.child then
		self.child:draw(pos, color)
	end
end

function SelectorElement:resize(size)
	if self.child then
		local preferred = self.child:getSize()
		local max = (size or self.config.maxSize)
		local target = max:min(preferred)
		if preferred ~= target then
			self.child:resize(max:min(preferred))
		end
		self.size = self.child:getSize()
	else
		self.super.resize(self, size)
	end
	return self.size
end

---@param packedEvent [ccTweaked.os.event, ...]
function SelectorElement:onEvent(packedEvent)
	--- TO BE IMPLEMENTED
	return packedEvent
end

return SelectorElement
