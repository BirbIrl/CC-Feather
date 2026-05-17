---@class lib.feather.Object
local Object = bundl("feather.Object")

---@class lib.feather.Object.example.child1: lib.feather.Object
---@field super lib.feather.Object
local Child1 = Object:extend()
function Child1:new()
	local child = Child1.super.new(self)
	---@type lib.feather.Object.example.child1
	return setmetatable(child, Child1)
end

function Child1:sob()
	return true
end

---@class lib.feather.Object.example.child2: lib.feather.Object
---
---@field super lib.feather.Object
local Child2 = Object:extend()
function Child2:new()
	local child = Child2.super.new(self)
	---@type lib.feather.Object.example.child2
	return setmetatable(child, Child2)
end

function Child2:cry()
	return true
end

local object = Object:new()
local child1 = Child1:new()
local child2 = Child2:new()
print(Object:isInstance())       -- false
print(Child1:isInstance())       -- false
print(object:isInstance())       -- true
print(child1:isInstance())       -- true
print(child1:instanceOf(Object)) -- true
print(child1:instanceOf(Child1)) -- true
print(child1:instanceOf(Child2)) -- false
print(child1:sob())              -- true
print(child2:cry())              -- true
