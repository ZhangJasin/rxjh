SL:Print("Hello World, This is GUIUtil!!!")
FGUI:Open("A_Right", "righttoppanl",nil,FGUI_LAYER.BG,{esc = false})

local attrConfigs = SL:GetValue("ATTR_CONFIGS") -- 属性配置(AttScore表)

local function  conditionFuc()
    local curtime = os.time()
    --print("定时器")
    -- 检测时装
    -- 检测时装，从数据层获取
    -- local fashionData = FashionSystemData:GetState().FashionDate
    -- if fashionData then
    --     if fashionData["pifeng"] then
    --         for k,v in pairs(fashionData["pifeng"]) do
    --             if v[2] ~= -1 and v[2] < curtime then
    --                 ssrMessage:sendmsgEx("FashionSystem", "TimeOut",{1,k})
    --             end
    --         end
    --     end
    --     if fashionData["huanwu"] then
    --         for k,v in pairs(fashionData["huanwu"]) do
    --             if v[2] ~= -1 and v[2] < curtime then
    --                 ssrMessage:sendmsgEx("FashionSystem", "TimeOut",{2,k})
    --             end
    --         end
    --     end
    --     if fashionData["toushi"] then
    --         for k,v in pairs(fashionData["toushi"]) do
    --             if v[2] ~= -1 and v[2] < curtime then
    --                 ssrMessage:sendmsgEx("FashionSystem", "TimeOut",{3,k})
    --             end
    --         end
    --     end
    -- end
end

SL:Schedule(conditionFuc, 3)  --开启一个3秒定时器

-------------------------------↓↓↓ 方法 ↓↓↓---------------------------------------
function Strsplit(str, char)
    local splitRet = {}
    repeat
        local _Ret = string.gsub(str, "^(.-)%" .. char .. "(.-)$", function(a, b)
            splitRet[#splitRet + 1] = a
            str = b
        end)
        if str == _Ret then
            splitRet[#splitRet + 1] = _Ret
            break
        end
    until (str == "")
    return splitRet
end

function GetNewTable(t)
    local values = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            table.insert(v, k)
        end
        table.insert(values, v)
    end
    return values
end

function ChangeKeyTable(t)  
    local values = {}
    for k, v in pairs(t) do
        values[t[k]["UserID"]] = v
    end
    return values
end

function IsPureNumber(str)
    -- 检查是否为空字符串
    if str == "" then
        return false
    end
    -- 匹配整个字符串：从开头到结尾必须全是数字
    if not str:match("^%d+$") then
        return false
    end
    -- 排除前导0（除非数字本身就是0）
    if #str > 1 and str:sub(1, 1) == "0" then
        return false
    end
    return true
end

function AtteChangeStr(t)
    local tab = {}
    for i=1,#t do
        local name = attrConfigs[t[i][1]]['Name']
        local value = t[i][2] or 0
        if attrConfigs[t[i][1]]['Type'] == 1 then
            value = (value/100).."%"
        end
        table.insert(tab,{name = name,value = value})
    end
    return tab
end

function GetMonthMxDay()
    -- 获取当前日期的年份和月份
    local year = os.date("%Y")
    local month = os.date("%m") + 1
    if month > 12 then
    month = 1
    year = year + 1
    end
    local timestamp = os.time({year = year, month = month, day = 1}) - 86400
    local date = os.date("!*t", timestamp)
    -- print("这个月的最大天数是：" .. date.day)
    return date.day or 28
end

