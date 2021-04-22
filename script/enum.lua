--enum.lua
--[[提供枚举机制
示例:
    local enum = require(enum)
    用法1：
    local TEST1 = enum("TEST1", 0, "ONE", "THREE", "TWO")
    print(TEST1.TWO)
    用法2：
    local TEST2 = enum("TEST2", 1, "ONE", "THREE", "TWO")
    TEST2.FOUR = TEST2()
    print(TEST2.TWO, TEST2.FOUR)
    用法3：
    local TEST3 = enum("TEST3", 2)
    TEST3("ONE")
    TEST3("TWO")
    TEST3("FOUR", 4)
    local five = TEST3("FIVE")
    print(TEST3.TWO, TEST3.FOUR, TEST3.FIVE, five)
--]]
local ipairs        = ipairs
local rawget        = rawget
local rawset        = rawset
local tconcat       = table.concat
local sformat       = string.format
local dgetinfo      = debug.getinfo
local setmetatable  = setmetatable

local enum_tpls = enum_tpls or {}

local function enum_tostring(eo)
    return sformat("enum:%s(max:%s, elems: {%s})", eo.__name, eo.__vmax, tconcat(eo.__vlist, ","))
end

local function enum_new(emobj, field, value)
    value = value or emobj.__vmax
    if field then
        emobj.__vlist[field] = value
        if value >= emobj.__vmax then
            emobj.__vmax = value + 1
        end
    end
    return value
end

local function enum_index(emobj, field)
    return emobj.__vlist[field]
end

local function enum_newindex(emobj, field, value)
    local vlist = emobj.__vlist
    if vlist[field] then
        print("enum %s redefine field %s!", emobj.__name, field)
    end
    vlist[field] = value
    if value >= emobj.__vmax then
        emobj.__vmax = value + 1
    end
end

local enumMT = {
    __call = enum_new,
    __index = enum_index,
    __newindex = enum_newindex,
    __tostring = enum_tostring,
}

local function enum_init(emobj, base, ...)
    emobj.__vlist = {}
    emobj.__vmax = base
    for _, field in ipairs({ ... }) do
        emobj.__vlist[field] = emobj.__vmax
        emobj.__vmax = emobj.__vmax + 1
    end
end

local function enum_list(ems)
    local elist = rawget(ems, "__list")
    if not elist then
        elist = {}
        rawset(ems, "__list", elist)
    end
    return elist
end

local function new(ems, name, base, ...)
    local info = dgetinfo(2, "S")
    local moudle = info.short_src
    local lists = enum_list(ems)
    local eobj = lists[name]
    if eobj then
        if eobj.__moudle ~= moudle then
            print("enum %s redefined! moudle:%s", name, moudle)
        end
    else
        eobj = { __name = name, __moudle = moudle }
    end
    enum_init(eobj, base, ...)
    setmetatable(eobj, enumMT)
    lists[name] = eobj
    return eobj
end

local function index(ems, field)
    local lists = enum_list(ems)
    return lists[field]
end

local MT = {
    __call = new,
    __index = index,
}
setmetatable(enum_tpls, MT)

function enum(name, base, ...)
    if base then
        return enum_tpls(name, base, ...)
    end
    --没有传base参数表示查询
    return enum_tpls[name]
end
