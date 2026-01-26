---@diagnostic disable
local pkgname = "flash"
local type = "bin"
local ver = "unstable"
local summary = "CLI for flashing FeatherOS on Computercraft computers"
local detailed =
[[Command line tool for copying a modifiable installation of FeatherOS onto another computer]]
local deps = { "bin.feather.featherOS" }

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
	type = "lib", -- not compatible with luarocks
}

source = {
	url = "git://" .. url .. ".git", -- not compatible with luarocks
	dir = dir
}

dependencies = deps
