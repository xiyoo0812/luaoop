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
    self:setup()
end

function Object:__release()
    print("release", self)
end

function Object:_run()
    print("_run", self.key2)
end

function Object:run()
    print("key3", self:get_key3())
    print("key1", self:get_key1())
    print("key2", self:get_key2())
    print("key4", self:get_key4())
    self:invoke("test1")
    self:test2()
    self:_sub_test("run")
end

local obj = Object()
obj:run()
obj:_run()
obj:_sub_test("main")

return Object
