cc = require("cc.pretty").pretty_print
local arg = ...
if arg ~= "noInstall" then
	local snippet = 'shell.run(".feather/bin/featherOS", "noInstall") --don\'t move'
	local startup = fs.open("startup.lua", "r+")
	if not startup then
		error("Couldn't open the startup.lua file")
	end
	local line = startup.readLine()
	if line ~= snippet then
		startup.seek("set")
		local all = startup.readAll()
		startup.seek("set")
		startup.writeLine(snippet)
		startup.write(all)
		startup.close()
		os.reboot()
	end
	startup.close()
end
