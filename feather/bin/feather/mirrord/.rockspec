---@diagnostic disable
local pkgname = "mirrord"
local type = "bin"
local ver = "unstable"
local summary = "backend for lib.feather.bundle for ComputerCraft"
local detailed =
[[mirrord is a daemon that servers installed lib.feather.bundle pacakges to other computers that wish to use the bin.feather.bundle packager]]
local deps = { "lib.feather.storage", "bin.feather.featherOS" }

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
