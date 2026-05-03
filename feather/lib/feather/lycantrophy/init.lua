local petty = bundl "feather.petty" ---@type lib.feather.petty
local Object = bundl("feather.object") ---@type lib.feather.object
local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d
---@class lib.feather.lycantrophy
local module = {}

---@alias lib.feather.lycantrophy.config {minSize?: lib.feather.vec2d, maxSize?: lib.feather.vec2d, border?: boolean, margin?: integer, borderColor: ccTweaked.colors.color, backgroundColor: ccTweaked.colors.color}


---@type lib.feather.lycantrophy.config
module.defaultConfig = {
	minSize = vec.zero,
	maxSize = vec.huge,
	border = true,
	margin = 1,
	borderColor = colors.gray,
	backgroundColor = colors.black,
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
---@field super lib.feather.object
module.Element = Object:extend()

---@param config? lib.feather.lycantrophy.config
function module.Element:new(config)
	local element = module.Element.super.new(self)
	---@cast element lib.feather.lycantrophy.Element
	element.config = config or module.defaultConfig
	return setmetatable(element, module.Element)
end

function module.Element:getAvailableSpace()
	local space =
		self.config.maxSize - self.config.margin * 2
	return space
end

---@param pos lib.feather.vec2d
---@param size? lib.feather.vec2d
function module.Element:draw(pos, size)
	size = size or vec.zero
	local margin = self.config.margin
	local to = pos + (size + margin * 2):max(self.config.minSize):min(self.config.maxSize) - vec.one
	paintutils.drawFilledBox(pos.x, pos.y, to.x, to.y,
		self.config.backgroundColor)
	if self.config.border then
		paintutils.drawBox(pos.x, pos.y, to.x, to.y,
			self.config.borderColor)
	end
	term.setBackgroundColor(self.config.backgroundColor)
	term.setCursorPos(pos.x + margin, pos.y + margin)
end

---@class lib.feather.lycantrophy.TextElement: lib.feather.lycantrophy.Element
---@field text ccTweaked.cc.pretty.Doc.concat|ccTweaked.cc.pretty.Doc.text
---@field wrapped {text: ccTweaked.cc.pretty.Doc.concat, size: lib.feather.vec2d}
---@field super lib.feather.lycantrophy.Element
module.TextElement = module.Element:extend()

---@param text ccTweaked.cc.pretty.Doc.concat|ccTweaked.cc.pretty.Doc.text
---@param config? lib.feather.lycantrophy.config
---@return lib.feather.lycantrophy.TextElement
function module.TextElement:new(text, config)
	local textElement = module.TextElement.super.new(self, config)

	---@cast textElement lib.feather.lycantrophy.TextElement
	textElement.text = text
	setmetatable(textElement, module.TextElement) --[[@as lib.feather.lycantrophy.TextElement]]
	textElement:onResize()
	return textElement
end

function module.TextElement:onResize()
	local text, height, width =
		petty.wrap(self.text, self:getAvailableSpace().x)
	self.wrapped = { text = text, size = vec.new(width, height) }
end

function module.TextElement:draw(pos)
	local size = self.wrapped.size:max(self.config.minSize):min(self.config.maxSize)
	module.TextElement.super.draw(self, pos, size)
	petty.pp(self.wrapped.text, nil, self:getAvailableSpace().y)
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
