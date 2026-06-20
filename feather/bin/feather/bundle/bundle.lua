local bundle = bundl "feather.bundle" ---@type feather.bundle
local luzz = bundl "feather.luzz" ---@type feather.luzz
local petty = bundl "feather.petty" ---@type feather.petty
local argh = bundl "feather.argh" ---@type feather.argh
local completion = require "cc.completion"


---@generic T
---@param map table<T,any>?
---@return T[]
local function makeKeyArray(map)
	local array = {}
	if map then
		for key, _ in pairs(map) do
			array[#array + 1] = key
		end
	end
	table.sort(array)
	return array
end

---@type feather.argh.spec
local spec = {
	sufficient = true,
	next = {
		{
			name = "get",
			argument = argh.argument.name,
			description = "installs the named package",
			branch = true,
			next = {
				name = "pkgName",
				sufficient = true,
				argument = function(str, _)
					local result, val = pcall(bundle.listAvailable)
					if not result then
						return {}, false
					end
					local choices = makeKeyArray(val)
					for _, choice in ipairs(choices) do
						if str == choice then
							return completion.choice(str, choices), true
						end
					end
					return completion.choice(str, choices), false
				end

			},
		},
		{
			name = "remove",
			argument = argh.argument.name,
			branch = true,
			description = "uninstalls the named package",
			next = {
				name = "pkgName",
				sufficient = true,
				argument = function(str, _)
					local choices = makeKeyArray(bundle.listInstalled())
					for _, choice in ipairs(choices) do
						if str == choice then
							return completion.choice(str, choices), true
						end
					end
					return completion.choice(str, choices), false
				end

			},
		},
		{
			name = "list",
			argument = argh.argument.name,
			next = {
				name = "filter",
				argument = argh.argument.string,
				description = "lists installed packages ",
			},
			sufficient = true,
		},
		{
			name = "repo",
			sufficient = true,
			argument = argh.argument.name,
			next = {
				name = "filter",
				argument = argh.argument.string,
				description = "lists packages available in the mirror",
			},
		},
		{
			name = "update",
			description = "updates all packages on the system",
			sufficient = true,
			argument = argh.argument.name,
		},
		{
			name = "mirror",
			argument = argh.argument.name,
			next = {
				{
					name = "set",
					argument = argh.argument.name,
					next = {
						name = "id",
						description = "sets a new mirror id",
						sufficient = true,
						argument = argh.argument.int
					},
				},
				{
					name = "get",
					sufficient = true,
					description = "gets the current mirror id",
					argument = argh.argument.name,
				}
			}
		},
		{
			name = "help",
			description = "shows this help menu",
			argument = argh.argument.name,
		},
	}
}

local programPath = fs.combine(feather.installPath, "bin/feather/bundle/bundle.lua")
local args = argh.parse(programPath, "bundle", "a package manager", spec, ...)

local installedThisSession = {}

local function install(pkgName)
	print("Fetching " .. pkgName)
	bundle.install(pkgName)
	installedThisSession[pkgName] = true
	local spec = bundle.get(pkgName)
	assert(spec, "somehow, we installed the package successfuly but can't find it. This shouldn't ever happen!")
	print(pkgName .. " successfully installed")

	local missing, needsUpdate = bundle.listIncompleteDependencies(spec)
	for dependencyName, _ in pairs(missing) do
		if not installedThisSession[dependencyName] then
			print("Dependency " .. dependencyName .. " is missing, resolving")
			install(dependencyName)
		end
	end
	for dependencyName, _ in pairs(needsUpdate) do
		if not installedThisSession[dependencyName] then --TODO: have this compare versions
			print("Dependency " .. dependencyName .. " needs an update, resolving")
			install(dependencyName)
		end
	end
end


---@param packages feather.bundle.packageTable
---@param filter string?
local function filterAndPrintPackages(packages, filter)
	local pkgNames = {}
	local longestPkgName = 0
	for pkgName, _ in pairs(packages) do
		pkgNames[#pkgNames + 1] =
			pkgName
		longestPkgName = math.max(longestPkgName, #pkgName)
	end
	if filter then
		pkgNames = luzz.rankingToColoredText(luzz.rank(pkgNames, filter))
	else
		table.sort(pkgNames)
	end
	for _, pkgName in ipairs(pkgNames) do
		local asString = tostring(pkgName)
		petty.print(pkgName .. (" "):rep(longestPkgName - #asString + 2) .. packages[asString].version)
	end
end

local mode = args[2] and args[2].name
if not mode or mode == "help" then
	argh.help(programPath)
elseif mode == "get" then
	install(args[3].argument)
elseif mode == "remove" then
	print("Unimplemented")
elseif mode == "list" then
	---@type string[]
	filterAndPrintPackages(bundle.listInstalled(), args[3] and args[3].argument)
elseif mode == "repo" then
	---@type string[]
	filterAndPrintPackages(bundle.listAvailable(), args[3] and args[3].argument)
elseif mode == "update" then
	for pkgToUpdate, _ in pairs(bundle.listInstalled()) do
		install(pkgToUpdate)
	end
elseif mode == "mirror" then
	if args[3].name == "get" then
		petty.print("Current mirror id is: " ..
			petty.text(tostring(settings.get("feather.bundle.mirrorID")), colors.yellow))
	else
		settings.set("feather.bundle.mirrorID", assert(tonumber(args[4].argument)))
		settings.save()
	end
end
