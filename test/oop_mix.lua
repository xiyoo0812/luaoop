--oop_mix.lua

local Mix = mixin()

local prop = property(Mix)
prop:accessor("key1", 1)
prop:accessor("key2", 2)

function Mix:__init()
    self:_sub_test("__init")
end

function Mix:_sub_test(src)
    print("_sub_test:", src)
    self:_sub_test2("_sub_test")
end

function Mix:_sub_test2(src)
    print("_sub_test2:", src)
end

function Mix:test1()
    self:_sub_test("test1")
    print("key1", self:get_key1())
    self:set_key2(4)
    print("key2", self:get_key2())
    self:set_key3(6)
    print("key3", self:get_key3())
end

function Mix:setup()
end

function Mix:test2()
    print("key2", self.key2)
end

function Mix:test3()
    print("key3", self.key3)
end

return Mix
