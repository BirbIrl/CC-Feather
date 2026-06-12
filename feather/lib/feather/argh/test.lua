local argh = bundl "feather.argh" ---@type feather.argh


shell.setCompletionFunction("rom/programs/fun/hello.lua", argh.makeCompletionFunction(
	{
		flags = { test = { short = "t" }, silent = { short = "s" } },
		next = {
			name = "label",
			argument = argh.argument.name,
			flags = { test = { short = "t" }, silent = { short = "s" } },
			next = {
				{
					name = "customFilter",
					argument = argh.argument.name,
				},
				{
					name = "anyString",
					argument = argh.argument.string,
				},
			}
		},
	}
))
