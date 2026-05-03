---@class lib.feather.petty
local module = {}
module.nbsp = "\160"

---@alias lib.feather.petty.doc (string|ccTweaked.colors.color|)[]

---@param subject? string|boolean|number|lib.feather.petty.doc
---@param maxWidth integer
---@return lib.feather.petty.doc doc
---@return integer height
function module.petty(subject, maxWidth)
	if type(subject) ~= "table" then
		subject = { tostring(subject) }
	end
	local doc = {}
	local currWidth = 0
	for _, str in ipairs(subject) do
		if type(str) ~= "string" then
			doc[#doc + 1] = str
		end
		local broken = ""
		for breakingChar, segment in str:gmatch("([ \n]?)([^ ^\n]*)") do
			local total = currWidth + #breakingChar + #segment
			if breakingChar == "\n" or total > maxWidth then
				currWidth = #segment
				repeat
					broken = broken .. breakingChar .. segment:sub(1, maxWidth)
					breakingChar = "\n" -- after the first loop, use \n for newlines
					segment = segment:sub(maxWidth + 1)
				until #segment == 0
			else
				currWidth = total
				broken = broken .. breakingChar .. segment
			end
		end
		if broken ~= "" then
			doc[#doc + 1] = broken
		end
	end
	return doc, 0
end

return module
