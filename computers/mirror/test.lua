local petty = bundl "feather.petty" ---@type lib.feather.petty

local doc, lines = petty.wrap(
	petty.concat("Hiii hell ", petty.text("hii ", colors.red), petty.text("hii", colors.yellow)), 11)
--local doc, lines = petty.wrap(petty.concat("Hiii hello, hi!", "hii"), 11)
petty.pp(doc)
petty.pp(lines)
--print(lines)
