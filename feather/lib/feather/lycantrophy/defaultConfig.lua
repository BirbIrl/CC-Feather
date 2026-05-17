local vec = bundl("feather.vec2d") ---@type lib.feather.vec2d

---@alias lib.feather.lycantrophy.config {
---minSize: lib.feather.vec2d,
---maxSize: lib.feather.vec2d,
---backgroundColor: ccTweaked.colors.color }


---@type lib.feather.lycantrophy.config
return {
	minSize = vec.zero,
	maxSize = vec.huge,
	backgroundColor = colors.gray,
}
