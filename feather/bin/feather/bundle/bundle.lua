local bundle = bundl "feather.bundle" ---@type feather.bundle



local function describeArg(argument, desc)
	term.setTextColor(colors.gray)
	write("\n" .. arg[0] .. " ")
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
end

local function install(pkgName)
	print("Fetching " .. pkgName)
	assert(bundle.install(pkgName), "Couldn't install " .. pkgName .. ", the mirror might be down.")
	local spec = bundle.get(pkgName)
	assert(spec, "somehow, we installed the package successfuly but can't find it. This shouldn't ever happen!")
	print(pkgName .. " successfully installed")

	for dependencyName, _ in pairs(bundle.listMissingDependencies(spec)) do
		print("Dependency " .. dependencyName .. " is missing, resolving")
		install(dependencyName)
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
else
	help()
end
