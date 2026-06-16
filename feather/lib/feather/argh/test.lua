local argh = bundl "feather.argh" ---@type feather.argh

---@type feather.argh.spec
local spec = {
	flags = {
		test = { short = "t", description = "test flag" },
		silent = { short = "s", description = "hides output" }
	},
	sufficient = true,
	next = {
		{
			name = "path",
			description = "takes in a path",
			argument = argh.argument.file,
		},
		{
			name = "label",
			argument = argh.argument.name,
			flags = { test = { short = "t" }, silent = { short = "s" } },
			next = {
				{
					name = "customFilter",
					description = "search using customFilter",
					argument = argh.argument.name,
				},
				{
					name = "numba",
					description = "search using given [numba]",
					argument = argh.argument.number,
				},
			},
		},
		{
			name = "help",
			description = "gives help on the testing function",
			argument = argh.argument.name,
		}
	},
}

local args = argh.parse("test.lua", "test", "testing function", spec, ...)

if not args[2] or args[2].name == "help" then
	argh.help("test.lua")
	return
end

local pp = require("cc.pretty").pretty_print
pp(args)
