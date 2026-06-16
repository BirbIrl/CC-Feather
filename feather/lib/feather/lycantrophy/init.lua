---@class feather.lycantrophy
local module = {}

module.defaultConfig = bundl("feather.lycantrophy.defaultConfig") ---@type feather.lycantrophy.config

---@param template? feather.lycantrophy.config
---@return feather.lycantrophy.config
function module.newConfig(template)
	local newConfig = {}
	for property, defaultValue in pairs(module.defaultConfig) do
		newConfig[property] = template and template[property] or defaultValue
	end
	return newConfig
end

module.Element = bundl("feather.lycantrophy.elements.Element") ---@type feather.lycantrophy.Element

module.TextElement = bundl("feather.lycantrophy.elements.TextElement") ---@type feather.lycantrophy.TextElement

module.FrameElement = bundl("feather.lycantrophy.elements.FrameElement") ---@type feather.lycantrophy.FrameElement

module.GroupElement = bundl("feather.lycantrophy.elements.GroupElement") ---@type feather.lycantrophy.GroupElement

module.SelectorElement = bundl("feather.lycantrophy.elements.SelectorElement") ---@type feather.lycantrophy.SelectorElement

module.RootElement = bundl("feather.lycantrophy.elements.RootElement") ---@type feather.lycantrophy.RootElement


return module
