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
local dgetinfo  = debug.getinfo
local getmetatable = getmetatable
local setmetatable = setmetatable

--类模板
local class_tpls = _ENV.class_tpls or {}

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

local function mixin_init(class, object, ...)
    if class.__super then
        mixin_init(class.__super, object, ...)
    end
    for _, mixin in ipairs(class.__mixins) do
        if type(mixin.__init) == "function" then
            mixin.__init(object, ...)
        end
    end
    return object
end

local function object_init(class, object, ...)
    if class.__super then
        object_init(class.__super, object, ...)
    end
    if type(class.__init) == "function" then
        class.__init(object, ...)
    end
    return object
end

local function object_release(class, object, ...)
    if type(class.__release) == "function" then
        class.__release(object, ...)
    end
    if class.__super then
        object_release(class.__super, object, ...)
    end
end

local function object_defer(class, object, ...)
    if type(class.__defer) == "function" then
        class.__defer(object, ...)
    end
    if class.__super then
        object_defer(class.__super, object, ...)
    end
end

local function object_default(class, object)
    if class.__super then
        object_default(class.__super, object)
    end
    local defaults = deep_copy(class.__default)
    for name, param in pairs(defaults) do
        object[name] = param[1]
    end
end

local function object_tostring(object)
    if type(object.tostring) == "function" then
        return object:tostring()
    end
    return sformat("class:%s(%s)", object.__moudle, object.__addr)
end

local function object_constructor(class, ...)
    local obj = {}
    object_default(class, obj)
    obj.__addr = ssub(tostring(obj), 7)
    local object = setmetatable(obj, class.__vtbl)
    object_init(class, object, ...)
    mixin_init(class, object, ...)
    return object
end

local function new(class, ...)
    if class.__singleton then
        local inst_obj = rawget(class, "__inst")
        if not inst_obj then
            inst_obj = object_constructor(class, ...)
            --定义单例方法
            local inst_func = function()
                return inst_obj
            end
            rawset(class, "__inst", inst_obj)
            rawset(class, "inst", inst_func)
        end
        return inst_obj
    else
        return object_constructor(class, ...)
    end
end

local function index(class, field)
    return class.__vtbl[field]
end

local function newindex(class, field, value)
    class.__vtbl[field] = value
end

local function release(obj)
    object_release(obj.__class, obj)
end

local function defer(obj)
    object_defer(obj.__class, obj)
end

local classMT = {
    __call = new,
    __index = index,
    __newindex = newindex
}

local function class_constructor(class, super, ...)
    local info = dgetinfo(2, "S")
    local moudle = info.short_src
    local class_tpl = class_tpls[moudle]
    if not class_tpl then
        local vtbl = {
            __class = class,
            __moudle = moudle,
            __tostring = object_tostring,
        }
        vtbl.__gc = release
        vtbl.__close = defer
        vtbl.__index = vtbl
        if super then
            setmetatable(vtbl, {__index = super})
        end
        class.__vtbl = vtbl
        class.__super = super
        class.__default = {}
        class.__mixins = {}
        class_tpl = setmetatable(class, classMT)
        implemented(class, { ... })
        class_tpls[moudle] = class_tpl
    end
    return class_tpl
end

function class(super, ...)
    return class_constructor({}, super, ...)
end

function singleton(super, ...)
    return class_constructor({__singleton = true}, super, ...)
end

function super(class)
    return rawget(class, "__super")
end

function is_class(class)
    return classMT == getmetatable(class)
end

function classof(object)
    return object.__class
end

function is_subclass(class, super)
    while class do
        if class == super then
            return true
        end
        class = rawget(class, "__super")
    end
    return false
end

function instanceof(object, class)
    if not object or not class then
        return false
    end
    local obj_class = object.__class
    if obj_class then
        return is_subclass(obj_class, class)
    end
    return false
end

function conv_class(name)
    local runtime = sformat("local obj = %s() return obj", name)
    local ok, obj = pcall(load(runtime))
    if ok then
        return obj
    end
end

