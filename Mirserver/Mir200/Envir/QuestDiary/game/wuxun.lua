wuxun = {}
local filname = "wuxun"
local wuxun_item_data      =  require("Envir/QuestDiary/game_config/cfgcsv/wuxun_item_data.lua")       -- 武勋值道具
local wuxun_level_data     =  require("Envir/QuestDiary/game_config/cfgcsv/wuxun_level_data.lua")      -- 武勋等级配置
local wuxun_chuilian_data  =  require("Envir/QuestDiary/game_config/cfgcsv/wuxun_chuilian_data.lua")   -- 武勋锤炼配置
local wuxun_zhujie_data    =  require("Envir/QuestDiary/game_config/cfgcsv/wuxun_zhujie_data.lua")     -- 武勋铸阶配置
local wuxun_jianding_attr  =  require("Envir/QuestDiary/game_config/cfgcsv/wuxun_jianding_attr.lua")   -- 武勋鉴定属性配置
local wuxun_skill_data     =  require("Envir/QuestDiary/game_config/cfgcsv/wuxun_skill_data.lua")      -- 武勋技能配置
local wuxun_equip_pos      = { [46] = "武器" , [47] = "衣服", [48] = "护腕", [49] = "戒指"}              -- 武勋装备位置（判断用）  同wuxun_level_data[1]['WuXun_EquipPos'] 
local wuxun_equip_Stdmode  = { [71] = 46 , [72] = 47, [73] = 48, [74] = 49,}            -- 武勋装备位置stdmode（判断用）  同wuxun_level_data[1]['WuXun_EquipPos'] 
--- changeitemaddvalueex  武勋装备  锤炼附加属性值  暂用位置 0~4  穿脱装备时更新清除附加属性值
--- changeitemaddvalueex  武勋装备  铸阶附加属性值  暂用位置 5~9  绑定装备
-------------------------------↓↓↓ 本地方法 ↓↓↓---------------------------------------
-- 获取当前使用武勋值道具数据列表
local function addWuXunExp(actor,itemID,itemobj,useNumber,curdura,maxdura)                 -- 使用经验值道具
    local camp = targetinfo(actor, "GOODEVILID")  --(0=无阵营 1=正派 2=邪派)     -- 获取阵营
    if camp == 0 then
        sendmsg(actor, 9, "请先选择阵营")
        return
    end
    local WuXun_Level  = gethumvar(actor,VarCfg.U_WuXun_Level) or 0             -- 当前武勋等级
    -- 当前特效id
    local curEffectid = 0
    -- 逐级检查并获取特效ID
    if wuxun_level_data[WuXun_Level] then
        local levelData = wuxun_level_data[WuXun_Level]
        if levelData['WuXunEffect'] and #levelData['WuXunEffect'] > 0 then
            curEffectid = levelData['WuXunEffect'][camp]
        end
    end
    if WuXun_Level < 1 then
        WuXun_Level = 1
    end
    local WuXun_curExp = gethumvar(actor,VarCfg.U_WuXun_curExp) or 0    -- 当前武勋值
    local WuXun_NextLv = WuXun_Level
    local playerLv = level(actor)
    local minlv,maxlv = wuxun_item_data[itemID]['levelLimit'][1],wuxun_item_data[itemID]['levelLimit'][2]
    
    if playerLv < minlv then
        sendmsg(actor, 9, "道具最低使用等级为"..minlv.."级")
        return
    end
    if playerLv > maxlv then
        sendmsg(actor, 9, "道具最高使用等级为"..maxlv.."级")
        return
    end
    

    local addWuXunExp = wuxun_item_data[itemID]['addWuXunExp'] or 0
    if addWuXunExp <= 0 then
        return
    end
    WuXun_curExp = WuXun_curExp + addWuXunExp * useNumber -- 增加武勋值
    -- 判断是否升级
    local maxLevel = #wuxun_level_data
    -- if WuXun_Level >= maxLevel then
    --     sendmsg(actor, 9, "武勋等级已达最高级")
    --     return
    -- else
        local curmaxExp = wuxun_level_data[WuXun_NextLv]['WuXunExp'][2] or 0   -- 当前等级升级所需武勋值
        -- print(WuXun_curExp,curmaxExp,WuXun_NextLv)
        while WuXun_curExp >= curmaxExp and WuXun_NextLv < maxLevel do          -- 满足升级条件
            WuXun_NextLv = WuXun_NextLv + 1
            curmaxExp = wuxun_level_data[WuXun_NextLv]['WuXunExp'][2] or 0   -- 当前等级升级所需武勋值
            -- print("升级",WuXun_NextLv,curmaxExp)
        end
    -- end
    -- 获取对应称号等级ID
    local titleID = wuxun_level_data[WuXun_NextLv]['WuXun_Title'][camp] or 0
    
    
    Player.takeItemByTable(actor, {{itemID,useNumber}})  -- 扣除道具

    sethumvar(actor,VarCfg.U_WuXun_Level,WuXun_NextLv)        -- 当前武勋等级
    sethumvar(actor,VarCfg.U_WuXun_curExp,WuXun_curExp)      -- 当前武勋值
    changemoney(actor, 8, "=", WuXun_curExp)                    -- 更新当前武勋值
    sendmsg(actor, 9, "获得"..addWuXunExp * useNumber.."点武勋值")
    -- 升级成功
    if WuXun_NextLv > WuXun_Level then
        sethumvar(actor,VarCfg.U_WuXun_DailyState,0)  -- 重置领取
        sendmsg(actor, 9, "恭喜您武勋升级到"..WuXun_NextLv.."级")
        -- 更新属性：扣除当前等级属性，下级属性
         Player.updateSomeAddr(actor, 
         wuxun_level_data[WuXun_Level]['attrlist'] or nil, 
         wuxun_level_data[WuXun_NextLv]['attrlist'])
        -- 更新武勋特效
        local effectid = wuxun_level_data[WuXun_NextLv]['WuXunEffect'] and wuxun_level_data[WuXun_NextLv]['WuXunEffect'][camp] or 0
        seticonid(actor, 0, titleID)        -- 更新称号
        
        if effectid > 0 and effectid ~= curEffectid then
            changescriptappear(actor, 12, effectid)  -- 武勋特效
            -- 特效改变 更新打开客户端升级特效界面
            Message.sendmsgEx(actor, "WuXunUpLevel","Open",{['param1']= effectid})
        end
    end
      
end

-- 登录更新属性 武勋外观特效
function WuXun_attr(actor,loginattrs)
    local WuXun_Level  = gethumvar(actor,VarCfg.U_WuXun_Level) or 0     -- 当前武勋等级
    local WuXun_curExp = gethumvar(actor,VarCfg.U_WuXun_curExp) or 0    -- 当前武勋值
    if wuxun_level_data[WuXun_Level] and wuxun_level_data[WuXun_Level]['DailyDeduct'] then -- 指定等级后每日扣除武勋值
        WuXun_curExp = WuXun_curExp - wuxun_level_data[WuXun_Level]['DailyDeduct'] or 0
    end
    -- 更新当前武勋等级
    for i= 1, #wuxun_level_data do
        if WuXun_curExp >= wuxun_level_data[i]['WuXunExp'][1] and WuXun_curExp < wuxun_level_data[i]['WuXunExp'][2] then
            WuXun_Level = i
            break
        end
    end
    
    local camp = targetinfo(actor, "GOODEVILID")  --(0=无阵营 1=正派 2=邪派)

    if wuxun_level_data[WuXun_Level] and wuxun_level_data[WuXun_Level]['attrlist'] and camp > 0 then
        table.insert(loginattrs,wuxun_level_data[WuXun_Level]['attrlist'])             
    end
    
    
    -- print("武勋等级",WuXun_Level,"武勋值",WuXun_curExp,"阵营",camp)
    if wuxun_level_data[WuXun_Level] and wuxun_level_data[WuXun_Level]['WuXunEffect'] and camp > 0 then
        -- 获取对应称号等级ID
        local titleID = wuxun_level_data[WuXun_Level]['WuXun_Title'][camp] or 0
        seticonid(actor, 0, titleID)  -- 更新称号
        local effectid = wuxun_level_data[WuXun_Level]['WuXunEffect'][camp] or 0  
        changescriptappear(actor, 12, effectid)  -- 武勋特效
        --print("武勋特效",effectid)
    end
    sethumvar(actor,VarCfg.U_WuXun_Level,WuXun_Level)        -- 当前武勋等级
    sethumvar(actor,VarCfg.U_WuXun_curExp,WuXun_curExp)      -- 当前武勋值
    changemoney(actor, 8, "=", WuXun_curExp)                    -- 更新当前武勋值
    return loginattrs
end

-- 武勋装备锤炼属性值更新
local function WuXunEquipChuilianAddAttr(actor, equipObj)
    local itemid = tonumber(getiteminfo(equipObj, "INDEX"))
    local stdmode = tonumber(getiteminfo(equipObj, "STDMODE"))
    if not wuxun_chuilian_data[itemid] then
        return
    end
    local WuXun_ChuiLianList = gethumvar(actor,VarCfg.T_WuXun_ChuiLianList) or ""   -- 锤炼等级列表
    if WuXun_ChuiLianList ~= "" then
        WuXun_ChuiLianList = json2tbl(WuXun_ChuiLianList)
    else
        WuXun_ChuiLianList = {}
    end
    -- dump(WuXun_ChuiLianList)
    local chuilianLv = WuXun_ChuiLianList[""..wuxun_equip_Stdmode[stdmode]] or 0
    -- print("锤炼等级",chuilianLv)
    if chuilianLv <= 0 then
        return
    end
    for i=1,#wuxun_chuilian_data[itemid][chuilianLv]['attrlist'] do
        local attrid = wuxun_chuilian_data[itemid][chuilianLv]['attrlist'][i][1]
        local value = wuxun_chuilian_data[itemid][chuilianLv]['attrlist'][i][2]
        changeitemaddvalueex(actor, equipObj, i-1, attrid, "=", value)
    end
    -- 修改装备标记值 锤炼等级
    changeitemaddvalue(actor, equipObj, 1, "=", chuilianLv)
    updateitemtoclient(actor, equipObj)
    
end
-- 脱装备清除武勋锤炼属性
local function WuXunEquipTakeoffClearAttr(actor, equipObj)
    local itemid = tonumber(getiteminfo(equipObj, "INDEX"))
    local stdmode = tonumber(getiteminfo(equipObj, "STDMODE"))
    if not wuxun_chuilian_data[itemid] then
        return
    end
    local WuXun_ChuiLianList = gethumvar(actor,VarCfg.T_WuXun_ChuiLianList) or ""   -- 锤炼等级列表
    if WuXun_ChuiLianList ~= "" then
        WuXun_ChuiLianList = json2tbl(WuXun_ChuiLianList)
    else
        WuXun_ChuiLianList = {}
    end
    local chuilianLv = WuXun_ChuiLianList[""..wuxun_equip_Stdmode[stdmode]] or 0
    if chuilianLv <= 0 then
        return
    end
    for i=1,#wuxun_chuilian_data[itemid][chuilianLv]['attrlist'] do
        local attrid = wuxun_chuilian_data[itemid][chuilianLv]['attrlist'][i][1]
        local value = wuxun_chuilian_data[itemid][chuilianLv]['attrlist'][i][2]
        changeitemaddvalueex(actor, equipObj, i-1, attrid, "=", 0)
    end
    -- 修改装备标记值 锤炼等级
    changeitemaddvalue(actor, equipObj, 1, "=", 0)
    updateitemtoclient(actor, equipObj)
end

-- 判断铸阶技能激活情况  穿脱装备后  装备铸阶后  武勋技能暂未定
local function WuXunEquipZujieSkillUpdate(actor)
    -- 获取身上各等级铸阶装备数量
    local WuXunZhuJieTab,wxminLv = wuxun:GetWuXunEquipLevel(actor)
    -- dump(WuXunZhuJieTab)
    sethumvar(actor,VarCfg.U_MinWuXunZJLevel,wxminLv)
    -- 清除之前激活铸阶技能
    -- 判断当前可激活那些铸阶技能
    PassiveManager:onVarChanged(actor, VarCfg.U_MinWuXunZJLevel)  -- 更新
end
-------------------------------↓↓↓ 网络消息 ↓↓↓---------------------------------------
-- 武勋装备是否可穿戴
function wuxun.WuXunEquipCanTakeon(actor, itemObj,pos)
    if wuxun_equip_pos[pos] then
        local jdattrid = custitemattinfo(actor, itemObj.."_0_1_ID") or 0
        if jdattrid <= 0 then
            sendmsg(actor, 9, "请先鉴定当前武勋装备！")
            return false
        end
    end
    return true
end
-- 打开武勋商店
function wuxun.OpenWuXunShop(actor)
    local job = job(actor)                              -- 职业   1 弓手 ,2 枪客, 3 刺客,4 医生,5 刀客,6 剑客
    opennpcshop(actor, 1, 29+job, 0,"武勋商店")
end
-- 领取每日奖励
function wuxun.GetDailyReward(actor)
    local WuXun_Level  = gethumvar(actor,VarCfg.U_WuXun_Level) or 0     -- 当前武勋等级
    local DailyState  = gethumvar(actor,VarCfg.U_WuXun_DailyState) or 0 -- 武勋每日奖励领取标识  
    local playerLv = level(actor)
    if WuXun_Level <= 0 then
        sendmsg(actor, 9, "武勋等级不足，无法领取")
        return
    end
    if DailyState == 1 then
        sendmsg(actor, 9, "今日已领取，请明日再来")
        return
    end
    local rewardList = wuxun_level_data[WuXun_Level] and wuxun_level_data[WuXun_Level]['rewardList'] or {{}}
    if not rewardList or #rewardList <= 0 then
        sendmsg(actor, 9, "当前武勋等级无奖励可领取")
        return
    end
    DailyState = 1
    -- 发放奖励
    sethumvar(actor,VarCfg.U_WuXun_DailyState,DailyState)  -- 今日已领取
    Player.giveItemByTable(actor, rewardList, 1)
    sendmsg(actor, 9, "恭喜您领取武勋每日奖励")
    -- 更新客户端界面显示
    Message.sendmsgEx(actor, "WuXunPanl","update_dailyPanl",{['param1']= DailyState})
end
-- 客户端打开界面  没激活则激活1级属性
function wuxun.OpenWuXunPanl(actor)
    local WuXun_Level  = gethumvar(actor,VarCfg.U_WuXun_Level) or 0     -- 当前武勋等级
    if WuXun_Level <= 0 then
        WuXun_Level = 1
        sethumvar(actor,VarCfg.U_WuXun_Level,WuXun_Level)  -- 激活1级属性
        -- 更新属性：扣除当前等级属性，下级属性
        if wuxun_level_data[WuXun_Level] then
            Player.updateSomeAddr(actor, nil, wuxun_level_data[WuXun_Level]['attrlist'])
        end
        -- 更新武勋特效
        local camp = targetinfo(actor, "GOODEVILID")  --(0=无阵营 1=正派 2=邪派)
        if camp <= 0 then   
            camp = 1
        end
        local effectid = wuxun_level_data[WuXun_Level]['WuXunEffect'] and wuxun_level_data[WuXun_Level]['WuXunEffect'][camp] or 0
        if effectid > 0 then
            changescriptappear(actor, 12, effectid)
            -- 特效改变 更新打开客户端升级特效界面
            Message.sendmsgEx(actor, "WuXunUpLevel","Open",{['param1']= effectid})
        end
    end
end
-- 武勋装备鉴定
function wuxun.WuXunEquipCheck(actor, data)
    local equipmakeIndex = tostring(data[1])
    local equipObj = itemobjbymakeindex(actor, equipmakeIndex)
    -- print("equipObj",equipObj)
    local stdmode = tonumber(getiteminfo(equipObj, "STDMODE"))
    -- print("stdmode",stdmode)
    if not wuxun_equip_Stdmode[stdmode] then
        return
    end
    local itemid = tonumber(getiteminfo(equipObj, "INDEX"))
    
    -- print("itemid",itemid,type(itemid))
    local sum = math.random(1,wuxun_jianding_attr[itemid][1]['attrRatioAll'])
    local index1,num = 1,0
    for i=1,#wuxun_jianding_attr[itemid] do
        num = num+wuxun_jianding_attr[itemid][i]['attrRatio']
        if sum <= num then
            index1 = i
            break
        end
    end
    local tab = wuxun_jianding_attr[itemid][index1]['AttScoreRatio_arr']
    local sum = math.random(1,wuxun_jianding_attr[itemid][index1]['RatioAll'])
    local index2,num = 1,0
    for i=1,#tab do
        num = num+tab[i]
        if sum <= num then
            index2 = i
            break
        end
    end
    local attrid = wuxun_jianding_attr[itemid][index1]['attrid']
    local value = math.random(wuxun_jianding_attr[itemid][index1]['AttScoreStageList'][index2][1],wuxun_jianding_attr[itemid][index1]['AttScoreStageList'][index2][2])
    changecustomitemabil(actor, equipObj, 0, 1, attrid, value)

    updateitemtoclient(actor, equipObj)
end

-- 武勋装备锤炼
function wuxun.WuXunEquipChuilian(actor, data)
    local WuXun_ChuiLianList = gethumvar(actor,VarCfg.T_WuXun_ChuiLianList) or ""   -- 锤炼等级列表
    if WuXun_ChuiLianList ~= "" then
        WuXun_ChuiLianList = json2tbl(WuXun_ChuiLianList)
    else
        WuXun_ChuiLianList = {}
    end
    local equipmakeIndex = tostring(data[1])
    local equipObj = itemobjbymakeindex(actor, equipmakeIndex)
    local itemid = tonumber(getiteminfo(equipObj, "INDEX"))
    local stdmode = tonumber(getiteminfo(equipObj, "STDMODE"))
    -- print("stdmode",stdmode)
    if not wuxun_chuilian_data[itemid] then
        sendmsg(actor, 9, "该装备不可锤炼！")
        return
    end
    local chuilianLv = WuXun_ChuiLianList[""..wuxun_equip_Stdmode[stdmode]] or 0
    if chuilianLv >= #wuxun_chuilian_data[itemid] then
        sendmsg(actor, 9, "该装备已达到最高锤炼等级！")
        return
    end
    local nextlv = chuilianLv + 1
    -- 消耗
    local cost = wuxun_chuilian_data[itemid][nextlv]['xhitemlist']
    local name, num = Player.checkItemNumByTable(actor, {cost})
    if name then
        sendmsg(actor, 9, "" .. name .. "不足")
        return
    end
    Player.takeItemByTable(actor, {cost})
    -- 更新锤炼等级
    WuXun_ChuiLianList[""..wuxun_equip_Stdmode[stdmode]] = nextlv
    sethumvar(actor,VarCfg.T_WuXun_ChuiLianList,tbl2json(WuXun_ChuiLianList))  -- 锤炼等级列表

    WuXunEquipChuilianAddAttr(actor, equipObj)

    -- 更新客户端界面显示
    Message.sendmsgEx(actor, "WuXunPanl","UpdateWuXunChuiLianData",{['param1']= WuXun_ChuiLianList})
end

-- 武勋装备铸阶
function wuxun.WuXunEquipZhujie(actor, data)
    local equipmakeIndex = tostring(data[1])
    local equipObj = itemobjbymakeindex(actor, equipmakeIndex)
    local itemid = tonumber(getiteminfo(equipObj, "INDEX"))
    local stdmode = tonumber(getiteminfo(equipObj, "STDMODE"))
    -- print("stdmode",stdmode)
    if not wuxun_zhujie_data[itemid] then
        sendmsg(actor, 9, "该装备不可铸阶！")
        return
    end
    -- 获取铸阶等级
    local zjLv = tonumber(itematt(actor, equipObj.."_2")) or 0
    if zjLv >= #wuxun_zhujie_data[itemid] then
        sendmsg(actor, 9, "该装备已达到最高铸阶等级！")
        return
    end
    local nextlv = zjLv + 1
    -- 升级是否满足达到指定武勋等级条件
    local WuXun_Level  = gethumvar(actor,VarCfg.U_WuXun_Level) or 0             -- 当前武勋等级
    if WuXun_Level < wuxun_zhujie_data[itemid][nextlv]['needWXLevel'] then
        sendmsg(actor, 9, "武勋等级不足！")
        return
    end

    -- 消耗
    local cost = wuxun_zhujie_data[itemid][nextlv]['xhitemlist']
    local name, num = Player.checkItemNumByTable(actor, {cost})
    if name then
        sendmsg(actor, 9, "" .. name .. "不足")
        return
    end
    Player.takeItemByTable(actor, {cost})
    -- 更新铸阶等级
    changeitemaddvalue(actor, equipObj, 2, "=", nextlv)
    -- 更新铸阶属性
    for i=1,#wuxun_zhujie_data[itemid][nextlv]['attrlist'] do
        local attrid = wuxun_zhujie_data[itemid][nextlv]['attrlist'][i][1]
        local value = wuxun_zhujie_data[itemid][nextlv]['attrlist'][i][2]
        changeitemaddvalueex(actor, equipObj, i+4, attrid, "=", value)
    end
    updateitemtoclient(actor, equipObj)
    -- 更新客户端界面显示
    Message.sendmsgEx(actor, "WuXunPanl","UpdateWuXunZhujieData")

    
    -- 判断是否解锁武勋技能  
    WuXunEquipZujieSkillUpdate(actor)

end

-- 获取武勋装备铸阶等级
function wuxun:GetWuXunEquipLevel(actor)
    local equippos =  wuxun_level_data[1]['WuXun_EquipPos'] or {}
    local WuXunZhuJieTab  = {}
    local wxminLv = 999
    for i = 1, #equippos do
        local equipObj = bodyiteminfo(actor,  equippos[i]..'_OBJ')
        if equipObj then
            local zjLv = tonumber(itematt(actor, equipObj.."_2")) or 0
            WuXunZhuJieTab[zjLv] = (WuXunZhuJieTab[zjLv] or 0) + 1
            if wxminLv > zjLv then
                wxminLv = zjLv
            end
        else
            wxminLv = 0
        end
    end
    return WuXunZhuJieTab,wxminLv
end

-- 武勋装备转印
function wuxun.WuXunEquipZhuanYin(actor, data)
    local wearequipmakeIndex = tostring(data[1])    -- 当前穿戴装备唯一ID
    local bagequipmakeIndex = tostring(data[2])     -- 背包装备唯一ID
    local wearAttrIndex = tonumber(data[3])         -- 当前穿戴装备选中索引    1 鉴定   2,3,4,5对应转印的1,2,3,4
    --local bagAttrIndex = tonumber(data[4])          -- 消耗的背包装备选中索引
    -- 获取当前穿戴装备对象 物品ID 装备类型
    local wearequipObj = itemobjbymakeindex(actor, wearequipmakeIndex)
    local wearitemid = tonumber(getiteminfo(wearequipObj, "INDEX"))
    local stdmode = tonumber(getiteminfo(wearequipObj, "STDMODE"))
    -- 获取背包装备对象 物品ID
    local bagequipObj = itemobjbymakeindex(actor, bagequipmakeIndex)
    local bagitemid = tonumber(getiteminfo(bagequipObj, "INDEX"))
    -- print("stdmode",stdmode)
    if bagequipmakeIndex == 0 or wearequipmakeIndex == 0 then
        sendmsg(actor, 9, "请选择要转印的装备！")
        return
    end
    if wearAttrIndex <= 0 then
        sendmsg(actor, 9, "请选择要转印的属性！")
        return
    end
    if not wuxun_zhujie_data[wearitemid] then
        sendmsg(actor, 9, "该装备不可转印！")
        return
    end
    if wearitemid ~= bagitemid then
        sendmsg(actor, 9, "转印装备与武勋装备物品ID不一致！")
        return
    end
    -- 获取铸阶等级
    local zjLv = tonumber(itematt(actor, wearequipObj.."_2")) or 0
    local limitNum = wuxun_zhujie_data[wearitemid][zjLv] and (wuxun_zhujie_data[wearitemid][zjLv]['zhuanyin'] or 0) or 0  -- 当前铸阶等级可转印条数
    if (wearAttrIndex-1) > limitNum then
        sendmsg(actor, 9, "该装备可转印条数不足！")
        return
    end
    -- 获取转印等级
    -- 当前武勋装备已鉴定转印获取的属性ID  同一属性不可重复
    local yhqAttrIDList = {}
    -- 鉴定属性ID
    local jdattrid = custitemattinfo(actor, wearequipObj.."_0_1_ID") or 0
    if jdattrid > 0 then
        yhqAttrIDList[jdattrid] = jdattrid
    end
    -- 已转印属性ID
    for i=1,limitNum do
        local zyattrid = custitemattinfo(actor, wearequipObj.."_1_"..i.."_ID") or 0
        if zyattrid > 0 then
            yhqAttrIDList[zyattrid] = zyattrid
        end
    end
    -- 获取身上装备选择的转印孔对应属性id
    local wearAttrID = 0
    if wearAttrIndex == 1 then
        wearAttrID = custitemattinfo(actor, wearequipObj.."_0_1_ID") or 0
    else
        wearAttrID = custitemattinfo(actor, wearequipObj.."_1_"..(wearAttrIndex-1).."_ID") or 0
    end
    -- 获取转印的属性ID 属性值
    local xhzyattrid = custitemattinfo(actor, bagequipObj.."_0_1_ID") or 0
    local xhzyattValue = custitemattinfo(actor, bagequipObj.."_0_1_VALUE") or 0
    if xhzyattrid <= 0 or xhzyattValue <= 0 then
        sendmsg(actor, 9, "该装备不可转印")
        return
    end
    -- print("wearAttrID",wearAttrID,"xhzyattrid",xhzyattrid)
    -- 如果选择相同转印属性可覆盖  但不能同时存在两条
    if yhqAttrIDList[xhzyattrid] and  xhzyattrid ~= wearAttrID then
        sendmsg(actor, 9, "不可转印相同属性！")
        return
    end

    -- 消耗转印装备
    delitembymakeindex(actor, bagequipmakeIndex)

    -- 更新转印等级
    -- zyLv = zyLv+1
    -- changeitemaddvalue(actor, wearequipObj, 3, "=", zyLv)
    -- print("更新转印属性",wearAttrIndex,xhzyattrid,xhzyattValue)
    -- 更新转印属性
    if wearAttrIndex == 1 then
        changecustomitemabil(actor, wearequipObj, 0, 1, xhzyattrid,xhzyattValue)                -- 更新鉴定
    else
        changecustomitemabil(actor, wearequipObj, 1, wearAttrIndex-1, xhzyattrid,xhzyattValue)  -- 更新转印
    end
    updateitemtoclient(actor, wearequipObj)
    -- 更新客户端界面显示
    Message.sendmsgEx(actor, "WuXunPanl","UpdateWuXunZhuanYinData")
end


-------------------------------↓↓↓ 事件 ↓↓↓---------------------------------------
-- 登录更新属性
GameEvent.add(EventCfg.onLoginAttr, function (actor,loginattrs)
    -- print("武勋属性")
    loginattrs = WuXun_attr(actor,loginattrs)
end, wuxun)
-- 双击使用时QF触发
GameEvent.add(EventCfg.stdUseItem, function (actor, itemID,itemobj,useNumber,param1,param2)  
    if wuxun_item_data[itemID] then
        addWuXunExp(actor,itemID,itemobj,useNumber,param1,param2)   
    end
end, wuxun)

-- 穿装备前QF触发
GameEvent.add(EventCfg.onTakeonbeforeex, function(actor, itemObj, pos)
    -- print("穿装备前QF触发",itemObj,pos)
    -- 更新穿戴武勋装备锤炼属性  锤炼绑定装备位
    WuXunEquipChuilianAddAttr(actor, itemObj)
end, wuxun)

-- 脱装备前QF触发
GameEvent.add(EventCfg.onTakebeforeex, function(actor, itemObj, pos)
    -- print("脱装备前QF触发",itemObj,pos)
    -- 更新穿戴武勋装备锤炼属性  锤炼绑定装备位
    WuXunEquipTakeoffClearAttr(actor, itemObj)
end, wuxun)

--人物穿装备触发
GameEvent.add(EventCfg.onTakeOnEx, function(actor, itemObj, pos, itemname, itemid)
    WuXunEquipZujieSkillUpdate(actor)
end, wuxun)
GameEvent.add(EventCfg.onTakeOffEx, function(actor, itemObj, pos, itemname, itemid)
    WuXunEquipZujieSkillUpdate(actor)
end, wuxun)

-- 跨天登录触发 重置领取状态
GameEvent.add(EventCfg.onResetday, function(actor)
    sethumvar(actor, VarCfg.U_WuXun_DailyState, 0)
end, wuxun)

-- 跨天登录触发 重置领取状态
GameEvent.add(EventCfg.onResetday, function(actor)
    sethumvar(actor, VarCfg.U_WuXun_DailyState, 0)
end, wuxun)

-- 加入正派
GameEvent.add(EventCfg.onJoinUpright, function(actor)
    WuXun_attr(actor,{})
end, wuxun)
-- 加入正派
GameEvent.add(EventCfg.onJoinEvil, function(actor)
    WuXun_attr(actor,{})
end, wuxun)




Message.RegisterNetMsg(ssrNetMsgCfg.wuxun, wuxun)
return wuxun



