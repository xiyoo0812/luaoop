--class.lua
local type      = type
local load      = load
local pcall     = pcall
local pairs     = pairs
local ipairs    = ipairs
local rawget    = rawget
local rawset    = rawset
local tostring  = tostring
local ssub      = string.sub
local sformat   = string.format
local sgmatch   = string.gmatch
local dgetinfo  = debug.getinfo
local getmetatable = getmetatable
local setmetatable = setmetatable

--类模板
local class_tpls = _ENV.__classes or {}

--栈对象
local stack_nil = { __name = "null" }
setmetatable(stack_nil, { __close = function() _G.__stack_cls = stack_nil end})

local function class_stack(cls)
    local old = _G.__stack_cls
    _G.__stack_cls = cls
    return old
end

local function deep_copy(src, dst)
    local ndst = dst or {}
    for key, value in pairs(src or {}) do
        if is_class(value) then
            ndst[key] = value()
        elseif (type(value) == "table") then
            ndst[key] = deep_copy(value)
        else
            ndst[key] = value
        end
    end
    return ndst
end

local function class_raw_call(method, class, obj, ...)
    local class_base_func = rawget(class.__vtbl, method)
    if class_base_func then
        class_base_func(obj, ...)
    end
end

local function class_mixin_call(method, class, obj, ...)
    for _, mixin in ipairs(class.__mixins) do
        local mixin_base_func = rawget(mixin.__methods, method)
        if mixin_base_func then
            local _<close> = class_stack(mixin)
            mixin_base_func(obj, ...)
        end
    end
end

local function object_init(class, obj, ...)
    local super = class.__super
    if super then
        object_init(super, obj, ...)
    end
    class_raw_call("__init", class, obj, ...)
    class_mixin_call("__init", class, obj, ...)
    return obj
end

local function object_release(class, obj, ...)
    class_mixin_call("__release", class, obj, ...)
    class_raw_call("__release", class, obj, ...)
    local super = class.__super
    if super then
        object_release(super, obj, ...)
    end
end

local function object_defer(class, obj, ...)
    class_mixin_call("__defer", class, obj, ...)
    class_raw_call("__defer", class, obj, ...)
    local super = class.__super
    if super then
        object_defer(super, obj, ...)
    end
end

local function clone_prop(args)
    local arg = args[1]
    if type(arg) ~= "table" or arg.__class then
        return arg
    end
    return deep_copy(arg)
end

local function object_props(class, obj)
    local super = class.__super
    if super then
        object_props(super, obj)
    end
    for name, args in pairs(class.__props) do
        obj[name] = clone_prop(args)
    end
    for _, mixin in ipairs(class.__mixins) do
        for name, args in pairs(mixin.__props) do
            obj[name] = clone_prop(args)
        end
    end
end

local function object_tostring(obj)
    if type(obj.tostring) == "function" then
        return object:tostring()
    end
    return sformat("class(%s)[%s]", obj.__addr, obj.__source)
end

local function object_constructor(class)
    local obj = {}
    class.__count = class.__count + 1
    object_props(class, obj)
    obj.__addr = ssub(tostring(obj), 8)
    setmetatable(obj, class.__vtbl)
    return obj
end

local function object_super(obj)
    return obj.__super
end

local function object_source(obj)
    return obj.__source
end

local function object_address(obj)
    return obj.__addr
end

local function mt_class_new(class, ...)
    if rawget(class, "__singleton") then
        local obj = rawget(class, "__inst")
        if not obj then
            obj = object_constructor(class)
            rawset(class, "__inst", obj)
            rawset(class, "inst", function()
                return obj
            end)
            object_init(class, obj, ...)
        end
        return obj
    else
        local obj = object_constructor(class)
        return object_init(class, obj, ...)
    end
end

local function mt_class_close(class)
    _G.__stack_cls = class
end

local function mt_class_index(class, method)
    return class.__vtbl[method]
end

local function mt_class_newindex(class, method, valfunc)
    if type(valfunc) ~= "function" then
        class.__vtbl[method] = valfunc
        return
    end
    if ssub(method, 1, 1) ~= "_" or ssub(method, 1, 2) == "__" then
        class.__vtbl[method] = function(...)
            local _<close> = class_stack(class)
            return valfunc(...)
        end
        return
    end
    class.__vtbl[method] = function(...)
        local stack<close> = class_stack(class)
        if stack ~= class then
            print(sformat("%s's method %s is private method.", class.__name, method))
            return
        end
        return valfunc(...)
    end
end

local function mt_object_release(obj)
    local class = obj.__class
    class.__count = class.__count - 1
    object_release(obj.__class, obj)
end

local function mt_object_defer(obj)
    object_defer(obj.__class, obj)
end

local classMT = {
    __call = mt_class_new,
    __close = mt_class_close,
    __index = mt_class_index,
    __newindex = mt_class_newindex
}

local function class_constructor(class, super, ...)
    local info = dgetinfo(2, "S")
    local source = info.short_src
    local class_tpl = class_tpls[source]
    local class_name = "class:" .. sgmatch(source, ".+[/\\](.+).lua")()
    if not class_tpl then
        local vtbl = {
            __class = class,
            __super = super,
            __source = source,
            __name = class_name,
            __tostring = object_tostring,
            super = object_super,
            source = object_source,
            address = object_address
        }
        vtbl.__index = vtbl
        vtbl.__gc = mt_object_release
        vtbl.__close = mt_object_defer
        if super then
            setmetatable(vtbl, {__index = super})
        end
        class.__count = 0
        class.__props = {}
        class.__mixins = {}
        class.__vtbl = vtbl
        class.__name = class_name
        class_tpl = setmetatable(class, classMT)
        implemented(class, ...)
        class_tpls[source] = class_tpl
    end
    return class_tpl
end

function class(super, ...)
    return class_constructor({}, super, ...)
end

function singleton(super, ...)
    return class_constructor({__singleton = true}, super, ...)
end

function super(value)
    return value.__super
end

function is_class(class)
    return classMT == getmetatable(class)
end

function classof(obj)
    return obj.__class
end

function conv_class(name)
    local runtime = sformat("local obj = %s() return obj", name)
    local ok, obj = pcall(load(runtime))
    if ok then
        return obj
    end
end

function class_review()
    local review = {}
    for _, class in pairs(class_tpls) do
        if class.__count > 0 then
            review[class.__name] = class.__count
        end
    end
    return review
end

_ENV.__classes = class_tpls
_ENV.__stack_cls = stack_nil
