local logpath = string.format("Envir/3rd/debug_log/%s.log", os.date("%Y%m%d"))

function LOGCreate()
    os.execute("mkdir \"Envir/3rd/debug_log\" >nul 2>nul")
end

-- if val of t has nil, table.concat will crushed.
local function concat(t) 
    local ret = ""
    for _, v in pairs(t) do
        if string.len(ret) == 0 then
            ret = tostring(v)
        else
            ret = ret .. " " .. tostring(v)
        end
    end
    return ret
end

local function timestamp()
    local t = os.date("*t")
    return string.format("[%04d-%02d-%02d %02d:%02d:%02d]", 
        t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local function src_line(debug_level)
    local info = debug.getinfo(debug_level)
    local filename = string.match(info.short_src, "[^/.]+.lua")
    return string.format("[%s:%d]", filename, info.currentline)
end

local function _write(...)
    local f = io.open(logpath, "a")
    if f then
        local str = timestamp()..src_line(4).." "..concat({...})
        f:write(str.."\n")
        f:close()
    end
end

local function _dump(value, desciption, nesting)
    local f = io.open(logpath, "a")
    if not f then return end

    if desciption then
        desciption = timestamp()..src_line(4)..desciption
    else
        desciption = timestamp()..src_line(4)
    end

    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        f:write(line.."\n")
    end

    f:close()
end

local function _print(...)
    local str = timestamp()..src_line(4).." "..concat({...})
    print(str)
end


local DEBUG = true      --debug模式,true打印日志
-- local DEBUG = false
function LOGPrint(...)
    if not DEBUG then return end
    _print(...)
end

function LOGWrite(...)
    if not DEBUG then return end
    _write(...)
end

function LOGDump(value, desciption, nesting)
    if not DEBUG then return end
    _dump(value, desciption, nesting)
end

function LOGStack()
    local str = debug.traceback()
    LOGWrite(str)
end