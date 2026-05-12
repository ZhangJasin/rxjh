--判断成功率:如果成功返回false
--suc_rate:成功率
--ratio:比率
--return:返回true没成功
function FProbabilityHit(suc_rate, ratio)
    ratio = ratio or 100
    local rate = math.random(1, ratio)
    return rate > suc_rate
end

--发送邮件
function FSendmail(actor_or_name, id_or_t, ...)
    local mailid, boxReward
    if type(id_or_t) == "table" then
        mailid = id_or_t.id
        boxReward = id_or_t.box
    else
        mailid = id_or_t
    end
    local cfg = sys_mail[mailid]
    if not cfg then return end
    --邮件内容
    local content
    if cfg.content then
        if cfg.parameter then
            content = string.format(cfg.content, ...)
        else
            content = cfg.content
        end
    end
    --邮件物品
    local stritem
    boxReward = boxReward or cfg.items
    if boxReward then
        if type(boxReward) == "table" then
            local items
            for _, item in ipairs(boxReward) do
                if type(item) == "table" then
                    items = items or {}
                    if item[3] == 1 then item[3] = ConstCfg.binding end
                    table.insert(items, table.concat(item, "#"))
                else
                    stritem = table.concat(boxReward, "#")
                    break
                end
            end

            if items then stritem = table.concat(items, "&") end
        else
            stritem = boxReward .. "#1"
        end
    end
    --发送
    if string.sub(actor_or_name, 1, 1) ~= "#" then --不是名字获取玩家唯一id
        actor_or_name = userid(actor_or_name)
    end
    -- print("发送邮件至"..actor_or_name)
    --发送
    sendmail(actor_or_name, mailid, cfg.title, content, stritem, 86400 * 7)
end

--发送邮件2
function _Fsendmail(name, id, reward, ...)
    local cfg = sys_mail[id]
    if not cfg then return end
    --邮件内容
    local content
    if cfg.content then
        if cfg.parameter then
            content = string.format(cfg.content, ...)
        else
            content = cfg.content
        end
    end
    local stritem
    --邮件物品
    if reward then
        if type(reward) == "table" then
            local items
            for _, item in ipairs(reward) do
                if type(item) == "table" then
                    items = items or {}
                    if item[3] == 1 then item[3] = ConstCfg.binding end
                    table.insert(items, table.concat(item, "#"))
                else
                    stritem = table.concat(reward, "#")
                    break
                end
            end

            if items then stritem = table.concat(items, "&") end
        else
            stritem = reward .. "#1"
        end
    end
    sendmail("#" .. name, id, cfg.title, content, stritem, 86400 * 7)
end

--user发送邮件
function _Usersendmail(userid, title, content, reward)
    local stritem
    --邮件物品
    if reward then
        if type(reward) == "table" then
            local items
            for _, item in ipairs(reward) do
                if type(item) == "table" then
                    items = items or {}
                    if item[3] and item[3] == 1 then item[3] = ConstCfg.binding end
                    table.insert(items, table.concat(item, "#"))
                else
                    stritem = table.concat(reward, "#")
                    break
                end
            end

            if items then stritem = table.concat(items, "&") end
        else
            stritem = reward .. "#1"
        end
    end
    sendmail(userid, 1, title, content, stritem, 86400 * 7)
end

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

--秒转时分秒  100 = 00:01:40
function ssrSecToHMS(sec)
    sec = sec or 0

    local h, m, s = 0, 0, 0
    if sec > 3600 then
        h = math.floor(sec / 3600)
    end
    sec = sec % 3600
    if sec > 60 then
        m = math.floor(sec / 60)
    end
    s = sec % 60

    return string.format("%02d:%02d:%02d", h, m, s)
end

--时间转换
function getTodayTimeStamp(hour, min, sec)
    local cDateCurrectTime = os.date("*t")
    local cDateTodayTime = os.time({
        year = cDateCurrectTime.year,
        month = cDateCurrectTime.month,
        day = cDateCurrectTime
            .day,
        hour = hour,
        min = min,
        sec = sec
    })
    return cDateTodayTime
end

--- 根据时分秒获取相对当天的时间戳
-- @param  h    number类型   时
-- @param  m    numebr类型  分
-- @param  s    number类型  秒
-- @param  timeInfo    table类型  时间信息
-- @return    number类型   时间戳
function FGetStampByHMS(h, m, s, timeInfo)
    local timeInfo = timeInfo or os.date("*t", os.time())
    return os.time({ year = timeInfo.year, month = timeInfo.month, day = timeInfo.day, hour = h, min = m, sec = s })
end

--- 根据年月日时分秒获取相对当天的时间戳
-- @return    number类型   时间戳
function FGetStampByYMDHMS(year, month, day, hour, min, sec)
    return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = sec }) or 0
end

--- 根据时间戳 获取当天0点时间戳
function FGetZeroStampByStamp(timestamp)
    if timestamp == 0 then
        return 0
    end
    local info = os.date("*t", timestamp)
    return os.time({ year = info.year, month = info.month, day = info.day, hour = 0, min = 0, sec = 0 }) or 0
end

function StrSplit2(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == '') then return false end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

--------------------仅用于dump打印-------------------
function dumptab(obj)
    local lua = ""
    local t = type(obj)
    if t == "number" then
        lua = lua .. obj
    elseif t == "boolean" then
        lua = lua .. tostring(obj)
    elseif t == "string" then
        lua = lua .. string.format("%q", obj)
    elseif t == "table" then
        lua = lua .. "{\n"
        for k, v in pairs(obj) do
            lua = lua .. "[" .. dumptab(k) .. "]=" .. dumptab(v) .. ",\n"
        end
        local metatable = getmetatable(obj)
        if metatable ~= nil and type(metatable.__index) == "table" then
            for k, v in pairs(metatable.__index) do
                lua = lua .. "[" .. dumptab(k) .. "]=" .. dumptab(v) .. ",\n"
            end
        end
        lua = lua .. "}"
    elseif t == "nil" then
        return nil
    else
        LOGPrint("序列化错误： " .. t .. " type.")
    end
    return lua
end

function dump(...)
    LOGPrint(dumptab(...))
end

-- 随机权重
--[[
    -- 示例
    local t = {11, 22, 33}
    local weights = {50, 100, 50, 200} -- 权重
    local aaa = RandomByWeight(t, weights)
    dump(aaa)
--]]
function RandomByWeight(t, weights)
    local sum = 0
    for i = 1, #weights do
        sum = sum + weights[i]
    end
    local compareWeight = math.random(1, sum)
    local weightIndex = 1
    while sum > 0 do
        sum = sum - weights[weightIndex]
        if sum <= compareWeight then
            return t[weightIndex]
        end
        weightIndex = weightIndex + 1
    end
    return nil
end

-- 随机权重
--[[
    -- 示例
    local tab = {{a = 11, b = 111}, {a = 22, b = 222}, {a = 33, b = 333}}
    local index = "a"
    local aaa = RandItemByWeightStrEx(tab,index)
    dump(aaa)
--]]
function RandItemByWeightStrEx(tab, index)
    local total = 0
    for i = 1, #tab do
        total = total + tab[i][index]
    end
    local randValue = math.random(1, total)
    local curValue = 0
    for i = 1, #tab do
        if randValue > curValue and randValue <= curValue + tab[i][index] then
            return tab[i]
        end
        curValue = curValue + tab[i][index]
    end
end

-- 随机权重
function RandItemByWeightStrNum(tab, index, num, indexEx)
    local function _getRand(list, idx, idxEx)
        local total = 0
        for i = 1, #list do
            total = total + list[i][idx] + (list[i][idxEx] or 0)
        end
        local randValue = math.random(1, total)
        local curValue = 0
        for i = 1, #list do
            if randValue > curValue and randValue <= curValue + list[i][idx] + (list[i][idxEx] or 0) then
                return i
            end
            curValue = curValue + list[i][idx] + (list[i][idxEx] or 0)
        end
    end

    local tab = clone(tab)
    local getTab = {}
    for i = 1, num, 1 do
        local idx = _getRand(tab, index, indexEx)
        table.insert(getTab, tab[idx])
        table.remove(tab, idx)
    end
    return getTab
end

-- 拆分字符串
--[[
    -- 示例
    local str = "4#6#5"
    local aaa = conditionSplit(str, "#")
    dump(aaa) -- 返回{4,6,5}
--]]
function conditionSplit(str, reps)
    local resultStrList = {}
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        table.insert(resultStrList, tonumber(w) or w)
    end)
    return resultStrList
end

function JsonToTable(str)
    local tab = {}
    if string.find(str, "#") then
        local table1 = string.split(str, "|")
        for index, value in ipairs(table1) do
            local table2 = string.split(value, "#")
            table.insert(tab, table2)
        end
    else
        local table1 = string.split(str, "|")
        tab = table1
    end
    return tab
end

function StrToTable(str, spl1, spl2)
    spl1 = spl1 or "#"
    spl2 = spl2 or "&"
    local tab = {}
    if string.find(str, spl1) then
        local table1 = string.split(str, spl2)
        for index, value in ipairs(table1) do
            local table2 = string.split(value, spl1)
            table.insert(tab, table2)
        end
    else
        tab = string.split(str, spl2)
    end

    for index, value in ipairs(tab) do
        if type(value) == "table" then
            for i = 1, #value, 1 do
                value[i] = tonumber(value[i])
            end
        else
            value = tonumber(value)
        end
    end
    return tab
end

--加经验
function FAddExp(actor, exp, param)
    changeexp(actor, "+", exp)
end

--获取开服时间格式化
function OpenSeverTime(gettime)
    local y_m_d = nil -- 年-月-日
    local h_m_s = nil -- 时:分:秒
    local timestr = os.date("%Y-%m-%d %H:%M:%S", gettime)
    y_m_d = string.split(timestr, " ")[1]
    h_m_s = string.split(timestr, " ")[2]
    return y_m_d, h_m_s
end

--获取开服天数
function OpenSeverDay(gettime)
    local day = 0
    local now = os.time()
    local preTime = gettime
    if now and preTime then
        local now = os.date("*t", now)
        local next = os.date("*t", preTime)
        if now and next then
            local num1 = os.time({ year = now.year, month = now.month, day = now.day })
            local num2 = os.time({ year = next.year, month = next.month, day = next.day })
            if num1 and num2 then
                if num1 < num2 then
                    day = 0
                else
                    day = math.ceil((num1 - num2) / (3600 * 24))
                end
            end
        end
    end
    local next = os.date("*t", preTime)
    local next_s = os.time({ year = next.year, month = next.month, day = next.day, hour = 0, min = 0, sec = 0 })
    if tonumber(next_s) == tonumber(preTime) then
        day = day + 1
    else
        day = day + 1
    end
    return day
end

--- 检查 货币数量是否足够
function g_CheckMoneyNum(actor, moneytype, num)
    local moneyNum = libxx:getmoney(actor, moneytype)
    return moneyNum >= num
end

--- 检查 背包物品数量是否足够
function g_CheckItemNumByIdx(actor, idx, num)
    return libxx:checkitem(actor, idx .. "#" .. num)
end

function g_CheckItemOrMoneyNumByIdx(actor, idx, num)
    if idx <= ConstCfg.maxMoneyIndex then
        return g_CheckMoneyNum(actor, idx, num)
    else
        return g_CheckItemNumByIdx(actor, idx, num)
    end
end

-- 境界等 jjlv  背包 BagBuff1 BagBuff2
function PushSetPlayerCustData(actor, key, vause)
    local str = targetinfo(actor, "CUSTDATA") or ""
    local table = json2tbl(str) or {}
    table[key] = vause
    setplayercustdata(actor, tbl2json(table))
    -- setplayercustjosndata(actor, tostring(key),tostring(vause))
end

--满血满蓝
function PlayerRecovery(actor)
    -- print("recovery")
    local maxhp = abil(actor, 1)
    local maxmp = abil(actor, 2)
    -- print(maxhp)
    -- print(maxmp)
    changeabil(actor, 1, "=", maxhp)
    changeabil(actor, 2, "=", maxmp)
end

-------------------------活动相关

--检测今天是否开活动，→0/1，下一次活动开启和关闭的的时间戳
function CheckIsEventOpenDay(eventid)
    local isopen = 0
    local opentime = 0
    local closetime = 0

    local time = os.date("*t", os.time())
    local weekday = time.wday
    if weekday == 1 then
        weekday = 8
    end
    weekday = weekday - 1
    local eventopenH = Setting_Event[eventid].opentimetab.h
    local eventopenM = Setting_Event[eventid].opentimetab.m

    local eventcloseH = Setting_Event[eventid].closetimetab.h
    local eventcloseM = Setting_Event[eventid].closetimetab.m
    --如果当天开活动，且当前时间在活动开启前
    if string.find(Setting_Event[eventid].openweek, "2004#" .. weekday) then
        isopen = 1
        opentime = os.time({ year = time.year, month = time.month, day = time.day, hour = eventopenH, min = eventopenM, sec = 0 })
        closetime = os.time({ year = time.year, month = time.month, day = time.day, hour = eventcloseH, min = eventcloseM, sec = 0 })

        if os.time() > closetime then --当前时间在活动开启后
            local a = os.time({ year = time.year, month = time.month, day = time.day })
            while true do
                a = a + 86400
                local wday = os.date("*t", a).wday
                if wday == 1 then
                    wday = 8
                end
                wday = wday - 1
                if string.find(Setting_Event[eventid].openweek, "2004#" .. wday) then
                    opentime = os.time({
                        year = os.date("*t", a).year,
                        month = os.date("*t", a).month,
                        day = os.date(
                            "*t", a).day,
                        hour = eventopenH,
                        min = eventopenM,
                        sec = 0
                    })
                    closetime = os.time({
                        year = os.date("*t", a).year,
                        month = os.date("*t", a).month,
                        day = os.date(
                            "*t", a).day,
                        hour = eventcloseH,
                        min = eventcloseM,
                        sec = 0
                    })
                    break
                end
            end
        end
    else --当天不开活动，检测下一次开活动的日期
        isopen = 0
        local a = os.time({ year = time.year, month = time.month, day = time.day })
        while true do
            a = a + 86400
            local wday = os.date("*t", a).wday
            if wday == 1 then
                wday = 8
            end
            wday = wday - 1
            if string.find(Setting_Event[eventid].openweek, "2004#" .. wday) then
                opentime = os.time({
                    year = os.date("*t", a).year,
                    month = os.date("*t", a).month,
                    day = os.date("*t", a)
                        .day,
                    hour = eventopenH,
                    min = eventopenM,
                    sec = 0
                })
                closetime = os.time({
                    year = os.date("*t", a).year,
                    month = os.date("*t", a).month,
                    day = os.date("*t", a)
                        .day,
                    hour = eventcloseH,
                    min = eventcloseM,
                    sec = 0
                })
                break
            end
        end
    end
    -- print(os.date("%Y-%m-%d %H:%M:%S",opentime))
    return isopen, opentime, closetime
end

function ssrStrSplit2(str, reps)
    -- ssrPrint(debug.traceback())
    local r = {}
    if str == nil then return nil end
    string.gsub(str, "[^" .. reps .. "]+", function(w) table.insert(r, tonumber(w) or w) end)
    return r
end

--repsArr  切割符 {"|","#"}|：第一切割 #：第二切割
-- att = "3#1#4260|3#3#36|3#4#76"
--解析为
-- att = {
--     [1] = {
--         [1] = 3,
--         [2] = 1,
--         [3] = 4260,
--     },
--     [2] = {
--         [1] = 3,
--         [2] = 3,
--         [3] = 36,
--     },
--     [3] = {
--         [1] = 3,
--         [2] = 4,
--         [3] = 76,
--     },
-- },
--切割字符串
function ssrStrSplitByMore(str, repsArr)
    if #repsArr < 1 then
        return tonumber(str) or str
    end
    local repsArrCopy = {}

    for k, v in ipairs(repsArr) do
        repsArrCopy[k] = v
    end

    local r = ssrStrSplit2(str, repsArrCopy[1])
    table.remove(repsArrCopy, 1)

    for k, v in ipairs(r) do
        r[k] = ssrStrSplitByMore(v, repsArrCopy)
    end

    return r
end

--判断两个日期是否在同一周
function isSameWeek(time1, time2)
    -- 将时间转换为table格式
    local t1 = os.date("*t", time1)
    local t2 = os.date("*t", time2)
    -- 计算ISO 8601标准下的第几周
    local function getIsoWeek(t)
        -- 创建一个假的日期，用于计算该年的第一个周四
        local firstThursday = os.time { year = t.year, month = 1, day = 4 }
        local ftDayOfYear = tonumber(os.date("%j", firstThursday))
        local ftWeekDay = tonumber(os.date("%w", firstThursday)) -- 周日是1，周六是7
        -- 调整到周一作为一周的第一天 (ISO 8601)
        if ftWeekDay == 7 then ftWeekDay = 0 end                 -- 如果是星期六，调整为0
        ftWeekDay = (ftWeekDay + 5) % 7 + 1                      -- 转换为从周一（1）开始
        -- 第一个周四所在的那一周是第一周
        local week1 = math.floor((ftDayOfYear - ftWeekDay + 7) / 7) + 1
        -- 获取当前日期的一年中的第几天以及星期几
        local time = os.time(t)
        local dayOfYear = tonumber(os.date("%j", time))
        local weekDay = tonumber(os.date("%w", time)) -- 周日是1，周六是7
        -- 调整到周一作为一周的第一天 (ISO 8601)
        if weekDay == 7 then weekDay = 0 end          -- 如果是星期六，调整为0
        weekDay = (weekDay + 5) % 7 + 1               -- 转换为从周一（1）开始
        -- 计算当前日期属于哪一周
        local currentWeek = math.floor((dayOfYear - weekDay + 7) / 7) + week1
        -- 特殊处理：如果是在年的开头或结尾，可能需要检查是否属于上一年或下一年的第一周
        if currentWeek < 1 then
            -- 可能属于上一年的最后一周
            return getIsoWeek(os.date("*t", os.time { year = t.year - 1, month = 12, day = 31 }))
        elseif currentWeek > 52 then
            -- 可能属于下一年的第一周
            return getIsoWeek(os.date("*t", os.time { year = t.year + 1, month = 1, day = 1 }))
        else
            return currentWeek
        end
    end

    -- 比较两个日期所在的ISO周数是否相同
    return getIsoWeek(t1) == getIsoWeek(t2)
end

local colortab = { "#46E7A8", "#57B7FA", "#F281FF", "#FBA23E", "#E7D25E", "#FF7777", "#F99EB4", "#FFED00", "#FF1493" }
--获取道具颜色名字
function GetItemColorName(actor, itemid)
    local grade = libxx:getgradebyidx(actor, itemid)
    local color = colortab[grade]
    local name = libxx:getnamebyidx(actor, itemid)
    local nametsr = string.format("<font color='%s'>%s</font>", color, name)
    return nametsr
end

function SendDiyMsg(actor, event_name, info)
    local map = info
    map.servid = serveridx(actor)
    map.server_name = servername(actor)
    local data = {
        event_name = event_name,
        map = map
    }
    senddiymsg(actor, tbl2json(data))
end

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

function backCity(actor)
    mapmove(actor, "101002", 365, 513, 3)
end

function getyb(actor)
    return money(actor, 2)
end

function getbindyb(actor)
    return money(actor, 5)
end

function getallyb(actor)
    return money(actor, 5) + money(actor, 2)
end

function delyb(actor, itemnum)
    changemoney(actor, 2, "-", itemnum)
end

function delbindyb(actor, itemnum)
    local yb = getyb(actor)
    local bdyb = getbindyb(actor)
    if yb + bdyb < itemnum then
        sendmsg(actor, 9, "[b]热血币数量不足[/b]")
        return
    end
    if itemnum <= bdyb then
        changemoney(actor, 5, "-", itemnum)
    else
        changemoney(actor, 5, "-", bdyb)
        changemoney(actor, 2, "-", itemnum - bdyb)
    end
end

function getrxb(actor)
    return money(actor, 9)
end

function getbindrxb(actor)
    return money(actor, 17)
end

function getallrxb(actor)
    return money(actor, 9) + money(actor, 17)
end

function delrxb(actor, itemnum)
    changemoney(actor, 2, "-", itemnum)
end

function delbindrxb(actor, itemnum)
    local rxb = getrxb(actor)
    local bdrxb = getbindrxb(actor)
    if rxb + bdrxb < itemnum then
        sendmsg(actor, 9, "[b]元宝数量不足[/b]")
        return
    end
    if itemnum <= bdrxb then
        changemoney(actor, 17, "-", itemnum)
    else
        changemoney(actor, 17, "-", bdrxb)
        changemoney(actor, 9, "-", itemnum - bdrxb)
    end
end

function getItemNum(actor, itemid)
    local itemname = itemid
    if type(itemid) == "number" then --货币
        itemname = fieldvalue(actor, string.format("%d_%s", itemid, "Name"))
        -- print("查询的是======================",itemname)
    end
    if itemname == "绑定元宝" then
        return getallyb(actor)
    elseif itemname == "元宝" then
        return getyb(actor)
    elseif itemname == "绑定热血币" then
        return getallrxb(actor)
    elseif type(itemid) == "number" and itemid <= 100 then --货币
        return money(actor, itemid)
    else
        return bagitemcount(actor, itemid)
    end
end

function delItemNum(actor, itemid, itemnum)
    local itemname = itemid
    if type(itemid) == "number" then --货币
        itemname = fieldvalue(actor, string.format("%d_%s", itemid, "Name"))
    end
    if itemname == "绑定元宝" then
        delbindyb(actor, itemnum)
    elseif itemname == "元宝" then
        delyb(actor, itemnum)
    elseif itemname == "绑定热血币" then
        delbindrxb(actor, itemnum)
    else
        takeitem(actor, "" .. itemname .. "#" .. itemnum .. "#0")
    end
end

function ConditionPD(actor, param1, param2)
    if param1 == "等级" then
        local value = level(actor)
        return value >= param2
    elseif param1 == "转职等级" then
        local value = targetinfo(actor, "RELEVEL")
        return value >= param2
    else
        local value = gethumvar(actor, param1) or 0
        return value >= param2
    end
end

--给物品
function giveItemByTable(actor, tab)
    local itemstr = ""
    for idx, num in pairs(tab) do
        --print(ids,num)
        if itemstr ~= "" then
            itemstr = itemstr .. "&"
        end
        itemstr = itemstr .. idx .. "#" .. num
    end
    --print(itemstr)
    giveitem(actor, itemstr)
end

--批量给物品，加经验
function giveItmeByList(actor, tab)
    local itemstr = ""
    local exp = 0
    for idx, num in pairs(tab) do
        -- print(ids,num)
        if idx == 3 then
            exp = num
        else
            if itemstr ~= "" then
                itemstr = itemstr .. "&"
            end
            itemstr = itemstr .. idx .. "#" .. num
        end
    end
    if exp > 0 then
        libxx:changeexp(actor, "+", exp)
    end
    giveitem(actor, itemstr)
end

function mapMove(actor, x, y, mapid, breakAutoFight, range)
    breakAutoFight = breakAutoFight or 1
    local range = tonumber(range) or 3
    -- local newX,newY = math.random(-range,range),math.random(-range,range)
    gotonow(actor, x, y, tostring(mapid), breakAutoFight, range)
end

-- 检查是否在同一队伍
function isInSameTeam(actor1, actor2)
    local team1 = targetinfo(actor1, "GROUPID")
    local team2 = targetinfo(actor2, "GROUPID")
    return team1 > 0 and team1 == team2
end

function GetMonthMxDay()
    -- 获取当前日期的年份和月份
    local year = os.date("%Y")
    local month = os.date("%m") + 1
    if month > 12 then
        month = 1
        year = year + 1
    end
    local timestamp = os.time({ year = year, month = month, day = 1 }) - 86400
    local date = os.date("!*t", timestamp)
    -- print("这个月的最大天数是：" .. date.day)
    return date.day or 28
end

-- Attribute 字符串属性转表
function Attribute2Table(attribute)
    local attrTable = {}
    if not attribute or attribute == "" then
        return attrTable
    end
    local attrList1 = string.split(attribute, "|")
    for _, attr in ipairs(attrList1) do
        local attrList2 = string.split(attr, "#")
        table.insert(attrTable, { tonumber(attrList2[1]) or 0, tonumber(attrList2[2]) or 0, tonumber(attrList2[3]) or 0 })
    end
    return attrTable
end

function recycleEnterBag(actor, itemid, itemObj, itemCount)
    -- 1. 获取玩家勾选配置
    local allSellIds = gethumvar(actor, VarCfg.T_AUTO_SELL_IDS)
    if allSellIds == "" or allSellIds == 0 then
        allSellIds = {}
    else
        allSellIds = json2tbl(allSellIds)
    end

    -- 2. 物品数据获取
    local isEquip = false
    local itemCfg = Item_cfg[itemid] or ItemEquip_cfg[itemid] or {}
    if ItemEquip_cfg[itemid] then
        isEquip = true
    end

    -- 3. 石头判定准备
    -- 获取物品的鉴定属性信息
    linkitembymakeindex(actor, getiteminfo(itemObj, "MAKEINDEX"))
    local attrData = {
        id = custitemattinfo(actor, "-1_0_1_ID"),
        value = custitemattinfo(actor, "-1_0_1_VALUE")
    }

    local matchedStonePrice = nil
    local isStone = false

    -- 遍历配置表寻找匹配的石头回收项
    for _, recycleObj in pairs(Recycle_cfg) do
        -- 判定是否为勾选的石头类 (Type >= 3)
        if allSellIds[recycleObj.Name] == 1 and recycleObj.Type and recycleObj.Type >= 3 then
            if CheckStoneValidServer(recycleObj, itemid, attrData) then
                matchedStonePrice = recycleObj.sell
                isStone = true
                break
            end
        end
    end

    -- 4. 基础装备回收判定逻辑 (如果不是石头，走原有的装备回收流程)
    local canNext = false
    if not isStone then
        if not itemCfg.recycle then return end

        local a, b, c, d, e = false, false, false, false, false
        local needLevel = getEquipLvById(itemid)

        for _, obj in pairs(Recycle_cfg) do
            if allSellIds[obj.Name] == 1 then
                if obj.ConditionType == 1 then -- 等级区间
                    if needLevel >= obj.Condition[1] and needLevel <= obj.Condition[2] then
                        canNext = true
                    end
                elseif obj.ConditionType == 2 then -- 品阶
                    if itemCfg.Grade == obj.Condition then a = true end
                elseif obj.ConditionType == 6 then -- 指定道具
                    for i = 1, #obj.Condition do
                        if obj.Condition[i] == itemid then
                            canNext = true
                            break
                        end
                    end
                end
            end
        end

        if not canNext then return end

        -- 职业匹配
        if Transfer_cfg[itemCfg.TransferID] and Transfer_cfg[itemCfg.TransferID].ClassID > 0 then
            b = (Transfer_cfg[itemCfg.TransferID].ClassID == job(actor)) or (allSellIds["非本职业装备"] == 1)
        else
            b = true
        end

        -- 等级匹配
        c = (allSellIds["高于等级回收"] == 1) or (needLevel <= level(actor))

        -- 部位匹配 (首饰/箭矢)
        for _, obj in pairs(Recycle_cfg) do
            if obj.Name == "首饰" then
                for k = 1, #obj.Condition do
                    if obj.Condition[k] == itemCfg.StdMode then
                        d = (allSellIds["首饰"] == 1)
                        break
                    end
                    d = true
                end
            end
            if obj.Name == "箭矢" then
                for p = 1, #obj.Condition do
                    if obj.Condition[p] == itemCfg.StdMode then
                        e = (allSellIds["箭矢"] == 1)
                        break
                    end
                    e = true
                end
            end
        end

        -- 最终装备回收确认
        if not (a and b and c and d and e and isEquip) then return end
    end

    -- 销毁进入背包的物品
    delItemNum(actor, itemid, itemCount)

    -- 5. 执行回收结算
    local priceStr = isStone and matchedStonePrice or itemCfg.recycle
    if priceStr and priceStr ~= "" then
        local jiacheng = scriptabil(actor, 118) or 0
        local recycleList = string.split(priceStr, "|")

        for m = 1, #recycleList do
            local priceObj = string.split(recycleList[m], "#")
            local priceId = priceObj[1]
            local num = tonumber(priceObj[2])

            if priceId and num then
                -- 收益加成 (仅金币)
                if tonumber(priceId) == 1 then
                    num = num + math.floor(num * jiacheng / 10000)
                    MentorShipChangTask(actor, 9, priceId, num * itemCount)
                end

                giveitem(actor, priceId .. "#" .. (num * itemCount))
            end
        end
    end
end

function recycleAllItem(actor, allItemIds)
    -- 1. 获取玩家勾选配置 (用于校验，虽然一键回收通常由客户端过滤，但服务端校验更安全)
    local allSellIds = gethumvar(actor, VarCfg.T_AUTO_SELL_IDS)
    if allSellIds == "" or allSellIds == 0 then
        allSellIds = {}
    else
        allSellIds = json2tbl(allSellIds)
    end

    local giveMoney = {}         -- 存储最终给玩家的钱：{货币ID = 数量}
    local delItemMakeIndexs = "" -- 存储待销毁物品的唯一标识

    -- 2. 遍历客户端传来的回收列表
    for i = 1, #allItemIds do
        local makeIndex = allItemIds[i].makeIndex
        -- 校验物品是否还在背包
        local result = hasitem(actor, makeIndex)
        if result and result == 1 then
            local itemObj = itemobjbymakeindex(actor, makeIndex)
            local itemid = tonumber(getiteminfo(itemObj, "INDEX")) or 0
            local itemcount = tonumber(getiteminfo(itemObj, "COUNT")) or 1

            -- 获取物品基础配置
            local itemCfg = Item_cfg[itemid] or ItemEquip_cfg[itemid] or {}

            ---- 获取物品的鉴定属性信息 (用于判定是否为石头)
            linkitembymakeindex(actor, makeIndex)
            local attrData = {
                id = custitemattinfo(actor, "-1_0_1_ID"),
                value = custitemattinfo(actor, "-1_0_1_VALUE")
            }

            local priceStr = ""

            -- 我们需要遍历 Recycle_cfg 来寻找匹配当前石头的配置项
            local matchedStonePrice = nil
            for _, recycleObj in pairs(Recycle_cfg) do
                -- 只有 Type >= 3 的才是石头类 (JGS, HYS, RXS 等)
                if recycleObj.Type and recycleObj.Type >= 3 then
                    if CheckStoneValidServer(recycleObj, itemid, attrData) then
                        matchedStonePrice = recycleObj.sell
                        break
                    end
                end
            end

            -- 3. 确定最终价格字符串
            if matchedStonePrice and matchedStonePrice ~= "" then
                priceStr = matchedStonePrice -- 优先使用 Recycle.lua 的 sell 字段
            elseif itemCfg.recycle and itemCfg.recycle ~= "" then
                priceStr = itemCfg.recycle   -- 否则使用 Item.lua 的 recycle 字段
            end

            -- 4. 累加计算
            if priceStr ~= "" then
                delItemMakeIndexs = delItemMakeIndexs .. makeIndex .. ","
                local recycleList = string.split(priceStr, "|")
                for w = 1, #recycleList do
                    local priceObj = string.split(recycleList[w], "#")
                    local priceId = priceObj[1]
                    local num = tonumber(priceObj[2]) * itemcount
                    giveMoney[priceId] = (giveMoney[priceId] or 0) + num
                end
            end
        end
    end

    -- 5. 计算加成并执行发放
    local giveStr = ""
    local jiacheng = scriptabil(actor, 118) or 0 -- 回收收益加成
    for mId, mNum in pairs(giveMoney) do
        local finalNum = mNum
        if tonumber(mId) == 1 then -- 仅针对金币进行加成计算
            finalNum = mNum + math.floor(mNum * jiacheng / 10000)
        end
        giveStr = giveStr .. mId .. "#" .. finalNum .. "&"
        -- 联动师徒任务
        MentorShipChangTask(actor, 9, mId, finalNum)
        ----师徒任务测试
        --MentorShipChangTask(actor, 9, 1, 500000)
    end

    --print("giveStr", giveStr)
    -- 6. 执行删除与发放
    if delItemMakeIndexs ~= "" then
        delitembymakeindex(actor, delItemMakeIndexs)
    end
    if giveStr ~= "" then
        giveitem(actor, giveStr)

        GameEvent.push(EventCfg.onRecycleItems, actor)
    end
end

function CheckStoneValidServer(cfg, stoneId, attrData)
    --dump(attrData)
    -- 判定配置里的 Condition 属性 ID 和值 是否在物品的属性列表
    if cfg.StoneId and cfg.StoneId == stoneId then
        for i, v in ipairs(cfg.Condition) do
            if v and v[1] and v[2] then
                if v[1] == attrData.id and v[2] == attrData.value then
                    return true
                end
            end
        end
    end
end

function isInBag(actor, makeIndex)
    local isIn = false
    local allItemList = getbagitems(actor)
    for i = 1, #allItemList do
        if allItemList[i] == makeIndex then
            isIn = true
        end
    end
    return isIn
end

local Master_and_apprentice = require("Envir/QuestDiary/game_config/cfgcsv/Master_and_apprentice.lua")

function getTaskByType(task_target, task_target_param)
    local Task = {}
    for i = 1, #Master_and_apprentice do
        local item = Master_and_apprentice[i]
        if item.task_target == task_target then
            --table 的只有击杀怪物 7  获得道具 4
            if type(item.task_target_param) == 'table' then
                local count = 0
                for w = 1, #item.task_target_param do
                    if item.task_target == 4 then
                        --获得道具
                        count = count + 1
                    else
                        --击杀
                        if item.task_target_param[w][1] == tonumber(task_target_param) or item.task_target_param[w][1] == "*" then
                            count = count + 1
                        end
                    end
                end
                if count == #item.task_target_param then
                    table.insert(Task, item)
                end
            else
                if tonumber(item.task_target_param) == tonumber(task_target_param) or item.task_target_param == "*" then
                    table.insert(Task, item)
                end
            end
        end
    end
    return Task
end

function MentorShipChangTask(actor, task_target, task_target_param, data)
    local taskList = getTaskByType(task_target, task_target_param)
    --print("task_target=", task_target)
    --print("task_target_param=", task_target_param)
    --dump(data)
    --dump(taskList)
    --特殊任务处理
    local specLst = { [11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [16] = true, [17] = true, [18] = true }

    if specLst[tonumber(task_target)] then
        local userID = userid(actor)
        -- 1. 统一读取徒弟普通任务进度变量
        local myTaskProByStr = getcustvar("11_" .. userID .. "_" .. "t_ApprenticeTaskPro")

        if myTaskProByStr and myTaskProByStr ~= "" then
            local myTaskProBy = json2tbl(myTaskProByStr)
            local isChanged = false

            -- 2. 遍历匹配到的任务列表
            for index = 1, #taskList do
                local task = taskList[index]
                local ID = task.ID
                -- 确保任务ID在玩家数据中存在
                if ID and myTaskProBy["" .. ID] then
                    local currentNum = tonumber(myTaskProBy["" .. ID].num) or 0
                    local targetNum = tonumber(task.task_target_num)
                    if targetNum and currentNum < targetNum then
                        local addNum = tonumber(data) or 1
                        local newNum = currentNum + addNum
                        myTaskProBy["" .. ID].num = newNum >= targetNum and targetNum or newNum
                        isChanged = true
                    end
                end
            end

            -- 3. 如果进度有实质改变，统一保存回数据库
            if isChanged then
                sefcustvar(11, userID, 't_ApprenticeTaskPro', tbl2json(myTaskProBy))
            end
        end
    else
        for index = 1, #taskList do
            local task = taskList[index]
            local ID = task.ID
            if ID then
                local myTaskProBy = {}
                if task.type == 1 then
                else
                    if task.type == 2 then
                        myTaskProBy = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprenticeTaskPro"))
                    end
                    if task.type == 3 then
                        myTaskProBy = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprenticeGxdTask"))
                    end
                    if not myTaskProBy then
                        return
                    end
                    local userID = userid(actor)
                    if myTaskProBy["" .. ID] then
                        if task.task_target == 1 or task.task_target == 2 or task.task_target == 6 or task.task_target == 8 then
                            local targetNum = tonumber(task.task_target_num)
                            local currentData = tonumber(data) or 0
                            --print("targetNum=", targetNum)
                            --print("currentData=", currentData)
                            if targetNum then
                                myTaskProBy["" .. ID].num = currentData > targetNum and targetNum or currentData
                            end
                        end
                        if task.task_target == 4 then
                            --获得道具
                            local count = 0
                            for i = 1, #task.task_target_param do
                                for i = 1, #task_target_param do
                                    --要求品阶
                                    if task_target_param[i] == 3 and task.task_target_param[i][1] == 3 then
                                        if task.task_target_param[i][2] ~= "*" or data.Grade >= tonumber(task.task_target_param[i][2]) then
                                            count = count + 1
                                        end
                                    end
                                    --装备等级
                                    if task_target_param[i] == 4 and task.task_target_param[i][1] == 4 then
                                        if task.task_target_param[i][2] ~= "*" or data.NeedLevel >= tonumber(task.task_target_param[i][2]) then
                                            count = count + 1
                                        end
                                    end
                                    --物品ID
                                    if task_target_param[i] == 1 and task.task_target_param[i][1] == 1 then
                                        if task.task_target_param[i][2] == "*" or data.itemId == tonumber(task.task_target_param[i][2]) then
                                            count = count + 1
                                        end
                                    end
                                end
                            end
                            if count == #task_target_param then
                                local num = data.num
                                myTaskProBy["" .. ID].num = (myTaskProBy["" .. ID].num + num) >= task.task_target_num and
                                    task.task_target_num or (myTaskProBy["" .. ID].num + num)
                            end
                        end
                        if task.task_target == 5 then
                            --完成次数
                            myTaskProBy["" .. ID].num = myTaskProBy["" .. ID].num >= task.task_target_num and
                                task.task_target_num or (myTaskProBy["" .. ID].num + 1)
                        end
                        if task.task_target == 7 then
                            --print("task.task_target == 7")
                            --击杀
                            if task.task_target_param == "*" then
                                -- 1. 纯通配符：任意怪物、任意地图
                                myTaskProBy["" .. ID].num = (myTaskProBy["" .. ID].num + 1) > task.task_target_num and
                                    task.task_target_num or (myTaskProBy["" .. ID].num + 1)
                            elseif type(task.task_target_param) == "table" and type(task.task_target_param[1]) == "table" then
                                -- 2. 数组配置：支持 { {怪物ID, 地图ID} } 格式
                                local cfgMonId = task.task_target_param[1][1]
                                local cfgMapId = task.task_target_param[1][2]
                                local curMapId = tonumber(targetinfo(actor, "NEWMAP"))

                                -- 怪物校验：是 * 或者是 指定的怪物ID(data)
                                local isMonMatch = (cfgMonId == "*") or (tonumber(cfgMonId) == tonumber(data))
                                -- 地图校验：是 * 或者是 玩家当前所在的地图ID
                                local isMapMatch = (cfgMapId == "*") or (tonumber(cfgMapId) == curMapId)

                                if isMonMatch and isMapMatch then
                                    myTaskProBy["" .. ID].num = (myTaskProBy["" .. ID].num + 1) > task.task_target_num and
                                        task.task_target_num or (myTaskProBy["" .. ID].num + 1)
                                end
                            end
                        end
                        if task.task_target == 9 then
                            --货币
                            myTaskProBy["" .. ID].num = (myTaskProBy["" .. ID].num + data) > task.task_target_num and
                                task.task_target_num or (myTaskProBy["" .. ID].num + data)
                        end
                        --师徒副本
                        if task.task_target == 10 then
                            myTaskProBy["" .. ID].num = (myTaskProBy["" .. ID].num + 1) > task.task_target_num and
                                task.task_target_num or (myTaskProBy["" .. ID].num + 1)
                        end
                        if task.type == 2 then
                            sefcustvar(11, userID, 't_ApprenticeTaskPro', tbl2json(myTaskProBy))
                        end
                        if task.type == 3 then
                            sefcustvar(11, userID, 't_ApprenticeGxdTask', tbl2json(myTaskProBy))
                        end
                    end
                end
            end
        end
    end
end

function getEquipLvById(itemId)
    if not ItemEquip_cfg[itemId] then
        return 0
    end
    local needStr = ItemEquip_cfg[itemId].Need
    if needStr then
        -- Need格式: "职业#性别#等级" 或 "职业#性别"
        local parts = string.split(needStr, "#")
        if parts and #parts >= 3 then
            return tonumber(parts[3]) or 0
        end
    end
    return 0
end

------#####装备标记使用情况
------#####装备标记使用情况
------#####装备标记使用情况

-- 0  装备强化等级
-- 1  装备赋予等阶
-- 2  装备镶嵌合成石数
-- 3  装备觉醒等阶
------#####装备标记使用情况
------#####装备标记使用情况
------#####装备标记使用情况


------#####属性组使用情况
------#####属性组使用情况
------#####属性组使用情况
-- 999999 gm无敌属性组
-- 1001  显示道具属性
