-- QF入口文件 当m2启动时候就会加载
math.randomseed(tostring(os.time()):reverse():sub(1, 7))
local _, errinfo = pcall(function()
    requireex("Envir/SkillFormula/Frame/init.lua")

    require("Envir/3rd/log/Logger.lua")
    require("Envir/Extension/LuaLibrary/string.lua")
    require("Envir/Extension/LuaLibrary/table.lua")

    --三方库
    -- json = cjson

    --扩展
    require("Envir/Extension/Utilserver/Player.lua")
    --配置
    require("Envir/QuestDiary/config/VarCfg.lua")
    require("Envir/QuestDiary/config/EventCfg.lua")
    require("Envir/QuestDiary/config/ConstCfg.lua")
    require("Envir/QuestDiary/config/ModuleCfg.lua")

    --网络
    ssrNetMsgCfg = require("Envir/QuestDiary/net/NetMsgCfg.lua")
    require("Envir/QuestDiary/net/Message.lua")

    -- --通用模块
    require("Envir/QuestDiary/util/util.lua")
    require("Envir/QuestDiary/util/GameEvent.lua")

    --配置

    enterbag          = require("Envir/QuestDiary/game_config/cfgcsv/enterbag.lua")
    LevelUpReward_cfg = require("Envir/QuestDiary/game_config/cfgcsv/LevelUpReward.lua")
    SysConstant       = require("Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")
    SpiritualBeast    = require("Envir/QuestDiary/game_config/cfgcsv/SpiritualBeast.lua")
    Task_cfg          = require("Envir/QuestDiary/game_config/cfgcsv/Task.lua")
    AttScore_cfg      = require("Envir/QuestDiary/game_config/AttScore.lua")
    Monster_cfg       = require("Envir/QuestDiary/game_config/Monster.lua")
    GameData_cfg      = require("Envir/QuestDiary/game_config/GameData.lua")
    guild_level_data  = require("Envir/QuestDiary/game_config/cfgcsv/guild_level_data.lua") -- 行会等级数据
    Class             = require("Envir/QuestDiary/game_config/Class.lua")
    Recycle_cfg       = require("Envir/QuestDiary/game_config/Recycle.lua")
    Transfer_cfg      = require("Envir/QuestDiary/game_config/Transfer.lua")       --人物转职信息
    TransferInfo      = require("Envir/QuestDiary/game/transfer/TransferInfo.lua") --人物转职信息(新)
    Item_cfg          = require("Envir/QuestDiary/game_config/Item.lua")
    ItemEquip_cfg     = require("Envir/QuestDiary/game_config/ItemEquip.lua")
    itemReplace       = require("Envir/QuestDiary/game/itemReplace.lua") -- 物品替换

    ----初始化个人模块
    require("Envir/QuestDiary/game/init.lua")
end)
-- local mountlist = require("Envir/QuestDiary/game/mountMain.lua")
if errinfo then print("初始化QFunction-0.lua", errinfo) end

---setrefdata 接口  id： 1已用作正邪正邪阵营改变   2已用作红蓝阵营改变


-- 引擎启动
function startup()
    GameEvent.push(EventCfg.onStartUp)
end

--登录
function login(actor)
    -- print("登录", actor)
    -- 第一次登录
    local isnewhuman = gethumvar(actor, VarCfg.U_player_login)
    -- LOGPrint("登录", actor, isnewhuman,type(actor))
    -- print("isnewhuman", isnewhuman, type(isnewhuman))
    if isnewhuman == 0 then
        sethumvar(actor, VarCfg.U_player_login, 1)
        GameEvent.push(EventCfg.onNewHuman, actor)
        --初始化背包回收勾选
        local allCheckBox = {}
        for i = 1, #Recycle_cfg do
            allCheckBox[Recycle_cfg[i].Name] = Recycle_cfg[i].Default
        end
        sethumvar(actor, VarCfg.T_AUTO_SELL_IDS, tbl2json(allCheckBox))
        setbagcell(actor, "=", 150)
    end
    -- 自动拾取
    local autoPick = gethumvar(actor, VarCfg.U_AutoPick)
    if autoPick == 1 then
        pickupitems(actor, autoPick, 5, 500, 999)
    end
    --坐骑总属性
    if gethumvar(actor, VarCfg.U_Mount_IS_SET) == 1 then
        mountMain.addsx(actor)
        --上次是否出战
        if gethumvar(actor, VarCfg.U_Mount_Status) == 1 then
            --setscriptabilvalue(actor, 9, "=", scriptabil(actor, 9) + 5000)
            changeappear(actor, 5, gethumvar(actor, VarCfg.U_Mount_Take_Id))
        end
    end
    --宠物
    -- print (gethumvar(actor,VarCfg.U_PETS_Take_Base),type(gethumvar(actor,VarCfg.U_PETS_Take_Base)),gethumvar(actor,VarCfg.U_PETS_Take_Base)>0)
    local ptb = gethumvar(actor, VarCfg.U_PETS_Take_Base) or 0
    if ptb > 0 then
        -- print("召唤宠物")
        local btid = gethumvar(actor, VarCfg.U_PETS_Take_Base)
        mountMain.recallpet(actor, { btid = btid }, nil, 1)
    end
    -- 登录
    GameEvent.push(EventCfg.onLogin, actor)

    -- 登录附加属性
    local loginattrs = {}
    GameEvent.push(EventCfg.onLoginAttr, actor, loginattrs)
    -- dump(loginattrs)
    Player.updateAddr(actor, loginattrs)


    -- 当前血量
    recalcabilitys(actor)
    local curhp = gethumvar(actor, VarCfg.U_OffLine_Hp) or 0
    local maxhp = abil(actor, 1)
    if curhp > maxhp or curhp == 0 then
        changeabil(actor, 1, "=", maxhp)
    else
        changeabil(actor, 1, "=", curhp)
    end
    local curMp = gethumvar(actor, VarCfg.U_OffLine_Mp) or 0
    local maxMp = abil(actor, 2)
    if curMp > maxMp then
        changeabil(actor, 2, "=", maxMp)
    else
        changeabil(actor, 2, "=", curMp)
    end
    -- 新号上限满血满蓝
    if isnewhuman == 0 then
        changeabil(actor, 2, "=", maxhp)
        changeabil(actor, 2, "=", maxMp)
    end

    if gethumvar(actor, "U47") > 0 then
        addtimerex(actor, 47, 1000, gethumvar(actor, "U47"), "@ontimer47", "")
    end
    if gethumvar(actor, "U48") > 0 then
        addtimerex(actor, 48, 1000, gethumvar(actor, "U48"), "@ontimer48", "")
    end

    -- 登录重置变量
    sethumvar(player, VarCfg.U_lastAttackTime, 0)

    -- 登录设置任务杀怪爆率倍数
    -- local burstrate = abil(actor, 77)  -- 获取属性ID 77的值
    -- killmonburstrate(actor, 100+math.floor(burstrate/100), 3600*24*30)

    -- 判断是否开启跨服
    if kuafuconnected() then -- 跨服连接中
        sethumvar(actor, VarCfg.U_IsKuaFu_State, 1)
    else
        sethumvar(actor, VarCfg.U_IsKuaFu_State, 0)
    end
end

--每天第一次登录
function setday(actor)
    -- print("每天第一次登录")
end

---跨天登录触发
function resetday(actor)
    -- print("跨天登录触发")

    GameEvent.push(EventCfg.onResetday, actor)
end

--所有发送给服务端的网络消息触发
function handlerequest(actor, msgid, arg1, arg2, arg3, sMsg)
    -- print("msgid="..msgid)
    if msgid == ssrNetMsgCfg.sync then
        login(actor)
        return
    end
    -- 阵营
    if msgid == 9999 then --根据客户端传递消息  2025/8/12
        local Upright = getplayercntbygoodevilid(1, 1)
        local Evil = getplayercntbygoodevilid(2, 1)
        if tonumber(arg1) == 11 then
            settargetinfo(actor, "GOODEVILID", 0)
            GameEvent.push(EventCfg.onClearGoodevolid, actor) --清除阵营
            sethumvar(actor, VarCfg.U_Camp_Type, 0)
            setrefdata(actor, 1, 0)
        elseif tonumber(arg1) == 12 then
            settargetinfo(actor, "GOODEVILID", 1)
            GameEvent.push(EventCfg.onJoinUpright, actor) --加入正派
            sethumvar(actor, VarCfg.U_Camp_Type, 1)
            setrefdata(actor, 1, 1)
        elseif tonumber(arg1) == 13 then
            settargetinfo(actor, "GOODEVILID", 2)
            GameEvent.push(EventCfg.onJoinEvil, actor) --加入邪派
            sethumvar(actor, VarCfg.U_Camp_Type, 2)
            setrefdata(actor, 1, 2)
        elseif tonumber(arg1) == 14 then
            -- 先获取
            local Upright = gethumvar(0, VarCfg.G_Sys_Upright) or 0
            local Evil = gethumvar(0, VarCfg.G_Sys_evil) or 0
            if Upright > Evil then
                settargetinfo(actor, "GOODEVILID", 2)
                GameEvent.push(EventCfg.onJoinEvil, actor) --加入邪派
                sethumvar(actor, VarCfg.U_Camp_Type, 2)
                setrefdata(actor, 1, 2)
            elseif Evil >= Upright then
                settargetinfo(actor, "GOODEVILID", 1)
                GameEvent.push(EventCfg.onJoinUpright, actor) --加入正派
                sethumvar(actor, VarCfg.U_Camp_Type, 1)
                setrefdata(actor, 1, 1)
            end
            if gethumvar(actor, VarCfg.U_Camp_State) == 0 then
                sethumvar(actor, VarCfg.U_Camp_State, 1)
                Player.giveItemByTable(actor, SysConstant['Reward_JoinZhenYing']['Value'], 1) -- 随机阵营奖励
            end
        end
        return
    elseif msgid == 9998 then
        -- 获取阵营 转职
        local faction = targetinfo(actor, "GOODEVILID")
        local relevel = targetinfo(actor, "RELEVEL")
        local sex = gender(actor) + 1 -- 1男2女
        local job = job(actor)        -- 角色职业 1弓手2剑士3弓箭手4骑士5法师6牧师
        -- 转职大于0 更新模型
        if relevel > 0 then
            for k, v in pairs(Transfer_cfg) do
                if v['ClassID'] == job and v['Type'] == faction and v['TransferLV'] == relevel and v['ModeId'] then
                    local body, helmet = v['ModeId'][sex][1], v['ModeId'][sex][2]
                    -- sethumvar(actor,VarCfg.U_Role_RELEVEL_Body,body)
                    sethumvar(actor, VarCfg.U_Role_RELEVEL_helmet, helmet)
                    -- changeappear(actor, 0, body)
                    changeappear(actor, 4, helmet)
                    break
                end
            end
        end
        return
    end
    -- print(type(sMsg))
    -- dump((sMsg))
    local result, errinfo = pcall(Message.dispatch, actor, msgid, arg1, arg2, arg3, sMsg)
    if not result then
        local msgName = ssrNetMsgCfg[msgid]
        local err = "网络消息派发错误：消息ID=" .. msgid .. "  消息Name=" .. msgName .. "   "
        -- print(err)
        -- print(errinfo)
    end
end

-- 获取全服正邪阵营人数触发
function g_playercntforgoodevilid(actor, count, goodEvilid, minLevel)
    -- print("正邪阵营人数：", actor, count, goodEvilid, minLevel)
    if goodEvilid == 1 then
        sethumvar(0, VarCfg.G_Sys_Upright, count)
    elseif goodEvilid == 2 then
        sethumvar(0, VarCfg.G_Sys_evil, count)
    end
end

--机器人脚本每小时触发函数
function runeveryhour(actor)
    GameEvent.push(EventCfg.runEveryHour, actor)
end

function OnSkillCheck(actor, skillid, level)
end

-- 聊天触发
function triggerchat(actor, sMsg, chat, target, time)
    -- if sMsg=='1' then
    --     sendmail(actor, 1, "系统奖励", "你好，这是邮件内容","金疮药（小）#10#3&人参#1#3",6000)
    -- elseif sMsg == '2' then
    --     confertitle(actor, 410001)
    --     confertitle(actor, 410002)
    --     confertitle(actor, 420010)
    -- elseif sMsg == '21' then
    --     seticonid(actor, 0, 11)
    -- elseif sMsg == '22' then
    --     seticonid(actor, 0, 0)
    -- elseif sMsg == '4' then
    --    local t =  json2tbl(gethumvar(actor,VarCfg.T_PetPay_Data)) or {}
    --    for k,v in pairs(t) do
    --         -- print(v.mark,"变量存储宠物mark")
    --    end
    --    local syspetinfo = getpetlist(actor) or {}
    --    for k,v in pairs(syspetinfo) do
    --         -- print(v,"系统获取宠物mark")
    --    end
    -- elseif sMsg == '5' then
    --     local petMark = addpet(actor, 10015)
    --     recallpet(actor, petMark)
    -- elseif string.find(sMsg, "强化") then
    --     local lv = tonumber(string.match(sMsg, "%d+")) or 0
    --     -- print("强化等级", lv)
    --     -- changeitemaddvalue(actor, -1, 0, "=", nextlv)
    --     local itemobj = bodyiteminfo(actor, '0_OBJ') or 0
    --     -- print("强化对象", itemobj)
    --     changeitemaddvalue(actor, itemobj, 0, "=", lv)
    --     updateitemtoclient(actor, itemobj)
    --     local qhlv = tonumber(getiteminfo(itemobj, "INTVALUE0"))
    --     -- print("强化等级", qhlv)
    --     EquipDuanZao.showWeaponEffect(actor, itemobj)
    --     -- print('name', type(bodyiteminfo(actor, '0_OBJ')))
    -- elseif sMsg=='锻造' then
    --     --sendmymsg(actor, 30001, 0, 0, 0, "" )
    --     giveitem(actor, "强化石#999")
    --     giveitem(actor, "木剑1#5")
    --     giveitem(actor, "水月剑1#5")
    --     giveitem(actor, "轩舞龙铠(女)1#5")
    --     giveitem(actor, "金丝甲1#5")
    --     giveitem(actor, "精炼护手1#5")
    --     giveitem(actor, "紫玉戒指1#5")
    --     giveitem(actor, "白玉耳环1#5")
    --     giveitem(actor, "玉影项链1#5")
    --     giveitem(actor, "天尊战靴1#5")
    --     giveitem(actor, "幸运符(5%)#50")
    --     giveitem(actor, "幸运符(10%)#50")
    --     giveitem(actor, "幸运符(15%)#50")
    --     giveitem(actor, "幸运符(20%)#50")
    --     giveitem(actor, "幸运符(25%)#50")
    --     giveitem(actor, "至尊取玉符(强化)【武器】#50")
    --     giveitem(actor, "至尊取玉符(强化)【防具】#50")
    --     giveitem(actor, "水晶符[防具]#50")
    --     giveitem(actor, "取玉符[防具]#50")
    --     giveitem(actor, "初级黄玉符[武器]#50")
    --     giveitem(actor, "水晶符[武器]#50")
    --     giveitem(actor, "取玉符[武器]#50")
    --     giveitem(actor, "初级黄玉符[防具]#50")
    --     giveitem(actor, "金刚守护符#50")
    --     giveitem(actor, "寒玉守护符#50")
    --     giveitem(actor, "守护符-武器#50")
    --     giveitem(actor, "守护符-防具#50")
    --     giveitem(actor, "初级升龙符[武器]#50")
    --     giveitem(actor, "初级升龙符[防具]#50")
    --     giveitem(actor, "中级黄玉符[武器]#50")
    --     giveitem(actor, "高级黄玉符[武器]#50")
    --     giveitem(actor, "中级黄玉符[防具]#50")
    --     giveitem(actor, "高级黄玉符[防具]#50")
    --     giveitem(actor, "初级水晶符[首饰]#50")
    --     giveitem(actor, "守护符[首饰]#50")
    --     giveitem(actor, "取玉符[首饰]#50")
    --     giveitem(actor, "水晶符[首饰]#50")
    --     giveitem(actor, "属性石(外)#50")
    --     giveitem(actor, "属性石(内)#50")
    --     giveitem(actor, "属性石(火)#50")
    --     giveitem(actor, "属性石(水)#50")
    --     giveitem(actor, "属性石(风)#50")
    --     giveitem(actor, "属性石(毒)#50")
    --     giveitem(actor, "属性水晶符(武器)#5")
    --     giveitem(actor, "属性取玉符(武器)#5")
    --     giveitem(actor, "属性水晶符(衣服)#5")
    --     giveitem(actor, "属性取玉符(衣服)#5")
    -- elseif sMsg=='打造' then
    --     giveitem(actor, "炼铁#999")
    --     giveitem(actor, "绢#888")
    --     giveitem(actor, "高级皮革#777")
    -- elseif sMsg=='回收' then
    --     giveitem(actor, "直刀1#1")
    --     giveitem(actor, "渤海刀1#1")
    --     giveitem(actor, "半月刀1#1")
    --     giveitem(actor, "木枪1#1")

    --     giveitem(actor, "浩天护手1#1")
    --     giveitem(actor, "皮护手1#1")
    --     giveitem(actor, "魔灵长靴4#1")
    --     giveitem(actor, "无名短靴1#1")
    --     giveitem(actor, "麒麟指环1#1")
    -- end

    local level = level(actor)
    if level < 10 then
        sendmsg(actor, 9, "等级达到10级即可发言")
        return false
    end
    GameEvent.push(EventCfg.onTriggerChat, actor, sMsg, chat, target)
    return true
end

-- 货币改变时触发 玩家对象ID 货币道具表ID 改变前数量
function moneychange(actor, moneyID, lastCount)
    --print("moneyID="..moneyID)
    if moneyID == 19 then -- 气功点
        GameEvent.push(EventCfg.onChangeQGD, actor, moneyID, lastCount)
    else
        GameEvent.push(EventCfg.onChangeMoney, actor, moneyID, lastCount)
    end
end

function clicknpc(actor, npcid)
    GameEvent.push(EventCfg.onClicknpc, actor, npcid)
end

local _NoTakePos = { -- 禁止脱下位
    [13] = 1,        -- 披风
    [26] = 1,        -- 幻武
    [25] = 1,        -- 头饰
}
--人物脱下任意装备触发
function takeoffex(actor, itemObj, pos, itemname, itemid)
    GameEvent.push(EventCfg.onTakeOffEx, actor, itemObj, pos, itemname, itemid)
end

--人物脱下任意装备触发
function takeoffbeforeex(actor, itemObj, pos)
    if _NoTakePos[pos] then
        -- sendmsg(actor, 9, "禁止脱下")
        return false
    end
    GameEvent.push(EventCfg.onTakebeforeex, actor, itemObj, pos)
end

--人物穿装备触发
function takeonex(actor, itemObj, pos, itemname, itemid)
    GameEvent.push(EventCfg.onTakeOnEx, actor, itemObj, pos, itemname, itemid)
end

-- 穿戴任意装备前触发
function takeonbeforeex(actor, itemObj, pos)
    local flag = wuxun.WuXunEquipCanTakeon(actor, itemObj, pos)
    if not flag then
        return false
    end
    GameEvent.push(EventCfg.onTakeonbeforeex, actor, itemObj, pos)
end

--物品进背包触发
function addbag(actor, itemObj, itemid, count)
    --enterbag
    GameEvent.push(EventCfg.onAddBag, actor, itemObj, itemid, count)
    if gethumvar(actor, VarCfg.U_AutoSell) == 1 and gethumvar(actor, VarCfg.U_AutoFilterByLv) == 1 then
        recycleEnterBag(actor, itemid, itemObj, count)
    end
end

--物品进背包前触发
function beforeaddbag(actor, itemObj, itemid, count)
    --神秘热血石进包处理
    if itemid == 3917 or itemid == 3963 then
        local newItemId, newCount = itemReplace.getRandomItem(itemid)
        if newItemId and newCount then
            delitembymakeindex(actor, getiteminfo(itemObj, "MAKEINDEX"))
            giveitem(actor, newItemId .. "#" .. newCount)
            return false
        end
    end

    if enterbag[itemid] then
        local jdattrid = custitemattinfo(actor, itemObj .. "_0_1_ID") or 0
        if jdattrid == 0 then
            local sum = math.random(1, enterbag[itemid]['RatioAll'])
            local index, num = 1, 0
            for i = 1, #enterbag[itemid]['AttScoreRatio_arr'] do
                num = num + enterbag[itemid]['AttScoreRatio_arr'][i]
                if sum <= num then
                    index = i
                    break
                end
            end
            local value = math.random(enterbag[itemid]['AttScoreStageList'][index][1],
                enterbag[itemid]['AttScoreStageList'][index][2])

            local attrid = enterbag[itemid]['attrid']
            if ConstCfg.isPercentAttr[attrid] then
                value = value * 100 --万分比属性 需X100
            end
            changecustomitemtext(actor, itemObj, 0, "[鉴定属性]")
            changecustomitemabil(actor, itemObj, 0, 1, attrid, value)
            updateitemtoclient(actor, itemObj) -- 将修改后的属性刷新到客户端
        end
    end
    GameEvent.push(EventCfg.onBeforeAddBag, actor, itemObj, itemid, count)
end

--创建队伍前触发
function startgroup(actor)
    GameEvent.push(EventCfg.onStartGroup, actor)
end

--创建队伍触发
function groupcreate(actor, roleName)
    GameEvent.push(EventCfg.onGroupCreate, actor, roleName)
end

--离开队伍前触发 	
function exitmygroup(actor)
    GameEvent.push(EventCfg.onStartGroup, actor)
end

--创建队伍触发
function groupcreate(actor, roleName)
    GameEvent.push(EventCfg.onGroupCreate, actor, roleName)
end

--离开队伍前触发 	
function exitmygroup(actor)
    GameEvent.push(EventCfg.onExitMyGroup, actor)
end

--离开队伍时触发 	
function leavegroup(actor)
    GameEvent.push(EventCfg.onLeaveGroup, actor)
end

--踢出队伍前触发  actor 队长玩家对象ID 被踢玩家名字
function groupdelmember(actor, targetName)
    GameEvent.push(EventCfg.onGroupDelMember, actor, targetName)
end

--邀请组队前触发  target 被邀请玩家对象ID
function invitegroup(actor, target)
    GameEvent.push(EventCfg.onInviteGroup, actor, target)
end

--申请加入队伍前触发
function groupuseraddmember(actor, target)
    GameEvent.push(EventCfg.onGroupUserAddMember, actor, target)
end

--加入队伍触发 添加组队成员触发 	targetName 被邀请的玩家名字
function groupaddmember(actor, targetName)
    GameEvent.push(EventCfg.onGroupAddMember, actor, targetName)
end

--组队杀怪触发
function groupkillmon(actor)
    GameEvent.push(EventCfg.onGroupKillMon, actor)
end

-- 穿戴称号触发
function clienttakontitle(actor, titleId)
    activetitle(actor, titleId)
    -- 称号显示与显示位置需要自己调整
    -- seticonid  设置称号显示
end

-- 脱下称号触发
function clienttakofftitle(actor, titleId)
    unactivetitle(actor, titleId)
end

-- 人物属性改变时触发 attrid变化的属性ID
function abilchange(actor, param)
    -- 保留原有的全局事件推送（如果需要）
    GameEvent.push(EventCfg.onAttrChange, actor, param)
end

-- 气功等级属性改变触发  AttScore表添加
function qigongattr(actor, attrid, curvalue)
    local qiId = ConstCfg.QiGongExtAttr[attrid]
    if qiId then
        local qigongtab = getallqigong(actor, 2) -- 获取所有气功 面板学习的等级
        if attrid == 126 then
            for i, v in pairs(qigongtab) do
                if v > 0 then
                    local qigonglevelAttr = curvalue
                    local qiAttrId = ConstCfg.QiGongAttrId[i]
                    if qiAttrId then
                        qigonglevelAttr = qigonglevelAttr + (abil(actor, qiAttrId) or 0)
                    end
                    updateqigong(actor, i, qigonglevelAttr, "=", 1) -- 脚本加气功等级
                else
                    updateqigong(actor, i, 0, "=", 1)               -- 脚本加气功等级
                end
            end
        else
            local qigonglevelAttr = curvalue + (abil(actor, 126) or 0)
            local currentLv = qigongtab[qiId] or 0
            if currentLv > 0 then
                updateqigong(actor, qiId, qigonglevelAttr, "=", 1) -- 脚本加气功等级
            end
        end
    end
end

-- 气功重置后触发
function resetqigong(actor, id, lv)
    updateqigong(actor, id, 0, "=", 1) -- 脚本加气功ID
end

-- 客户端操作气功修炼成功触发
function clientupqigongsuccess(actor, qiId, maxlv, clientLv, scripLv, equipLv)
    local qigonglevelAttr = abil(actor, 126) -- 获取属性ID 126的值
    local qiAttrId = ConstCfg.QiGongAttrId[qiId]
    if qiAttrId then
        qigonglevelAttr = qigonglevelAttr + (abil(actor, qiAttrId) or 0)
    end
    if qigonglevelAttr > 0 then
        updateqigong(actor, qiId, qigonglevelAttr, "=", 1) -- 脚本加气功等级
    end
end

-- 人物复活前触发
function revival(actor)
end

-- 人物死亡触发
function die(actor, target)
    local killname = username(target)
    local mapname = targetinfo(actor, "MAPTITLE") --当前地图id
    sendmail(actor, 1, "死亡邮件", "您在【" .. mapname .. "】被【" .. killname .. "】击杀。", "", 36000)

    -- 死亡重置变量
    sethumvar(actor, VarCfg.U_lastAttackTime, 0)
    GameEvent.push(EventCfg.onPlayDie, actor, target)
end

--人物死亡装备掉落前触发 支持return命令中止
function checkdropuseitems(actor, pos, itemid)
    GameEvent.push(EventCfg.onCheckDropuseItems, actor, pos, itemid)
end

-- 杀死怪物触发 玩家对象ID 怪物唯一ID
function m_die(mon, attack)
    -- addmondrop(mon,"1010#5|1011#12")
    local attackType = tonumber(targetinfo(attack, "race")) -- 对象类型(0=玩家 1=怪物 2=BB 3=NPC 4=虚拟体)
    local mapid = targetinfo(mon, "NEWMAP")

    if not mapid then return end

    if attackType == 2 or attackType == 4 then
        -- 主人id
        attack = targetinfo(attack, "MASTERID")
    end
    if not attack then
        -- LOGPrint("no attack")
        return
    end

    -- 获取当前时间戳（秒）
    local curtime = math.floor(utcint64now() / 1000)

    sethumvar(attack, VarCfg.U_lastMonDieTime, curtime) -- 上次怪物死亡时间

    local monidx = tonumber(targetinfo(mon, "ID"))
    GameEvent.push(EventCfg.onKillMon, attack, mon, mapid, monidx)
end

-- 玩家捡取任意物品前触发
function pickupitemfrontex(actor, itemid, aaaa)
    -- print("玩家捡取任意物品前触发",actor, itemid, aaaa)
    GameEvent.push(EventCfg.onPickUpItemfrontEX, actor, itemid)
end

-- 玩家捡取任意物品后触发
function pickupitemex(actor, itemobj, itemid)
    GameEvent.push(EventCfg.onPickUpItemEX, actor, itemobj, itemid)
end

-- 怪物掉落任意物品前触发
function mondropitemex(actor, itemobj, monid, x, y, itemid)
    GameEvent.push(EventCfg.onMonDropItemEX, actor, itemobj, monid, x, y, itemid)
    return true
end

-- 进入场景地图时触发
function entermap(actor)
    local former_mapid = gethumvar(actor, VarCfg.S_cur_mapid)
    local cur_mapid = targetinfo(actor, "NEWMAP")
    if cur_mapid ~= former_mapid then --切换了地图
        sethumvar(actor, VarCfg.S_cur_mapid, cur_mapid)
        GameEvent.push(EventCfg.goSwitchMap, actor, cur_mapid, former_mapid)
    else
        GameEvent.push(EventCfg.goEnterMap, actor, cur_mapid)
    end
end

-- 离开场景地图时触发
function leavemap(actor)
end

-- 添加任务触发
function picktask(actor, taskid)
    -- print("添加任务触发",actor, taskid)
    GameEvent.push(EventCfg.onAddTask, actor, taskid)
end

-- 点击任务触发
function clicknewtask(actor, taskid)
    GameEvent.push(EventCfg.onTaskClick, actor, taskid)
end

-- 刷新任务触发
function changetask(actor, taskid)
    GameEvent.push(EventCfg.onTaskRe, actor, taskid)
end

-- 完成任务触发
function completetask(actor, taskid)
    GameEvent.push(EventCfg.onTaskFinish, actor, taskid)
end

-- 删除任务触发
function deletetask(actor, taskid)
    GameEvent.push(EventCfg.onTaskDel, actor, taskid)
end

-- 人物获得当前经验触发
function getexp(actor, exp)
    GameEvent.push(EventCfg.onChangeExp, actor, exp)
end

-- 自定义经验触发
function custcalexp(actor, monId, exp)

end

-- 人物升级触发
function playlevelup(actor)
    -- 升级满血满蓝
    changeabil(actor, 1, "=", abil(actor, 1))
    changeabil(actor, 2, "=", abil(actor, 2))
    local before_level = gethumvar(actor, VarCfg.N_cur_level) or 0
    local cur_level = currabil(actor, 0)
    sethumvar(actor, VarCfg.N_cur_level, cur_level)
    sethumvar(actor, VarCfg.N_LS_Level, cur_level)
    savehumvar(actor, VarCfg.N_LS_Level)
    if LevelUpReward_cfg[cur_level] and LevelUpReward_cfg[cur_level]['LevelUpReward'] and cur_level > before_level then
        local job = job(actor)
        local tab = LevelUpReward_cfg[cur_level]['LevelUpReward'][job]
        giveitem(actor, tab[1] .. "#" .. tab[2])
    end
    GameEvent.push(EventCfg.onPlayLevelUp, actor, cur_level, before_level)
end

--上马触发
function horseup(actor)
    local setdata = gethumvar(actor, VarCfg.T_Modul_Change) or ""
    local setdata = json2tbl(setdata) or {}
    if setdata["MountCheckBox"] == 0 then
        return false
    end
    --addbuff(actor, 10000 )  --坐骑加速buff  buff表配置
    return true
end

--下马触发
function horsedown(actor)
    -- print("下马")
    sethumvar(actor, VarCfg.U_Mount_Status, 0)
    --setscriptabilvalue(actor, 9, "=", scriptabil(actor, 9) - 5000)
    Message.sendmsgEx(actor, "mountMain", "updateBtnName", { status = 0 })
end

-- 获得宝宝触发 玩家对象 宝宝唯一ID
function slavebb(actor, bbindex)
end

--宝宝死亡
function b_die(actor, killer)
    local monId = targetinfo(actor, "ID")
    local mastertId = targetinfo(actor, "MASTERID")
    local isPc = clientflag(mastertId) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"

    -- 检查是否是新系统灵兽
    local petBaseId = gethumvar(mastertId, VarCfg.U_Pet_Base_ID)
    local petMark = gethumvar(mastertId, VarCfg.T_Pet_Mark)

    -- 如果是新系统灵兽（通过mark判断是否是当前出战的灵兽）
    if petBaseId and petBaseId > 0 and petMark and petMark ~= "" then
        local petIdx = getpetidx(mastertId, petMark)
        if petIdx and petIdx == actor then
            -- 这是新系统灵兽，设置死亡倒计时
            local dieCd = tonumber(SysConstant['PET_Resurre_CD']['Value']) or 30
            sethumvar(mastertId, VarCfg.U_Pet_Die_Time, dieCd)
            -- 启动定时器
            addtimerex(mastertId, 49, 1000, dieCd, "@ontimer49", "")
            Message.sendmsgEx(mastertId, methodName, "petResurrec", utcint64now())
        end
    end

    GameEvent.push(EventCfg.onFightBBDie, actor)
end

-- 移动触发
function walk(actor)
    GameEvent.push(EventCfg.onWalk, actor)
end

-- 击飞击退前触发 玩家对象ID 目标唯一ID 技能效果ID
function beforepushtaget(actor, target, effectID)
    return true
end

--充值 是用金额区分做封装的，不能有重复金额的订单
--money  充值rmb金额
--id  产品id
--moneyID 货币ID
--type =1真实充值 =0扶持充值
--timestamp 时间戳
function recharge(actor, money, id, moneyID, type, timestamp)

end

-- 创建门派前触发
---@param actor userdata 玩家对象ID
---@param guildName string 门派名称
---@return boolean 是否允许创建
function checkbuildguild(actor, guildName)
    local camp = targetinfo(actor, "GOODEVILID") --(0=无阵营 1=正派 2=邪派)     -- 获取阵营
    if camp == 0 then
        sendmsg(actor, 9, "请先选择阵营")
        return false
    end
    GameEvent.push(EventCfg.onCheckbuildguild, actor, guildName)
    return true
end

---加入门派前触发
---@return boolean 是否允许加入
function guildaddmember(actor, guildId, guildName)
    GameEvent.push(EventCfg.onGuildaddmember, actor, guildId, guildName)
    return true
end

---加入门派触发
function guildaddmemberafter(actor, guildId, guildName)
    GameEvent.push(EventCfg.onGuildaddmemberafter, actor, guildId, guildName)
end

---退出门派前触发
---@param actor userdata 玩家ID
---@param guild userdata 门派ID
---@return boolean 是否允许退出
function guilddelmemberbefore(actor, guild)
    GameEvent.push(EventCfg.onGuilddelmemberbefore, actor, guild)
    return true
end

---退出门派触发
function guilddelmember(actor)
    GameEvent.push(EventCfg.onGuilddelmember, actor)
end

---编辑门派公告前触发
---@param actor userdata 玩家对象ID
---@return boolean 是否允许编辑
function updateguildnotice(actor)
    GameEvent.push(EventCfg.onUpdateguildnotice, actor)
end

--掌门踢出门派成员前触发
---@param actor  userdata   玩家ID
---@param target userdata 	被踢玩家ID
function guildchiefdelmember(actor, target)
    GameEvent.push(EventCfg.onGuildchiefdelmember, actor, target)
end

--解散门派前触发
---@param actor   userdata 玩家ID
---@param guildid userdata 门派ID
---@return boolean 是否允许创建
function guildclosebefore(actor, guildid)
    GameEvent.push(EventCfg.onGuildclosebefore, actor, guildid)
end

--创建门派成功触发
---@param actor      userdata 玩家ID
---@param guildid    userdata 门派ID
---@param guildName userdata 门派名
function createguild(actor, guildid, guildName)
    local guildObj = guildobj(guildid)
    local guildPerple = guild_level_data[1]["maxPreple"] or 50
    setguildinfo(guildObj, 3, guildPerple) -- 设置最大人数
    setguildinfo(guildObj, 7, 1)           -- 设置当前等级
    GameEvent.push(EventCfg.onCreateguild, actor, guildid, guildName)
end

--邀请加入门派前触发
---@param actor      userdata 玩家ID
---@param guildId    userdata 门派ID
---@param guildName  userdata 门派名
---@param targetId   userdata 被邀请对象id
function inivitguild(actor, guildId, guildName, targetId)
    GameEvent.push(EventCfg.onInivitguild, actor, guildId, guildName, targetId)
end

-- 客户端点击门派捐献触发
function guildsetexp(actor, type)
    local allNum = tonumber(SysConstant['DailyNum_SectDonate']["Value"])
    local Donate = gethumvar(actor, VarCfg.U_Donate_Num)
    if Donate >= allNum then
        sendmsg(actor, 9, "今日捐献次数已用完")
        return
    end
    local guildObj = targetinfo(actor, "GUILDOBJID")
    local curexp = getguildinfo(guildObj .. "_" .. 12) or 0
    local curLevel = getguildinfo(guildObj .. "_" .. 13) or 1
    -- if curLevel >= #guild_level_data then
    --     sendmsg(actor, 9, "门派等级已满")
    --     return
    -- end
    local hbid, xhnum, addzj = 0, 0, 0
    if type == 1 then --SysConstant
        hbid = SysConstant['SectDonate_Currency_Num1']["Value"][1]
        xhnum = SysConstant['SectDonate_Currency_Num1']["Value"][2]
        addzj = SysConstant['SectDonate_Currency_Num1']["Value"][3]
    elseif type == 2 then
        hbid = SysConstant['SectDonate_Currency_Num2']["Value"][1]
        xhnum = SysConstant['SectDonate_Currency_Num2']["Value"][2]
        addzj = SysConstant['SectDonate_Currency_Num2']["Value"][3]
    end
    local name, num = Player.checkItemNumByTable(actor, { { hbid, xhnum } })
    if name then
        sendmsg(actor, 9, "" .. name .. "不足")
        return
    end
    Player.takeItemByTable(actor, { { hbid, xhnum } })
    -- 更新玩家门派贡献值
    changemoney(actor, 20, "+", addzj)
    setguildmemberexp(guildObj, actor, '+', addzj)              -- 设置成员贡献值
    curexp = curexp + addzj
    local needexp = guild_level_data[curLevel]["Exp"] or 100    -- 升级需要经验值
    while curexp >= needexp and curLevel < #guild_level_data do -- 满足升级条件
        curLevel = curLevel + 1
        curexp = curexp - needexp
        needexp = guild_level_data[curLevel]["Exp"] or 100 -- 升级需要经验值
    end
    local maxPreple = guild_level_data[curLevel]["maxPreple"] or 50
    setguildexp(guildObj, "=", curexp, actor)
    setguildinfo(guildObj, 3, maxPreple)            -- 设置最大人数
    setguildinfo(guildObj, 6, "=", curLevel, actor) -- 设置当前等级
    Donate = Donate + 1
    sethumvar(actor, VarCfg.U_Donate_Num, Donate)

    Guild.getData(actor)
    GameEvent.push(EventCfg.onGuildsetexp, actor, type, addzj, curLevel, curexp)
end

--双击使用道具前触发 支持stop终止
function beforeeatitem(actor, itemid, itemobj, num, curdura, maxdura)
    --写在event里无法阻止使用道具
    -- print("双击使用道具前触发")
    GameEvent.push(EventCfg.beforeUseItem, actor, itemid, itemobj, num, curdura, maxdura)
end

-- 双击使用时QF触发 支持stop终止
function stdmodefunc(actor, itemid, itemobj, useNumber, param1, param2)
    local sex = gender(actor) + 1 -- 1男2女
    --print("双击使用时QF触发", itemid,itemobj,useNumber,param1,param2)
    local quickflag = quickItem.useItem(actor, itemid, itemobj, useNumber, param1, param2)
    if not quickflag then
        return false
    end
    if itemid == 2418 then --土灵符道具
        local TuLingPosTab = gethumvar(actor, VarCfg.T_TuLingPosTab) or ""
        if TuLingPosTab ~= "" then
            TuLingPosTab = json2tbl(TuLingPosTab)
        else
            TuLingPosTab = {}
        end
        Message.sendmsgEx(actor, "tulingfuPanl", "Open", { param1 = TuLingPosTab })
        return false
    end

    --历练丹
    if itemid == 3984 then
        if getItemNum(actor, itemid) < useNumber then
            return false
        end
        local num = useNumber * 1000
        takeitem(actor, itemid .. "#" .. useNumber)
        giveitem(actor, "7#" .. num)
    end
    if itemid == 4038 then --初级活跃宝箱
        giveitem(actor, string.format("1#%d#%d&143#%d#%d", 50000*useNumber,ConstCfg.binding,2*useNumber,ConstCfg.binding),1)
    end
    if itemid == 4039 then --中级活跃宝箱
        giveitem(actor, string.format("1#%d#%d&190#%d#%d&3961#%d#%d", 100000*useNumber,ConstCfg.binding,useNumber,ConstCfg.binding,useNumber,ConstCfg.binding),1)
    end
    if itemid == 4040 then --高级活跃宝箱
        giveitem(actor, string.format("9#%d#%d&3984#%d#%d&248#%d#%d", 2000*useNumber,ConstCfg.binding,2*useNumber,ConstCfg.binding,useNumber,ConstCfg.binding),1)
    end

    if itemReplace.canReplace(itemid) then
        local realUseCount = itemReplace.batchReplace(actor, itemid, useNumber)
        if realUseCount > 0 then
            GameEvent.push(EventCfg.stdUseItem, actor, itemid, itemobj, useNumber, param1, param2)
        end
        if realUseCount < useNumber then
            changeiteminfo(actor, itemobj, 3, "-", realUseCount)
            return false
        end
        return true
    end

    GameEvent.push(EventCfg.stdUseItem, actor, itemid, itemobj, useNumber, param1, param2)
end

-- 开始挂机触发
function startautoplaygame(actor)
    -- print("开始挂机触发")
    GameEvent.push(EventCfg.onAutoPlayGame, actor, 1)
end

-- 停止挂机触发
function stopautoplaygame(actor)
    -- print("停止挂机触发")
    GameEvent.push(EventCfg.onAutoPlayGame, actor, 0)
end

--添加好友前触发
function beforeaddfriend(actor, count)
    -- print("添加好友前触发")
end

-- 同意好友成功触发  param1 申请人ID
function addfriendself(actor, param1)
    GameEvent.push(EventCfg.onAddFriendSelf, actor, param1)
end

-- 删除好友成功触发 param1 被删除人ID
function delfirendself(actor, param1)
    GameEvent.push(EventCfg.onDelFirendSelf, actor, param1)
end

--镜像地图到期触发
function g_mirrormapend(actor, mapid)
    GameEvent.push(EventCfg.onMirrorMapEnd, actor, mapid)
end

-- 提取邮件触发
function getmailitem(actor, mailid, mailtype, itemJson)
    GameEvent.push(EventCfg.onGetMailItem, actor, mailid, mailtype, itemJson)
end

-- 技能前触发  自身唯一ID 目标唯一ID 技能ID 技能等级
function onskillbegin(actor, target, skillId, skillLv)
    BattleManager:skillBegin(actor, target, skillId, skillLv)
end

-----------------------------------------定时器-----------------------------------------
-- actor 默认全局触发对象0
-- obj 执行定时器的对象
-- 定时器id
-- 自定义参数
function g_ontimer101(obj, actor, id)
    backCity(actor) --回主城
    disabletimer(actor, id)
end

function g_ontimer103(obj, actor, id)
    autoplaygame(actor, 1)
end

function g_ontimer47(obj, actor, id)
    local time = gethumvar(actor, VarCfg.U_SLBYCD)
    if time > 1 then
        time = time - 1
    else
        disabletimer(actor, 47)
    end
    sethumvar(actor, VarCfg.U_SLBYCD, time)
end

function g_ontimer48(obj, actor, id)
    local time = gethumvar(actor, VarCfg.U_YZWCD)
    if time > 1 then
        time = time - 1
    else
        disabletimer(actor, 48)
    end
    sethumvar(actor, VarCfg.U_YZWCD, time)
end

function g_ontimer49(obj, actor, id)
    local time = gethumvar(actor, VarCfg.U_Pet_Die_Time)
    if time > 1 then
        time = time - 1
        sethumvar(actor, VarCfg.U_Pet_Die_Time, time)
    else
        disabletimer(actor, 49)
        --复活出战宠物
        mountMain.resurre(actor)
    end
end

-- Boss挑战创建镜像地图延时回调
function boss_chall(actor)
    BossChall.doCreateMirrorMap(actor)
end

---新伤害流程
function loginend(actor)
    -- print("loginend")
    BattleManager:initActor(actor)
    -- 登录完成
    local logindatas = {}
    GameEvent.push(EventCfg.onLoginEnd, actor, logindatas)
    Message.sendmsg(actor, ssrNetMsgCfg.sync, nil, nil, nil, logindatas) --同步数据
    -- 等级
    local level = currabil(actor, 0)
    sethumvar(actor, VarCfg.N_cur_level, level)
    -- 阵营图标
    local camp = targetinfo(actor, "GOODEVILID") --(0=无阵营 1=正派 2=邪派)     -- 获取阵营
    setrefdata(actor, 1, camp)                   -- 更新阵营显示图标
end

-- 下线卸载被动数据
function playreconnection(actor)
    sethumvar(actor, VarCfg.U_OffLine_Time, os.time())
    sethumvar(actor, VarCfg.U_OffLine_Hp, currabil(actor, 1))
    sethumvar(actor, VarCfg.U_OffLine_Mp, currabil(actor, 2))
    GameEvent.push(EventCfg.onExitGame, actor)

    PassiveManager:remove(actor)
end

function playoffline(actor)
    sethumvar(actor, VarCfg.U_OffLine_Time, os.time())
    sethumvar(actor, VarCfg.U_OffLine_Hp, currabil(actor, 1))
    sethumvar(actor, VarCfg.U_OffLine_Mp, currabil(actor, 2))

    GameEvent.push(EventCfg.onExitGame, actor)

    PassiveManager:remove(actor)
end

-- 怪物buff操作触发
function m_buffchange(mon, buffid, groupid, model, target)
    GameEvent.push(EventCfg.onMonBuffChange, mon, buffid, groupid, model, target)
end

function b_buffchange(mon, buffid, groupid, model, target)
    GameEvent.push(EventCfg.onBBBuffChange, mon, buffid, groupid, model, target)
end

function buffchange(actor, buffId, buffType, lis, actorId)
    BattleManager:buffEvent(actor, buffId, buffType, lis, actorId)
    GameEvent.push(EventCfg.onBuffChange, actor, buffId, buffType, lis, actorId)
end

-- 特殊扣血buff列表
local speDelHpBuff = {
    [150026] = true, -- 113属性中毒效果
    -- 以下为刺客出血buff
    [126201] = true,
    [126202] = true,
    [126203] = true,
    [126204] = true,
    [126205] = true,
}
function bufftriggerhpchange(actor, buffId, buffGroup, hp, buffHost)
    if speDelHpBuff[buffId] then                            -- 特殊扣血buff列表
        local delhp = (getbuffcustdata(actor, buffId)) or 0 --每次扣血数
        return -delhp
    end
    local result = BattleManager:buffTrig(actor, buffId, buffGroup, hp, buffHost)
    if result and result >= 0 then
        return result
    end
end

function m_bufftriggerhpchange(mon, buffId, buffGroup, hp, buffHost)
    if speDelHpBuff[buffId] then                          -- 特殊扣血buff列表
        local delhp = (getbuffcustdata(mon, buffId)) or 0 --每次扣血数
        return -delhp
    end
    local result = BattleManager:buffTrig(mon, buffId, buffGroup, hp, buffHost)
    if result and result >= 0 then
        return result
    end
end

function base(actor, target, effectid, skillid, skilllv, race)
    local result = BattleManager:Do(actor, target, effectid, skillid, skilllv, race)
    GameEvent.push(EventCfg.onAttack, actor, target, effectid, skillid, skilllv, race)

    if targetinfo(target, "RACE") == 6 then
        -- 玩家攻击宠物：从宠物主人属性获取68PK减免
        local mastertId = targetinfo(target, "MASTERID")
        local pkReduce = tonumber(abil(mastertId, 68)) or 0
        if pkReduce > 0 then
            local reduced = math.floor(result * pkReduce / 10000)
            result = math.max(1, result - reduced)
        end

        -- 宠物血量显示
        local oldHp = currabil(target, 1)
        local nowHp = oldHp - result
        local max = abil(target, 1)
        if nowHp < 0 then
            nowHp = 0
        end
        local isPc = clientflag(mastertId) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        Message.sendmsgEx(mastertId, methodName, "showPetPro", { type = "red", max = max, now = nowHp })
    end
    result = SpeHarmMain(actor, target, result)

    return result
end

function m_base(actor, target, effectid, skillid, skilllv, race)
    local result = BattleManager:Do(actor, target, effectid, skillid, skilllv, race)
    GameEvent.push(EventCfg.onAttack, actor, target, effectid, skillid, skilllv, race)

    if targetinfo(target, "RACE") == 6 then
        -- 怪物攻击宠物：从宠物主人属性获取56对怪防御和116受怪减伤
        local mastertId = targetinfo(target, "MASTERID")

        -- 属性56：对怪防御（固定值减免）
        local pveDef = tonumber(abil(mastertId, 56)) or 0
        if pveDef > 0 then
            result = math.max(1, result - pveDef)
        end

        -- 属性116：受怪减伤（万分比减免）
        local reducePct = tonumber(abil(mastertId, 116)) or 0
        if reducePct > 0 then
            local reduced = math.floor(result * reducePct / 10000)
            result = math.max(1, result - reduced)
        end

        -- 宠物血量显示
        local oldHp = currabil(target, 1)
        local nowHp = oldHp - result
        local max = abil(target, 1)
        if nowHp < 0 then
            nowHp = 0
        end
        local isPc = clientflag(mastertId) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        Message.sendmsgEx(mastertId, methodName, "showPetPro", { type = "red", max = max, now = nowHp })
    elseif isplayer(target) then
        -- 怪物攻击玩家：从玩家属性获取56对怪防御和116受怪减伤
        -- 属性56：对怪防御（固定值减免）
        local pveDef = tonumber(abil(target, 56)) or 0
        if pveDef > 0 then
            result = math.max(1, result - pveDef)
        end

        -- 属性116：受怪减伤（万分比减免）
        local reducePct = tonumber(abil(target, 116)) or 0
        if reducePct > 0 then
            local reduced = math.floor(result * reducePct / 10000)
            result = math.max(1, result - reduced)
        end
    end

    result = SpeHarmMain(actor, target, result)

    return result
end

function b_base(actor, target, effectId, skillId, skillLv, race)
    local result = BattleManager:Do(actor, target, effectId, skillId, skillLv, race)
    GameEvent.push(EventCfg.onAttack, actor, target, effectId, skillId, skillLv, race)
    if targetinfo(target, "RACE") == 6 then
        --是宠物受到伤害（宠物PK：目标也是宠物，攻击者是怪物）
        local masterId = targetinfo(actor, "MASTERID")
        if masterId and masterId > 0 then
            -- 目标宠物主人获取68PK减免
            local targetMasterId = targetinfo(target, "MASTERID")
            if targetMasterId and targetMasterId > 0 then
                local pkReduce = tonumber(abil(targetMasterId, 68)) or 0
                if pkReduce > 0 then
                    local reduced = math.floor(result * pkReduce / 10000)
                    result = math.max(1, result - reduced)
                end
            end
        end

        local oldHp = currabil(target, 1)
        local nowHp = oldHp - result
        local max = abil(target, 1)
        if nowHp < 0 then
            nowHp = 0
        end
        local mastertId = targetinfo(target, "MASTERID")
        local isPc = clientflag(mastertId) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        Message.sendmsgEx(mastertId, methodName, "showPetPro", { type = "red", max = max, now = nowHp })
    elseif isplayer(target) then
        -- 宠物攻击玩家（宠物PK）
        local masterId = targetinfo(actor, "MASTERID")
        if masterId and masterId > 0 then
            -- 攻击方主人获取67PK加成
            local pkBonus = tonumber(abil(masterId, 67)) or 0
            if pkBonus > 0 then
                local bonusDamage = math.floor(result * pkBonus / 10000)
                result = result + bonusDamage
            end
        end
    else
        -- 宠物攻击怪物
        local masterId = targetinfo(actor, "MASTERID")
        if masterId and masterId > 0 then
            -- 主人获取165对怪伤害
            local pveDamage = tonumber(abil(masterId, 165)) or 0
            if pveDamage > 0 then
                result = result + pveDamage
            end
        end
    end

    result = SpeHarmMain(actor, target, result)

    return result
end

function qigongupdate(actor, qiId, maxlv, clientLv, scripLv, equipLv)
    QiGongManager:update(actor, qiId, maxlv)
end

function qigongupdate(actor, qiId, maxlv, clientLv, scripLv, equipLv)
    QiGongManager:update(actor, qiId, maxlv)
end

function buyshopitem(actor, id, name, price, num)
    GameEvent.push(EventCfg.onBuyShopItem, actor, id, num)
end

---- 部分特殊效果计算
function SpeHarmMain(actor, target, result)
    local actorAttrTab = getattrtabex(actor) or {}
    local targetAttrTab = getattrtabex(target) or {}
    -- 中毒效果
    if targetAttrTab[113] and targetAttrTab[113] > 0 and targetAttrTab[113] >= math.random(1, 10000) then
        local value, time = tonumber(SysConstant['AttScoreBuff_Ratio_113']['Value'][1]) or 0,
            tonumber(SysConstant['AttScoreBuff_Ratio_113']['Value'][2]) or 0
        addbuff(actor, 150026, time, time, target)
        local gj = targetAttrTab[23] or 0           --获取攻击力
        local delhp = math.ceil(value / 100 * gj)
        setbuffcustdata(actor, 150026, "" .. delhp) --每秒扣血数
    end

    return result
end

function canshowshopitem(actor, condisId)
     print(" ----------- canshowshopitem" ,actor, condisId)
    if condisId == "123" then
        print(" ----------- 123不显示" )
        return false
    end
    return true
end