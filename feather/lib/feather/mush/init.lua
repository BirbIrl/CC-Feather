local featherd = bundl "feather.featherd" ---@type feather.featherd
local windex = bundl "feather.windex" ---@type feather.windex
local tty = bundl "feather.tty" ---@type feather.tty
local vec = bundl "feather.vec2d" ---@type lib.feather.vec2d

---@class feather.mush
local module = {}


---@type integer[]
local tabs = {}

---@type number
local currTab = nil
---@type feather.featherd.process
local currProcess = nil

function shell.openTab(...)
	local args = table.pack(...)
	local size = tty.getSize()
	local proc = featherd.addProcess("mush_tab", function()
		shell.run(table.unpack(args))
	end, "discard", false, windex.create(term.native(), 1, 2, size.x, size.y - 1, false))
	tabs[#tabs + 1] = proc.pid
	return proc.pid
end

---@param id integer
function shell.switchTab(id)
	local pid = tabs[id]
	if not pid then
		return false
	end
	local process = featherd.processesByPid[pid]
	assert(process, "couldn't find process under the given pid")
	if currProcess then
		currProcess.inputType = false
		currProcess.window.setVisible(false)
	end
	currProcess = process
	process.inputType = true
	process.window.setVisible(true)
	currTab = id
end

function module.disableMultishellCommands()
	shell.setPath(shell.path():gsub(":/rom/programs/advanced", ""))
end

function module.init()
	assert(not (featherd.processesByName["mush"] and featherd.processesByName["mush"][1]))
	assert(not multishell, "bios.use_multishell must be set to false for featheros to work")
	module.disableMultishellCommands()
	featherd.addProcess("mush", function()
		tty.setBackgroundColor(colors.gray)
		tty.setTextColor(colors.black)
		while true do
			tty.clear()
			tty.setCursorPos(vec.one)
			for i, _ in ipairs(tabs) do
				if i == currTab then
					tty.push()
					tty.setBackgroundColor(colors.black)
					tty.setTextColor(colors.yellow)
					tty.write("[" .. i .. "]")
					tty.pop()
				else
					tty.write("[" .. i .. "]")
				end
			end
			local eventName, e1, e2, e3 = os.pullEvent()
			if eventName == "mouse_click" then
				if e3 == 1 then
					local target = math.ceil(e2 / 3)
					if tabs[target] then
						shell.switchTab(target)
					end
				end
			end
		end
	end, "keep", true, windex.create(term.current(), 1, 1, select(1, term.getSize()), 1, true), "silent"
	)
	shell.openTab("shell")
	shell.openTab("shell")
	shell.switchTab(#tabs)
end

return module
