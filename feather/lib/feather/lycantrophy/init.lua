local petty = bundl "feather.petty" ---@type lib.feather.petty
local Object = bundl("feather.object") ---@type lib.feather.object
local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d
---@class lib.feather.lycantrophy
local module = {}

---@alias lib.feather.lycantrophy.config {
---minSize?: lib.feather.vec2d,
---maxSize?: lib.feather.vec2d,
---backgroundColor: ccTweaked.colors.color }


---@type lib.feather.lycantrophy.config
module.defaultConfig = {
	minSize = vec.zero,
	maxSize = vec.huge,
	backgroundColor = colors.blue,
}

---@param template? lib.feather.lycantrophy.config
---@return lib.feather.lycantrophy.config
function module.newConfig(template)
	template = template or module.defaultConfig
	local newConfig = {}
	for k, v in pairs(template) do
		newConfig[k] = v
	end
	return newConfig
end

---@class lib.feather.lycantrophy.Element: lib.feather.object
---@field config lib.feather.lycantrophy.config
---@field size? lib.feather.vec2d
---@field super lib.feather.object
module.Element = Object:extend()

---@param config? lib.feather.lycantrophy.config
function module.Element:new(config)
	local element = module.Element.super.new(self)
	---@cast element lib.feather.lycantrophy.Element
	element.config = config or module.defaultConfig
	return setmetatable(element, module.Element)
end

---@param pos lib.feather.vec2d
function module.Element:draw(pos)
	local to = pos + self:getSize() - vec.one
	paintutils.drawFilledBox(pos.x, pos.y, to.x, to.y,
		self.config.backgroundColor)
	term.setBackgroundColor(self.config.backgroundColor)
end

---@param size? lib.feather.vec2d
function module.Element:resize(size)
	self.size = size or self.config.minSize
end

function module.Element:getSize()
	_ = self.size or self:resize()
	return self.size
end

---@class lib.feather.lycantrophy.TextElement: lib.feather.lycantrophy.Element
---@field text ccTweaked.cc.pretty.Doc.concat|ccTweaked.cc.pretty.Doc.text
---@field alignment lib.feather.petty.alignment
---@field wrapped ccTweaked.cc.pretty.Doc.concat
---@field super lib.feather.lycantrophy.Element
module.TextElement = module.Element:extend()

---@param text ccTweaked.cc.pretty.Doc.concat|ccTweaked.cc.pretty.Doc.text
---@param alignemnt? lib.feather.petty.alignment
---@param config? lib.feather.lycantrophy.config
---@return lib.feather.lycantrophy.TextElement
function module.TextElement:new(text, alignemnt, config)
	local textElement = module.TextElement.super.new(self, config)
	---@cast textElement lib.feather.lycantrophy.TextElement
	textElement.text = text
	textElement.alignment = alignemnt or "left"
	setmetatable(textElement, module.TextElement) --[[@as lib.feather.lycantrophy.TextElement]]
	return textElement
end

---@param size? lib.feather.vec2d
function module.TextElement:resize(size)
	---@cast size lib.feather.vec2d
	local maxSize = self.config.maxSize:min(size or vec.huge)
	local text, height, width =
		petty.wrap(self.text, maxSize.x)
	if size then
		self.size = size
	else
		self.size = vec.new(width, height)
	end
	print(width)
	self.wrapped = petty.align(text, maxSize.x, self.alignment)
end

function module.TextElement:draw(pos)
	local size = self:getSize()
		:max(self.config.minSize)
		:min(self.config.maxSize)
	module.TextElement.super.draw(self, pos)
	term.setCursorPos(pos.x, pos.y)
	petty.pp(self.wrapped, nil, self.config.maxSize.y)
end

---@alias lib.feather.lycantrophy.direction "horizontal"|"vertical"

---@class lib.feather.lycantrophy.GroupElement: lib.feather.lycantrophy.Element
---@field children lib.feather.lycantrophy.Element[]
---@field super lib.feather.lycantrophy.Element
---@field direction lib.feather.lycantrophy.direction
module.GroupElement = module.Element:extend()

---@param direction? lib.feather.lycantrophy.direction
---@param config? lib.feather.lycantrophy.config
---@param ... unknown
function module.GroupElement:new(direction, config, ...)
	local groupElement = module.GroupElement.super.new(self, config)
	---@cast groupElement lib.feather.lycantrophy.GroupElement
	groupElement.direction = direction or "horizontal"
	groupElement.children = table.pack(...)
	return setmetatable(groupElement, module.GroupElement) --[[@as lib.feather.lycantrophy.GroupElement]]
end

return module
