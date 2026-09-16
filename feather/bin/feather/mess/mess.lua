---@type feather.petty
local petty = bundl("feather.petty")
---@type feather.mess
local mess = bundl("feather.mess")

local argh = bundl "feather.argh" ---@type feather.argh

---TODO: using ctrl+w when a process is running breaks it


local programPath = fs.combine(feather.installPath, "bin/feather/mess/mess.lua")
local args = argh.parse(programPath, "mess", "a lua reimplementation of less",
	{
		flags = {
			wrap = { short = "w", description = "wraps text to fit the terminal" },
		},
		sufficient = true,
		next = {
			{
				name = "textFile",
				description = "path of file to read",
				argument = argh.argument.file,
			},
			{
				name = "help",
				description = "shows this help menu",
				argument = argh.argument.name,
			},
		}
	}, ...)



if not args[2] or args[2].name == "help" then
	argh.help(programPath)
	return
end

local filename = args[2].argument
local file = fs.open(filename, "r")
assert(file, "Couldn't open file: " .. filename)
local contents = file.readAll() or ""

---@type ccTweaked.cc.pretty.Doc.text
local doc = petty.text(contents)
if args[1].flags.wrap then
	doc = petty.wrap(doc, term.getSize())
end

mess.focus(doc)
