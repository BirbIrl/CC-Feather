local featherd = bundl "feather.featherd" ---@type feather.featherd
local windex = bundl "feather.windex" ---@type feather.windex
local tty = bundl "feather.tty" ---@type feather.tty
local vec = bundl "feather.vec2d" ---@type feather.vec2d

---@class feather.mush
local module = {}


---@type integer[]
local tabs = {}

---@type number
local currTab = nil
---@type feather.featherd.process
local currProcess = nil

local lastTpress = os.clock()

function shell.openTab(...)
	local args = table.pack(...)
	local prev = term.redirect(term.native())
	local size = tty.getSize()
	local proc = featherd.addProcess("mush_tab", function()
		shell.run(table.unpack(args))
	end, "discard", false, windex.create(term.current(), 1, 2, size.x, size.y - 1, false))
	table.insert(tabs, (currTab or 0) + 1, proc.pid)
	term.redirect(prev)
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
		local ctrlHeld = false
		local shiftHeld = false
		tty.setBackgroundColor(colors.gray)
		tty.setTextColor(colors.black)
		while true do
			tty.clear()
			tty.setCursorPos(vec.one)
			for i = #tabs, 1, -1 do
				if coroutine.status(featherd.processesByPid[tabs[i]].thread) == "dead" then
					table.remove(tabs, i)
					if i == currTab then
						shell.switchTab(i)
					end
				end
			end
			if #tabs == 0 then
				os.reboot()
			end
			if currTab > #tabs then
				shell.switchTab(#tabs)
			end
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
			elseif eventName == "key" then
				if e1 == keys.leftCtrl or e1 == keys.rightCtrl then
					ctrlHeld = true
				elseif e1 == keys.leftShift or e1 == keys.rightShift then
					shiftHeld = true
				elseif e1 == keys.w and ctrlHeld then
					featherd.killProcess(featherd.getProcess(tabs[currTab]))
				elseif e1 == keys.tab and ctrlHeld and shiftHeld then
					shell.switchTab((currTab - 2) % #tabs + 1)
				elseif e1 == keys.tab and ctrlHeld then
					shell.switchTab(currTab % #tabs + 1)
				elseif e1 > 1 and e1 < 11 and ctrlHeld then
					shell.switchTab(e1 - 1)
				elseif e1 == keys.t then
					lastTpress = os.clock()
				end
			elseif eventName == "key_up" then
				if e1 == keys.leftCtrl or e1 == keys.rightCtrl then
					ctrlHeld = false
				elseif e1 == keys.t and lastTpress + 0.25 > os.clock() and ctrlHeld then
					shell.openTab("shell")
					shell.switchTab(currTab + 1)
				elseif e1 == keys.leftShift or e1 == keys.rightShift then
					shiftHeld = false
				end
			end
		end
	end, "keep", true, windex.create(term.current(), 1, 1, select(1, term.getSize()), 1, true), "silent")
	shell.openTab("shell")
	shell.switchTab(#tabs)
end

return module
