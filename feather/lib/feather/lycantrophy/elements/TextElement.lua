local petty = bundl "feather.petty" ---@type feather.petty
local vec = bundl("feather.vec2d") ---@type feather.vec2d
local Element = bundl "feather.lycantrophy.elements.Element" ---@type feather.lycantrophy.Element

---@class feather.lycantrophy.TextElement: feather.lycantrophy.Element
---@field text ccTweaked.cc.pretty.Doc.concat|ccTweaked.cc.pretty.Doc.text
---@field alignment feather.petty.alignment
---@field wrapped ccTweaked.cc.pretty.Doc.concat
---@field super feather.lycantrophy.Element
local TextElement = Element:extend()

---@param text ccTweaked.cc.pretty.Doc.concat|ccTweaked.cc.pretty.Doc.text
---@param alignemnt? feather.petty.alignment
---@param config? feather.lycantrophy.config
---@return feather.lycantrophy.TextElement
function TextElement:new(text, alignemnt, config)
	local textElement = TextElement.super.new(self, config)
	---@cast textElement feather.lycantrophy.TextElement
	textElement.text = text
	textElement.alignment = alignemnt or "left"
	setmetatable(textElement, TextElement) --[[@as feather.lycantrophy.TextElement]]
	return textElement
end

---@param size? feather.vec2d
---@return feather.vec2d size
function TextElement:resize(size)
	---@cast size feather.vec2d
	local maxSize = self.config.maxSize:min(size or vec.huge)
	local text, height, width =
		petty.wrap(self.text, maxSize.x)
	if size then
		self.size = size
	else
		self.size = vec.new(width, height)
	end
	self.wrapped = petty.align(text, maxSize.x, self.alignment)
	return self.size
end

---@param pos feather.vec2d
---@param backgroundColor? ccTweaked.colors.color
function TextElement:draw(pos, backgroundColor)
	TextElement.super.draw(self, pos, backgroundColor)
	term.setCursorPos(pos.x, pos.y)
	petty.pp(self.wrapped, nil, self:getSize().y)
end

return TextElement
