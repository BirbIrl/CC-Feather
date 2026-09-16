local argh = bundl "feather.argh" ---@type feather.argh
local nas = bundl "feather.nas" ---@type feather.nas
local raid = bundl "feather.raid" ---@type feather.raid
local petty = bundl "feather.petty" ---@type feather.petty

local programPath = fs.combine(feather.installPath, "bin/feather/nas/nasd.lua")
local args = argh.parse(programPath, "nasd", "a network storage manager", {
	sufficient = true,
	next = {
		{
			name = "bind",
			argument = argh.argument.name,
			sufficient = true,
			description = "binds all unlabeled, empty drives to the NAS"
		},
		{
			name = "stat",
			argument = argh.argument.name,
			sufficient = true,
			description = "lists available space and drives"
		}
	},
}, ...)

if not args[2] then
	argh.help(programPath)
	return
end

if args[2].name == "bind" then
	raid.bind()
end

if args[2].name == "stat" then
	local free = raid.getFreeSoace()
	local capacity = raid.getCapacity()
	petty.print(
		petty.text("Available drives: ") .. petty.text(tostring(#raid.getPartitions()), colors.yellow) ..
		petty.line ..
		petty.text("Space Usage: ") .. petty.text(tostring((capacity - free) / 1000), colors.yellow) .. "/" ..
		petty.text(tostring(capacity / 1000), colors.yellow) .. "kb"
	)
end
