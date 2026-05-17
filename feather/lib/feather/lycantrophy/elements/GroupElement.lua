local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d
local Element = bundl "feather.lycantrophy.elements.Element" ---@type lib.feather.lycantrophy.Element
---@alias lib.feather.lycantrophy.direction "horizontal"|"vertical"

---@class lib.feather.lycantrophy.GroupElement: lib.feather.lycantrophy.Element
---@field children lib.feather.lycantrophy.Element[]
---@field direction lib.feather.lycantrophy.direction
---@field super lib.feather.lycantrophy.Element
local GroupElement = Element:extend()

---@param direction? lib.feather.lycantrophy.direction
---@param config? lib.feather.lycantrophy.config
---@param ... lib.feather.lycantrophy.Element
function GroupElement:new(direction, config, ...)
	local groupElement = GroupElement.super.new(self, config)
	---@cast groupElement lib.feather.lycantrophy.GroupElement
	groupElement.direction = direction or "horizontal"
	groupElement.children = table.pack(...)
	return setmetatable(groupElement, GroupElement) --[[@as lib.feather.lycantrophy.GroupElement]]
end

return GroupElement
