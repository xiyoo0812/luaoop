--[[property.lua
    local Object = class()
    prop = property(Object)
    prop:reader("id", 0)
    prop:accessor("name", "")
--]]
local type      = type

local WRITER    = 1
local READER    = 2
local ACCESSOR  = 3

local function prop_accessor(prop, class, name, default, mode, notify)
    class.__default[name] = { default }
    if (mode & READER) == READER then
        class["get_" .. name] = function(self)
            if self[name] == nil then
                return default
            end
            return self[name]
        end
        if type(default) == "boolean" then
            class["is_" .. name] = class["get_" .. name]
        end
    end
    if (mode & WRITER) == WRITER then
        class["set_" .. name] = function(self, value)
            if self[name] == nil or self[name] ~= value then
                self[name] = value
                if notify then
                    local name_notify = "on" .. name .. "changed"
                    if self[name_notify] then
                        self[name_notify](self, value)
                        return
                    end
                    local common_notify = "on_prop_changed"
                    if self[common_notify] then
                        self[common_notify](self, name, value)
                    end
                end
            end
        end
    end
end

local property_reader = function(self, name, default)
    prop_accessor(self, self.__class, name, default, READER)
end
local property_writer = function(self, name, default, notify)
    prop_accessor(self, self.__class, name, default, WRITER, notify)
end
local property_accessor = function(self, name, default, notify)
    prop_accessor(self, self.__class, name, default, ACCESSOR, notify)
end

function property(class)
    local prop = {
        __class = class,
        reader = property_reader,
        writer = property_writer,
        accessor = property_accessor,
    }
    return prop
end

