local url = 'github.com/birbirl/CC-Feather'
local git_url = "git://" .. url .. '.git'
local repo_url = 'https://' .. url
local pkgname = "bundleUtil"

rockspec_format = "3.0"
package = "feather." .. pkgname
version = "unstable"

description = {
	summary = 'packaging lib for computercraft',
	detailed =
	[[packaging library for the computercraft mod, part of the cc-feather project]],
	labels = { 'CC-Feather' },
	homepage = repo_url,
	license = 'GPL-3.0'
}

source = {
	url = git_url, -- sorry, not compatible with luarocks
	dir = '.feather/lib/' .. pkgname,
}

dependencies = {}
