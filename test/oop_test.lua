--ooptest.lua

warn = print
table.copy = function(src, dst)
    for field, value in pairs(src or {}) do
        dst[field] = value
    end
end

--oop_test.lua
require "luaoop.enum"
require "luaoop.class"
require "luaoop.mixin"
require "luaoop.property"

require "test.oop_enum"

local Mix = require("test.oop_mix")
local Base = require("test.oop_base")

local Object = class(Base, Mix)
local prop2 = property(Object)
prop2:accessor("key3", 3)
function Object:__init()
    print("Object:__init")
    self:setup()
end

function Object:__init_static()
    print("Object:__init_static")
end

function Object:setup()
    print("Object:setup", self)
end

function Object:__release()
    print("Object:release", self)
end

function Object:_run()
    print("Object:_run", self.key2)
end

function Object:run()
    print("Object:run key3", self:get_key3())
    print("Object:run key1", self:get_key1())
    print("Object:run key2", self:get_key2())
    print("Object:run key4", self:get_key4())
    self:invoke("test1")
    self:test2()
    self:_sub_test("run")
end

local obj = Object()
obj:run()
obj:_run()
obj:_sub_test("main")

return Object
