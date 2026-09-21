local luzz = bundl "feather.luzz" ---@type feather.luzz
local argh = bundl "feather.argh" ---@type feather.argh
local vault = bundl "feather.vault" ---@type feather.vault
local petty = bundl "feather.petty" ---@type feather.petty


---TODO add a flag to ignore search by modname, causes issues. maybe just remove the thingy from minecraft: tag?
local programPath = fs.combine(feather.installPath, "bin/feather/vault/vault.lua")
local args = argh.parse(programPath, "vault", "an item manager",
	{
		sufficient = true,
		next = {
			{
				name = "get",
				argument = argh.argument.name,
				next = {
					name = "filter",
					argument = argh.argument.string,
					sufficient = true,
					flags = {
						stacks = {
							short = "s",
							description =
							"When used after get, it will get the number of stacks instead of single items"
						},
					},
					next = {
						name = "count",
						argument = argh.argument.int,
						description = "Gets items that match filter up till count, or a stack if not specified",
					}
				}
			},
			{
				name = "list",
				argument = argh.argument.name,
				sufficient = true,
				next = {
					description = "lists items available, can be filtered",
					name = "filter",
					argument = argh.argument.string,
				}
			},
			{
				name = "setOutput",
				argument = argh.argument.name,
				sufficient = true,
				next = {
					description = "sets the item output in this pc's config",
					name = "peripheralname",
					argument = argh.argument.peripheral,
				}
			},
			{
				name = "dump",
				argument = argh.argument.name,
				flags = {
					watch = {
						short = "w",
						description = "will dump items periodically unless an item is requested"
					}
				}
			},
			{
				name = "help",
				description = "shows this help menu",
				argument = argh.argument.name,
			},
		}
	}, ...)


---@generic T
---@param tbl T[]
---@param tailLength integer
---@return T[]
local function getTableTail(tbl, tailLength)
	local slice = {}
	for i = 1, tailLength, 1 do
		slice[#slice + 1] = tbl[#tbl - tailLength + i]
	end
	return slice
end

if (not args[2]) or args[2].name == "help" then
	argh.help(programPath)
	return
end

if args[2].name == "setOutput" then
	settings.set("feather.vault.output", args[3].argument)
	settings.save()
	return
end
local filter = args[3] and args[3].argument
local items = vault.list()
local itemNames = {}
for key, _ in pairs(items) do
	itemNames[#itemNames + 1] = key
end
if args[2].name == "list" then
	local interactive = not filter
	filter = filter or ""
	---@type ccTweaked.cc.pretty.Doc
	local lines
	::printresults::
	if #filter > 0 then
		local ranking = luzz.rank(itemNames, filter)
		lines = luzz.rankingToColoredText(ranking)
	else
		table.sort(itemNames, function(a, b)
			if items[a].total == items[b].total then
				return a < b
			end
			return items[a].total < items[b].total
		end)
		lines = itemNames
	end
	local _, h = term.getSize()
	lines = getTableTail(lines, h - 1)
	term.clear()
	term.setCursorPos(1, h)
	for _, itemName in ipairs(lines) do
		petty.print(itemName .. petty.text(" - ", colors.gray) .. tostring(items[tostring(itemName)].total))
	end
	if interactive then
		term.setCursorBlink(true)
		term.write(filter)
		while true do
			local eventType, eventData = os.pullEvent()
			if eventType == "char" then
				filter = filter .. eventData
				goto printresults
			elseif eventType == "key" then
				if eventData == keys.backspace then
					if #filter == 0 then
						break
					end
					filter = filter:sub(1, -2)
					goto printresults
				elseif eventData == keys.enter then
					term.clearLine()
					term.setCursorPos(1, h)
					for char in tostring("vault get " .. lines[#lines] .. " "):gmatch(".") do
						os.queueEvent("char", char)
					end
					break
				end
			end
		end
	end
end

if args[2].name == "get" then
	local ranking = luzz.rank(itemNames, filter)
	assert(ranking[1], "Didn't find any matching items")
	local routes = items[ranking[1].item]
	local details = routes.getDetails()
	local amount = tonumber(args[4] and args[4].argument) or details.maxCount
	if args[3].flags.stacks and args[4] then
		amount = amount * details.maxCount
	end
	local imported = vault.import(routes, amount)
	petty.print("Got " .. petty.text(tostring(imported), colors.yellow) .. " " .. details.displayName)
end


if args[2].name == "dump" then
	local output, outputName = vault.getOutput()
	local storages = vault.getStorages()
	for slot, item in pairs(output.list()) do
		local left = item.count
		local routes = items[item.name]
		if routes then
			local details = routes.getDetails()
			if details.maxCount > 1 then
				for _, route in ipairs(routes) do
					if route.item.count < details.maxCount then
						left = left - route.peripheral.pullItems(outputName, slot)
						if left == 0 then
							break
						end
					end
				end
			end
		end
		if left > 0 then
			local lambdas = {}
			for _, storage in ipairs(storages) do
				lambdas[#lambdas + 1] = function()
					if left > 0 then
						left = left - storage.pullItems(outputName, slot)
					end
				end
			end
			parallel.waitForAll(table.unpack(lambdas))
		end
	end
	print("Successfuly dumped")
end

--[[
local items = {
	["minecraft:mossy_cobblestone"] = {
		count = 22,
	},
	["minecraft:stone_bricks"] = {
		count = 27,
	},
	["minecraft:cobblestone_slab"] = {
		count = 5,
	},
	["minecraft:stone_brick_wall"] = {
		count = 6,
	},
	["minecraft:cobblestone"] = {
		count = 6,
	},
	["minecraft:cobbled_deepslate"] = {
		count = 2,
	},
	["minecraft:tuff"] = {
		count = 19,
	},
	["minecraft:deepslate"] = {
		count = 10,
	},
	["minecraft:gravel"] = {
		count = 4,
	},
	["minecraft:smooth_basalt"] = {
		count = 3,
	},
	["minecraft:purpur_block"] = {
		count = 19,
	},
	["minecraft:stone_brick_stairs"] = {
		count = 9,
	},
	["minecraft:obsidian"] = {
		count = 45,
	},
	["minecraft:mossy_cobblestone_slab"] = {
		count = 9,
	},
	["minecraft:stone_slab"] = {
		count = 5,
	},
	["minecraft:amethyst_block"] = {
		count = 20,
	},
	["minecraft:calcite"] = {
		count = 5,
	},
	["minecraft:pointed_dripstone"] = {
		count = 36,
	},
	["minecraft:stone_brick_slab"] = {
		count = 12,
	},
	["minecraft:smooth_stone"] = {
		count = 10,
	},
	["minecraft:stone"] = {
		count = 64,
	},
	["minecraft:stone_pressure_plate"] = {
		count = 2,
	},
}

---@param ranking feather.luzz.rating[]
local function printRanking(ranking)
	for i = #ranking, 1, -1 do
		local rating = ranking[i]
		local currLetter = 1
		local currHit = 1
		for letter in rating.item:gmatch(".") do
			if currLetter == rating.hits[currHit] then
				currHit = currHit + 1
				term.setTextColor(colors.green)
			else
				term.setTextColor(colors.white)
			end
			write(letter)
			currLetter = currLetter + 1
		end
		print()
	end
end

local itemNames = {}
for name, _ in pairs(items) do
	itemNames[#itemNames + 1] = name
end
local rankedNames = luzz.rank(itemNames, ... or "")
printRanking(rankedNames)
--]]
