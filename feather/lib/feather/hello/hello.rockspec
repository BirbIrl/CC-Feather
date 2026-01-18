local repo_url = 'github.com/birbirl/CC-Feather'
local pkgname = "hello"

rockspec_format = "3.0"
package = "feather." .. pkgname
version = "unstable"

description = {
	summary = 'Example pacakge',
	detailed =
	[[Prints and returns the string "Hello World!" ]],
	labels = { 'CC-Feather' },
	homepage = repo_url,
	license = 'GPL-3.0'
}

source = {
	url = "git://" .. repo_url .. '.git', -- sorry, not compatible with luarocks
	dir = '.feather/lib/' .. pkgname,
}

dependencies = {}
