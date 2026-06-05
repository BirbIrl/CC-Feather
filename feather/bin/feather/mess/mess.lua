---@type lib.feather.petty
local petty = bundl("feather.petty")
---@type lib.feather.mess
local mess = bundl("feather.mess")

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
	write("Mess")
	term.setTextColor(colors.white)
	print(", a text file reader.")
	describeArg("[fileName]", "opens the given file as text")
	--TODO implement this
	--describeArg("w [fileName]", "wraps the text")
end

local flags = {
	w = false -- wrap
}


local filename

for i, argument in ipairs(arg) do
	if i == #arg then
		filename = argument
	else
		assert(argument:sub(1, 1) == "-", "arguments must start with -")
		local flag = argument:sub(2, 2)
		assert(flag ~= "", "no flag given after dash")
		assert(flags[flag] ~= nil, "the given flag" .. flag .. " doesn't exist")
		flags[flag] = true
	end
end




if not filename then
	help()
	return
end

local file = fs.open(filename, "r")
assert(file, "Couldn't open file: " .. filename)
local contents = file.readAll() or ""

---@type ccTweaked.cc.pretty.Doc.text
local doc = petty.text(contents)

mess.focus(doc)
