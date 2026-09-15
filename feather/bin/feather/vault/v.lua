local argh = bundl "feather.argh" ---@type feather.argh
local vaultPath = fs.combine(feather.installPath, "bin/feather/vault/vault.lua")
local programPath = fs.combine(feather.installPath, "bin/feather/vault/v.lua")
local numberSpec = {}
---@type feather.argh.spec
local itemSpec = {}
itemSpec.name = "itemName"
itemSpec.sufficient = true
itemSpec.flags = {
	stacks = {
		short = "s",
		description = "grabs the number of stacks instead of single items"
	},
}
itemSpec.description = "searches an item with the given name"
itemSpec.argument = argh.argument.string
itemSpec.next = {
	numberSpec, itemSpec
}
numberSpec.name = "count"
numberSpec.sufficient = true
numberSpec.argument = argh.argument.int
numberSpec.next = {
	itemSpec
}
numberSpec.description = "provides a limit for the number"

local helpSpec = {
	name = "help",
	argument = argh.argument.name,
	description = "shows this help menu",
}

local args = argh.parse(programPath, "v", "a vault macro", {
	sufficient = true,
	next = { helpSpec, itemSpec },
	description = "opens the interactive vault fuzzy search"
}, ...)

if not args[2] then
	shell.run(vaultPath, "list")
	return
end

if args[2].name == "help" then
	argh.help(programPath)
end

for i, arg in ipairs(args) do
	if arg.name == "itemName" then
		local next = args[i + 1]
		local count = next and next.name == "count" and next.argument or nil
		count = count and " " .. count or ""
		local flag = arg.flags.stacks and " -s" or ""
		shell.run(vaultPath, "get " .. arg.argument .. flag .. count)
	end
end
