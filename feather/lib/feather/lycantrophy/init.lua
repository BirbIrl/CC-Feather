---@class lib.feather.lycantrophy
local module = {}

module.defaultConfig = bundl("feather.lycantrophy.defaultConfig") ---@type lib.feather.lycantrophy.config

---@param template? lib.feather.lycantrophy.config
---@return lib.feather.lycantrophy.config
function module.newConfig(template)
	local newConfig = {}
	for property, defaultValue in pairs(module.defaultConfig) do
		newConfig[property] = template and template[property] or defaultValue
	end
	return newConfig
end

module.Element = bundl("feather.lycantrophy.elements.Element") ---@type lib.feather.lycantrophy.Element

module.TextElement = bundl("feather.lycantrophy.elements.TextElement") ---@type lib.feather.lycantrophy.TextElement

module.FrameElement = bundl("feather.lycantrophy.elements.FrameElement") ---@type lib.feather.lycantrophy.FrameElement

module.GroupElement = bundl("feather.lycantrophy.elements.GroupElement") ---@type lib.feather.lycantrophy.GroupElement


return module
