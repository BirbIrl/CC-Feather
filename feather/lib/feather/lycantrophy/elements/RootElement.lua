local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d

---@alias lib.feather.lycantrophy.RootElement.selectorMap table<lib.feather.lycantrophy.SelectorElement, lib.feather.vec2d>

local Element = bundl "feather.lycantrophy.elements.Element" ---@type lib.feather.lycantrophy.Element
local SelectorElement = bundl "feather.lycantrophy.elements.SelectorElement" ---@type lib.feather.lycantrophy.SelectorElement
---@class lib.feather.lycantrophy.RootElement: lib.feather.lycantrophy.Element
---@field child? lib.feather.lycantrophy.Element
---@field super lib.feather.lycantrophy.Element
---@field selectors lib.feather.lycantrophy.RootElement.selectorMap
---@field focusedElement? lib.feather.lycantrophy.SelectorElement
local RootElement = Element:extend()


---@param child? lib.feather.lycantrophy.Element
---@param config? lib.feather.lycantrophy.config
function RootElement:new(child, config)
	local rootElement = RootElement.super.new(self, config)
	---@cast rootElement lib.feather.lycantrophy.RootElement
	rootElement.child = child
	return setmetatable(rootElement, RootElement) --[[@as lib.feather.lycantrophy.RootElement]]
end

---@param node lib.feather.lycantrophy.Element
---@param record? lib.feather.lycantrophy.RootElement.selectorMap
---@return lib.feather.lycantrophy.RootElement.selectorMap
local function map(node, record)
	record = record or {}
	if node:instanceOf(SelectorElement) and node.pos then
		assert(not record[node], "element already inside the record, you're probably displayng the same selector twice")
		record[node] = node.pos
	end
	---@cast node lib.feather.lycantrophy.FrameElement|lib.feather.lycantrophy.GroupElement
	if node.child then
		map(node.child, record)
	elseif node.children then
		for _, child in ipairs(node.children) do
			map(child, record)
		end
	end
	return record
end

function RootElement:resize()
	if self.child then
		self.size = self.child:getSize()
	else
		self.size = vec.zero
	end
	return self.size
end

function RootElement:mapSelectors()
	assert(self.pos, "Must be drawn first before mapping selectors")
	self.selectors = map(self)
end

---@param node lib.feather.lycantrophy.SelectorElement
function RootElement:focus(node)
	assert(node:instanceOf(SelectorElement))
	if self.focusedElement == node then
		return
	elseif self.focusedElement then
		self.focusedElement.focused = false
		self.focusedElement:redraw()
	end
	self.focusedElement = node
	node.focused = true
	node:redraw()
end

---@param pos lib.feather.vec2d
function RootElement:draw(pos)
	self.super.draw(self, pos)
	if self.child then
		self.child:draw(pos)
	end
end

function RootElement:process()
	repeat

	until self:processEvent(table.pack(os.pullEvent()))
	if self.pos then
		term.setCursorPos(1, self:getSize().y + self.pos.y)
	end
end

---@private
---@param pos lib.feather.vec2d
function RootElement:findSelectorUnderPixel(pos)
	assert(self.selectors, "Selectors must be mapped first")
	for node, nodePos in pairs(self.selectors) do
		if (node.size - 1):contains(pos - nodePos) then
			return node
		end
	end
end

---@param axis lib.feather.lycantrophy.axis
---@param backwards boolean
function RootElement:moveSelection(axis, backwards)
	local curr = self.focusedElement
	if not curr then
		return
	end
	local termSize = vec.new(term.getSize())
	for offset = curr.pos[axis], backwards and 0 or termSize[axis], backwards and -1 or 1 do
		local targetPos = curr.pos:clone()
		targetPos[axis] = offset
		local found = self:findSelectorUnderPixel(targetPos)
		if found and found ~= curr then
			self:focus(found)
			return true
		end
	end
	return false
end

---@param packedEvent [ccTweaked.os.event, ...]
function RootElement:processEvent(packedEvent)
	local eventName = packedEvent[1]
	if eventName == "key" then
		local key = packedEvent[2]
		if key == keys.backspace then
			return true
		elseif key == keys.enter then
		elseif key == keys.up then
			self:moveSelection("y", true)
		elseif key == keys.down then
			self:moveSelection("y", false)
		elseif key == keys.left then
			self:moveSelection("x", true)
		elseif key == keys.right then
			self:moveSelection("x", false)
		end
	elseif eventName == "mouse_click" then
		--local btn = packedEvent[2]
		local pos = vec.new(packedEvent[3], packedEvent[4])
		local target = self:findSelectorUnderPixel(pos)
		if target then
			self:focus(target)
		end
	end
	if self.focusedElement then
		self.focusedElement:onEvent(packedEvent)
	end
end

return RootElement
