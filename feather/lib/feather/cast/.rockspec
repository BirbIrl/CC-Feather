---@diagnostic disable: lowercase-global
local pkgname = "cast"
local type = "lib"
local ver = "unstable"
local summary = "network object access lib for computercraft"
local detailed =
[[universal way of passing an object onto the network for any other computercraft computer to use, part of the cc-feather project]]
local deps = {}

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
