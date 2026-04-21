local pretty = require "cc.pretty"
local luzz = bundl "feather.luzz" ---@type feather.luzz

local items = {
	--[[
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
	["minecraft:stone"] = {
		count = 64,
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
	["minecraft:stone_pressure_plate"] = {
		count = 2,
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
	--]]
	["minecraft:smooth_stone"] = {
		count = 10,
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
local rankedNames = luzz.rank(itemNames, "stone")
pretty.pretty_print(rankedNames)
printRanking(rankedNames)
