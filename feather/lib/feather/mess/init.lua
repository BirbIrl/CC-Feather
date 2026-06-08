---@type feather.featherd
local featherd = bundl "feather.featherd"
---@type lib.feather.petty
local petty = bundl("feather.petty")
---@type lib.feather.vec2d
local vec = bundl("feather.vec2d")
---@class lib.feather.mess
local module = {}
---@param doc ccTweaked.cc.pretty.Doc.text
---@param yShift integer
---@param xShift integer
---@param maxLineCount? integer
local function display(doc, xShift, yShift, maxLineCount)
	term.setCursorPos(-xShift + 1, 1)
	petty.pp(doc, yShift, yShift + maxLineCount, true)
end

local binds = {
	right = {
		[keys.right] = true,
		[keys.d] = true,
		[keys.l] = true,
	},
	left = {
		[keys.left] = true,
		[keys.a] = true,
		[keys.h] = true,
	},
	up = {
		[keys.up] = true,
		[keys.w] = true,
		[keys.k] = true,
	},
	down = {
		[keys.down] = true,
		[keys.s] = true,
		[keys.j] = true,
	},

}

---@param str string
---@param pattern string
---@param caseSensitive boolean
---@return [integer,string][]
local function findPosOfAllMatches(str, pattern, caseSensitive)
	local hits = {}
	local offset = 1
	local ogStr = str
	if not caseSensitive then
		str = str:lower()
		pattern = pattern:lower()
	end
	while true do
		local x, y = string.find(str, pattern, offset, true)
		if x == nil then break end
		hits[#hits + 1] = { x, ogStr:sub(x, y) }
		offset = y + 1
	end
	return hits
end


local function search(doc, searchStr, caseSensitive)
	local hits = {}
	if #searchStr == 0 then return hits end
	local lineNum = 1
	local lineContent = ""
	for _, chunk in ipairs(petty.squash(doc)) do
		if chunk.tag == "text" then
			---@cast chunk ccTweaked.cc.pretty.Doc.text
			lineContent = lineContent .. chunk.text
		elseif chunk.tag == "line" then
			for _, hit in ipairs(findPosOfAllMatches(lineContent, searchStr, caseSensitive)) do
				hits[#hits + 1] = { pos = vec.new(hit[1], lineNum), contents = hit[2] }
			end
			lineNum = lineNum + 1
			lineContent = ""
		end
	end
	return hits
end

function module.focus(doc)
	---Todo, switch to vectors
	term.clear()
	local x, y = 0, 0
	local termSizeX, termSizeY = term.getSize()
	local workingSizeX, workingSizeY = termSizeX, termSizeY - 1
	local docSizeX, docSizeY = petty.getSize(doc)
	local searchStr = ""
	local caseSensitive = false
	local refresh = true
	---@type "search"?
	local mode
	---@type {pos: lib.feather.vec2d, contents: string}[]
	local searchHits = {}
	local currSearchFocus
	---@type integer?
	local mult
	while true do
		local oldX, oldY, oldMult = x, y, mult
		if refresh then
			refresh = false
			---TODO make a "theme" library to make this less clunky
			local c = term.getTextColor()
			local bgC = term.getBackgroundColor()
			display(doc, x, y, workingSizeY)
			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			for i, hit in ipairs(searchHits) do
				if hit.pos.x > x and hit.pos.x <= x + workingSizeX and
					hit.pos.y > y and hit.pos.y <= y + workingSizeY then
					if i == currSearchFocus then
						term.setBackgroundColor(colors.yellow)
					end
					term.setCursorPos(hit.pos.x - x, hit.pos.y - y)
					term.write(hit.contents)
					if i == currSearchFocus then
						term.setBackgroundColor(colors.white)
					end
				end
			end
			if mode == "search" then
				term.setCursorPos(1, termSizeY)
				term.write((caseSensitive and "?" or "/") .. searchStr)
			else
				term.setCursorPos(1, termSizeY)
				term.write("Lines: " .. y .. "-" .. math.min(y + workingSizeY, docSizeY) .. "/" .. docSizeY)
			end
			if #searchStr > 0 then
				local str = ((currSearchFocus and currSearchFocus .. "/") or "") .. #searchHits
				term.setCursorPos(termSizeX - #str, termSizeY)
				term.write(str)
			end
			if mult then
				local str = "*" .. mult
				term.setCursorPos((termSizeX - #str) / 2, termSizeY)
				term.write(str)
			end
			term.setTextColor(c)
			term.setBackgroundColor(bgC)
		end
		local type, key = os.pullEvent()
		---@type integer
		local num = tonumber(key) --[[@as integer]]
		if mode == "search" then
			if type == "char" then
				searchStr = searchStr .. key
				searchHits = search(doc, searchStr, caseSensitive)
				refresh = true
			elseif type == "key" then
				if key == keys.enter then
					mode = nil
				elseif key == keys.backspace then
					if #searchStr == 0 then
						mode = nil
						refresh = true
					else
						searchStr = searchStr:sub(1, -2)
						searchHits = search(doc, searchStr, caseSensitive)
						refresh = true
					end
				end
			end
		elseif mode == nil then
			if type == "key" then
				if key == keys.q then
					term.clear()
					term.setCursorPos(1, 1)
					sleep(0)
					return
				elseif binds.right[key] then
					x = x + 1 * (mult or 1)
					mult = nil
				elseif binds.left[key] then
					x = x - 1 * (mult or 1)
					mult = nil
				elseif binds.up[key] then
					y = y - 1 * (mult or 1)
					mult = nil
				elseif binds.down[key] then
					y = y + 1 * (mult or 1)
					mult = nil
				elseif key == keys.backspace and mult then
					mult = tonumber(tostring(mult):sub(1, -2))
					refresh = true
				end
			elseif type == "char" then
				if key == "/" then
					caseSensitive = false
					mode = "search"
					searchStr = ""
					searchHits = {}
					refresh = true
				elseif key == "?" then
					caseSensitive = true
					mode = "search"
					searchStr = ""
					searchHits = {}
					refresh = true
				elseif key == "n" or key == "N" then
					if #searchHits > 0 then
						if key == "n" then
							currSearchFocus = currSearchFocus or 0
							currSearchFocus = (currSearchFocus - 1 + (mult or 1)) % #searchHits + 1
						else
							currSearchFocus = currSearchFocus or 1
							currSearchFocus = (currSearchFocus - 1 - (mult or 1)) % #searchHits + 1
						end
						x = searchHits[currSearchFocus].pos.x - termSizeX + #searchStr
						y = searchHits[currSearchFocus].pos.y - termSizeY + 1
						mult = nil
						refresh = true
					end
				elseif num then
					if not mult and num == 0 then
						mult = 10
					elseif not mult then
						mult = num
					elseif math.log10(mult) < 4 then
						mult = tonumber(mult .. num) --[[@as integer]]
					end
					refresh = true
				elseif key == "g" then
					x = 0
					y = 0
				elseif key == "G" then
					x = 0
					y = math.huge
				end
			end
		end
		if #searchStr == 0 then
			if currSearchFocus then
				currSearchFocus = nil
				refresh = true
			end
		end

		x = math.max(math.min(x, docSizeX - termSizeX + 1), 0)
		y = math.max(math.min(y, docSizeY - termSizeY + 1), 0)

		if oldX ~= x or oldY ~= y or oldMult ~= mult then
			refresh = true
		end
	end
end

return module
