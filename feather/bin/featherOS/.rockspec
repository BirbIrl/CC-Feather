local pkgname = "featherOS"
local type = "bin"
local ver = "unstable"
local summary = "filesystem lib for computercraft"
local detailed =
[[filesystem library for the computercraft mod, part of the cc-feather project]]

local url = "github.com/birbirl/CC-Feather"
local manifest = "feather"

local dir = type .. "/"
if type == "lib" then
	dir = dir .. manifest .. "/"
end

rockspec_format = "3.0"
package = manifest .. "." .. pkgname
version = ver

description = {
	summary = summary,
	detailed = detailed,
	labels = { "CC-Feather" },
	homepage = "https://" .. url,
	license = "GPL-3.0"
}

build = {
	type = "lib", -- not compatible with luarocks
}

source = {
	url = "git://" .. url .. ".git", -- not compatible with luarocks
	dir = dir .. pkgname
}

dependencies = {}
