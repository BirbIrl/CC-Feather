local vec = bundl("feather.vec2d") ---@type feather.vec2d

---@alias feather.lycantrophy.config {
---minSize: feather.vec2d,
---maxSize: feather.vec2d,
---backgroundColor: ccTweaked.colors.color }


---@type feather.lycantrophy.config
return {
	minSize = vec.zero,
	maxSize = vec.huge,
	backgroundColor = colors.gray,
}
