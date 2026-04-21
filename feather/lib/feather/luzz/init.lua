---@class feather.luzz
local module = {}


---@param item string
---@param key string
---@return feather.luzz.rating?
function module.match(item, key)
	---@type feather.luzz.rating
	local rating = { item = item }
	local hits = {}
	---@type integer?
	local offset = 1
	local lastLetter = nil
	for letter in key:gmatch(".") do
		offset = item:find(letter, offset)
		if not offset then
			return nil
		end
		if lastLetter then -- in cases like minecraft:tuff, this will cut the gap betweet t:tuff, reducing it to a match length of 4 instead of 6
			local snippet = item:sub(hits[#hits], offset)
			local repeatPos = snippet:len() - snippet:reverse():find(lastLetter) + hits[#hits]
			print(snippet)
			hits[#hits] = repeatPos
		end
		hits[#hits + 1] = offset
		lastLetter = letter
	end
	rating.hits = hits
	return rating
end

-- hits: letters that are matches in `key`
-- item: the item being rated
---@alias feather.luzz.rating {hits: integer[], item: string, index: integer}

---@param items string[]
---@param key string
function module.rank(items, key)
	---@type table<string, feather.luzz.rating>
	local matches = {}
	if key == "" then
		return matches
	end
	for index, item in ipairs(items) do
		local rating = module.match(item, key)
		if rating then
			rating.index = index
			matches[#matches + 1] = rating
		end
	end
	---@param a feather.luzz.rating
	---@param b feather.luzz.rating
	---@return boolean
	table.sort(matches, function(a, b)
		local aGap = a.hits[#a.hits] - a.hits[1]
		local bGap = b.hits[#b.hits] - b.hits[1]

		return aGap < bGap or a.item:len() < b.item:len()
	end)
	return matches
end

return module
