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
	write("Postman")
	term.setTextColor(colors.white)
	print(
		", package routing utility for create.")
	describeArg("serve", "runs the program using current configuration")
	describeArg("add [name] \"[address]\" [recieveOnly?]",
		"tracks an inventory with the given name and will route items to it like it's a frogport/postbox")
	describeArg("setBin [name]",
		"tracks an inventory and will put all non package items from within the network into it")
	describeArg("setDefault [name]",
		"tracks an inventory and will put all packages with no matching address from within the network into it")
	describeArg("remove [name]", "removes an inventory from the tracked list")
	print("\nPostman doesn't support pattern matching.")
end

local arg, name, address, recieveOnly = ...
---@alias fever.postman.config {address:string, recieveOnly: true?}
---@type table<string,fever.postman.config >
local inventories = settings.get("fever.postman.inventories", {})
local bin = settings.get("fever.postman.bin")
local default = settings.get("fever.postman.default")
local delay = settings.get("4ever.postman.delay", 1)

if arg == "add" then
	assert(name and address, "Must provide Name and Address")
	assert(peripheral.wrap(name),
		"Couldn't find an inventory matching name, check what it's called when you plug it in with a modem.")
	inventories[name] = { address = address, recieveOnly = recieveOnly }
	settings.set("fever.postman.inventories", inventories)
	settings.save()
elseif arg == "remove" then
	assert(inventories[name], "can't remove inventory that isn't tracked yet")
	inventories[name] = nil
	settings.set("fever.postman.inventories", inventories)
	settings.save()
elseif arg == "setBin" then
	assert(peripheral.wrap(name),
		"Couldn't find an inventory matching name, check what it's called when you plug it in with a modem.")
	settings.set("fever.postman.bin", name)
	settings.save()
elseif arg == "setDefault" then
	assert(peripheral.wrap(name),
		"Couldn't find an inventory matching name, check what it's called when you plug it in with a modem.")
	settings.set("fever.postman.default", name)
	settings.save()
elseif arg == "serve" then
	---@type table<ccTweaked.peripheral.Inventory, fever.postman.config>
	local peripherals = {}
	---@type table<string, string>
	local byAddress = {}
	for invName, config in pairs(inventories) do
		local inv = assert(peripheral.wrap(invName), "Peripheral with the assigned name '" .. invName .. "' not found")
		if not recieveOnly then
			peripherals[inv] = config
		end
		assert(not byAddress[config.address],
			tostring(byAddress[config.address]) ..
			" and " .. invName .. " both try to use the address: '" .. config.address .. "'")
		byAddress[config.address] = invName
	end
	while true do
		for inv, config in pairs(peripherals) do
			for slot, _ in pairs(inv.list()) do
				local item = inv.getItemDetail(slot)
				local package = item and item.package;
				if package then
					local packageAddress = package.getAddress()
					if packageAddress ~= config.address then
						local target = byAddress[packageAddress]
						if target then
							inv.pushItems(target, slot)
						elseif default then
							inv.pushItems(default, slot)
						end
					end
				elseif bin then
					inv.pushItems(bin, slot)
				end
			end
		end
		sleep(delay)
	end
else
	help()
end
