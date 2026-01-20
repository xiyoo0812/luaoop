--oop_mixbase.lua

local MixBase = mixin()

local prop = property(MixBase)
prop:accessor("key1", 1)

function MixBase:__init()
    self:_sub_test("__init")
end

function MixBase:_sub_test(src)
    print("MixBase:_sub_test:", src)
    self:_sub_test2("_sub_test")
end

function MixBase:_sub_test3(src)
    print("MixBase:_sub_test3:", src)
end

return MixBase
