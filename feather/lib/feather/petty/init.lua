local pretty = require("cc.pretty")
---@class lib.feather.petty: ccTweaked.cc.pretty
local module = {}
setmetatable(module, { __index = pretty })
local docMt = getmetatable(module.empty)
module.nbsp = "\160"

---@param doc ccTweaked.cc.pretty.Doc
local function squash(doc)
	if doc.tag ~= "concat" then
		return { doc }
	end
	local elems = {}
	for _, elem in ipairs(doc) do
		for _, bit in ipairs(squash(elem)) do
			elems[#elems + 1] = bit
		end
	end
	return elems
end

---Make sure to add spaces at the start of words, instead of leaving trailing spaces which won't break the line naturally
---@param subject ccTweaked.cc.pretty.Doc.text|ccTweaked.cc.pretty.Doc.concat
---@param maxWidth integer
---@return ccTweaked.cc.pretty.Doc.text[] doc
---@return integer height
---@return integer longestLine
function module.wrap(subject, maxWidth)
	assert(maxWidth > 0, "maxWidth must be more than 0. Currently: " .. maxWidth)
	local doc = {}
	local takenWidth = 0
	local lines = 1
	local longestLine = 0
	for _, text in ipairs(squash(subject)) do
		local broken = ""
		if text.tag == "text" then
			---@cast text ccTweaked.cc.pretty.Doc.text
			for breakingChar, segment in text.text:gmatch("([ \n]?)([^ ^\n]*)") do
				if segment == "" then
					segment = breakingChar
					breakingChar = ""
				end
				while #segment > 0 do
					if breakingChar == "\n" then
						takenWidth = 0
						lines = lines + 1
					elseif breakingChar == " " then
						if takenWidth + #segment + 1 <= maxWidth then
							takenWidth = takenWidth + 1
						else
							breakingChar = "\n"
							takenWidth = 0
							lines = lines + 1
						end
					end
					local spliceLength = math.min(maxWidth - takenWidth, #segment)
					broken = broken .. breakingChar .. segment:sub(1, spliceLength)
					takenWidth = takenWidth + #segment
					longestLine = math.max(longestLine, takenWidth)
					segment = segment:sub(spliceLength + 1)
					breakingChar = "\n"
				end
			end
			doc[#doc + 1] = pretty.text(broken, text.colour)
		elseif text.tag == "line" then
			doc[#doc + 1] = text
			takenWidth = 0
			lines = lines + 1
		else
			assert(text.tag == "text", "Every element must be a text or line element")
		end
	end
	return pretty.concat(table.unpack(doc)), lines, longestLine
end

---@param obj any The object to print
---@param options? prettyOptions Options for how certain things are displayed
---@param maxSize? integer For docs, maximum number of newlines, for everything else, maximum fraction of the screen width that can be written to before wrapping. Defaults to 0.6
function module.pp(obj, options, maxSize)
	if getmetatable(obj) == docMt then
		---@cast obj ccTweaked.cc.pretty.Doc
		if maxSize and obj.tag == "concat" then
			local lines = 1
			local x, y  = term.getCursorPos()
			for _, v in ipairs(squash(obj)) do
				---@cast v ccTweaked.cc.pretty.Doc
				if v.tag == "line" then
					term.setCursorPos(x, y + lines)
					lines = lines + 1
				else
					module.write(v)
				end
				if lines > maxSize then
					break
				end
			end
		end
	else
		module.pretty_print(obj, options, maxSize)
	end
end

return module
