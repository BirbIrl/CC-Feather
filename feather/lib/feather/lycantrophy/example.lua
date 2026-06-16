local vec = bundl "feather.vec2d" ---@type feather.vec2d
local lycantrophy = bundl "feather.lycantrophy" ---@type feather.lycantrophy
local petty = bundl "feather.petty" ---@type feather.petty

local config = lycantrophy.newConfig()
config.maxSize = vec.newCCSquare(10)
local config2 = lycantrophy.newConfig()
config2.maxSize = vec.new(19, 10)
local textObject1 = lycantrophy.TextElement:new(petty.concat(petty.text("Word,", colors.green),
	petty.text(" Loooooooooooo"), petty.text("OOO", colors.red), petty.text("ooooooongWooord!")), "center", config)
local textObject2 = lycantrophy.TextElement:new(petty.concat(petty.text("Word,", colors.green),
	petty.text(" Loooooooooooo"), petty.text("OOO", colors.red), petty.text("ooooooongWooord!")), "center", config2)
local frame1 = lycantrophy.FrameElement:new(1, colors.red, textObject1, config)
local frame2 = lycantrophy.FrameElement:new(1, colors.red, textObject2, config2)
local selector1 = lycantrophy.SelectorElement:new(colors.green, frame1)
local selector2 = lycantrophy.SelectorElement:new(colors.green, frame2)
local group = lycantrophy.GroupElement:new("y", false, false, nil, selector1, selector2)
local root = lycantrophy.RootElement:new(group)

--[[
frame:draw(vec.new(20, 5))
frame:draw(vec.new(40, 5))
--]]
group:resize(vec.newCCSquare(25))
root:draw(vec.new(term.getCursorPos()))
term.setBackgroundColor(colors.black)
term.setCursorPos(1, 30)
root:mapSelectors()
root:focus(selector1)
root:process()
