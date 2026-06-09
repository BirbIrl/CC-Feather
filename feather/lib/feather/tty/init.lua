local vec = bundl "feather.vec2d" ---@type lib.feather.vec2d

---@class feather.tty: term
local module = {}
setmetatable(module, { __index = term })

---@class feather.tty.style
---@field pos? lib.feather.vec2d
---@field color ccTweaked.colors.color
---@field bgColor ccTweaked.colors.color
---@field blink boolean
--maybe implement palette later?


---@type feather.tty.style[]
module.stack = {}

---@return lib.feather.vec2d
function module.getSize()
	return vec.new(term.getSize())
end

---@return lib.feather.vec2d
function module.getCursorPos()
	return vec.new(term.getCursorPos())
end

---@param pos lib.feather.vec2d
function module.setCursorPos(pos)
	term.setCursorPos(pos.x, pos.y)
end

---@param savePosition true?
function module.saveStyle(savePosition)
	return {
		pos = savePosition and module.getCursorPos(),
		color = module.getTextColor(),
		bgColor = module.getBackgroundColor(),
		blink = module.getCursorBlink()
	}
end

---@param style feather.tty.style
function module.loadStyle(style)
	if style.pos then
		module.setCursorPos(style.pos)
	end
	module.setTextColor(style.color)
	module.setBackgroundColor(style.bgColor)
	module.setCursorBlink(style.blink)
end

---@param savePosition true?
function module.push(savePosition)
	module.stack[#module.stack + 1] = module.saveStyle(savePosition)
end

function module.pop()
	local head = module.stack[#module.stack]
	module.loadStyle(head)
	module.stack[#module.stack] = nil
end

return module
