local featherd = bundl "feather.featherd" ---@type feather.featherd

local ogPosX, ogPosY = term.getCursorPos()
local win1 = window.create(term.current(), 10, 10, 30, 20, true)

local proc1 = featherd.addProcess("shell1", function()
	shell.run("shell")
end, nil, nil, win1, true)

--[[
local win2 = window.create(term.current(), 40, 10, 30, 20, false)
local proc2 = featherd.addProcess("shell2", function()
	shell.run("shell")
end, nil, nil, win2, true)

featherd.addProcess("shell2visibler", function()
	sleep(3)
	local ogPosX, ogPosY = term.getCursorPos()
	win2.setVisible(true)
	term.setCursorPos(ogPosX, ogPosY)
end)

featherd.addProcess("shell1visibler", function()
	sleep(3)
	proc1.captureInput = false
end)
--]]


term.setCursorPos(ogPosX, ogPosY)
