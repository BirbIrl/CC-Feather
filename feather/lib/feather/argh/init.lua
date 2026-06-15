local featherd = bundl "feather.featherd" ---@type feather.featherd
---@class feather.argh
local module = {}

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


---@class feather.argh.spec
---@field name? string -- name of the argument, nil if you want it to just be flags
---@field description? string -- description of the argument and each following it
---@field argument? feather.argh.argumentFunction -- function used for the argument
---@field sufficient? boolean -- whether you can end on this argument
---@field next? feather.argh.spec|feather.argh.spec[] -- the argument(s) that can be used after this one
---@field flags? table<string, {short: string?, description: string?}> -- flags that appear after the argument

---@class feather.argh.return
---@field name? string
---@field argument string
---@field flags table<string,true>

---@param path string
---@param name string
---@param description string
---@param spec feather.argh.spec
---@param ... string
function module.parse(path, name, description, spec, ...)
	if ... == "__ARGH_REGISTER_ARGS" then
		registry[path] = { name = name, description = description, spec = spec }
		shell.setCompletionFunction(path, module.makeCompletionFunction(spec))
		return
	end
end

---@param str string
---@param branch feather.argh.spec
---@return string?
local function getFlag(str, branch)
	for flagName, flagSpec in pairs(branch.flags or {}) do
		if "--" .. flagName == str or "-" .. flagSpec.short == str then
			return flagName
		end
	end
end

---@param str string
---@param branch feather.argh.spec
local function isValidArg(str, branch)
end


---@generic T
---@param param T[]|T
---@return T[]
local function arrayIfSingle(param)
	if not param then
		return {}
	end
	if param[1] then
		return param
	end
	return { param }
end

---@param spec feather.argh.spec
---@param current string
---@param previous string[]
function module.complete(spec, current, previous)
	table.remove(previous, 1)
	table.insert(previous, current)
	local args = previous
	local currBranch = spec
	---@type feather.argh.return
	local currArg = { name = currBranch.name, flags = {}, argument = args[1] }
	local record = { currArg }
	local completions = {}
	local endsValid = false
	local done = false
	for i, arg in ipairs(args) do
		done = false
		local flag = getFlag(arg, currBranch)
		if flag then
			currArg.flags[flag] = true
			goto continue
		end
		completions = {} -- the flow is all fucked up with this, i need to rethink all of this
		-- maybe i should just do this recursively? is there any state i need to keep track of?

		local nextBranches = arrayIfSingle(currBranch.next)

		if not flag and nextBranches[1] then
			for _, specCandidate in ipairs(nextBranches) do
				featherd.log(specCandidate)
				local parsedCompletions, isValid = specCandidate.argument(arg, specCandidate)
				endsValid = isValid
				for _, completion in ipairs(parsedCompletions) do
					if specCandidate.next or specCandidate.flags then
						completion = completion .. " "
					end
					completions[#completions + 1] = completion
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

		if currBranch.flags and next(currBranch.flags) then
			if arg == "" then
				completions[#completions + 1] = "-" --TODO don't show if no new flags left to do
			elseif arg == "-" then
				for _, flagSpec in pairs(currBranch.flags) do
					completions[#completions + 1] = flagSpec.short .. " "
				end
				completions[#completions + 1] = "-" --TODO don't show if no new flags left to do
			elseif arg:sub(1, 2) == "--" then
				local currPartialFlag = arg:sub(3, -1)
				for flagName in pairs(currBranch.flags) do
					if flagName:sub(1, #currPartialFlag) == currPartialFlag then
						completions[#completions + 1] = flagName:sub(#currPartialFlag + 1, -1) .. " "
					end
				end
			end
		end

		if done then
			break
		end
		::continue::
	end
	featherd.log(currBranch)
	if (currBranch.next or (currBranch.flags and next(currBranch.flags))) and not completions[1] then
		completions[1] = " "
	end
	return completions, record, endsValid
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
