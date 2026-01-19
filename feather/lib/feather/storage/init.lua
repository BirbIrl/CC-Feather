---@class feather.storage
local module = {}

---@class feather.storage.entryStruct
---@field name string
---@field path ccTweaked.fs.path

---@class feather.storage.fileStruct: feather.storage.entryStruct
---@field contents string

---@class feather.storage.folderStruct: feather.storage.entryStruct
---@field contents feather.storage.entryStruct[]



---Encodes a file path as a feather.storage.entryStruct
---@param path ccTweaked.fs.path
---@return feather.storage.entryStruct
function module.encode(path)
	if not fs.exists(path) then
		error("path: " .. path .. " doesn't exist")
	end

	if fs.isDir(path) then
		---@type feather.storage.folderStruct
		local folder = {
			name = fs.getName(path),
			path = path,
			contents = {}
		}
		for _, entryName in ipairs(fs.list(path)) do
			folder.contents[#folder.contents + 1] = module.encode(
				fs.combine(path, entryName)
			)
		end
		return folder
	else
		local file = assert(fs.open(path, "r"))
		local contents = file.readAll()
		file.close()
		---@type feather.storage.fileStruct
		return {
			name = fs.getName(path),
			path = path,
			contents = contents or ""

		}
	end
end

---Decodes a feather.storage.entryStruct and saves the files to their original path, or a given path
---the path given is the new full pathname of the root file/folder of the struct
---@param entry feather.storage.entryStruct|feather.storage.fileStruct|feather.storage.folderStruct
---@param path ccTweaked.fs.path?
function module.decode(entry, path)
	path = path or entry.path
	if type(entry.contents) == "string" then
		local file = assert(fs.open(path, "w"))
		file.write(entry.contents)
		file.close()
	else
		fs.makeDir(path)
		for _, child in ipairs(entry.contents --[[@as feather.storage.folderStruct[] ]]) do
			module.decode(child, fs.combine(path, child.name))
		end
	end
end

return module
