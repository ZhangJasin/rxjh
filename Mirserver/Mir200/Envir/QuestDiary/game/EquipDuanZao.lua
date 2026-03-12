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
local equippos2 = { [5]=1, [3]=2, [8]=3, [9]=4, [51]=5, [15]=6, [19]=7, [22]=8 ,[53]=9}


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
    
    -- 强化等级上限判断  强化15级以上或者加工装备失败
    if qhlv >= 15 or posindex > 5 then
        falselv = -1 -- 装备损坏
    end
    local itemid = linkitem(actor, "INDEX")
    local qhTabIndex = ItemEquip[itemid]['EquipQHTabId']
    local curQHTabData = EquipQHTab[posindex]
    if qhTabIndex then
        curQHTabData = EquipQHTab[qhTabIndex]
    end
    if nextlv > #curQHTabData['attridList'] then
        sendmsg(actor, 9, "已达到当前强化等级上限！")
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
            sendmsg(actor, 9, "强化失败!装备已损坏！")
            Message.sendmsgEx(actor, "EquipDuanZao", "UpdataQH", { param1 = 0, param2 = 0 })
            return
        else
            sendmsg(actor, 9, "强化失败!当前装备强化等级：" .. falselv)
            nextlv = falselv
        end
    else
        if useitem2flag then
            nextlv = EquipDuanZao.itemTSSuc(actor, xhitemid2, nextlv, qhlv)
        end
        sendmsg(actor, 9, "强化成功!当前装备强化等级：" .. nextlv)
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
    -- print("equipObj", equipObj)
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
    local eqfylv = (qhlv - 20) > 0 and (qhlv - 20) or 0
    local fylv = linkitem(actor, "INTVALUE1")
    local nextlv = fylv + 1
    local falselv = 0

    -- 强化等级上限判断
    if nextlv > #EquipFYTab[posindex]['sucjl_arr'] - 5 then
        sendmsg(actor, 9, "已达到当前强化等级上限！")
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
    if qhlv > 20 then
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
    local hclv = linkitem(actor, "INTVALUE2")  --已镶嵌合成石数量
    local nextlv = hclv+1
    local hccnum = ItemEquip[itemid]['SyntheticStone'] or 0
    if nextlv > hccnum then
        sendmsg(actor, 9, "已达到当前装备合成槽上限！")
        return
    end
    --xhitemid3 = 2013
    if not EquipQHItemTab[xhitemid3] then
        sendmsg(actor, 9, "请选择合成石道具！")
        return
    end
    local sum = math.random(1,10000)
    local basesuc = EquipHCTab[posindex]['EquipHCRatio_arr'][nextlv]
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
    --nextlv = 16
    changecustomitemtext(actor, -1, 2, "[合成石]")

    changeitemaddvalue(actor, -1, 2, "=", nextlv)  --已镶嵌数

    changecustomitemabil(actor, -1, 2, hclv, hcattrid, hcattrvalue)
    updateitemtoclient(actor,-1)  -- 将修改后的属性刷新到客户端

    --sendmymsg(actor, 10015, 1, 0, 0, "" )
    if nextlv == hccnum then
        Message.sendmsgEx(actor, "EquipDuanZao","UpdataHC",{param1=1})
    else
        Message.sendmsgEx(actor, "EquipDuanZao","UpdataHC",{param1=0})
    end
    
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