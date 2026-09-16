local paths = fs.find(".feather/share/craft/recipies/minecraft/*")

local total = 0
dbg(paths)
for _, path in ipairs(paths) do
    total = total + fs.getSize(path)
end
print(total)
