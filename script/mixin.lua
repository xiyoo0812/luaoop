--mixin.lua
--[[提供混入机制
示例:
    Execute = mixin(nil, "execute")
    Listener = class(nil, Listener)
备注：
    mixin类似多继承，但是继承强调i'am，而mixin强调i'can.
    mixin无法实例化，必须依附到class上，mixin函数的self都是属主class对象
--]]
local pcall         = pcall
local pairs         = pairs
local tinsert       = table.insert
local dgetinfo      = debug.getinfo
local sformat       = string.format
local setmetatable  = setmetatable

local mixin_tpls    = _ENV.mixin_tpls or {}

local function index(mixin, field)
    return mixin.__vtbl[field]
end

local function newindex(mixin, field, value)
    mixin.__vtbl[field] = value
end

local function invoke(class, object, method, ...)
    local _super = super(class)
    if _super then
        invoke(_super, object, method, ...)
    end
    for _, mixin in ipairs(class.__mixins) do
        local mixin_method = mixin[method]
        if mixin_method then
            local ok, res = pcall(mixin_method, object, ...)
            if not ok then
                error(sformat("mixin: %s invoke '%s' failed: %s.", mixin.__moudle, method, res))
            end
        end
    end
end

--返回true表示所有接口都完成
local function collect(class, object, method, ...)
    local _super = super(class)
    if _super then
        if not collect(_super, object, method, ...) then
            return false
        end
    end
    for _, mixin in ipairs(class.__mixins) do
        local mixin_method = mixin[method]
        if mixin_method then
            local ok, res = pcall(mixin_method, object, ...)
            if (not ok) or (not res) then
                error(sformat("mixin: %s collect '%s' failed: %s.", mixin.__moudle, method, res))
                return false
            end
        end
    end
    return true
end

--代理一个类的所有接口，并检测接口是否实现
function implemented(class, mixins)
    class.invoke = function(object, method, ...)
        invoke(object.__class, object, method, ...)
    end
    class.collect = function(object, method, ...)
        collect(object.__class, object, method, ...)
    end
    for _, mixin in ipairs(mixins) do
        --属性处理
        for name, value in pairs(mixin.__default) do
            if class.__default[name] then
                print(sformat("the mixin default %s has repeat defined.", name))
            end
            class.__default[name] = value
            local access_prefix = {"is_", "get_", "set_"}
            for _, prefix in pairs(access_prefix) do
                local access_method = prefix .. name
                if mixin[access_method] then
                    tinsert(mixin.__methods, access_method)
                end
            end
        end
        for _, method in pairs(mixin.__methods) do
            if not mixin[method] then
                print(sformat("the mixin method %s hasn't implemented.", method))
                mixin[method] = function()
                    print(sformat("the mixin method %s hasn't implemented.", method))
                end
            end
            if class[method] then
                print(sformat("the mixin method %s override implemented.", method))
                goto continue
            end
            --接口代理
            class[method] = function(...)
                return mixin[method](...)
            end
            :: continue ::
        end
        tinsert(class.__mixins, mixin)
    end
end

local mixinMT = {
    __index = index,
    __newindex = newindex
}

local function mixin_tostring(mixin)
    return sformat("mixin:%s", mixin.__moudle)
end

--接口定义函数
function mixin(...)
    local info = dgetinfo(2, "S")
    local moudle = info.short_src
    local mixin_tpl = mixin_tpls[moudle]
    if not mixin_tpl then
        local mixin = {
            __vtbl = {},
            __default = {},
            __moudle = moudle,
            __methods = { ... },
            __tostring = mixin_tostring,
        }
        mixin_tpl = setmetatable(mixin, mixinMT)
        mixin_tpls[moudle] = mixin_tpl
    end
    return mixin_tpl
end
