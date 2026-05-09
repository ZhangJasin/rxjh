Player = {}

--检查 物品 货币 装备是否满足数量(数量不足返回不足物品的名字)
function Player.checkItemNumByTable(actor, t, multiple)
    for _,item in ipairs(t) do
        local idx,num = item[1], item[2]
        if multiple then num = math.floor(num * multiple) end
        local state = checkitem(actor, idx .. "#" .. num) -- 用物品名称检测 boolean true false
        if not state then
            return fieldvalue(actor, idx .. "_NAME") , num
        end
    end
end

--检查 物品 货币 装备是否满足数量(数量不足返回不足物品的名字和idx) 并通知客户端
-- function Player.checkItemNumByTableEX(actor, t, multiple , tips )
--     for _,item in ipairs(t) do
--         local idx,num = item[1], item[2]
--         if multiple then num = num * multiple end
--         local state = checkitem(actor, idx .. "#" .. num) -- 用物品名称检测 boolean true false
--         if not state then
--             Message.sendmsgEx(actor, ssrNetMsgCfg.ItemWay, "noItem", { id = idx , tips = tips})
--             return fieldvalue(actor, idx .. "_NAME") , idx , num
--         end
--     end
-- end

--拿走物品
function Player.takeItemByTable(actor, t, multiple)
    local parts = {}
    for _,item in ipairs(t) do
        local idx,num = item[1], item[2]
        if multiple then num=math.floor(num * multiple) end
        table.insert(parts, idx .. "#" .. num)
    end
    if #parts > 0 then
        takeitem(actor, table.concat(parts, "&"))
    end
end

--拿走物品
function Player.takeItemByTableEx(actor, t, multiple)
    if type(t) == "table" then
        local parts = {}
        for _,item in ipairs(t) do
            local idx,num = item[1],item[2]
            if multiple then num = num * multiple end
            table.insert(parts, idx .. "#" .. num)
        end
        if #parts > 0 then
            takeitem(actor, table.concat(parts, "&"))
        end
    end
end

local taskEquipSpec={--装备ID 和stdmode
    --[380001]= 52 ,
    [57001]= 5 ,
    [53001]= 5 ,
    [51301]= 5 ,
    [59101]= 5 ,
    [51001]= 5 ,
    [55001]= 5 ,
    [34115]= 3 ,
    [32115]= 3 ,
    [36115]= 3 ,
    [35115]= 3 ,
    [31115]= 3 ,
    [33115]= 3 ,
    [34118]= 3 ,
    [32118]= 3 ,
    [36118]= 3 ,
    [35118]= 3 ,
    [31118]= 3 ,
    [33118]= 3 ,
    [57048]= 5 ,
    [53048]= 5 ,
    [51348]= 5 ,
    [59148]= 5 ,
    [51048]= 5 ,
    [55048]= 5 ,
    [91003]= 9 ,
    [81002]= 8 ,
    [41001]= 22 ,
    [60001]= 51 ,
    [71001]= 19 ,
    [330001]= 15 ,
    [330008]= 15 ,
}
--给物品
local function _addGuildExp(actor, exp)
    if exp < 1 then
        return
    end
    local guildObj = targetinfo(actor, "GUILDOBJID")
    local curexp = getguildinfo(guildObj .. "_" .. 12) or 0
    local curLevel = getguildinfo(guildObj .. "_" .. 13) or 1
    -- 更新玩家门派贡献值
    changemoney(actor, 20, "+", exp)
    setguildmemberexp(guildObj, actor, '+', exp)              -- 设置成员贡献值
    curexp = curexp + exp
    local needexp = guild_level_data[curLevel]["Exp"] or 100    -- 升级需要经验值
    while curexp >= needexp and curLevel < #guild_level_data do -- 满足升级条件
        curLevel = curLevel + 1
        curexp = curexp - needexp
        needexp = guild_level_data[curLevel]["Exp"] or 100 -- 升级需要经验值
    end
    local maxPreple = guild_level_data[curLevel]["maxPreple"] or 5
    setguildexp(guildObj, "=", curexp, actor)
    setguildinfo(guildObj, 3, maxPreple)            -- 设置最大人数
    setguildinfo(guildObj, 6, "=", curLevel, actor) -- 设置当前等级

    Guild.getData(actor)
end

function Player.giveItemByTable(actor, t, multiple, isbind)
    multiple = multiple or 1         --倍数
    local parts = {}
    for _,item in ipairs(t or {}) do
        local idx,num,bind = item[1],item[2],item[3]
        -- print("idx="..idx)
        -- print("num="..num)
        if idx == 3 or idx == "经验" then
            changeexp(actor, "+", num * multiple)
        elseif idx == 20 or idx == "门派贡献" then
            _addGuildExp(actor, num * multiple)
        else
            if bind or isbind then
                table.insert(parts, idx .. "#" .. num * multiple .. "#" .. ConstCfg.binding)
            else
                table.insert(parts, idx .. "#" .. num * multiple)
            end
        end  
    end
    if #parts > 0 then
        giveitem(actor, table.concat(parts, "&"),1)
    end
end
--按职业 性别 阵营 给物品
function Player.giveItemByJobTable(actor, t, multiple, isbind)
    multiple = multiple or 1                            -- 倍数
    local job = job(actor)                              -- 职业  
    local sex = gender(actor)+1                         -- 性别 
    local playzy = targetinfo(actor, "GOODEVILID")      -- 阵营 
    local parts = {}
    for _,item in ipairs(t or {}) do
        local needjob,idx,num,needsex,needzy = item[1],item[2],item[3],item[4] or 0,item[5] or 0
        if idx == 3 or idx == "经验" then
            changeexp(actor, "+", num * multiple)
        elseif idx == 20 or idx == "门派贡献" then
            _addGuildExp(actor, num * multiple)
        else
            if (needjob == job or needjob == 9) and (needsex == sex or needsex == 0) and (needzy == playzy or needzy == 0) then  --  9任意职业0任意性别
                --部分装备直接穿戴
                local stdmode = taskEquipSpec[idx]
                local isAutoOn = false
                if stdmode then
                    for _, pos in ipairs(ConstCfg.equipPos[stdmode] or {}) do
                        local equipmakeIndex = bodyiteminfo(actor, pos..'_MakeIndex')
                        if not equipmakeIndex or equipmakeIndex == "" then
                            giveonitem(actor, pos, idx)
                            isAutoOn = true
                            break
                        end
                    end
                end
                
                if not isAutoOn then
                    if isbind then
                        table.insert(parts, idx .. "#" .. num * multiple .. "#" .. ConstCfg.binding)
                    else
                        table.insert(parts, idx .. "#" .. num * multiple)
                    end
                end                
            end
        end 
    end
    if #parts > 0 then
        giveitem(actor, table.concat(parts, "&"),1)
    end
end

--更新属性
local _addrs = {}
function Player.updateAddr(actor, loginattrs)
    --引擎属性
    for attridx=1,250 do
        _addrs[attridx] = 0
    end
    for _,addr in ipairs(loginattrs) do
        for _,v in ipairs(addr) do
            local attridx = v[1] 
            if not attridx then
                dump("没有attridx，请检查表内属性配置")
            end
            _addrs[attridx] = _addrs[attridx] + v[2]
        end
    end

    --附加引擎属性
    for attridx,value in ipairs(_addrs) do
        if value > 0 then
            setscriptabilvalue(actor, attridx, "=", _addrs[attridx])
        end
    end
end

--更新部分属性
function Player.updateSomeAddr(actor, cur_attr, next_attr)
    local newattr = {}
    if cur_attr then
        for _,attr in ipairs(cur_attr) do
            if #attr > 0  then
                local attridx, attrvalue = attr[1], attr[2]
                newattr[attridx] = newattr[attridx] or scriptabil(actor, attridx)
                newattr[attridx] = newattr[attridx] - attrvalue
                if newattr[attridx] < 0 then newattr[attridx] = 0 end
            end
        end
    end
    if next_attr then
        for _,attr in ipairs(next_attr) do
            if #attr > 0 then
                local attridx, attrvalue = attr[1], attr[2]
                newattr[attridx] = newattr[attridx] or scriptabil(actor, attridx)
                newattr[attridx] = newattr[attridx] + attrvalue
            end
        end
    end
    for attridx,attrvalue in pairs(newattr) do
        setscriptabilvalue(actor, attridx, "=", attrvalue)
    end
end

return Player

