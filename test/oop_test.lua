--oop_test.lua
require "luaoop.enum"
require "luaoop.class"
require "luaoop.mixin"
require "luaoop.property"

local IObject = mixin()

local prop = property(IObject)
prop:accessor("key1", 1)
prop:accessor("key2", 2)

function IObject:__init()
    self:_sub_test("__init")
end

function IObject:_sub_test(src)
    print("_sub_test:", src)
    self:_sub_test2("_sub_test")
end

function IObject:_sub_test2(src)
    print("_sub_test2:", src)
end

function IObject:test1()
    self:_sub_test("test1")
    print("key1", self:get_key1())
    self:set_key2(4)
    print("key2", self:get_key2())
    self:set_key3(6)
    print("key3", self:get_key3())
end

function IObject:setup()
end

function IObject:test2()
    print("key2", self.key2)
end

function IObject:test3()
    print("key3", self.key3)
end

local Base = require("test.oop_base")

local Object = class(Base, IObject)
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
