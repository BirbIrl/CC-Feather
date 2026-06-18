local completion = require "cc.shell.completion"
local featherd = bundl "feather.featherd" ---@type feather.featherd
local petty = bundl "feather.petty" ---@type feather.petty
local mess = bundl "feather.mess" ---@type feather.mess
---@class feather.argh
local module = {}

local registerArgsArg = "__ARGH_REGISTER_ARGS"
local registeredSuccessfullyMessage = "Args registered successfuly"

local helpPath = fs.combine(feather.installPath, "share/argh")
help.setPath(help.path() .. ":" .. helpPath)

---todo: add support for settings

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

---TODO: should probably make a way to identify if a function is loose or not instead of just chudding it out with adding text to the name.. or maybe i should use text objects.. i just want it colored but also handle it for hints.
function module.argument.string(str, spec)
	if str:sub(1, 2) == "--" then -- TODO: THIS IS TERRIBLE DONT DO THIS
		return {}, false
	end
	if #str > 0 then
		return { "" }, true
	end
	return { petty.text("[", colors.gray) .. petty.text(spec.name, colors.yellow) .. petty.text("]", colors.gray) }, true
end

function module.argument.number(str, spec)
	local name, valid = module.argument.string(str, spec)
	return name, valid and tonumber(str) ~= nil
end

function module.argument.name(str, spec)
	if spec.name:sub(1, #str) ~= str then
		return {}, false
	end
	return { spec.name:sub(#str + 1, -1) }, spec.name == str
end

function module.argument.peripheral(str, spec)
	return completion.peripheral(shell, str), peripheral.wrap(str) ~= nil
end

function module.argument.dir(str, _)
	local absolutePath = fs.combine(shell.dir(), str)
	return completion.dir(shell, str), #str > 0 and fs.isDir(absolutePath)
end

function module.argument.file(str, _)
	local absolutePath = fs.combine(shell.dir(), str)
	return completion.file(shell, str), #str > 0 and fs.exists(absolutePath) and not fs.isDir(absolutePath)
end

function module.argument.path(str, _)
	local absolutePath = fs.combine(shell.dir(), str)
	return completion.dirOrFile(shell, str), #str > 0 and fs.exists(absolutePath)
end

---@alias  feather.argh.registryEntry  {name: string, description: string, spec: feather.argh.spec}
---@type table<string, feather.argh.registryEntry>
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
---@param ...string
---@return feather.argh.return[]
function module.parse(path, name, description, spec, ...)
	if ... == registerArgsArg then
		registry[path] = { name = name, description = description, spec = spec }
		shell.setCompletionFunction(path, module.makeCompletionFunction(spec))
		local helpFilePath = fs.combine(helpPath, name)
		local helpFile = fs.open(helpFilePath, "w")
		assert(helpFile, "couldn't make a help file at " .. helpFilePath)
		helpFile.write(tostring(module.makeHelpText(path)))
		helpFile.close()
		error(registeredSuccessfullyMessage)
	end
	local args = table.pack(...)
	local last = args[#args]
	args[#args] = nil
	table.insert(args, 1, shell.getRunningProgram())
	local _, record, invalidArg, complete = module.complete(spec, last, args)
	assert(not invalidArg, "Couldn't parse the given argument: " .. (invalidArg or ""))
	assert(complete, "The program needs more arguments.")
	return record
end

local function tableContains(tbl, elem)
	for _, value in pairs(tbl) do
		if value == elem then
			return true
		end
	end
	return false
end

function module.init()
	featherd.addProcess("arghRegisterer", function()
		local bundle = bundl("feather.bundle") ---@type feather.bundle
		local installPath = feather.installPath
		fs.delete(helpPath)
		for _, rockspec in pairs(bundle.listInstalled()) do
			if rockspec.build.type == "bin" and tableContains(rockspec.dependencies, "lib.feather.argh") then
				local binDirPath = fs.combine(installPath, rockspec.source.dir)
				for _, fileName in ipairs(fs.list(binDirPath)) do
					if fileName:sub(-4, -1) == ".lua" then
						local fullPath = fs.combine(binDirPath, fileName)
						local chunk = loadfile(fullPath, nil, _ENV)
						if chunk then
							local _, message = pcall(chunk, registerArgsArg)
							if type(message) == "string" and message:find(registeredSuccessfullyMessage) then
								featherd.log("Registered args for: " .. fullPath)
							else
								featherd.log(
									"Didn't register args for: " .. fullPath .. " the error message reads: " .. message,
									"error")
							end
						else
							featherd.log("Couldn't load code chunk for: " .. fullPath)
						end
					end
				end
			end
		end
	end)
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
				if not specCandidate.argument then
					dbg(currBranch)
					dbg(specCandidate)
				end
				local candidateCompletions, isValid = specCandidate.argument(arg, specCandidate)
				endsValid = isValid
				for _, candidateCompletion in ipairs(candidateCompletions) do
					if specCandidate.next or specCandidate.flags then
						candidateCompletion = candidateCompletion .. " "
					end
					table.insert(completions, tostring(candidateCompletion))
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

---@param  spec feather.argh.spec
local function chainsToSufficiency(spec)
	if spec.sufficient and spec.next then
		return true
	end
	local next = spec.next
	if next then
		if not next[1] then ---TODO remove this and just make a spec normalizer on load
			next = { spec.next }
		end
		for _, nextSpec in ipairs(next) do
			if chainsToSufficiency(nextSpec) then
				return true
			end
		end
	end
	return false
end

---@param branch feather.argh.spec
---@param name string|ccTweaked.cc.pretty.Doc -- gets edited further down the chain to match args
---@param doc ccTweaked.cc.pretty.Doc.concat
---@param lastDescription? string only called from within the loop to remember the description down the chain
---@param cache? table<feather.argh.spec,true>
---@return ccTweaked.cc.pretty.Doc.concat, table<string,feather.argh.flag>?
local function appendArgHelpText(branch, name, doc, lastDescription, cache)
	cache = cache or {}
	local first = next(cache) == nil
	cache[branch] = true

	if type(name) == "string" then
		name = petty.text(name, colors.gray)
	end
	local description = branch.description or lastDescription
	local flags = branch.flags or {}
	local next = branch.next
	next = next and not next[1] and { next } or next
	if (branch.sufficient or not branch.next) and description then
		---@type string|ccTweaked.cc.pretty.Doc.text
		local dots = ""
		if next then
			for _, nextBranch in ipairs(next) do
				if cache[nextBranch] then
					dots = petty.text("...", colors.gray)
				end
				break
			end
		end
		doc = doc .. petty.line .. name .. dots .. " - " .. description
	end
	if next then
		for _, nextBranch in ipairs(next) do
			if cache[nextBranch] then
				goto continue
			end
			local newFlags
			local defaultResults = nextBranch.argument("", nextBranch)
			---@type ccTweaked.cc.pretty.Doc|string
			local argName = (defaultResults and defaultResults[1]) or nextBranch.name or ""
			if type(argName) == "string" then
				argName = petty.text(nextBranch.name, colors.yellow)
			end
			if not chainsToSufficiency(nextBranch) then
				argName = argName .. petty.text("?", colors.gray)
			end
			argName = name .. " " .. argName
			doc, newFlags = appendArgHelpText(nextBranch, argName,
				doc, description, cache)
			if newFlags then
				for flagName, flag in pairs(newFlags) do
					if flag.description then
						flags[flagName] = flag
					end
				end
			end
			::continue::
		end
	end
	if first then
		local flagsAlphabetically = {}
		for flagName, _ in pairs(flags) do
			flagsAlphabetically[#flagsAlphabetically + 1] = flagName
		end
		table.sort(flagsAlphabetically)
		for _, flagName in ipairs(flagsAlphabetically) do
			local flag = flags[flagName]
			if flag.description then
				doc = doc .. petty.line .. "  " ..
					petty.text("-" .. flag.short, colors.yellow) ..
					petty.text("/", colors.gray) ..
					petty.text("--" .. flagName, colors.yellow) ..
					": " .. flag.description
			end
		end
	end
	return doc, branch.flags
end

---@private
---@param path string
---@return ccTweaked.cc.pretty.Doc.concat helpText
function module.makeHelpText(path)
	local program = registry[path]
	assert(program, "Program under path: " .. path .. " is not registered to then have it's help menu displayed.")
	local helpText = petty.text(program.name, colors.yellow) .. ", " .. program.description
	helpText = appendArgHelpText(program.spec, program.name, helpText)
	return helpText
end

---@param path string
function module.help(path)
	local helpText = module.makeHelpText(path)
	local w, h = term.getSize()
	local doc, textHeight = petty.wrap(helpText, w)
	if textHeight >= h then
		mess.focus(doc)
	else
		petty.pp(doc, nil, nil, nil)
		print()
	end
end

-- programs called with the argument __ARGH_REGISTER_ARGS will have an extra trigger in argh.parse, that would parse the function's autocompletion for the shell
-- featherOS already keeps track of dependencies, so all binaries that depend on ARGH will be automatically ran with that arg




return module
