---@diagnostic disable
local pkgname = "mess"
local type = "bin"
local ver = "unstable"
local summary = "text reader for computercraft"
local detailed =
[[Command line tool for reading files and searching for content inside them]]
local deps = { "lib.feather.mess", "lib.feather.argh" }

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
