local bundleUtil = bundle "feather.bundleUtil" ---@type feather.bundleUtil



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


local mode, pkgName = ...
if mode == "get" then
	bundleUtil.install(pkgName, "lib")
elseif mode == "remove" then
elseif mode == "install" then
	bundleUtil.install(pkgName, "bin")
elseif mode == "uninstall" then
else
	help()
end
