local vec = bundl "feather.vec2d" ---@type lib.feather.vec2d
local lycantrophy = bundl "feather.lycantrophy" ---@type lib.feather.lycantrophy
local petty = bundl "feather.petty" ---@type lib.feather.petty

local config = lycantrophy.newConfig()
config.maxSize = vec.new(10, 10)
local textObject = lycantrophy.TextElement:new(petty.concat(petty.text("Word,", colors.green),
	petty.text(" Loooooooooooo"), petty.text("OOO", colors.red), petty.text("ooooooongWooord!")), config)


textObject:draw(vec.new(5, 5))
term.setCursorPos(1, 20)
term.clearLine()
