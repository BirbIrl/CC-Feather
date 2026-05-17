local vec = bundl "feather.vec2d" ---@type lib.feather.vec2d
local lycantrophy = bundl "feather.lycantrophy" ---@type lib.feather.lycantrophy
local petty = bundl "feather.petty" ---@type lib.feather.petty

local config = lycantrophy.newConfig()
config.maxSize = vec.newCCSquare(10)
local textObject = lycantrophy.TextElement:new(petty.concat(petty.text("Word,", colors.green),
	petty.text(" Loooooooooooo"), petty.text("OOO", colors.red), petty.text("ooooooongWooord!")), "center", config)


local frame = lycantrophy.FrameElement:new(1, colors.red, textObject, config)
local group = lycantrophy.GroupElement:new("y", false, false, nil, frame, frame)

--[[
frame:draw(vec.new(20, 5))
frame:draw(vec.new(40, 5))
--]]
group:resize(vec.newCCSquare(25))
group:draw(vec.new(20, 5))
term.setBackgroundColor(colors.black)
term.setCursorPos(1, 30)
term.clearLine()
