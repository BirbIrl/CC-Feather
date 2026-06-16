local Element = bundl "feather.lycantrophy.elements.Element" ---@type feather.lycantrophy.Element
local vec = bundl("feather.vec2d") ---@type feather.vec2d

---@alias feather.lycantrophy.axis "x"|"y"

local flippedAxis = {
	x = "y",
	y = "x"
}

---@class feather.lycantrophy.GroupElement: feather.lycantrophy.Element
---@field children feather.lycantrophy.Element[]
---@field axis feather.lycantrophy.axis
---@field super feather.lycantrophy.Element
---@field overflow boolean
---@field backwards boolean
---@field visibleChildren? integer
local GroupElement = Element:extend()

---@param axis? feather.lycantrophy.axis
---@param overflow? boolean
---@param backwards? boolean
---@param config? feather.lycantrophy.config
---@param ... feather.lycantrophy.Element
function GroupElement:new(axis, overflow, backwards, config, ...)
	local groupElement = GroupElement.super.new(self, config)
	---@cast groupElement feather.lycantrophy.GroupElement
	groupElement.axis = axis or "x"
	groupElement.children = table.pack(...)
	groupElement.overflow = overflow or false
	groupElement.backwards = backwards or false
	groupElement.visibleChildren = 0
	return setmetatable(groupElement, GroupElement) --[[@as feather.lycantrophy.GroupElement]]
end

---@param size? feather.vec2d
---@return feather.vec2d size
function GroupElement:resize(size)
	if size then
		self.size = size
	else
		local preferred = vec.zero:clone()
		for _, child in ipairs(self.children) do
			local childSize = child:getSize()
			preferred[self.axis] = preferred[self.axis] + childSize[self.axis]
			preferred = preferred:max(childSize)
		end
		self.size = preferred
	end
	self.super.resize(self, self.size)
	local availableSpace = self.size[self.axis]
	local limitingSpace = self.size[flippedAxis[self.axis]]

	if self.overflow then
		self.visibleChildren = #self.children
		return self.size
	end

	self.visibleChildren = 0
	for _, child in ipairs(self.children) do
		local childSize = child:getSize()
		availableSpace = availableSpace - childSize[self.axis]
		if availableSpace >= 0 then
			self.visibleChildren = self.visibleChildren + 1
		end
		local wantedLimitedSpace = childSize[flippedAxis[self.axis]]
		assert(limitingSpace >= wantedLimitedSpace,
			"Child in group element doesn't fit. The axis: " ..
			flippedAxis[self.axis] ..
			" has a limit of: " .. limitingSpace .. " but the child wants to take up: " .. wantedLimitedSpace)
	end
	return self.size
end

---@param pos feather.vec2d
---@param backgroundColor? ccTweaked.colors.color
function GroupElement:draw(pos, backgroundColor)
	GroupElement.super.draw(self, pos, backgroundColor)
	local size = self:getSize()
	local offset = 0
	if self.backwards then
		for i = self.visibleChildren, 1, -1 do
			local child = self.children[i]
			local childSize = child:getSize()
			local offsetPos = pos:clone()
			offsetPos[self.axis] = offsetPos[self.axis] + size[self.axis] - offset - childSize[self.axis]
			child:draw(offsetPos)
			offset = offset + childSize[self.axis]
		end
	else
		for i = 1, self.visibleChildren, 1 do
			local child = self.children[i]
			local childSize = child:getSize()
			local offsetPos = pos:clone()
			offsetPos[self.axis] = offsetPos[self.axis] + offset
			child:draw(offsetPos)
			offset = offset + childSize[self.axis]
		end
	end
end

return GroupElement
