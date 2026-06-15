local featherd = bundl "feather.featherd" ---@type feather.featherd
---@class feather.argh
local module = {}
local pp = require("cc.pretty").pretty_print

---todo: register to help menu as well
---todo: flags only work on the first one
---todo: flags shouldn't show up for flags that were already filled

--[[
--library that would let you register arguments like this:
local argh = bundl("argh") ---@type feather.argh
local exactFlag = {
	short = "e",
	description = "only matches packages with the exact package name"
}
local pkgName = {
	name = "pkgName",
	argument = argh.argument.choice(function(str, spec)
		local bundle = bundl("bundle")
		local pkgNames = {}
		for name, _ in bundle.listAvailable() do
			if name:sub(1,#str) == str then
				pkgNames[#pkgNames + 1] = name:sub(#str+1,-1)
			end
		end
		return pkgNames, true
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
local args = argh.parse("bundle", "A featherOS package manager", { -- first entry is only for the flags
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
--  bundle [-s] - shows this help menu
--  bundle install [-e] [pkgName] - installs a program
--  bundle get [-e] [pkgName] - installs a library
--  bundle list [filter?] - lists available packages, can be filtered
--
--  -s --silent - hides extra outputs
--  -e --exact - only matches packages with the exact package name
--
-- lower depth is calculated first, and flags don't get repeated on further concats
-- args would return a tree like so:


args = {
	{
		name = "root",
		argument = "bundle",
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
		name = "root",
		argument = "bundle",
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

--]]


---@alias feather.argh.argumentFunction fun(str: string, spec: feather.argh.spec): string[], boolean
module.argument = {
}

function module.argument.string(str, spec)
	if #str > 0 then
		return {}, true
	end
	return { "[" .. spec.name .. "]" }, true
end

function module.argument.number(str, spec)
	local name, valid = module.argument.string(str, spec)
	return name, tonumber(valid) ~= nil
end

function module.argument.name(str, spec)
	if spec.name:sub(1, #str) ~= str then
		return {}, false
	end
	return { spec.name:sub(#str + 1, -1) }, spec.name == str
end

---@type table<string, {name: string, description: string, spec: feather.argh.spec}>
local registry = {}

---@alias feather.argh.flag {short: string?, description: string?}

---@class feather.argh.spec
---@field name? string -- name of the argument, nil if you want it to just be flags
---@field description? string -- description of the argument and each following it
---@field argument? feather.argh.argumentFunction -- function used for the argument
---@field sufficient? boolean -- whether you can end on this argument
---@field next? feather.argh.spec|feather.argh.spec[] -- the argument(s) that can be used after this one
---@field flags? table<string, feather.argh.flag> -- flags that appear after the argument



---@class feather.argh.return
---@field name? string
---@field argument string
---@field flags table<string,true>

---@param path string
---@param name string
---@param description string
---@param spec feather.argh.spec
---@param args string[]
function module.parse(path, name, description, spec, args)
	if args[1] == "__ARGH_REGISTER_ARGS" then
		registry[path] = { name = name, description = description, spec = spec }
		shell.setCompletionFunction(path, module.makeCompletionFunction(spec))
		return
	end
	local last = args[#args]
	local previous = {}
	for i = 0, #args - 1, 1 do
		previous[i + 1] = args[i]
	end
	local _, record, invalidArg, complete = module.complete(spec, last, previous)
	assert(not invalidArg, "Couldn't parse the given argument: " .. (invalidArg or ""))
	assert(complete, "The program needs more arguments.")
	return record
end

---@param str string
---@param branch feather.argh.spec
---@param takenFlags table<string, boolean>
---@return string? flagFound
---@return integer flagsLeft
local function getFlag(str, branch, takenFlags)
	local found
	local flagsLeft = 0
	for flagName, flagSpec in pairs(branch.flags or {}) do
		if takenFlags[flagName] then
			-- skip
		elseif "--" .. flagName == str or "-" .. flagSpec.short == str then
			found = flagName
		else
			flagsLeft = flagsLeft + 1
		end
	end
	return found, flagsLeft
end


---@param spec feather.argh.spec
---@param current string
---@param args string[]
---@return string[] completions
---@return feather.argh.return[] record
---@return string? invalidArg if the arguments parsed are invalid, this will return the invalid arg
---@return boolean complete whether there was enough arguments
function module.complete(spec, current, args)
	-- this is so far the worst code i've written - birb
	table.insert(args, current)
	local cmdName = table.remove(args, 1)
	local currBranch = spec
	---@type feather.argh.return
	local currArg = { name = "root", flags = {}, argument = cmdName }
	local record = { currArg }
	local completions = {}
	local endsValid = true
	local broken = false -- broken is considered when it's not valid and won't be valid
	local done = true
	local flag
	local flagsLeft = 0
	local lastParsedArg = cmdName -- used to return where the parser broke
	for i, arg in ipairs(args) do
		lastParsedArg = arg
		done = false
		flag, flagsLeft = getFlag(arg, currBranch, currArg.flags)
		if flag then
			currArg.flags[flag] = true
			goto continue
		end
		completions = {}
		local nextBranches = currBranch.next
		if nextBranches and not nextBranches[1] then
			nextBranches = { nextBranches }
		end

		local flagCompletions = {}

		if currBranch.flags then
			if arg == "" then
				if flagsLeft > 0 then
					flagCompletions[#flagCompletions + 1] = "-"
				end
			elseif arg == "-" then
				for flagName, flagSpec in pairs(currBranch.flags) do
					if not currArg.flags[flagName] then
						flagCompletions[#flagCompletions + 1] = flagSpec.short .. " "
					end
				end
				if flagsLeft > 0 then
					flagCompletions[#flagCompletions + 1] = "-"
				end
			elseif arg:sub(1, 2) == "--" then
				local currPartialFlag = arg:sub(3, -1)
				for flagName in pairs(currBranch.flags) do
					if not currArg.flags[flagName] and flagName:sub(1, #currPartialFlag) == currPartialFlag then
						flagCompletions[#flagCompletions + 1] = flagName:sub(#currPartialFlag + 1, -1) .. " "
					end
				end
			end
		end

		if not flag and nextBranches then
			for _, specCandidate in ipairs(nextBranches) do
				local parsedCompletions, isValid = specCandidate.argument(arg, specCandidate)
				endsValid = isValid
				for _, completion in ipairs(parsedCompletions) do
					if specCandidate.next or specCandidate.flags then
						completion = completion .. " "
					end
					table.insert(completions, 1, completion)
				end
				if isValid then
					currBranch = specCandidate
					currArg = { name = currBranch.name, flags = {}, argument = arg }
					record[#record + 1] = currArg
					done = false
					break
				elseif arg ~= "" then
					if i ~= #args then
						completions = {}
					end
					done = true
				end
			end
		end

		if arg == ("--"):sub(1, #arg) and not flag and args[i + 1] then
			completions = {}
			broken = true
			break
		end

		for _, flagCompletion in ipairs(flagCompletions) do
			completions[#completions + 1] = flagCompletion
		end

		if done then
			break
		end
		::continue::
	end
	if (currBranch.next or flagsLeft > 0) and not completions[1] and not done and not broken and not endsValid then
		completions[1] = " "
	end
	local complete = currBranch.sufficient or not currBranch.next
	return completions, record, (not endsValid and lastParsedArg) or nil, complete -- and yet work it does!
end

---@param spec feather.argh.spec
---@return function
function module.makeCompletionFunction(spec)
	return function(_, _, current, previous)
		return module.complete(spec, current, previous)
	end
end

function module.help()
end

-- programs called with the argument __ARGH_REGISTER_ARGS will have an extra trigger in argh.parse, that would parse the function's autocompletion for the shell
-- featherOS already keeps track of dependencies, so all binaries that depend on ARGH will be automatically ran with that arg




return module
