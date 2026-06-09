local mush = bundl "feather.mush" ---@type feather.mush

local function describeArg(argument, desc)
	term.setTextColor(colors.gray)
	write(arg[0] .. " ")
	term.setTextColor(colors.yellow)
	write(argument)
	term.setTextColor(colors.white)
	print(" - " .. desc)
end

local function help()
	term.setTextColor(colors.yellow)
	write("Mush")
	term.setTextColor(colors.white)
	print(", a multishell alternative.")
	describeArg("", "starts mush, or macros a new tab")
end


local arg = ...
if arg == "help" then
	help()
end
