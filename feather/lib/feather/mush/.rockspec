local pkgname = "mush"
local type = "lib"
local ver = "unstable"
local summary = "A multishell for featherOS"
local detailed =
[[]]
local deps = { "bin.feather.featherd", "lib.feather.windex", "lib.feather.tty", "lib.feather.vec2d" }

local url = "github.com/birbirl/CC-Feather"
local manifest = "feather"

local dir = type .. "/" .. manifest .. "/" .. pkgname

rockspec_format = "3.0"
package = dir:gsub("/", ".")
version = ver

description = {
	summary = summary,
	detailed = detailed,
	labels = { "CC-Feather" },
	homepage = "https://" .. url,
	license = "GPL-3.0"
}

build = {
	type = type, -- not compatible with luarocks
}

source = {
	url = "git://" .. url .. ".git", -- not compatible with luarocks
	dir = dir
}

dependencies = deps
