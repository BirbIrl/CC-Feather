---@class feather.luzz
local module = {}


---@param item string
---@param key string
---@return feather.luzz.rating?
function module.match(item, key)
	---@type feather.luzz.rating
	local rating = { item = item, hits = {} }
	if key == "" then
		return rating
	end
	local pattern = ""
	for letter in key:gmatch(".") do
		pattern = pattern .. letter .. ".-"
	end
	---@type integer?, integer?, integer?
	local from, to, length = 0, nil, nil
	local bestStart = nil
	while true do
		from, to = item:find(pattern, from + 1)
		if from then
			if not length or length > to - from then
				length = to - from
				bestStart = from
			end
		else
			break
		end
	end
	if not bestStart then
		return nil
	end
	local i = bestStart
	for letter in rating.item:sub(bestStart, -1):gmatch(".") do
		local next = #rating.hits + 1
		if letter == key:sub(next, next) then
			rating.hits[next] = i
		end
		i = i + 1
	end
	return rating
end

-- hits: letters that are matches in `key`
-- item: the item being rated
-- index: refers to which element in the original list this entry refers to
---@alias feather.luzz.rating {hits: integer[], item: string, index: integer}

---@param items string[]
---@param key string
function module.rank(items, key)
	---@type table<string, feather.luzz.rating>
	local matches = {}
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
		if #a.hits == 0 then
			return false
		end
		local aGap = a.hits[#a.hits] - a.hits[1]
		local bGap = b.hits[#b.hits] - b.hits[1]
		if aGap ~= bGap then
			return aGap < bGap
		end
		return #a.item < #b.item
	end)
	return matches
end

return module
