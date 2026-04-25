local storage = bundl "feather.storage" ---@type feather.storage

local function describeArg(argument, desc)
	term.setTextColor(colors.gray)
	write("\n" .. arg[0] .. " ")
	term.setTextColor(colors.yellow)
	write(argument)
	term.setTextColor(colors.white)
	print(" - " .. desc)
end

local path, archiveName = ...
if not path then
	term.setTextColor(colors.yellow)
	write("ccar")
	term.setTextColor(colors.white)
	print(
		", a FeatherOS utility for packing a node tree into a .ccar.lua that can unpack on it's own")
	describeArg("[path] [name?]",
		"Packs the folder/file in [path] into a [name].car.lua archive")
	return
end

local archive = fs.open((archiveName or "archive") .. ".ccar.lua", "w")
assert(archive, "Couldn't create an archive file")

archive.write([[
local function decode(entry, path)
	path = path or entry.path
	if type(entry.contents) == "string" then
		local file = assert(fs.open(path, "w"))
		file.write(entry.contents)
		file.close()
	else
		fs.makeDir(path)
		for _, child in ipairs(entry.contents) do
			decode(child, fs.combine(path, child.name))
		end
	end
	end
]]
	..
	"local archive =" .. textutils.serialise(storage.encode(path))
	..
	[[
local function y()
	term.setTextColor(colors.yellow)
end
local function r()
	term.setTextColor(colors.red)
end
local function w()
	term.setTextColor(colors.white)
end
local function prompt()
	y()
	write("Y")
	w()
	write("/")
	y()
	print("N")
	w()
	write(">")
	y()
	return read(nil, { "Y", "N" }, nil, "Y"):upper() ~= "Y"
end

local curr = shell.getRunningProgram()
local path = ... or archive.path
w()
write("Unpack " )
y()
write(curr)
w()
write(" to ")
y()
write(path)
w()
print("?")

if prompt() then
	r()
	print("Aborted")
	return
end
decode(archive, path)
print("Unpacked")
w()
write("Delete the archive: ")
y()
write(curr)
w()
print("?")
if not prompt() then
	fs.delete(curr)
	print("Deleted")
end
]])
