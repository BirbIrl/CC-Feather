local featherd = bundl "feather.featherd" ---@type feather.featherd
---@class feather.raid
local module = {}

---@class feather.raid.partition
---@field path ccTweaked.fs.path
---@field id integer


---@param drive ccTweaked.peripheral.Drive
---@return integer?
local function getPartitionId(drive)
	local label = drive.getDiskLabel()
	if label and label:sub(1, 3) == "NAS" then
		return tonumber(label:sub(4, -1))
	end
end

---@return feather.raid.partition[]
function module.getPartitions()
	local drives = { peripheral.find("drive") } ---@type ccTweaked.peripheral.Drive[]
	local partitions = {}
	local highest = 0
	for _, drive in ipairs(drives) do
		local id = getPartitionId(drive)
		if id then
			if id > highest then
				highest = id
			end
			if partitions[id] then
				error("Duplicate drive found for id: " .. id)
			end
			partitions[id] = { path = drive.getMountPath(), id = id }
		end
	end
	if #partitions ~= highest then
		error("Missing disk in order with ID: " .. #partitions + 1 .. ". Highest id found until then: " .. highest)
	end
	return partitions
end

---Gets the largest partition with the minimum required free space
---@param minSpace? integer default 1kb
---@return feather.raid.partition?
function module.getPartition(minSpace)
	minSpace = minSpace or 1000
	local partitions = module.getPartitions()
	local best = nil
	local bestSpace = math.huge
	for _, partition in ipairs(partitions) do
		local space = fs.getFreeSpace(partition.path)
		assert(type(space) == "number")
		if space > minSpace and space < bestSpace then
			best = partition
			bestSpace = space
		end
	end
	return best
end

function module.bind()
	local partitions = module.getPartitions()
	local currId = #partitions + 1
	local drives = { peripheral.find("drive") } ---@type ccTweaked.peripheral.Drive[]
	for _, drive in ipairs(drives) do
		local path = drive.getMountPath()
		if path and not getPartitionId(drive) then
			if #fs.list(path) == 0 then
				drive.setDiskLabel("NAS" .. currId)
				currId = currId + 1
			else
				featherd.log("Ignored mounting drive: " .. drive.getDiskLabel() .. " not empty.")
			end
		end
	end
end

---@return integer free
function module.getFreeSoace()
	local partitions = module.getPartitions()
	local free = 0
	for _, partition in ipairs(partitions) do
		free = free + fs.getFreeSpace(partition.path)
	end
	return free
end

---@return integer capacity
function module.getCapacity()
	local partitions = module.getPartitions()
	local capacity = 0
	for _, partition in ipairs(partitions) do
		capacity = capacity + fs.getCapacity(partition.path)
	end
	return capacity
end

---@param path ccTweaked.fs.path The path to the file to open
local function getInstance(path)
	if path:find("*") then
		error("Wildcard \"*\" is not supported")
	end
	local hits = fs.find(fs.combine("disk*/", path))
	if #hits == 0 then
		return nil
	elseif #hits == 1 then
		return hits[1]
	else
		for _, hit in ipairs(hits) do
			if not fs.isDir(hit) then
				error("Found multiple paths that match the given path to non-directory, that's a problem! Paths:" ..
					textutils.serialise(hits))
			end
		end
		return hits[1]
	end
end
--fs.find("disk*/")


---@param path ccTweaked.fs.path The path to the file to open
---@param mode ccTweaked.fs.openMode The mode to open the file with
---@param minSpace? integer The minimum free space in KB in the drive this should be created in, default 1KB
---@return ccTweaked.fs.ReadHandle|ccTweaked.fs.BinaryReadHandle|ccTweaked.fs.WriteHandle|ccTweaked.fs.BinaryWriteHandle|nil handler A file handler object or nil if the file does not exist or cannot be opened
---@return nil|string errorMessage Why the file cannot be opened
---@throws If an invalid mode was given
function module.open(path, mode, minSpace)
	minSpace = minSpace or 1000
	local instance = getInstance(path)
	if not instance then
		local partition = module.getPartition(minSpace)
		assert(partition, "Couldn't find a drive with " .. minSpace / 1000 .. "kb available")
		return fs.open(fs.combine(partition.path, path), mode)
	else
		return fs.open(instance, mode)
	end
end

--- doesn't work with directories yet
---@param from string
---@param to string
function module.copy(from, to)
	local instance = getInstance(from)
	assert(instance, "No such file found")
	assert(not fs.isDir(instance), "Copying directories is not supperted yet")
	assert(not getInstance(from), "File already exists")
	local minSize = fs.getSize(instance)
	local partition = module.getPartition(minSize)
	assert(partition, "No partition found with " .. minSize / 1000 .. "kb spare found")
	fs.copy(instance, fs.combine(partition.path, to)) -- this will error, good!
end

--- doesn't work with directories yet
---@param from string
---@param to string
function module.move(from, to)
	local instance = getInstance(from)
	assert(instance, "No such file found")
	assert(not fs.isDir(instance), "Copying directories is not supperted yet")
	assert(not getInstance(from), "File already exists")
	local disk = instance:match("disk%d*/")
	fs.move(instance, fs.combine(disk, to))
end

---@param path ccTweaked.fs.path The path to the file/directory to get the attributes of
function module.attributes(path)
	local instance = getInstance(path)
	assert(instance, "No such file or directory found")
	return fs.attributes(instance)
end

---@param path ccTweaked.fs.path The path to check the existence of
function module.exists(path)
	local instance = getInstance(path)
	if instance then
		return true
	end
	return false
end

---Get whether a path is a directory
---@param path ccTweaked.fs.path The path to check
---@return boolean isDirectory If the path exists **and** is a directory
function module.isDir(path)
	local instance = getInstance(path)
	if instance and fs.isDir(instance) then
		return true
	end
	return false
end

---@param path ccTweaked.fs.path The path to the file to get the size of
---@return number bytes The size of the file in bytes. 0 if the path points to a directory
function module.getSize(path)
	local instance = getInstance(path)
	assert(instance, "No such file")
	return fs.getSize(instance)
end

---Create a directory, including any missing parents
---@param path ccTweaked.fs.path The path to (and including) the directory to create
---@throws If target path could not be written to
function module.makeDir(path)
	local partition = module.getPartition(500)
	assert(partition, "Couldn't find a drive with " .. 500 .. "kb available")
	fs.makeDir(fs.combine(partition.path, path))
end

---Deletes a file/directory
---
---Deleting a directory **deletes ALL children** (files and subdirectories)
---
---❗Be **VERY** careful when deleting directories as you could easily delete a
---**LOT** of files by accident
---@param path ccTweaked.fs.path The path to delete
---@throws If file/directory cannot be deleted
function module.delete(path)
	local partitions = module.getPartitions()
	for _, partition in ipairs(partitions) do
		fs.delete(fs.combine(partition.path, path))
	end
end

return module
