---@class feather.argh
local module = {}
--[[
--library that would let you register arguments like this:
local argh = bundl("argh") ---@type feather.argh
local exactFlag = {
	short = "e",
	description = "only matches packages with the exact package name"
}
local pkgName = {
	name = "pkgName",
	argument = argh.argument.choice(function()
		local bundle = bundl("bundle")
		local pkgNames = {}
		for name, _ in bundle.listAvailable() do
			pkgNames[#pkgNames + 1] = name
		end
		return pkgNames
	end),
}
local install = {
	name = "install",
	argument = argh.argument.name(), -- not neccessary, default
	next = pkgName,
	description = "installs a program",
	flags = {
		exact = exactFlag
	}
}
local list = {
	name = "list",
	sufficient = true,
	description = false, -- false description hides it from the help menu
	next = {
		name = "filter",
		type = argh.argument.string,
		description = "lists available packages, can be filtered"
	}
}
local get = {
	name = "get",
	next = pkgName,
	description = "installs a library",
	flags = {
		exact = exactFlag -- repeat flag names are not registered for the help menu
	}
}
local args = argh.register("bundle", "A featherOS package manager", { -- first entry is only for the flags
	flags = {
		silent = {
			short = "s",
			description = "hides extra outputs"
		}
	},
	description = "shows this help menu", -- args remember their last description.
	sufficient = true,                 -- args marked as sufficient can be ended without doing their next arguments
	next = { install, get, list }      -- this will match results for either of the next members in the tree, with the first being prioritized
})

-- the help menu would generate like this:
--
--  bundle [-s?] - shows this help menu
--  bundle install [-e?] [pkgName] - installs a program
--  bundle get [-e?] [pkgName] - installs a library
--  bundle list [filter?] - lists available packages, can be filtered
--
--  -s --silent - hides extra outputs
--  -e --exact - only matches packages with the exact package name
--
-- lower depth is calculated first, and flags don't get repeated on further concats
-- args would return a tree like so:


args = {
	{
		name = nil,
		argument = nil,
		flags = {
			silent = true,
		},
	},
	{
		name = "install",
		argument = "install",
		flags = {
			exact = false
		},
	},
	{
		name = "pkgName",
		argument = "featherd",
		flags = {
		},
	},
}
-- or

args = {
	{
		name = nil,
		argument = nil,
		flags = {
			silent = false,
		},
	},
	{
		name = "list",
		argument = "list",
		flags = {
		},
	},
}

-- and then would be used like this:

if #args == 1 then
	argh.help()
end

if args[2].name == "install" then --we don't need to make sure 3 exists because argh will check that for us	
	bundle.install(args[3].argument)
end

if not args[1].flags.silent then
	print("Done!")
end

module.argument = {
	choice = nil,
	name = nil,
	string = nil,
	number = nil,
}

function module.register(name, description, spec)
	error("to be implemented")
end

-- programs called with the argument __ARGH_REGISTER_ARGS will have an extra trigger in argh.register, that would register the function's autocompletion for the shell
-- featherOS already keeps track of dependencies, so all binaries that depend on ARGH will be automatically ran with that arg

--]]
return module
