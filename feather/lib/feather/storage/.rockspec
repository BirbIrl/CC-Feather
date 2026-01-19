local url = 'github.com/birbirl/CC-Feather'
local git_url = "git://" .. url .. '.git'
local repo_url = 'https://' .. url
local pkgname = "storage"

rockspec_format = "3.0"
package = "feather." .. pkgname
version = "unstable"

description = {
	summary = 'filesystem lib for computercraft',
	detailed =
	[[filesystem library for the computercraft mod, part of the cc-feather project]],
	labels = { 'CC-Feather' },
	homepage = repo_url,
	license = 'GPL-3.0'
}

source = {
	url = git_url, -- sorry, not compatible with luarocks
	dir = '.feather/lib/' .. pkgname,
}

dependencies = {}
