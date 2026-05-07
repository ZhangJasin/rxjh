-- 时装系统主模块
FashionSystem = {}
-- 配置文件加载
local filname = "FashionSystem"
local fashion_huanwu_data       =  require("Envir/QuestDiary/game_config/cfgcsv/fashion_huanwu_data.lua")       --幻武装备数据
local fashion_pifeng_data       =  require("Envir/QuestDiary/game_config/cfgcsv/fashion_pifeng_data.lua")       --披风装备数据
local fashion_toushi_data       =  require("Envir/QuestDiary/game_config/cfgcsv/fashion_toushi_data.lua")       --头饰装备数据
local fashion_charmlevel_data   =  require("Envir/QuestDiary/game_config/cfgcsv/fashion_charmlevel_data.lua")   --魅力值属性数据
local fashion_jihuo             =  require("Envir/QuestDiary/game_config/cfgcsv/fashion_jihuo.lua")             --时装激活道具数据 

-- 时装类型定义
local _FashionType = {          
    PiFeng  = 1,                -- 披风
    HuanWan = 2,                -- 幻武
    TouShi  = 3,                -- 头饰
}
local _FashionTypeKey = {       -- 时装类型
    [1]  = "pifeng",            -- 披风
    [2]  = "huanwu",            -- 幻武
    [3]  = "toushi",            -- 头饰
}
local _FashionAppearIndex = {   -- 时装外观model
    [1]  = 0,                   -- 披风
    [2]  = 2,                   -- 幻武
    [3]  = 4,                   -- 头饰
}
local _FashionPos = {           -- 时装装备位置
    [1]  = 13,                  -- 披风
    [2]  = 26,                  -- 幻武
    [3]  = 25,                  -- 头饰
}
-------------------------------↓↓↓ 本地方法 ↓↓↓---------------------------------------
-- 获取当前时装数据列表
local function getCurFashionData(actor)
    local Fashion_data = gethumvar(actor,VarCfg.T_Fashion_data) or "" 
    if Fashion_data ~= "" then
        Fashion_data = json2tbl(Fashion_data)
    else
        Fashion_data = {} 
    end
    return Fashion_data
    -- ###时装变量说明
    -- Fashion_data['pifeng']               -- 披风已激活时装列表 Fashion_data['pifeng'][''..时装ID] = {默认激活1级,到期时间(-1永久)}
    -- Fashion_data['huanwu']               -- 幻武已激活时装列表
    -- Fashion_data['toushi']               -- 头饰已激活时装列表
    -- Fashion_data['huanhua']['pifeng']    -- 披风幻化时装id
    -- Fashion_data['huanhua']['huanwu']    -- 幻武幻化时装id
    -- Fashion_data['huanhua']['toushi']    -- 头饰幻化时装id
    -- Fashion_data['wear']['pifeng']       -- 披风穿戴时装数据 {时装id,...}
    -- Fashion_data['wear']['huanwu']       -- 幻武穿戴时装数据 {时装id,...}
    -- Fashion_data['wear']['toushi']       -- 头饰穿戴时装数据 {时装id,...}
end 
local function charmValueUpdata(actor,charmValue)    -- 更新魅力值等级 属性
    local charmLv = gethumvar(actor,VarCfg.N_fashion_charmLv) or 1 
    local nextlv = #fashion_charmlevel_data
    for i=1,#fashion_charmlevel_data do
        if charmValue < fashion_charmlevel_data[i]['need'] then
            nextlv = i-1
            break
        end
    end
    if charmLv ~= nextlv then                       -- 魅力值等级变化时更新属性与等级
        if fashion_charmlevel_data[charmLv] then
            Player.updateSomeAddr(actor, fashion_charmlevel_data[charmLv]['attrlist'], nil) -- 清除之前等级属性
        end
        if fashion_charmlevel_data[nextlv] then
            Player.updateSomeAddr(actor, nil, fashion_charmlevel_data[nextlv]['attrlist'])  -- 更新当前等级属性
            sethumvar(actor,VarCfg.N_fashion_charmLv,nextlv)                                -- 当前时装魅力值等级
        end
    end
    return nextlv
end
local function pifengjihuo(actor,itemID,itemobj)  -- 披风激活 更新属性
    -- print("itemID="..itemID)
    local equipID = fashion_jihuo[itemID]['equipID']
    local Fashion_data = getCurFashionData(actor)
    if not Fashion_data['pifeng'] then
        Fashion_data['pifeng'] = {}
    end
    if Fashion_data['pifeng'][''..equipID] then
        sendmsg(actor, 9, "当前时装已激活！")
        return
    end
    local name, num = Player.checkItemNumByTable(actor, {{itemID,1}})
    if name then
        sendmsg(actor, 9, "" .. name .. "不足")
        return
    end
    local sex = gender(actor)+1           -- 1男2女
    -- 拿走物品
    Player.takeItemByTable(actor, {{itemID,1}})
    Fashion_data['pifeng'][''..equipID] = {1,-1}  --时装激活默认1级  配成可拓展表   
    if fashion_jihuo[itemID]['time'] then
        Fashion_data['pifeng'][''..equipID][2] = os.time()+fashion_jihuo[itemID]['time']*60
    end  

    local charmValue = gethumvar(actor,VarCfg.N_fashion_charmValue) or 0 
    -- 更新属性
    for k,v in pairs(fashion_pifeng_data) do   -- 披风属性
        local idx = v['sex_type'][sex]
        if idx == equipID then
            Player.updateSomeAddr(actor, nil, v['fashion_attr'])
            charmValue = charmValue + v['charmValue']
        end
    end
    -- print("charmValue="..charmValue)
    sethumvar(actor,VarCfg.T_Fashion_data,tbl2json(Fashion_data))  -- 当前已激活时装列表
    sethumvar(actor,VarCfg.N_fashion_charmValue,charmValue)        -- 当前已激活时装魅力值
    local charmLv = charmValueUpdata(actor,charmValue)             -- 更新魅力值等级 属性
    -- 更新客户端数据
    Message.sendmsgEx(actor, "FashionSystemPanl","UpdataData",{['param1']= Fashion_data,['param2']= charmValue,['param3']= charmLv})

end
local function huanwujihuo(actor,itemID,itemobj)  -- 幻武激活 更新属性
    local equipID = fashion_jihuo[itemID]['equipID']
    local Fashion_data = getCurFashionData(actor)
    if not Fashion_data['huanwu'] then
        Fashion_data['huanwu'] = {}
    end
    if Fashion_data['huanwu'][''..equipID] then
        sendmsg(actor, 9, "当前时装已激活！")
        return
    end
    local name, num = Player.checkItemNumByTable(actor, {{itemID,1}})
    if name then
        sendmsg(actor, 9, "" .. name .. "不足")
        return
    end
    local job = job(actor)                -- 角色职业
    -- 拿走物品
    Player.takeItemByTable(actor, {{itemID,1}})
    Fashion_data['huanwu'][''..equipID] = {1,-1}  --时装激活默认1级  配成可拓展表    
    if fashion_jihuo[itemID]['time'] then
        Fashion_data['huanwu'][''..equipID][2] = os.time()+fashion_jihuo[itemID]['time']*60
    end  
    local charmValue = gethumvar(actor,VarCfg.N_fashion_charmValue) or 0 
    
    -- 更新属性
    for k,v in pairs(fashion_huanwu_data) do   -- 披风属性
        local idx = v['job_type'][job]
        if idx == equipID then
            Player.updateSomeAddr(actor, nil, v['fashion_attr'])
            charmValue = charmValue + v['charmValue']
        end
    end
    sethumvar(actor,VarCfg.T_Fashion_data,tbl2json(Fashion_data))  -- 当前已激活时装列表
    sethumvar(actor,VarCfg.N_fashion_charmValue,charmValue)        -- 当前已激活时装魅力值
    local charmLv = charmValueUpdata(actor,charmValue)             -- 更新魅力值等级 属性
    -- 更新客户端数据
    Message.sendmsgEx(actor, "FashionSystemPanl","UpdataData",{['param1']= Fashion_data,['param2']= charmValue,['param3']= charmLv})

end
local function toushijihuo(actor,itemID,itemobj)  -- 头饰激活 更新属性
    local equipID = fashion_jihuo[itemID]['equipID']
    local Fashion_data = getCurFashionData(actor)
    if not Fashion_data['toushi'] then
        Fashion_data['toushi'] = {}
    end
    if Fashion_data['toushi'][''..equipID] then
        sendmsg(actor, 9, "当前时装已激活！")
        return
    end
    local name, num = Player.checkItemNumByTable(actor, {{itemID,1}})
    if name then
        sendmsg(actor, 9, "" .. name .. "不足")
        return
    end
    local sex = gender(actor)+1           -- 1男2女
    -- 拿走物品
    Player.takeItemByTable(actor, {{itemID,1}})
    Fashion_data['toushi'][''..equipID] = {1,-1}  --时装激活默认1级  配成可拓展表    
    if fashion_jihuo[itemID]['time'] then
        Fashion_data['toushi'][''..equipID][2] = os.time()+fashion_jihuo[itemID]['time']*60
    end  
    local charmValue = gethumvar(actor,VarCfg.N_fashion_charmValue) or 0 
    -- 更新属性
    for k,v in pairs(fashion_toushi_data) do   -- 披风属性
        local idx = v['sex_type'][sex]
        if idx == equipID then
            Player.updateSomeAddr(actor, nil, v['fashion_attr'])
            charmValue = charmValue + v['charmValue']
        end
    end
    sethumvar(actor,VarCfg.T_Fashion_data,tbl2json(Fashion_data))  -- 当前已激活时装列表
    sethumvar(actor,VarCfg.N_fashion_charmValue,charmValue)        -- 当前已激活时装魅力值
    local charmLv = charmValueUpdata(actor,charmValue)             -- 更新魅力值等级 属性
    -- 更新客户端数据
    Message.sendmsgEx(actor, "FashionSystemPanl","UpdataData",{['param1']= Fashion_data,['param2']= charmValue,['param3']= charmLv})

end

local function fashion_attr(actor,loginattrs)        -- 时装属性更新  登录获取  更新外观
    local sex = gender(actor)+1           -- 1男2女
    local job = job(actor)                -- 角色职业
    local playlevel = currabil(actor, 0)  -- 角色等级
    -- local curtime = os.time()           -- 注释掉不再需要的过期检测变量
    local charmValue = 0                  -- 角色当前已激活时装魅力值
    local Fashion_data = getCurFashionData(actor)
    local jihuoData = Fashion_data['pifeng'] or {}
    if not Fashion_data['huanhua'] then
        Fashion_data['huanhua'] = {}
    end
    if not Fashion_data['wear'] then
        Fashion_data['wear'] = {}
    end
    for k,v in pairs(fashion_pifeng_data) do   -- 披风属性
        local equipID = v['sex_type'][sex]
        if jihuoData[""..equipID] then
            -- 注释掉过期检测逻辑，已激活的时装永久有效
            -- local flag = false                 -- 是否过期
            -- if jihuoData[""..equipID][2] == -1 or  jihuoData[""..equipID][2] > curtime then  -- 检测时装是否过期 -1为永久时装
                table.insert(loginattrs,v['fashion_attr'])
                charmValue = charmValue + v['charmValue']
            -- else
            --     jihuoData[""..equipID] = nil
            --     flag = true
            -- end
            if Fashion_data['huanhua']['pifeng'] and Fashion_data['huanhua']['pifeng'] == equipID then
                -- if flag then
                --     model = 0
                --     Fashion_data['huanhua']['pifeng'] = nil
                    -- 过期后若有转职模型 ，则恢复转职模型
                    -- local rolemodel = gethumvar(actor,VarCfg.U_Role_RELEVEL_Body) or 0
                    -- if rolemodel > 0 then
                    --     model = rolemodel
                    -- end
                -- else
                    model  = v['model'][sex] or 0
                -- end
                changeappear(actor, _FashionAppearIndex[_FashionType.PiFeng], model)          -- 改变所选装备外观
            end
            -- 注释掉过期后清除穿戴装备的逻辑
            -- if Fashion_data['wear']['pifeng'] and Fashion_data['wear']['pifeng'][1] == equipID then
            --     if flag then
            --         Fashion_data['wear']['pifeng'] = nil
            --         local equipmakeIndex = bodyiteminfo(actor, _FashionPos[1]..'_MakeIndex')
            --         if equipmakeIndex and equipmakeIndex ~= "" then
            --             delbodybymakeindex(actor, equipmakeIndex)                              -- 清除穿戴装备                             --
            --         end
            --     end
            -- end
        end
    end
    local jihuoData = Fashion_data['toushi'] or {}
    for k,v in pairs(fashion_toushi_data) do   -- 头饰属性
        local equipID = v['sex_type'][sex]
        if jihuoData[""..equipID] then
            -- 注释掉过期检测逻辑，已激活的时装永久有效
            -- local flag = false                 -- 是否过期
            -- if jihuoData[""..equipID][2] == -1 or  jihuoData[""..equipID][2] > curtime then  -- 检测时装是否过期 -1为永久时装
                table.insert(loginattrs,v['fashion_attr'])
                charmValue = charmValue + v['charmValue']
            -- else
            --     jihuoData[""..equipID] = nil
            --     flag = true
            -- end
            if Fashion_data['huanhua']['toushi'] and Fashion_data['huanhua']['toushi'] == equipID then
                -- if flag then
                --     model = 0
                --     Fashion_data['huanhua']['toushi'] = nil
                    -- 过期后若有转职模型 ，则恢复转职模型
                    -- local rolemodel = gethumvar(actor,VarCfg.U_Role_RELEVEL_helmet) or 0
                    -- if rolemodel > 0 then
                    --     model = rolemodel
                    -- end
                -- else
                    model  = v['model'][sex] or 0
                -- end
                changeappear(actor, _FashionAppearIndex[_FashionType.TouShi], model)          -- 改变所选装备外观
            end
            -- 注释掉过期后清除穿戴装备的逻辑
            -- if Fashion_data['wear']['toushi'] and Fashion_data['wear']['toushi'][1] == equipID then
            --     if flag then
            --         Fashion_data['wear']['toushi'] = nil
            --         local equipmakeIndex = bodyiteminfo(actor, _FashionPos[3]..'_MakeIndex')
            --         if equipmakeIndex and equipmakeIndex ~= "" then
            --             delbodybymakeindex(actor, equipmakeIndex)                              -- 清除穿戴装备
            --         end
            --     end
            -- end
        end
    end
    local jihuoData = Fashion_data['huanwu'] or {}
    for k,v in pairs(fashion_huanwu_data) do   -- 幻武属性
        local equipID = v['job_type'][job]
        if jihuoData[""..equipID] then
            -- 注释掉过期检测逻辑，已激活的时装永久有效
            -- local flag = false                 -- 是否过期
            -- if jihuoData[""..equipID][2] == -1 or  jihuoData[""..equipID][2] > curtime then  -- 检测时装是否过期 -1为永久时装
                table.insert(loginattrs,v['fashion_attr'])
                charmValue = charmValue + v['charmValue']
            -- else
            --     jihuoData[""..equipID] = nil
            --     flag = true
            -- end
            if Fashion_data['huanhua']['huanwu'] and Fashion_data['huanhua']['huanwu'] == equipID then
                -- if flag then
                --     model = 0
                --     Fashion_data['huanhua']['huanwu'] = nil
                -- else
                    model  = v['model'][job] or 0
                -- end
                changeappear(actor, _FashionAppearIndex[_FashionType.HuanWan], model)          -- 改变所选装备外观
            end
            -- 注释掉过期后清除穿戴装备的逻辑
            -- if Fashion_data['wear']['huanwu'] and Fashion_data['wear']['huanwu'][1] == equipID then
            --     if flag then
            --         Fashion_data['wear']['huanwu'] = nil
            --         local equipmakeIndex = bodyiteminfo(actor, _FashionPos[2]..'_MakeIndex')
            --         if equipmakeIndex and equipmakeIndex ~= "" then
            --             delbodybymakeindex(actor, equipmakeIndex)                              -- 清除穿戴装备
            --         end
            --     end
            -- end
        end
    end
    -- 更新魅力值属性
    local mlzlv = gethumvar(actor,VarCfg.N_fashion_charmLv) or 0 
    if playlevel >= 1 then
        mlzlv = #fashion_charmlevel_data
        for i=1,#fashion_charmlevel_data do
            if charmValue < fashion_charmlevel_data[i]['need'] then
                mlzlv = i-1
                break
            end
        end
        if fashion_charmlevel_data[mlzlv] then
            table.insert(loginattrs,fashion_charmlevel_data[mlzlv]['attrlist'])
            sethumvar(actor,VarCfg.N_fashion_charmLv,mlzlv)        -- 当前当前时装魅力值等级
        end
    end
    sethumvar(actor,VarCfg.N_fashion_charmValue,charmValue)        -- 当前当前时装魅力值等级
    sethumvar(actor,VarCfg.T_Fashion_data,tbl2json(Fashion_data))  -- 当前已激活时装列表
    -- 更新客户端数据
    Message.sendmsgEx(actor, "FashionSystemPanl","UpdataData",{['param1']= Fashion_data,['param2']= charmValue,['param3']= mlzlv})
    return loginattrs
end 

local function fashion_jihuoFunc(actor,itemID,itemobj)       -- 时装激活
    local type = fashion_jihuo[itemID]['type']       -- 激活时装类型
    if type == _FashionType.PiFeng then
        pifengjihuo(actor,itemID,itemobj)
    elseif type == _FashionType.HuanWan then
        huanwujihuo(actor,itemID,itemobj)
    elseif type == _FashionType.TouShi then
        toushijihuo(actor,itemID,itemobj)
    end
end

-------------------------------↓↓↓ 网络消息 ↓↓↓---------------------------------------
function FashionSystem.openshow(actor,data)
	page = tonumber(data[1]) or 1
    Message.sendmsgEx(actor, "FashionSystemPanl","Open",{page = page})
end

function FashionSystem.JiHuo(actor,data)              -- 时装激活（客户端请求）
    local type,fashionID = tonumber(data[1]),tonumber(data[2])
    local sex = gender(actor)+1           -- 1男2女
    local job = job(actor)                -- 角色职业
    local equipID = 0
    local itemID = 0
    
    -- 根据时装类型和配置表下标找到对应的装备ID
    if type == 1 then
        equipID = fashion_pifeng_data[fashionID]['sex_type'][sex] or 0
    elseif type == 2 then
        equipID = fashion_huanwu_data[fashionID]['job_type'][job] or 0
    elseif type == 3 then
        equipID = fashion_toushi_data[fashionID]['sex_type'][sex] or 0
    end
    
    if equipID <= 0 then
        sendmsg(actor, 9, "时装数据错误！")
        return
    end
    
    -- 反向查找道具ID：遍历fashion_jihuo找到equipID匹配的itemID
    for k,v in pairs(fashion_jihuo) do
        if v['equipID'] == equipID and v['type'] == type then
            itemID = k
            break
        end
    end
    
    if itemID <= 0 then
        sendmsg(actor, 9, "未找到对应的激活道具！")
        return
    end
    
    -- 检查背包中是否有该道具
    local name, num = Player.checkItemNumByTable(actor, {{itemID,1}})
    if name then
        sendmsg(actor, 9, "背包中需要" .. name .. "！")
        return
    end
    
    -- 调用激活函数
    if type == 1 then
        pifengjihuo(actor,itemID,nil)
    elseif type == 2 then
        huanwujihuo(actor,itemID,nil)
    elseif type == 3 then
        toushijihuo(actor,itemID,nil)
    end
end

function FashionSystem.HuanHua(actor,data)              -- 时装幻化
	local type,index = tonumber(data[1]),tonumber(data[2])
    local sex = gender(actor)+1           -- 1男2女
    local job = job(actor)                -- 角色职业
    local equipID = 0
    if type == 1 and not fashion_pifeng_data[index] then
        return
    end
    if type == 2 and not fashion_huanwu_data[index] then
        return
    end
    if type == 3 and not fashion_toushi_data[index] then
        return
    end
    local Fashion_data = getCurFashionData(actor)
    local model = 0
    if type == _FashionType.PiFeng then
        equipID = fashion_pifeng_data[index]['sex_type'][sex] or 0
        model   = fashion_pifeng_data[index]['model'][sex] or 0
    elseif type == _FashionType.HuanWan then
        equipID = fashion_huanwu_data[index]['job_type'][job] or 0
        model   = fashion_huanwu_data[index]['model'][job] or 0
    elseif type == _FashionType.TouShi then
        equipID = fashion_toushi_data[index]['sex_type'][sex] or 0
        model   = fashion_toushi_data[index]['model'][sex] or 0
    end
    if not Fashion_data["".._FashionTypeKey[type]] or not Fashion_data["".._FashionTypeKey[type]][""..equipID] then 
        sendmsg(actor, 9, "请先激活该时装")
        return 
    end
    if equipID <= 0 then
        return
    end
    if not Fashion_data['huanhua'] then
        Fashion_data['huanhua'] = {}
    end
    
    local curequipid =  Fashion_data['huanhua'][''.._FashionTypeKey[type]] or 0
    if curequipid == equipID then   --- 取消幻化
        model = 0
        equipID = nil
        -- 取消幻化时，若有转职模型 ，则恢复转职模型
        -- local rolebody = gethumvar(actor,VarCfg.U_Role_RELEVEL_Body) or 0
        -- if rolebody > 0 and _FashionAppearIndex[type] == 0 then         
        --     model = rolebody
        -- end
        local rolehelmet = gethumvar(actor,VarCfg.U_Role_RELEVEL_helmet) or 0
        if rolehelmet > 0 and _FashionAppearIndex[type] == 4 then
            model = rolehelmet
        end
    end
    changeappear(actor, _FashionAppearIndex[type], model)          -- 改变所选装备外观
    Fashion_data['huanhua'][''.._FashionTypeKey[type]] = equipID   -- 当前幻化时装id

    
    sethumvar(actor,VarCfg.T_Fashion_data,tbl2json(Fashion_data))  -- 当前时装数据列表
    --更新客户端数据
    local charmLv = gethumvar(actor,VarCfg.N_fashion_charmLv) or 0 
    local charmValue = gethumvar(actor,VarCfg.N_fashion_charmValue) or 0 
    Message.sendmsgEx(actor, "FashionSystemPanl","UpdataData",{['param1']= Fashion_data,['param2']= charmValue,['param3']= charmLv})


end
function FashionSystem.wearAttr(actor,data)             -- 时装穿戴属性
    local type,index = tonumber(data[1]),tonumber(data[2])
    local sex = gender(actor)+1           -- 1男2女
    local job = job(actor)                -- 角色职业
    local equipID = 0
    if type == 1 and not fashion_pifeng_data[index] then
        return
    end
    if type == 2 and not fashion_huanwu_data[index] then
        return
    end
    if type == 3 and not fashion_toushi_data[index] then
        return
    end
    
    local Fashion_data = getCurFashionData(actor)
    if type == _FashionType.PiFeng then
        equipID = fashion_pifeng_data[index]['sex_type'][sex] or 0
    elseif type == _FashionType.HuanWan then
        equipID = fashion_huanwu_data[index]['job_type'][job] or 0
    elseif type == _FashionType.TouShi then
        equipID = fashion_toushi_data[index]['sex_type'][sex] or 0
    end
    if equipID <= 0 then
        return
    end
    if not Fashion_data["".._FashionTypeKey[type]] then 
        sendmsg(actor, 9, "请先激活该时装")
        return 
    end
    if not Fashion_data["".._FashionTypeKey[type]][""..equipID] then 
        sendmsg(actor, 9, "请先激活该时装")
        return 
    end
    if not Fashion_data['wear'] then
        Fashion_data['wear'] = {}
    end
    if not Fashion_data['wear'][''.._FashionTypeKey[type]] then
        Fashion_data['wear'][''.._FashionTypeKey[type]] = {}  -- 当前穿戴时装属性
    end
    local equipmakeIndex = bodyiteminfo(actor, _FashionPos[type]..'_MakeIndex')
    if equipmakeIndex and equipmakeIndex ~= "" then
        --print("equipmakeIndex="..equipmakeIndex)
        delbodybymakeindex(actor, equipmakeIndex)
    end
    local curequipid = Fashion_data['wear'][''.._FashionTypeKey[type]][1] or 0
    --print("curequipid="..curequipid)
    --print("equipID="..equipID)
    if curequipid == equipID then
        --print("删除时装")
        Fashion_data['wear'][''.._FashionTypeKey[type]] = nil
    else
        --print("添加时装")
        Fashion_data['wear'][''.._FashionTypeKey[type]] = {equipID}  -- 更新当前穿戴时装
        newbodyitem(actor, equipID ,_FashionPos[type])               -- 穿戴时装
    end
    
    sethumvar(actor,VarCfg.T_Fashion_data,tbl2json(Fashion_data))  -- 当前时装数据列表
    --更新客户端数据
    local charmLv = gethumvar(actor,VarCfg.N_fashion_charmLv) or 0 
    local charmValue = gethumvar(actor,VarCfg.N_fashion_charmValue) or 0 
    Message.sendmsgEx(actor, "FashionSystemPanl","UpdataData",{['param1']= Fashion_data,['param2']= charmValue,['param3']= charmLv})

end
-- 注释掉整个 TimeOut 函数，不再处理过期逻辑
-- function FashionSystem.TimeOut(actor,data)              -- 时装过期  客户端定时器检测
--     local type = tonumber(data[1]) or 1
--     local fashionID = tonumber(data[2]) or 0
--     local Fashion_data = getCurFashionData(actor)
--     local curtime = os.time()
--     if Fashion_data[''.._FashionTypeKey[type]][''..fashionID] and Fashion_data[''.._FashionTypeKey[type]][''..fashionID][2] ~= -1 then
--         local gqtime = Fashion_data[''.._FashionTypeKey[type]][''..fashionID][2]
--         if curtime >= gqtime then
--             Fashion_data[''.._FashionTypeKey[type]][''..fashionID] = nil
--             if Fashion_data['huanhua'][''.._FashionTypeKey[type]] and Fashion_data['huanhua'][''.._FashionTypeKey[type]] == fashionID then
--                 Fashion_data['huanhua'][''.._FashionTypeKey[type]] = nil
--             end
--             if Fashion_data['wear'][''.._FashionTypeKey[type]] and Fashion_data['wear'][''.._FashionTypeKey[type]][1] == fashionID then
--                 Fashion_data['wear'][''.._FashionTypeKey[type]] = nil
--             end
--             local sex = gender(actor)+1           -- 1男2女
--             local job = job(actor)                -- 角色职业
--             local charmValue = gethumvar(actor,VarCfg.N_fashion_charmValue) or 0
--             --更新属性
--             local tab = fashion_pifeng_data
--             if _FashionTypeKey[type] == "huanwu" then
--                 tab = fashion_huanwu_data
--             elseif _FashionTypeKey[type] == "toushi" then
--                 tab = fashion_toushi_data
--             end
--             for k,v in pairs(tab) do   -- 披风属性
--                 local idx = 0
--                 if _FashionTypeKey[type] == "huanwu" then
--                     idx = v['job_type'][job]
--                 else
--                     idx = v['sex_type'][sex]
--                 end
--                 if idx == fashionID then
--                     Player.updateSomeAddr(actor, v['fashion_attr'], nil)   -- 更新属性
--                     charmValue = charmValue - v['charmValue']              -- 更新魅力值
--                     local equipmakeIndex = bodyiteminfo(actor, _FashionPos[type]..'_MakeIndex')
--                     if equipmakeIndex and equipmakeIndex ~= "" then
--                         delbodybymakeindex(actor, equipmakeIndex)
--                         local model = 0
--                         -- 过期后，若有转职模型 ，则恢复转职模型
--                         -- local rolebody = gethumvar(actor,VarCfg.U_Role_RELEVEL_Body) or 0
--                         -- if rolebody > 0 and _FashionAppearIndex[type] == 0 then
--                         --     model = rolebody
--                         -- end
--                         local rolehelmet = gethumvar(actor,VarCfg.U_Role_RELEVEL_helmet) or 0
--                         if rolehelmet > 0 and _FashionAppearIndex[type] == 4 then
--                             model = rolehelmet
--                         end
--                         changeappear(actor, _FashionAppearIndex[type], model)  -- 改变所选装备外观
--                     end
--                 end
--             end
--             -- 更新魅力值属性
--             sethumvar(actor,VarCfg.T_Fashion_data,tbl2json(Fashion_data))  -- 当前已激活时装列表
--             sethumvar(actor,VarCfg.N_fashion_charmValue,charmValue)        -- 当前已激活时装魅力值
--             local charmLv = charmValueUpdata(actor,charmValue)             -- 更新魅力值等级 属性
--             -- 更新客户端数据
--             Message.sendmsgEx(actor, "FashionSystemPanl","UpdataData",{['param1']= Fashion_data,['param2']= charmValue,['param3']= charmLv})

--         end
--     end
-- end

-------------------------------↓↓↓ 事件 ↓↓↓---------------------------------------
GameEvent.add(EventCfg.onLogin, function(actor)
    -- 获取阵营 转职
    local faction = targetinfo(actor, "GOODEVILID")
    local relevel = targetinfo(actor, "RELEVEL")
    local sex = gender(actor)+1           -- 1男2女
    local job = job(actor)                -- 角色职业 1弓手2剑士3弓箭手4骑士5法师6牧师
    -- 阵营大于0 转职大于0 更新模型
    if relevel > 0 then
        for k,v in pairs(Transfer_cfg) do
            if v['ClassID'] == job and v['Type'] == faction and v['TransferLV'] == relevel and v['ModeId'] then
                local body,helmet = v['ModeId'][sex][1],v['ModeId'][sex][2]
                -- sethumvar(actor,VarCfg.U_Role_RELEVEL_Body,body)
                sethumvar(actor,VarCfg.U_Role_RELEVEL_helmet,helmet)
                -- changeappear(actor, 0, body)
                changeappear(actor, 4, helmet)
                break
            end
        end
    end
end, FashionSystem)
--登录更新属性
GameEvent.add(EventCfg.onLoginAttr, function (actor,loginattrs)
    loginattrs = fashion_attr(actor,loginattrs)
end, FashionSystem)

GameEvent.add(EventCfg.stdUseItem, function (actor, itemID,itemobj,useNumber,param1,param2)  -- 双击使用时QF触发
    -- print("双击使用时QF触发",itemID)
    if fashion_jihuo[itemID] and fashion_jihuo[itemID]['equipID'] then
        local sex = gender(actor)+1           -- 1男2女
        local itemname = fieldvalue(actor, string.format("%d_%s", itemID, "Name"))
        -- print(itemname)
        if string.find(itemname,"男") and sex == 2 then
            sendmsg(actor, 9, "性别不符")
            return false
        elseif string.find(itemname,"女") and sex == 1 then
            sendmsg(actor, 9, "性别不符")
            return false
        end
        fashion_jihuoFunc(actor,itemID,itemobj)
    end
end, FashionSystem)
GameEvent.add(EventCfg.onPlayLevelUp, function (actor, cur_level, before_level)         -- 升级触发
    if cur_level >= 1 then
        local charmValue = gethumvar(actor,VarCfg.N_fashion_charmValue) or 0 
        local charmLv = charmValueUpdata(actor,charmValue)                              -- 更新魅力值等级 属性
    end
end, FashionSystem)

GameEvent.add(EventCfg.onKuaFuLogin, function(actor)
    fashion_attr(actor,{})
end, FashionSystem)

Message.RegisterNetMsg(ssrNetMsgCfg.FashionSystem, FashionSystem)
return FashionSystem



