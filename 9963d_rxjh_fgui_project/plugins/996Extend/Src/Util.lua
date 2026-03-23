function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function string.startWith(input, start)
    return string.subUTF8(input, 1, #start) == start
end

function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.subUTF8(str, subStar, subEnd)
    if not str or str == "" then
        return ""
    end
    local charsize = function(ch)
        if not ch then 
            return 0
        elseif ch >= 252 then 
            return 6
        elseif ch >= 248 and ch < 252 then 
            return 5
        elseif ch >= 240 and ch < 248 then 
            return 4
        elseif ch >= 224 and ch < 240 then 
            return 3
        elseif ch >= 192 and ch < 224 then 
            return 2
        elseif ch < 192 then 
            return 1
        end
    end
    subStar                         = subStar or 1
    subEnd                          = subEnd or string.utf8len(str)
    local subLen                    = subEnd-subStar+1
    local byteStar,byteEnd,tempLen  = 0,1,0
    while subStar <= subEnd and subLen > 0 do
        local char = string.byte(str, byteEnd)
        byteEnd = byteEnd + charsize(char)
        tempLen = tempLen + 1
        if tempLen > subStar then
            subLen = subLen - 1
        elseif tempLen == subStar then
            byteStar = byteEnd - charsize(char)
            subLen = subLen - 1
        end
    end
    return string.sub(str, byteStar, byteEnd-1)
end

function getCurrentDir()
    if package.config:sub(1,1) == "\\" then -- windows
        local f= io.popen("cd")
        local dir = f:read("*a")
        f:close()
        return dir:gsub("[\r\n+$]","")
    end
end

-- 运行脚本路径
function getScriptDir()
    local info = debug.getinfo(1,"S")
    local path = info.source:sub(2)
    return path:match("(.*[/\\])") or "./"
end

function checkPath(path)
    local dir,err = io.open(path,"r")
    if dir then
        dir:close()
        return true
    end
    return false
end

function createFile(path,islog,content)
    local file,err = io.open(path,"w")
    if file then
        if content then
            file:write(content)
        end
        if islog then
            App.Alert("创建"..path.."成功")
        end
        file:close()
        return true
    end
    if islog then
        App.Alert("创建"..path.."失败[Err]"..err)
    end
    return false
end

function mkdir_p(path)
    path = path:gsub("/","\\")
    cmd = 'md "'.. path .. '" 2>nul'
    local file,err = io.popen(cmd,"r")
    if file then
        file:close()
        return true
    end
    App.Alert("创建"..path.."目录失败[Err]"..err)
    return false
end


function directoryExists(path)
    if not path or type(path) ~= "string" or #path == 0 then
        return 0
    end

    path = path:gsub("[/\\]+$","")
    local cmd = string.format('if exist "%s" (echo true) else (echo false)',path)
    local handle = io.popen(cmd)
    if not handle then
        return false
    end

    local result = handle:read("*a"):gsub("%s+","")
    handle:close()
    return result =="true"
end

