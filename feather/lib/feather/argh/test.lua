local argh = bundl "feather.argh" ---@type feather.argh

---@type feather.argh.spec
local spec = {
	flags = { test = { short = "t" }, silent = { short = "s" } },
	sufficient = true,
	next = {
		{
			name = "label",
			argument = argh.argument.name,
			flags = { test = { short = "t" }, silent = { short = "s" } },
			sufficient = nil,
			next = {
				{
					name = "customFilter",
					argument = argh.argument.name,
				},
				{
					name = "anyString",
					argument = argh.argument.string,
				},
			},
		},
		{
			name = "help",
			argument = argh.argument.name,
		}
	},
}

shell.setCompletionFunction("test.lua", argh.makeCompletionFunction(
	spec
))


local pp = require("cc.pretty").pretty_print

pp(argh.parse("test.lua", "test", "testing function", spec, arg))
