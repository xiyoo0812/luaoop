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

local function on_prop_changed(object, name, value)
    local on_watch = "on_" .. name .. "_changed"
    if object[on_watch] then
        object[on_watch](object, value, name)
        return
    end
    if object["on_prop_changed"] then
        object["on_prop_changed"](object, value, name)
    end
end

local function prop_accessor(prop, class, name, default, mode, watch, unfold)
    class.__props[name] = { default, mode }
    if (mode & READER) == READER then
        class["get_" .. name] = function(self)
            return self[name]
        end
        if type(default) == "boolean" then
            class["is_" .. name] = class["get_" .. name]
        end
        if unfold and type(default) == "table" then
            for key in pairs(default) do
                if type(key) == "string" then
                    class["get_" .. name .. "_" .. key] = function(self)
                        local prop = self[name]
                        if prop then
                            return prop[key]
                        end
                    end
                end
            end
        end
    end
    if (mode & WRITER) == WRITER then
        local function
        class["set_" .. name] = function(self, value)
            if self[name] ~= value then
                self[name] = value
                if watch then
                    on_prop_changed(self, name, value)
                end
            end
        end
        if unfold and type(default) == "table" then
            for key in pairs(default) do
                if type(key) == "string" then
                    class["set_" .. name .. "_" .. key] = function(self, value)
                        local prop = self[name]
                        if prop and prop[key] ~= value then
                            prop[key] = value
                            if watch then
                                on_prop_changed(self, name, prop)
                            end
                        end
                    end
                end
            end
        end
    end
end

local property_reader = function(self, name, default)
    prop_accessor(self, self.__class, name, default, READER)
end
local property_writer = function(self, name, default, watch)
    prop_accessor(self, self.__class, name, default, WRITER, watch)
end
local property_accessor = function(self, name, default, watch)
    prop_accessor(self, self.__class, name, default, ACCESSOR, watch)
end

local unfold_property_reader = function(self, name, default)
    prop_accessor(self, self.__class, name, default, READER, false, true)
end
local unfold_property_writer = function(self, name, default, watch)
    prop_accessor(self, self.__class, name, default, WRITER, watch, true)
end
local unfold_property_accessor = function(self, name, default, watch)
    prop_accessor(self, self.__class, name, default, ACCESSOR, watch, true)
end

function property(class)
    local prop = {
        __class = class,
        reader = property_reader,
        writer = property_writer,
        accessor = property_accessor,
        unfold_reader = unfold_property_reader,
        unfold_writer = unfold_property_writer,
        unfold_accessor = unfold_property_accessor,
    }
    return prop
end

