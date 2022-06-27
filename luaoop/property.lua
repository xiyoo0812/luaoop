--property.lua
--[[提供对象属性机制
示例:
    local Object = class()
    prop = property(Object)
    prop:reader("id", 0)
    prop:accessor("name", "")
--]]

local type      = type
local select    = select
local tpack     = table.pack

local WRITER    = 1
local READER    = 2
local ACCESSOR  = 3

local function unequal(a, b)
    if type(a) ~= "table" then
        return a ~= b
    end
    for k, v in pairs(a) do
        if b[k] ~= v then
            return true
        end
    end
    return false
end

local function on_prop_changed(object, name, value, ...)
    local f_prop_changed = object.on_prop_changed
    if f_prop_changed then
        f_prop_changed(object, value, name, ...)
    end
end

local function prop_accessor(class, name, default, mode)
    class.__props[name] = tpack(default, mode)
    if (mode & READER) == READER then
        class["get_" .. name] = function(self)
            return self[name]
        end
        if type(default) == "boolean" then
            class["is_" .. name] = class["get_" .. name]
        end
    end
    if (mode & WRITER) == WRITER then
        class["set_" .. name] = function(self, value, ...)
            if unequal(self[name], value) then
                self[name] = value
                local n = select("#", ...)
                if n > 0 then
                    on_prop_changed(self, name, value, ...)
                end
            end
        end
    end
end

local property_reader = function(self, name, default)
    prop_accessor(self.__class, name, default, READER)
end
local property_writer = function(self, name, default)
    prop_accessor(self.__class, name, default, WRITER)
end
local property_accessor = function(self, name, default)
    prop_accessor(self.__class, name, default, ACCESSOR)
end

function property(class)
    local prop = {
        __class = class,
        reader = property_reader,
        writer = property_writer,
        accessor = property_accessor
    }
    return prop
end

