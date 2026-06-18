local vaultPath = fs.combine(feather.installPath, "bin/feather/vault/vault.lua")
local programPath = fs.combine(feather.installPath, "bin/feather/vault/d.lua")
local argh = bundl "feather.argh" ---@type feather.argh
local args = argh.parse(programPath, "d", "alias for vault dump",
	{
		sufficient = true,
		description = "dumps all items into the storage",
		next = {
			name = "help",
			argument = argh.argument.name,
			description = "shows this help menu",
		}

	}, ...)

if args[2] then
	argh.help(programPath)
	return
end
shell.execute(vaultPath, "dump")
