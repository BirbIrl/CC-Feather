local pp = require("cc.pretty").pretty_print
local petty = bundl"feather.petty"


local doc,lines  = petty.petty({"Hell", "o", "this is a test"}, 4)
pp(doc)
pp(lines)
