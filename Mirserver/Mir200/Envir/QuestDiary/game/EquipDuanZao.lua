-- 装备锻造相关功能模块
EquipDuanZao = {}
local filname = "EquipDuanZao"

-- 配置表加载
local EquipQHTab          = require("Envir/QuestDiary/game_config/cfgcsv/EquipQHTab.lua")       -- 装备强化配置
local EquipQHItemTab      = require("Envir/QuestDiary/game_config/cfgcsv/EquipQHItemTab.lua")   -- 装备强化材料配置 提升材料 幸运符  
local EquipFYTab          = require("Envir/QuestDiary/game_config/cfgcsv/EquipFYTab.lua")       -- 装备加工配置
local EquipHCTab          = require("Envir/QuestDiary/game_config/cfgcsv/EquipHCTab.lua")       -- 装备合成配置
local EquipQHEffectShow   = require("Envir/QuestDiary/game_config/cfgcsv/EquipQHEffectShow.lua")-- 装备强化特效展示配置  配置左右手特效
local ItemEquip           = require("Envir/QuestDiary/game_config/ItemEquip.lua")

-- 装备位置映射
local equippos2 = { [5]=1, [3]=2, [8]=3, [9]=4, [51]=5, [15]=6, [19]=7, [22]=8 ,[53]=9,[54]=6,[65]=7,[66]=8}

local qhGroupId = 0 --强化加工使用 自定义属性组0
local fyGroupId = 1 --赋予使用 自定义属性组1
local hcGroupId = 2 --合成使用 自定义属性组2
local hcBaseValue ={3,4,5,6}  --合成使用 合成石1-4对应的基础属性值存储

-- 打开锻造界面
function EquipDuanZao.openshow(actor, page)
    page = tonumber(page) or 1
    local isget = gethumvar(actor, "U1") or 0
    Message.sendmsgEx(actor, "EquipDuanZao", "Open", {})
end

--- 强化/加工
-- @param actor 玩家对象
-- @param data 参数表
function EquipDuanZao.qianghua(actor, data)
    local equipmakeIndex = tostring(data[4])
    local xhitemid = tonumber(data[1])   -- 幸运符道具
    local xhitemid2 = tonumber(data[2])  -- 提升类道具
    local xhitemid3 = tonumber(data[3])  
    local gxybxh = tonumber(data[5])
    local isbag = tonumber(data[6])
    if equipmakeIndex == "0" then return end

    linkitembymakeindex(actor, equipmakeIndex)
    local equipObj = itemobjbymakeindex(actor, equipmakeIndex)
    local stdmode = linkitem(actor, "STDMODE")
    local posindex = equippos2[stdmode]
    local qhlv = linkitem(actor, "INTVALUE0")
    local nextlv = qhlv + 1
    local falselv = qhlv - 1 <= 0 and 0 or qhlv - 1
    
    -- 强化等级上限判断  强化8级以上或者加工装备5级以上失败
    if qhlv >= 8 or (posindex > 5 and qhlv >= 5) then
        falselv = -1 -- 装备损坏
    end
    local itemid = linkitem(actor, "INDEX")
    local qhTabIndex = ItemEquip[itemid]['EquipQHTabId']   
    if not qhTabIndex then
        sendmsg(actor, 9, posindex > 5 and "60级以上首饰才可加工！" or "当前装备不可强化！")
        return
    end
    
    local curQHTabData = EquipQHTab[posindex]
    if qhTabIndex then
        curQHTabData = EquipQHTab[qhTabIndex]
    end
    if nextlv > #curQHTabData['attridList'] then
        sendmsg(actor, 9, "已达到当前等级上限！")
        return
    end

    -- 材料消耗判断
    local xhitemtab = curQHTabData['xhitemList'][nextlv]
    local xhnumtab = curQHTabData['xhnumList'][nextlv]
    if type(xhitemtab) == "number" then
        if getItemNum(actor, xhitemtab) < xhnumtab then
            sendmsg(actor, 9, "消耗材料数量不足！")
            return
        end
    else
        for i = 1, #xhitemtab do
            if getItemNum(actor, xhitemtab[i]) < xhnumtab[i] then
                sendmsg(actor, 9, "消耗材料数量不足！")
                return
            end
        end
    end

    -- 成功率计算
    local sum = math.random(1, 100)
    local basesuc = curQHTabData['sucjl_arr'][nextlv]
    if gxybxh == 1 then
        local ybnum = getItemNum(actor, "元宝")
        local needyb = curQHTabData['addsucc_arr'][1]
        if ybnum < needyb then
            sendmsg(actor, 9, "元宝不足！！")
            return
        end
        delItemNum(actor, "元宝", needyb)
        basesuc = basesuc + curQHTabData['addsucc_arr'][2]
    end

    -- 材料消耗
    if type(xhitemtab) == "number" then
        delItemNum(actor, xhitemtab, xhnumtab)
    else
        for i = 1, #xhitemtab do
            delItemNum(actor, xhitemtab[i], xhnumtab[i])
        end
    end

    -- 幸运符道具
    if EquipQHItemTab[xhitemid] then
        local minlv, maxlv = EquipQHItemTab[xhitemid]['level_arr'][1], EquipQHItemTab[xhitemid]['level_arr'][2]
        if qhlv >= minlv and qhlv <= maxlv then
            delItemNum(actor, xhitemid, 1)
            if EquipQHItemTab[xhitemid]['addsuccess'] then
                basesuc = basesuc + EquipQHItemTab[xhitemid]['addsuccess']
            end
        end
    end

    -- 提升道具
    local useitem2flag = false
    if EquipQHItemTab[xhitemid2] then
        local minlv, maxlv = EquipQHItemTab[xhitemid2]['level_arr'][1], EquipQHItemTab[xhitemid2]['level_arr'][2]
        if qhlv >= minlv and qhlv <= maxlv then
            delItemNum(actor, xhitemid2, 1)
            useitem2flag = true
            if EquipQHItemTab[xhitemid2]['addsuccess'] then
                basesuc = basesuc + EquipQHItemTab[xhitemid2]['addsuccess']
            end
        end
    end

    -- 强化次数事件触发
    if posindex <= 5 then
        GameEvent.push(EventCfg.onQiangHua, actor, sum > basesuc)
    end
    -- basesuc = 100
    -- 强化结果判定
    if sum > basesuc then
        if useitem2flag then
            falselv = EquipDuanZao.itemTSfalse(actor, xhitemid2, falselv, qhlv)
        end
        if falselv == -1 then
            if isbag == 1 then
                delitembymakeindex(actor, equipmakeIndex)
            else
                delbodybymakeindex(actor, equipmakeIndex)
            end
            sendmsg(actor, 9, posindex > 5 and "加工失败!装备已损坏！" or "强化失败!装备已损坏！")
            Message.sendmsgEx(actor, "EquipDuanZao", "UpdataQH", { param1 = 0, param2 = 0 })
            return
        else
            sendmsg(actor, 9, posindex > 5 and "加工失败!当前装备强化等级：" .. falselv or "强化失败!当前装备强化等级：" .. falselv)
            nextlv = falselv
        end
    else
        if useitem2flag then
            nextlv = EquipDuanZao.itemTSSuc(actor, xhitemid2, nextlv, qhlv)
        end
        sendmsg(actor, 9, posindex > 5 and "加工成功!当前装备强化等级：" .. nextlv or "强化成功!当前装备强化等级：" .. nextlv)
    end
    -- 修改装备标记值
    changeitemaddvalue(actor, -1, 0, "=", nextlv)

    -- 属性刷新
    if nextlv == 0 then
        clearcustomitemabil(actor, -1, 0)
    else
        changecustomitemtext(actor, -1, 0, posindex > 5 and "[加工]" or "[强化]")
        if type(curQHTabData['attridList'][nextlv]) == "number" then
            changecustomitemabil(actor, -1, 0, 1, curQHTabData['attridList'][nextlv], curQHTabData['attrList'][nextlv])
        else
            for i = 1, #curQHTabData['attridList'][nextlv] do
                changecustomitemabil(actor, -1, 0, i, curQHTabData['attridList'][nextlv][i], curQHTabData['attrList'][nextlv][i])
            end
        end
    end

    -- 根据强化等级更新合成石和属性石属性
    if posindex <= 5 and qhlv > 5  then        
        EquipDuanZao.updateEquipAttrsByQHLv(actor, equipmakeIndex, nextlv)
    end

    EquipDuanZao.showWeaponEffect(actor, equipObj)
    updateitemtoclient(actor, -1)
    Message.sendmsgEx(actor, "EquipDuanZao", "UpdataQH", { param1 = 1, param2 = nextlv })
end

-- 赋予属性
function EquipDuanZao.fuyu(actor, data)
    local equipmakeIndex = tostring(data[4])
    local xhitemid = tonumber(data[1])
    local xhitemid2 = tonumber(data[2])
    local xhitemid3 = tonumber(data[3])
    local gxybxh = tonumber(data[5])
    local isbag = tonumber(data[6])
    if equipmakeIndex == "0" then return end

    linkitembymakeindex(actor, equipmakeIndex)
    local stdmode = linkitem(actor, "STDMODE")
    local posindex = equippos2[stdmode]
    local qhlv = linkitem(actor, "INTVALUE0")
    local eqfylv = (qhlv - 5) > 0 and (qhlv - 5) or 0 --强化到+6及以上时给提升赋予等级
    local fylv = linkitem(actor, "INTVALUE1")
    local nextlv = fylv + 1
    local falselv = 0

    -- 赋予等级上限判断
    if nextlv > #EquipFYTab[posindex]['sucjl_arr'] then
        sendmsg(actor, 9, "已达到当前赋予等级上限！")
        return
    end

    -- 属性石道具判断
    if not EquipQHItemTab[xhitemid3] then
        sendmsg(actor, 9, "请选择属性石道具！")
        return
    end
    local attridindex = EquipQHItemTab[xhitemid3]['fyattrid']
    local attrid = EquipFYTab[posindex]['attrid_arr'][attridindex]
    local fyaxid = custitemattinfo(actor, "-1_1_1_ID")
    if fyaxid ~= attrid and fyaxid ~= 0 then
        sendmsg(actor, 9, "请选择对应属性石道具！")
        return
    end

    -- 成功率计算
    local sum = math.random(1, 100)
    local basesuc = EquipFYTab[posindex]['sucjl_arr'][nextlv]
    if gxybxh == 1 then
        local ybnum = getItemNum(actor, "元宝")
        local needyb = EquipFYTab[posindex]['addsucc_arr'][1]
        if ybnum < needyb then
            sendmsg(actor, 9, "元宝不足！！")
            return
        end
        delItemNum(actor, "元宝", needyb)
        basesuc = basesuc + EquipFYTab[posindex]['addsucc_arr'][2]
    end

    -- 幸运符道具
    if EquipQHItemTab[xhitemid] then
        local minlv, maxlv = EquipQHItemTab[xhitemid]['level_arr'][1], EquipQHItemTab[xhitemid]['level_arr'][2]
        if fylv >= minlv and fylv <= maxlv then
            delItemNum(actor, xhitemid, 1)
            if EquipQHItemTab[xhitemid]['addsuccess'] then
                basesuc = basesuc + EquipQHItemTab[xhitemid]['addsuccess']
            end
        end
    end

    -- 提升道具
    local useitem2flag = false
    if EquipQHItemTab[xhitemid2] then
        local minlv, maxlv = EquipQHItemTab[xhitemid2]['level_arr'][1], EquipQHItemTab[xhitemid2]['level_arr'][2]
        if fylv >= minlv and fylv <= maxlv then
            delItemNum(actor, xhitemid2, 1)
            useitem2flag = true
            if EquipQHItemTab[xhitemid2]['addsuccess'] then
                basesuc = basesuc + EquipQHItemTab[xhitemid2]['addsuccess']
            end
        end
    end

    if falselv < 0 then falselv = 0 end
    delItemNum(actor, xhitemid3, 1)


    -- 赋予结果判定
    if sum > basesuc then
        if useitem2flag then
            falselv = EquipDuanZao.itemTSfalse(actor, xhitemid2, falselv, fylv)
        end
        sendmsg(actor, 9, "赋予属性失败!当前装备赋予等级：" .. falselv)
        nextlv = falselv
    else
        if useitem2flag then
            nextlv = EquipDuanZao.itemTSSuc(actor, xhitemid2, nextlv, fylv)
        end
        sendmsg(actor, 9, "赋予属性成功!当前装备赋予等级：" .. nextlv)
    end

    -- 修改装备标记值
    changeitemaddvalue(actor, -1, 1, "=", nextlv)

    -- 属性刷新
    if qhlv > 5 then
        changecustomitemtext(actor, -1, 1, "[赋予：" .. nextlv .. "+" .. eqfylv .. "阶段]")
    else
        changecustomitemtext(actor, -1, 1, "[赋予：" .. nextlv .. "阶段]")
    end

    if nextlv + eqfylv > 0 then
        local value = EquipFYTab[posindex]['attrList'][attridindex][nextlv + eqfylv]
        changecustomitemabil(actor, -1, 1, 1, attrid, value)
    else
        clearcustomitemabil(actor, -1, 1)
    end

    updateitemtoclient(actor, -1)
    Message.sendmsgEx(actor, "EquipDuanZao", "UpdataFY", { param1 = 1, param2 = nextlv })
end

-- 合成
function EquipDuanZao.hecheng(actor, data)
    local equipmakeIndex = tostring(data[4])
    local xhitemid = tonumber(data[1])
    local xhitemid2 = tonumber(data[2])
    local xhitemid3 = tonumber(data[3]) or 0
    local xhitem3makeIndex = tostring(data[5])
    local gxybxh = tonumber(data[6])
    if equipmakeIndex == "0" then
        return
    end
    if xhitem3makeIndex == "0" then
        sendmsg(actor, 9, "请选择合成石道具！")
        return
    end
    linkitembymakeindex(actor, xhitem3makeIndex)
    local hcattrid = custitemattinfo(actor, "-1_0_1_ID")  --合成石属性id
    local hcattrvalue = custitemattinfo(actor, "-1_0_1_VALUE")  --合成石属性id
    linkitembymakeindex(actor, equipmakeIndex)
    local itemid = linkitem(actor, "INDEX")
    local stdmode = linkitem(actor, "STDMODE")
    local posindex = equippos2[stdmode]
    local qhlv = linkitem(actor, "INTVALUE0")
    local hclv = linkitem(actor, "INTVALUE2")  --已镶嵌合成石数量
    local nextlv = hclv+1
    local hccnum = ItemEquip[itemid]['SyntheticStone'] or 0
    if nextlv > hccnum then
        sendmsg(actor, 9, "已达到当前装备合成槽上限！")
        return
    end

    local equipLv = getEquipLvById(itemid)
    if not EquipQHItemTab[xhitemid3] then
        sendmsg(actor, 9, "请选择合成石道具！")
        return
    end

    --增加等级限制
    local minLv = EquipQHItemTab[xhitemid3]['equipMinLv'] or 0
    local maxLv = EquipQHItemTab[xhitemid3]['equipMaxLv'] or 999

    -- 检查装备等级是否满足合成石要求
    if minLv and equipLv < minLv then
        sendmsg(actor, 9, string.format("装备等级不足！需要%d级装备", minLv))
        return
    end
    if maxLv and equipLv > maxLv then
        sendmsg(actor, 9, string.format("装备等级过高！需要%d级以下装备", maxLv))
        return
    end

    local sum = math.random(1,10000)
    local basesuc = EquipHCTab[posindex]['EquipHCRatio_arr'][nextlv]
    local hcAttrVal = abil(actor, 164) or 0
    if hcAttrVal > 0 then
        basesuc = basesuc + math.floor(basesuc*hcAttrVal/10000)
    end
    if gxybxh == 1 then
        local ybnum = getItemNum(actor,"元宝")
        local needyb = EquipHCTab[posindex]['addsucc_arr'][1]
        if ybnum < needyb then
            sendmsg(actor, 9, "元宝不足！！")
            return
        end
        delItemNum(actor,"元宝",needyb)
        basesuc = basesuc+EquipHCTab[posindex]['addsucc_arr'][2]
    end
    delitembymakeindex(actor, xhitem3makeIndex)
    if EquipQHItemTab[xhitemid] then   --幸运符道具
        local minlv,maxlv = EquipQHItemTab[xhitemid]['level_arr'][1],EquipQHItemTab[xhitemid]['level_arr'][2]
        if hclv >= minlv and hclv <= maxlv then
            delItemNum(actor,xhitemid,1)
            if EquipQHItemTab[xhitemid]['addsuccess'] then
                basesuc = basesuc+EquipQHItemTab[xhitemid]['addsuccess']*100
            end
        end
    end
    if sum > basesuc then
        sendmsg(actor, 9, "镶嵌合成石失败！")
        --sendmymsg(actor, 10015, 0, 0, 0, "" )
        Message.sendmsgEx(actor, "EquipDuanZao","UpdataHC",{param1=0})
        return
    else
        sendmsg(actor, 9, "镶嵌合成石成功！")
    end
    changecustomitemtext(actor, -1, 2, "[合成石]")

    changeitemaddvalue(actor, -1, 2, "=", nextlv)  --已镶嵌数

    --强化等级 提升合成
    local addValue = 0     -- 数值加成
    if qhlv > 6 then
        if hclv < 2 then --第一或第二个合成石
            addValue = qhlv - 6
        else
            addValue = qhlv - 7
        end
    end
    if addValue > 0 and ConstCfg.isPercentAttr[hcattrid] then
        addValue = addValue * 100 --万分比
    end
    changecustomitemabil(actor, -1, 2, hclv, hcattrid, hcattrvalue+addValue)
    changeitemaddvalue(actor, -1, 3+hclv, "=", hcattrvalue) --存储合成石基础属性
    updateitemtoclient(actor,-1)  -- 将修改后的属性刷新到客户端
    
    if nextlv == hccnum then
        Message.sendmsgEx(actor, "EquipDuanZao","UpdataHC",{param1=1})
    else
        Message.sendmsgEx(actor, "EquipDuanZao","UpdataHC",{param1=0})
    end
    
end

-- 强化转移功能
-- @param actor 玩家对象
-- @param data 参数表 [源装备makeIndex, 目标装备makeIndex, 是否在背包中]
function EquipDuanZao.transfer(actor, data)
    local sourceMakeIndex = tostring(data[1])
    local targetMakeIndex = tostring(data[2])
    
    if sourceMakeIndex == "0" or targetMakeIndex == "0" then
        sendmsg(actor, 9, "请选择源装备和目标装备！")
        return
    end
    
    if sourceMakeIndex == targetMakeIndex then
        sendmsg(actor, 9, "源装备和目标装备不能相同！")
        return
    end
    
    -- 获取源装备信息
    linkitembymakeindex(actor, sourceMakeIndex)
    local sourceStdMode = linkitem(actor, "STDMODE")
    local sourceQhLv = linkitem(actor, "INTVALUE0")
    local sourceItemId = linkitem(actor, "INDEX")
    
    -- 获取目标装备信息
    linkitembymakeindex(actor, targetMakeIndex)
    local targetStdMode = linkitem(actor, "STDMODE")
    local targetQhLv = linkitem(actor, "INTVALUE0")
    local targetItemId = linkitem(actor, "INDEX")
    
    -- 检查装备类型是否相同
    if sourceStdMode ~= targetStdMode then
        sendmsg(actor, 9, "源装备和目标装备类型不一致！")
        return
    end
    
    -- 检查源装备是否有强化等级
    if sourceQhLv < 1 then
        sendmsg(actor, 9, "源装备没有强化等级！")
        return
    end
    
    -- 检查目标装备强化等级是否已满（固定上限15级）
    if targetQhLv >= 15 then
        sendmsg(actor, 9, "目标装备强化等级已达到上限！")
        return
    end
    if sourceQhLv <= targetQhLv then
        sendmsg(actor, 9, "源装备强化等级低，无需转移！")
        return
    end
    
    -- 检查消耗材料（固定5个强化石，物品ID:143）
    local costItem = 143  -- 强化石物品ID
    local costItemNum = 5 -- 固定消耗5个
    if getItemNum(actor, costItem) < costItemNum then
        sendmsg(actor, 9, "强化石数量不足！需要5个强化石")
        return
    end
    
    -- 计算转移后的等级（固定100%保留）
    local transferLevel = sourceQhLv  -- 100%保留源装备等级
    if transferLevel < 1 then
        transferLevel = 1
    end
    
    -- 检查是否超过目标装备上限（15级）
    if transferLevel > 15 then
        transferLevel = 15
    end
    
    -- 固定100%成功率，无需随机检查
    
    -- 消耗材料（5个强化石）
    delItemNum(actor, costItem, costItemNum)
    
    -- 转移强化等级    
    -- 2. 目标装备获得转移的强化等级
    linkitembymakeindex(actor, targetMakeIndex)
    changeitemaddvalue(actor, -1, 0, "=", transferLevel)
    if transferLevel > 5 then        
        EquipDuanZao.updateEquipAttrsByQHLv(actor, targetMakeIndex, transferLevel)
    end

    -- 3. 更新目标装备属性
    local posindex = equippos2[targetStdMode]
    local qhTabIndex = ItemEquip[targetItemId]['EquipQHTabId']
    local curQHTabData = EquipQHTab[posindex]
    if qhTabIndex then
        curQHTabData = EquipQHTab[qhTabIndex]
    end
    
    -- 清除目标装备原有强化属性
    clearcustomitemabil(actor, -1, 0)
    
    -- 添加新的强化属性
    if transferLevel > 0 then
        changecustomitemtext(actor, -1, 0, "[强化]")
        if type(curQHTabData['attridList'][transferLevel]) == "number" then
            changecustomitemabil(actor, -1, 0, 1, curQHTabData['attridList'][transferLevel], curQHTabData['attrList'][transferLevel])
        else
            for i = 1, #curQHTabData['attridList'][transferLevel] do
                changecustomitemabil(actor, -1, 0, i, curQHTabData['attridList'][transferLevel][i], curQHTabData['attrList'][transferLevel][i])
            end
        end
    end
    -- 更新客户端显示
    updateitemtoclient(actor, -1)



    -- 更新源装备属性以及强化等级（清空后）
    linkitembymakeindex(actor, sourceMakeIndex)
    changeitemaddvalue(actor, -1, 0, "=", 0)
    clearcustomitemabil(actor, -1, 0)
    changecustomitemtext(actor, -1, 0, "")
    if transferLevel > 5 then        
        EquipDuanZao.updateEquipAttrsByQHLv(actor, sourceMakeIndex, 0)
    end
    
    -- 更新客户端显示
    updateitemtoclient(actor, -1)
    
    -- 发送成功消息
    sendmsg(actor, 9, string.format("强化转移成功！源装备强化等级清空，目标装备获得+%d强化", transferLevel))
    
    -- 通知客户端更新
    Message.sendmsgEx(actor, "EquipDuanZao", "UpdataTransfer", { 
        param1 = 1, 
        param2 = transferLevel,
        param3 = 0  -- 源装备固定清0
    })
    
    local targetEquipObj = itemobjbymakeindex(actor, targetMakeIndex)
    EquipDuanZao.showWeaponEffect(actor, targetEquipObj)
end


-- 提升类道具：成功后效果
function EquipDuanZao.itemTSSuc(actor, xhitemid2, nextlv, qhlv)
    if EquipQHItemTab[xhitemid2]['addlvmin'] then
        local addminlv = EquipQHItemTab[xhitemid2]['addlvmin']
        local addmaxlv = addminlv
        if EquipQHItemTab[xhitemid2]['addlvmax'] then
            addmaxlv = EquipQHItemTab[xhitemid2]['addlvmax']
        end
        nextlv = qhlv + math.random(addminlv, addmaxlv)
    end
    return nextlv
end

-- 提升类道具：失败后效果
function EquipDuanZao.itemTSfalse(actor, xhitemid2, falselv, qhlv)
    if EquipQHItemTab[xhitemid2]['dellv'] then
        if EquipQHItemTab[xhitemid2]['dellv'] > 0 then
            falselv = EquipQHItemTab[xhitemid2]['dellv']
        elseif EquipQHItemTab[xhitemid2]['dellv'] <= 0 then
            falselv = qhlv + EquipQHItemTab[xhitemid2]['dellv']
        end
    end
    if EquipQHItemTab[xhitemid2]['limitlv'] then
        falselv = EquipQHItemTab[xhitemid2]['limitlv']
    end
    return falselv
end

-- 武器强化特效展示
function EquipDuanZao.showWeaponEffect(actor, itemObj)
    local stdmode = tonumber(getiteminfo(itemObj, "STDMODE"))
	if stdmode == 5 then -- 武器才有强化特效
        -- 获取强化等级
		local qhlv = tonumber(getiteminfo(itemObj, "INTVALUE0"))
        local job = job(actor)                              -- 职业   1 弓手 ,2 枪客, 3 刺客,4 医生,5 刀客,6 剑客
        local index = 0    -- 当前强化等级激活特效外观索引
        for i = 1 , #EquipQHEffectShow do
            if qhlv >= EquipQHEffectShow[i]['UpgradeLv'] then
                index = i
            else
                break
            end
        end
        -- 重置特效 10左手 11右手
        changescriptappear(actor, 10, 0)
        changescriptappear(actor, 11, 0)
        -- 检查是否有激活特效
        if EquipQHEffectShow[index] then
            if job == 1 then  -- 弓箭手特效设置 左手
                local effectid = EquipQHEffectShow[index]['Arch_Effect']
                changescriptappear(actor, 11, effectid)
            elseif job == 2 then  -- 枪客特效设置 右手
                local effectid = EquipQHEffectShow[index]['Spear_Effect']
                changescriptappear(actor, 11, effectid)
            elseif job == 3 then  -- 刺客特效设置 双手
                local effectid = EquipQHEffectShow[index]['Assassin_Effect']
                changescriptappear(actor, 10, effectid)
                changescriptappear(actor, 11, effectid)
            elseif job == 4 then  -- 医生特效设置 右手
                local effectid = EquipQHEffectShow[index]['Doctor_Effect']
                changescriptappear(actor, 11, effectid)
            elseif job == 5 then  -- 刀客特效设置 右手
                local effectid = EquipQHEffectShow[index]['Knife_Effect']
                changescriptappear(actor, 11, effectid)
            elseif job == 6 then  -- 剑客特效设置 右手
                local effectid = EquipQHEffectShow[index]['Sword_Effect']
                changescriptappear(actor, 11, effectid)
            end
        end
	end
end

-- 根据强化等级更新合成石和属性石属性
-- @param actor 玩家对象
-- @param equipmakeIndex 装备makeIndex
-- @param qhlv 强化等级
function EquipDuanZao.updateEquipAttrsByQHLv(actor, equipmakeIndex, qhlv)
    if not equipmakeIndex or equipmakeIndex == "0" then
        return
    end

    linkitembymakeindex(actor, equipmakeIndex)
    local itemid = linkitem(actor, "INDEX")
    local stdmode = linkitem(actor, "STDMODE")
    local posindex = equippos2[stdmode]

    -- 更新属性石属性（INTVALUE1）
    local fylv = linkitem(actor, "INTVALUE1")
    if fylv > 0 then
        -- 获取属性石属性ID
        local attrid = custitemattinfo(actor, "-1_1_1_ID")

        -- 获取赋予阶段等级（eqfylv，即装备强化等级-5）
        local eqfylv = 0
        if qhlv > 5 then
            eqfylv = qhlv - 5
        end
        local finalLv = fylv + eqfylv
        if finalLv > 0 and attrid and attrid > 0 then
            local attrLvList = EquipFYTab[posindex]['attrList']
            if attrLvList then
                -- 根据attrid找到对应的索引
                local attridindex = 0
                for i, aid in ipairs(EquipFYTab[posindex]['attrid_arr']) do
                    if aid == attrid then
                        attridindex = i
                        break
                    end
                end

                if attridindex > 0 and attrLvList[attridindex] then
                    -- 确保不超出属性表范围
                    if finalLv > #attrLvList[attridindex] then
                        finalLv = #attrLvList[attridindex]
                    end
                    local value = attrLvList[attridindex][finalLv]
                    changecustomitemabil(actor, -1, 1, 1, attrid, value)
                end
            end
        end
    end

    -- 更新合成石属性（INTVALUE2）
    local hclv = linkitem(actor, "INTVALUE2")
    if hclv > 0 then
        -- 遍历所有已镶嵌的合成石，重新计算属性加成
        for i = 0, hclv - 1 do
            local attrid = custitemattinfo(actor, string.format("-1_2_%d_ID", i))
            local attrBaseValue = linkitem(actor, string.format("INTVALUE%d",3+i))

            if attrid and attrid > 0 and attrBaseValue and attrBaseValue > 0 then
                -- 根据强化等级计算合成石属性加成
                local addValue = 0
                if i < 2 and qhlv > 6 then
                    addValue = qhlv - 6
                end
                if i> 1 and qhlv > 7 then
                    addValue = qhlv - 7
                end

                if addValue > 0 and ConstCfg.isPercentAttr[attrid] then
                    addValue = addValue * 100 --万分比
                end

                changecustomitemabil(actor, -1, 2, i, attrid, attrBaseValue + addValue)
            end
        end
    end
end

-- 事件注册
-- 装备脱下事件
GameEvent.add(EventCfg.onTakeOffEx, function(actor, itemObj, pos, itemname, itemid)
    -- 重置特效 10左手 11右手
    if pos == 0 then
        changescriptappear(actor, 10, 0)
        changescriptappear(actor, 11, 0)
    end
end, EquipDuanZao)
-- 装备穿戴事件
GameEvent.add(EventCfg.onTakeOnEx, function(actor, itemObj, pos, itemname, itemid)
    EquipDuanZao.showWeaponEffect(actor, itemObj)
end, EquipDuanZao)
-- 登录更新
GameEvent.add(EventCfg.onLoginEnd, function (actor)
    local itemobj = bodyiteminfo(actor, '0_OBJ') or 0
    if itemobj > 0 then
        EquipDuanZao.showWeaponEffect(actor, itemobj)
    end
end, EquipDuanZao)

Message.RegisterNetMsg(ssrNetMsgCfg.EquipDuanZao, EquipDuanZao)

return EquipDuanZao