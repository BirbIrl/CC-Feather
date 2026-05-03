local pretty = require("cc.pretty")
---@class lib.feather.petty: ccTweaked.cc.pretty
local module = {}
setmetatable(module, { __index = pretty })
local docMt = getmetatable(module.empty)
module.nbsp = "\160"

---Make sure to add spaces at the start of words, instead of leaving trailing spaces
---@param subject ccTweaked.cc.pretty.Doc.text|ccTweaked.cc.pretty.Doc.concat
---@param maxWidth integer
---@return ccTweaked.cc.pretty.Doc.text[] doc
---@return integer height
function module.wrap(subject, maxWidth)
	local doc = {}
	local currWidth = 0
	local lines = 1
	if subject.tag == "text" then
		subject = { subject } ---@diagnostic disable-line
	end
	for _, text in ipairs(subject) do
		local broken = ""
		assert(text.tag == "text", "Every element must be a text element")
		for breakingChar, segment in text.text:gmatch("([ \n]?)([^ ^\n]*)") do
			if segment == "" then
				segment = breakingChar
				breakingChar = ""
			end
			while #segment > 0 do
				if breakingChar == "\n" then
					currWidth = 0
					lines = lines + 1
				elseif breakingChar == " " then
					if currWidth + #segment + 1 <= maxWidth then
						currWidth = currWidth + 1
					else
						breakingChar = "\n"
						currWidth = 0
						lines = lines + 1
					end
				end

				local spliceLength = maxWidth - currWidth
				broken = broken .. breakingChar .. segment:sub(1, spliceLength)
				currWidth = currWidth + #segment
				segment = segment:sub(spliceLength + 1)
				breakingChar = "\n"
			end
		end
		doc[#doc + 1] = pretty.text(broken, text.colour)
	end
	return pretty.concat(table.unpack(doc)), lines
end

---@param obj any The object to print
---@param options? prettyOptions Options for how certain things are displayed
---@param maxWidth? number The maximum fraction of the screen width that can be written to before wrapping. Defaults to 0.6
function module.pp(obj, options, maxWidth)
	if getmetatable(obj) == docMt then
		module.print(obj)
	else
		module.pretty_print(obj, options, maxWidth)
	end
end

return module
