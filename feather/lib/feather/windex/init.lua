---@class feather.windex
local module = {}



---Windex will create a window object while retaining cursor pos.
---original documentation:
---Create a `Window` object that can be used as a terminal redirect
---@param parent ccTweaked.term.Redirect|ccTweaked.peripheral.Monitor The parent terminal to draw to
---@param x number The x position of this window within the parent
---@param y number The y position of this window within the parent
---@param width number The width of this window
---@param height number The height of this window
---@param visible? boolean If this window should immediately be visible (defaults to true)
---@return Window window The window object
------
---[Official Documentation](https://tweaked.cc/module/window.html#v:create)
function module.create(parent, x, y, width, height, visible)
	local curX, curY = term.getCursorPos()
	local w = window.create(parent, x, y, width, height, visible)
	term.setCursorPos(curX, curY)
	return w
end

return module
