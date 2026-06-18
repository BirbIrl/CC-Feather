local argh = bundl "feather.argh" ---@type feather.argh
local vaultPath = fs.combine(feather.installPath, "bin/feather/vault/vault.lua")
local programPath = fs.combine(feather.installPath, "bin/feather/vault/v.lua")
local numberSpec = {}
---@type feather.argh.spec
local itemSpec = {}
itemSpec.name = "itemName"
itemSpec.sufficient = true
itemSpec.flags = {
	exact = {
		short = "e",
		description = "grabs the exact number of items instead of stacks"
	},
}
itemSpec.description = "searches an item with the given name"
itemSpec.argument = argh.argument.string
itemSpec.next = {
	numberSpec, itemSpec
}
numberSpec.name = "count"
numberSpec.sufficient = true
numberSpec.argument = argh.argument.number
numberSpec.next = {
	itemSpec
}
numberSpec.description = "provides a limit for the number"

local args = argh.parse(programPath, "v", "a vault macro", {
	sufficient = true,
	next = itemSpec
}, ...)

if not args[2] then
	argh.help(programPath)
end

for i, arg in ipairs(args) do
	if arg.name == "itemName" then
		local next = args[i + 1]
		local count = next and next.name == "count" and next.argument or nil
		count = count and " " .. count or ""
		local flag = arg.flags.exact and " -e" or ""
		shell.run(vaultPath, "get " .. arg.argument .. flag .. count)
	end
end
