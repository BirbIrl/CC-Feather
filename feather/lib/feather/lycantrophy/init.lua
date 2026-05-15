local petty = bundl "feather.petty" ---@type lib.feather.petty
local Object = bundl("feather.object") ---@type lib.feather.object
local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d
---@class lib.feather.lycantrophy
local module = {}

---@alias lib.feather.lycantrophy.config {
---minSize: lib.feather.vec2d,
---maxSize: lib.feather.vec2d,
---backgroundColor: ccTweaked.colors.color }


---@type lib.feather.lycantrophy.config
module.defaultConfig = {
	minSize = vec.zero,
	maxSize = vec.huge,
	backgroundColor = colors.gray,
}

---@param template? lib.feather.lycantrophy.config
---@return lib.feather.lycantrophy.config
function module.newConfig(template)
	local newConfig = {}
	for k, v in pairs(module.defaultConfig) do
		newConfig[k] = template and template[k] or v
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
	return setmetatable(element, module.Element) --[[@as lib.feather.lycantrophy.Element]]
end

---@param pos lib.feather.vec2d
function module.Element:draw(pos)
	local to = pos + self:getSize() - vec.one
	paintutils.drawFilledBox(pos.x, pos.y, to.x, to.y,
		self.config.backgroundColor)
	term.setBackgroundColor(self.config.backgroundColor)
end

---@param size? lib.feather.vec2d
---@return lib.feather.vec2d size
function module.Element:resize(size)
	self.size = size or self.config.minSize
	return self.size
end

function module.Element:getSize()
	return self.size or self:resize()
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
---@return lib.feather.vec2d size
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
	self.wrapped = petty.align(text, maxSize.x, self.alignment)
	return self.size
end

function module.TextElement:draw(pos)
	module.TextElement.super.draw(self, pos)
	term.setCursorPos(pos.x, pos.y)
	petty.pp(self.wrapped, nil, self:getSize().y)
end

---@class lib.feather.lycantrophy.FrameElement: lib.feather.lycantrophy.Element
---@field thickness integer
---@field color? ccTweaked.colors.color
---@field child? lib.feather.lycantrophy.Element
---@field super lib.feather.lycantrophy.Element
module.FrameElement = module.Element:extend()

---@param thickness integer
---@param color? ccTweaked.colors.color
---@param child? lib.feather.lycantrophy.Element
---@param config? lib.feather.lycantrophy.config
function module.FrameElement:new(thickness, color, child, config)
	assert(thickness > 0, "thickness must be greater than 0")
	local frameElement = module.FrameElement.super.new(self, config)
	---@cast frameElement lib.feather.lycantrophy.FrameElement
	frameElement.thickness = thickness
	frameElement.color = color
	frameElement.child = child
	return setmetatable(frameElement, module.FrameElement) --[[@as lib.feather.lycantrophy.FrameElement]]
end

function module.FrameElement:resize(size)
	if not self.child then
		self.size = (vec.one * self.thickness * 2):max(self.config.minSize):min(self.config.maxSize)
		return self.size
	end
	local preferred = self.child:getSize()
	local max = (size or self.config.maxSize) - self.thickness * 2
	self.child:resize(max:min(preferred))
	self.size = self.child:getSize() + self.thickness * 2
	return self.size
end

function module.FrameElement:draw(pos)
	module.FrameElement.super.draw(self, pos)
	local size = self:getSize()
	local to = pos + size - 1
	for i = 0, self.thickness - 1, 1 do
		paintutils.drawBox(pos.x + i, pos.y + i, to.x - i, to.y - i, self.color)
	end
	if self.child then
		self.child:draw(pos + self.thickness)
	end
end

---@alias lib.feather.lycantrophy.direction "horizontal"|"vertical"

---@class lib.feather.lycantrophy.GroupElement: lib.feather.lycantrophy.Element
---@field children lib.feather.lycantrophy.Element[]
---@field direction lib.feather.lycantrophy.direction
---@field super lib.feather.lycantrophy.Element
module.GroupElement = module.Element:extend()

---@param direction? lib.feather.lycantrophy.direction
---@param config? lib.feather.lycantrophy.config
---@param ... lib.feather.lycantrophy.Element
function module.GroupElement:new(direction, config, ...)
	local groupElement = module.GroupElement.super.new(self, config)
	---@cast groupElement lib.feather.lycantrophy.GroupElement
	groupElement.direction = direction or "horizontal"
	groupElement.children = table.pack(...)
	return setmetatable(groupElement, module.GroupElement) --[[@as lib.feather.lycantrophy.GroupElement]]
end

return module
