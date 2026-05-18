local Element = bundl "feather.lycantrophy.elements.Element" ---@type lib.feather.lycantrophy.Element
---@class lib.feather.lycantrophy.SelectorElement: lib.feather.lycantrophy.Element
---@field thickness integer
---@field highlightColor? ccTweaked.colors.color
---@field child? lib.feather.lycantrophy.Element
---@field focused boolean
---@field super lib.feather.lycantrophy.Element
local SelectorElement = Element:extend()

---@param hightlightColor? ccTweaked.colors.color
---@param child? lib.feather.lycantrophy.Element
---@param config? lib.feather.lycantrophy.config
function SelectorElement:new(hightlightColor, child, config)
	local selectorElement = SelectorElement.super.new(self, config)
	---@cast selectorElement lib.feather.lycantrophy.SelectorElement
	selectorElement.highlightColor = hightlightColor
	selectorElement.child = child
	selectorElement.focused = false
	return setmetatable(selectorElement, SelectorElement) --[[@as lib.feather.lycantrophy.SelectorElement]]
end

---@param pos lib.feather.vec2d
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
end

return SelectorElement
