local petty = bundl "feather.petty" ---@type lib.feather.petty
local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d
local Element = bundl "feather.lycantrophy.elements.Element" ---@type lib.feather.lycantrophy.Element

---@class lib.feather.lycantrophy.TextElement: lib.feather.lycantrophy.Element
---@field text ccTweaked.cc.pretty.Doc.concat|ccTweaked.cc.pretty.Doc.text
---@field alignment lib.feather.petty.alignment
---@field wrapped ccTweaked.cc.pretty.Doc.concat
---@field super lib.feather.lycantrophy.Element
local TextElement = Element:extend()

---@param text ccTweaked.cc.pretty.Doc.concat|ccTweaked.cc.pretty.Doc.text
---@param alignemnt? lib.feather.petty.alignment
---@param config? lib.feather.lycantrophy.config
---@return lib.feather.lycantrophy.TextElement
function TextElement:new(text, alignemnt, config)
	local textElement = TextElement.super.new(self, config)
	---@cast textElement lib.feather.lycantrophy.TextElement
	textElement.text = text
	textElement.alignment = alignemnt or "left"
	setmetatable(textElement, TextElement) --[[@as lib.feather.lycantrophy.TextElement]]
	return textElement
end

---@param size? lib.feather.vec2d
---@return lib.feather.vec2d size
function TextElement:resize(size)
	---@cast size lib.feather.vec2d
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

---@param pos lib.feather.vec2d
---@param backgroundColor? ccTweaked.colors.color
function TextElement:draw(pos, backgroundColor)
	TextElement.super.draw(self, pos, backgroundColor)
	term.setCursorPos(pos.x, pos.y)
	petty.pp(self.wrapped, nil, self:getSize().y)
end

return TextElement
