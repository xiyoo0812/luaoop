--oop_base.lua

local Base = class()
local prop2 = property(Base)
prop2:accessor("key4", 4)

function Base:__init()
    print("Base:__init", self)
end

function Base:__release()
    print("Base:release", self)
end

function Base:setup()
    print("Base:setup", self)
end

function Base:run()
    print("Base:run", self)
end

return Base
