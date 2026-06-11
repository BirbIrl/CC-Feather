local bundle = bundl "feather.bundle" ---@type feather.bundle


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
	write("Bundle")
	term.setTextColor(colors.white)
	print(", a FeatherOS package manager.")
	describeArg("get [pkg]", "gets a libary package from the mirror")
	describeArg("remove [pkg]", "removes a local library package")
	describeArg("install [pkg]", "installs a program from the mirror")
	describeArg("uninstall [pkg]", "uninstalls a local program")
	describeArg("list [filter?]", "lists installed packages and libraries")
	describeArg("repo [filter?]", "lists available packages and libraries")
	describeArg("update", "updates and reinstalls all your packages")
end

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
		if not installedThisSession[dependencyName] then
			print("Dependency " .. dependencyName .. " needs an update, resolving")
			install(dependencyName)
		end
	end
end


---@param packages feather.bundle.packageTable
---@param filter string?
local function filterAndPrintPackages(packages, filter)
	local sortedPkgNames = {}
	local longestPkgName = 0
	for pkgName, _ in pairs(packages) do
		if filter and not pkgName:find(filter) then
			goto continue
		end
		sortedPkgNames[#sortedPkgNames + 1] =
			pkgName
		longestPkgName = math.max(longestPkgName, #pkgName)
		::continue::
	end
	table.sort(sortedPkgNames)
	for _, pkgName in ipairs(sortedPkgNames) do
		print(pkgName .. (" "):rep(longestPkgName - #pkgName + 2) .. packages[pkgName]
			.version)
	end
end

local mode, pkgName = ...
if mode == "get" then
	install("lib.feather." .. pkgName)
elseif mode == "remove" then
	print("Unimplemented")
elseif mode == "install" then
	install("bin.feather." .. pkgName)
elseif mode == "uninstall" then
	print("Unimplemented")
elseif mode == "list" then
	---@type string[]
	filterAndPrintPackages(bundle.listInstalled(), pkgName)
elseif mode == "repo" then
	---@type string[]
	filterAndPrintPackages(bundle.listAvailable(), pkgName)
elseif mode == "update" then
	for pkgToUpdate, _ in pairs(bundle.listInstalled()) do
		install(pkgToUpdate)
	end
else
	help()
end
