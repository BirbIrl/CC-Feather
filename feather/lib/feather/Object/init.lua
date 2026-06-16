---@class feather.Object
local Class = {}

---@private
Class.__index = Class

function Class:new()
	local object = {}
	return setmetatable(object, Class)
end

function Class:getClass()
	return getmetatable(self)
end

--- checks if this is an instance of any class
---@return boolean isInstance true if it's an instance, false if it's a class
function Class:isInstance()
	return self.__index ~= self -- and yet work it does
end

--- checks if this is an instance of a specific class
---@param class feather.Object class to check if this an instance of
---@param strict? true doesn't check the inheritance chain
---@return boolean
function Class:instanceOf(class, strict)
	assert(not class:isInstance())
	local thisClass = self:getClass()
	repeat
		if thisClass == class then return true end
		thisClass = thisClass:getClass()
	until strict or thisClass == Class or not thisClass
	return false
end

---makes a new child object based on parent. can only be called by the class acquired with `getClass`
---```
-----Example usage:
------@class childObject: feather.Object
------@field super feather.Object
---local Child = Class:extend()
---
---function Child:new()
---   local child = Child.super.new(self)
---   ---@type childObject
---   return setmetatable(child, Child)
---end
---```
---@return self
function Class:extend()
	assert(not self:isInstance(), "Extend should only be used by the class, not the instantiated object")
	local child = {}
	child.__index = child
	child.super = self
	return setmetatable(child, self)
end

return Class
