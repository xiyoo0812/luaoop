--oop_mix.lua

local MixBase = require("test.oop_mixbase")

local Mix = mixin(MixBase)

local prop = property(Mix)
prop:accessor("key2", 2)

function Mix:__init()
    self:_sub_test3("__init")
end

function Mix:_sub_test(src)
    print("Mix:_sub_test:", src)
    self:_sub_test2("_sub_test")
end

function Mix:_sub_test2(src)
    print("Mix:_sub_test2:", src)
end

function Mix:test1()
    self:_sub_test("test1")
    print("Mix:test1 key1", self:get_key1())
    self:set_key2(4)
    print("Mix:test1 key2", self:get_key2())
    self:set_key3(6)
    print("Mix:test1 key3", self:get_key3())
end

function Mix:test2()
    print("Mix:test2 key2", self.key2)
end

function Mix:test3()
    print("Mix:test3 key3", self.key3)
end

return Mix
