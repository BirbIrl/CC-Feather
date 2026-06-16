local pkgname = "vault"
local type = "bin"
local ver = "unstable"
local summary = "Item management system for computercraft"
local detailed = [[
]]
local deps = { "lib.feather.luzz" }

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
