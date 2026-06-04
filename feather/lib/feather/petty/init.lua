local pretty = require("cc.pretty")
---@class lib.feather.petty: ccTweaked.cc.pretty
local module = {}
setmetatable(module, { __index = pretty })
local docMt = getmetatable(module.empty)
local ogDocMt = getmetatable(pretty.empty)
module.nbsp = "\160"


---@param doc ccTweaked.cc.pretty.Doc
function module.squash(doc)
	if doc.tag ~= "concat" then
		return { doc }
	end
	local elems = {}
	for _, elem in ipairs(doc) do
		for _, bit in ipairs(module.squash(elem)) do
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
	for _, text in ipairs(module.squash(subject)) do
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
					takenWidth = takenWidth + spliceLength
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

---@param doc ccTweaked.cc.pretty.Doc
function module.getSize(doc)
	local len = 0
	local longestLine = 0
	local lines = 0
	for _, part in ipairs(module.squash(doc)) do
		if part.tag == "line" then
			len = 0
			lines = lines + 1
		elseif part.tag == "text" then
			---@cast part ccTweaked.cc.pretty.Doc.text
			len = len + #part.text
			if len > longestLine then
				longestLine = len
			end
		end
	end
	return longestLine, lines
end

---@alias lib.feather.petty.alignment "left"|"right"|"center"

---@param obj ccTweaked.cc.pretty.Doc.concat
---@param maxLength integer
---@param alignment lib.feather.petty.alignment
---@return ccTweaked.cc.pretty.Doc.concat
function module.align(obj, maxLength, alignment)
	if alignment == "left" then
		return obj
	end
	assert(maxLength > 0)
	local currLength = 0
	---@type ccTweaked.cc.pretty.Doc.text?
	local opener
	local squashed = module.squash(obj)
	for i, doc in ipairs(squashed) do
		if doc.tag == "text" then
			---@cast doc ccTweaked.cc.pretty.Doc.text
			opener = opener or doc
			currLength = currLength + #doc.text
		end
		if doc.tag == "line" or not squashed[i + 1] then
			---@cast doc ccTweaked.cc.pretty.Doc.line
			if opener and alignment == "center" then
				opener.text = string.rep(" ", math.ceil((maxLength - currLength) / 2)) .. opener.text
			elseif opener and alignment == "right" then
				opener.text = string.rep(" ", maxLength - currLength) .. opener.text
			end
			opener = nil
			currLength = 0
		end
	end

	return obj
end

---@param str string
---@param color? ccTweaked.colors.color
local function writeColored(str, color)
	local c = term.getTextColor()
	if color then
		term.setTextColor(color)
	end
	term.write(str)
	term.setTextColor(c)
end

---@param obj any The object to print
---@param options? prettyOptions Options for how certain things are displayed
---@param fromLine? integer For petty docs, maximum number of newlines
---@param toLine? integer For petty docs, maximum number of newlines
function module.pp(obj, options, fromLine, toLine)
	fromLine = fromLine or 0
	if getmetatable(obj) == docMt or getmetatable(obj) == ogDocMt then
		---@cast obj ccTweaked.cc.pretty.Doc
		if obj.tag == "concat" then
			local lines = 1
			local x, y  = term.getCursorPos()
			for _, v in ipairs(module.squash(obj)) do
				---@cast v ccTweaked.cc.pretty.Doc
				if v.tag == "line" then
					term.setCursorPos(x, y + lines - fromLine)
					lines = lines + 1
				elseif lines < fromLine then
				elseif v.tag == "text" then
					---@cast v ccTweaked.cc.pretty.Doc.text
					writeColored(v.text, v.colour)
				else
					module.write(v, math.huge)
					assert(not fromLine,
						"fromline doesn't work with non-text/newline characters. trying to handle type: " .. v
						.tag)
				end
				if toLine and lines > toLine then
					break
				end
			end
		end
	else
		module.pretty_print(obj, options)
	end
end

return module
