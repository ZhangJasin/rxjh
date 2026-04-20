local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainMission = class("MainMission", BaseFGUILayout)
local MainMissionData = require("FGUILayout/Main/MainMissionData")
local taskDeliverData = require("FGUILayout/A_TaskDeliver/taskDeliverData")
local Task_cfg = require("game_config/cfgcsv/Task")
local Language_cfg = require("game_config/cfgcsv/Language")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local GuideTask = require("FGUILayout/Guide/GuideTask")

function MainMission:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self._topMission = nil
    self._missionDatas = {}
    self._missionMovies = {}
    self._isRefreshing = false  -- 添加防循环标志
    
    FGUI:GList_setVirtual(self._ui.List_mission)
    FGUI:GList_itemRenderer(self._ui.List_mission, handler(self, self.OnItemRendererMission))
    FGUI:GList_addOnClickItemEvent(self._ui.List_mission, handler(self, self.OnListMissionItemClick))
    
    -- 订阅数据更新 - 使用更安全的回调方式
    self._dataCallback = function(data)
        self:OnDataUpdate(data)
    end
    MainMissionData:Subscribe(self._dataCallback)
    
    self:EnterFuben({isEnter = false})
end

function MainMission:Enter()
    self:InitMissions()
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootMission, self._ui.Node_attach)
    self:RegisterEvent()
    FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.MissionGuideFunc, handler(self, self.GetGuideItem))
end

function MainMission:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootMission)
    self:RemoveEvent()
    FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.MissionGuideFunc)
    -- 取消订阅数据更新
    if self._dataCallback then
        MainMissionData:Unsubscribe(self._dataCallback)
        self._dataCallback = nil
    end
end

function MainMission:Destroy()
    self._ui = nil
    -- 取消订阅数据更新
    if self._dataCallback then
        MainMissionData:Unsubscribe(self._dataCallback)
        self._dataCallback = nil
    end
end
-- 数据更新回调
function MainMission:OnDataUpdate(data)
    -- 安全检查：确保UI组件存在且数据有效
    if not self._ui or not self.component or not data then
        -- UI组件已销毁或数据无效，取消订阅
        if self._dataCallback then
            MainMissionData:Unsubscribe(self._dataCallback)
            self._dataCallback = nil
        end
        return
    end
    
    -- 确保数据格式正确
    if not data.missionDatas then
        -- print("MainMission:OnDataUpdate - 数据格式错误，缺少missionDatas字段")
        return
    end
    
    self._missionDatas = data.missionDatas or {}
    self:RefreshUI()
end

-- 刷新UI
function MainMission:RefreshUI()
    -- 避免在数据更新过程中频繁刷新
    if self._isRefreshing then
        return
    end
 

    self._isRefreshing = true
    FGUI:GList_setNumItems(self._ui.List_mission, #self._missionDatas)
    self:UpDateSize()

    -- 滚动到点击的任务处
    local taskID = MainMissionData:GetTaskID()
    if taskID then
        local index = nil
        for k, v in pairs(self._missionDatas) do
            if v.taskid == taskID then
                index = k
                break
            end
        end
        if index then 
            FGUI:GList_scrollToView(self._ui.List_mission, index-1, false, false)
        end
    end

    self._isRefreshing = false
end

----------------------------------------------------------------------------



function MainMission:InitMissions()
    local datas = SL:GetValue("MISSION_ALL_DATA")
    MainMissionData:SetMissionDatas(datas)
    MainMissionData:InitTaskProgress()
end

-- 根据职业筛选奖励
function MainMission:FilterRewardsByJob(tab)
    if not tab then return {} end
    
    local myJob = SL:GetValue("JOB")
    local mySex = SL:GetValue("SEX")
    local myZy = SL:GetValue("GOODEVILID") or 0
    local filteredRewards = {}
    local index = 0
    
    for _, v in pairs(tab) do
        local needjob,needsex,needzy = v[1],v[4] or 0,v[5] or 0 
        if (needjob == myJob or needjob == 9) and (needsex == mySex or needsex == 0) and (needzy == myZy or needzy == 0) then
            index = index + 1
            filteredRewards[index] = v
        end
    end
    
    return filteredRewards
end

function MainMission:OnItemRendererMission(index, item)
    local data = self._missionDatas[index + 1]
    if not data then return end
    
    FGUI:SetIntData(item, index+1)
    local playlevel = SL:GetValue("LEVEL")
    local needlevel = Task_cfg[data.taskid]['task_level'] or 0
    local imgControlle = FGUI:getController(item,"img")  --主线图标
    
    if Task_cfg[data.taskid]['task_type'] then
        FGUI:Controller_setSelectedIndex(imgControlle,Task_cfg[data.taskid]['task_type']-1)
    end
    
    -- title 
    local richTitle = FGUI:GetChild(item, "RichText_title")
    FGUI:GRichTextField_setText(richTitle, Language_cfg[Task_cfg[data.taskid]['task_name']]['Dec'])
    
    -- content
    local richContent = FGUI:GetChild(item, "RichText_content")
    if needlevel > playlevel then
        FGUI:GRichTextField_setText(richContent, "接取所需等级："..playlevel.."/"..needlevel)
    else
        FGUI:GRichTextField_setText(richContent, Language_cfg[Task_cfg[data.taskid]['task_targetdec']]['Dec'])
    end

    -- 显示任务奖励（使用道具框）
    local taskDrop = MainMission:FilterRewardsByJob(Task_cfg[data.taskid] and Task_cfg[data.taskid]['task_drop'])
    local award1 = FGUI:GetChild(item, "award1")
    if FGUI:GetChildCount(award1) > 0 then
        FGUI:RemoveChildAt(award1, 0, true)
    end
    local reward1 = taskDrop[1]
    if reward1 then
        local itemData = SL:GetValue("ITEM_DATA", reward1[2])
        local extData = {
            hideTip = true,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true,
            OverLap = reward1[3]
        }
        local item = ItemUtil:ItemShow_Create(itemData, award1, extData)
        -- 设置数量字体大小为13
        -- if item and item._component then
        --     local text_count = FGUI:GetChild(item._component, "Text_count")
        --     if text_count then
        --         local curPosX =  FGUI:getPositionX(text_count)
        --         FGUI:setPositionX(text_count, curPosX + (SL:GetValue("IS_PC_OPER_MODE") and 5 or 8))
        --         FGUI:GTextField_setFontSize(text_count, 12)
        --     end
        -- end
    end
    local award2 = FGUI:GetChild(item, "award2")
    if FGUI:GetChildCount(award2) > 0 then
        FGUI:RemoveChildAt(award2, 0, true)
    end
    local reward2 = taskDrop[2]
    if reward2 then
        local itemData = SL:GetValue("ITEM_DATA", reward2[2])
        local extData = {
            hideTip = true,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true,
            OverLap = reward2[3]
        }
        local item = ItemUtil:ItemShow_Create(itemData, award2, extData)
        -- 设置数量字体大小为13
        -- if item and item._component then
        --     local text_count = FGUI:GetChild(item._component, "Text_count")
        --     if text_count then
        --         local curPosX,curPoxY =  FGUI:getPositionX(text_count)
        --         FGUI:setPositionX(text_count, curPosX+(SL:GetValue("IS_PC_OPER_MODE") and 5 or 8))
        --         FGUI:GTextField_setFontSize(text_count, 12)
        --     end
        -- end
    end

    local jindu = Task_cfg[data.taskid]['task_progress'] or 1
    local taskProgressList = MainMissionData:GetTaskProgressList()
    
    local curjindu = 0
    local taskflag = false
    if taskProgressList[""..data.taskid] then
        curjindu = taskProgressList[""..data.taskid]["count"] or 0
        taskflag = taskProgressList[""..data.taskid]["state"] == 2
    end

    local ywc = FGUI:GetChild(item, "ywc")
    -- 避免在设置可见性时触发事件
    local currentVisible = FGUI:getVisible(ywc)
    if currentVisible ~= taskflag then
        FGUI:setVisible(ywc, taskflag)
    end
    
    -- 移除可能导致循环的打印语句
    -- print("=====================",taskflag,Task_cfg[data.taskid]['task_type'])
    
    if taskflag and Task_cfg[data.taskid]['task_type'] == 5 then
        --江湖录自动提交完成，不给奖励
         ssrMessage:sendmsgEx("Task", "finishJiangHuLing",data.taskid)
    end

    local richProgress = FGUI:GetChild(item, "RichText_progress")
    
    if Task_cfg[data.taskid]['task_progress'] then
        local progressVisible = FGUI:getVisible(richProgress)
        if progressVisible ~= true then
            FGUI:setVisible(richProgress, true)
        end
        FGUI:GRichTextField_setText(richProgress, (curjindu > jindu and jindu or curjindu).."/"..jindu )
        local progressFinalVisible = FGUI:getVisible(richProgress)
        if progressFinalVisible ~= (not taskflag) then
            FGUI:setVisible(richProgress, not taskflag)
        end
    else
        local progressVisible = FGUI:getVisible(richProgress)
        if progressVisible ~= false then
            FGUI:setVisible(richProgress, false)
        end
    end
end

function MainMission:OnListMissionItemClick(context)
    local index=FGUI:GetIntData(context.data)
    local data = self._missionDatas[index]
    SL:RequestSubmitMission(data.taskid) --点击任务
    
    local playlevel = SL:GetValue("LEVEL")
    local needlevel = Task_cfg[data.taskid]['task_level'] or 0
    if playlevel < needlevel then
        return
    end

    local taskProgressList = MainMissionData:GetTaskProgressList()
    local curjindu = taskProgressList[""..data.taskid]["count"] or 0
    local taskflag = taskProgressList[""..data.taskid]["state"] == 2

    MainMissionData:SetTaskID(data.taskid)  --设置当前点击任务ID
    taskDeliverData:SetTaskID(data.taskid)
    
    local task_turntype = Task_cfg[data.taskid]['task_turntype'] or 1
    local task_turn_param = Task_cfg[data.taskid]['task_turn_param'] or 1

    if task_turn_param == 10 then
        FGUI:Open("Reward", "rewardMain",1,nil,{fullScreen = false,destroyTime = 1})
    elseif task_turntype == 1 or taskflag then   --寻路到指定地点
        ssrMessage:sendmsgEx("Task", "xunlu",{data.taskid})
    elseif task_turntype == 2 then   --打开指定界面
        if task_turn_param == 1 then  --打开武功功界面
            FGUI:Open("Skill", "SkillFramePanel", 1)
        elseif task_turn_param == 2 then  --打开气功界面
            FGUI:Open("Skill", "SkillFramePanel", 2)
        elseif task_turn_param == 3 then  --打开转职界面
            FGUI:Open("Transfer", "TransferPanel")
            -- ssrMessage:sendmsgEx("Task", "onTransfer")
        elseif task_turn_param == 4 then  --打开阵营界面
            FGUI:Open("Transfer","campPanl")
        elseif task_turn_param == 5 then  --打开强化界面
            FGUI:Open("A_EquipDuanZao", "EquipDuanZao",2,nil,{fullScreen = false,destroyTime = 1})
        elseif task_turn_param == 6 then  --打开好友界面
            FGUI:Open("Friend", "FriendPanel", FGUIDefine.FriendPage.Friend)
        elseif task_turn_param == 7 then  --打开门派界面
            local targetTab = Task_cfg[data.taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == 12 then --门派任务
            elseif targetType == 13 then --门派捐献
                FGUIFunction:OpenGuildMainFrameUI(1)
            else
                FGUIFunction:OpenGuildAutoUI()
            end
        elseif task_turn_param == 8 then  --打开灵兽界面
            FGUI:Open("Mount", "mountMain",{type=0})
        elseif task_turn_param == 9 then  --打开组队界面
            FGUIFunction:OpenTeamAutoUI()
        elseif task_turn_param == 11 then  --打开加工界面
            FGUI:Open("A_EquipDuanZao", "EquipDuanZao",3,nil,{fullScreen = false,destroyTime = 1})
        elseif task_turn_param == 12 then  --打开师徒界面
            FGUI:Open("MentorShip", "MentorShipPanel")
        elseif task_turn_param == 13 then  --打开坐骑界面
            FGUI:Open("Mount", "mountMain",{type=1})
        elseif task_turn_param == 14 then  --打开赋予界面
            FGUI:Open("A_EquipDuanZao", "EquipDuanZao",4,nil,{fullScreen = false,destroyTime = 1})
        elseif task_turn_param == 16 then  --打开武勋界面
            FGUI:Open("A_WuXun", "WuXunPanl", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
            ssrMessage:sendmsgEx("Task", "onTaskTurnComplete", {taskid = data.taskid})
        end
    elseif task_turntype == 3 then   --引导
        self:StartGuide(task_turn_param, data.taskid)
    end
end

function MainMission:onMissionItemAdd(data)
    MainMissionData:AddMissionItem(data)
end

function MainMission:onMissionItemChange(data)
    MainMissionData:ChangeMissionItem(data)
end

function MainMission:onMissionItemRemove(data)
    MainMissionData:RemoveMissionItem(data)
end

function MainMission:onMissionItemTop(id)
    MainMissionData:TopMissionItem(id)
end

function MainMission:UpDateSize()
    FGUI:GList_resizeToFit(self._ui.List_mission)
    local wide,height = FGUI:getSize(self._ui.List_mission)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    if isPC then 
        FGUI:setSize(self._ui.List_mission, wide, 130)
    else 
        FGUI:setSize(self._ui.List_mission, wide, 195)
    end 
end

function MainMission:onMissionShow(data)
    self:ShowMission()
end

function MainMission:UpdateMissionCellData(cell, data)
    -- title
    local richTitle = FGUI:GetChild(cell, "RichText_title")
    FGUI:GRichTextField_setText(richTitle, data.head.content)
    FGUI:GRichTextField_setColor(richTitle, SL:GetValue("COLOR_BY_ID", data.head.color))

    -- content
    local richContent = FGUI:GetChild(cell, "RichText_content")
    FGUI:GRichTextField_setText(richContent, data.body.content)
    FGUI:GRichTextField_setColor(richContent, SL:GetValue("COLOR_BY_ID", data.body.color))
    

    self:UpdateMissionCellOrder(cell, data)
end
--自动寻路开始
function MainMission:onXunlunBegin(data) --table — {mapID = 目标地图ID, x = 目标坐标X, y = 目标坐标Y}

end
--自动寻路结束
function MainMission:onXunlunEnd()
    -- print("自动寻路结束")
    local taskID = MainMissionData:GetTaskID()
    if taskID then
        local curtaskid = taskID
        local curx,cury,curmapid = SL:GetValue("X"),SL:GetValue("Z"),SL:GetValue("MAP_ID")
        local postab = Task_cfg[curtaskid]['task_finpos']
        if postab then
            local mapid,x,y,range = postab[1],postab[2],postab[3],postab[4]
            local taskProgressList = MainMissionData:GetTaskProgressList()
            if tostring(mapid) == tostring(curmapid) and taskProgressList[""..curtaskid] then
                local taskflag = taskProgressList[""..curtaskid]["state"] == 2
                if taskflag or not Task_cfg[curtaskid]['task_targettype'] then
                    local dx = x > curx and x - curx or curx - x
                    local dy = y > cury and y - cury or cury - y
                    if dx <= 3 and dy <= 3 then
                        taskDeliverData:SetTaskID(taskID)
                        FGUI:Open("A_TaskDeliver", "taskDeliver",{},FGUI_LAYER.NORMAL,{fullScreen = false,destroyTime = 0.1})
                    end
                end 
            end
        end
    end
end
--左右晃动动作
function MainMission:HDRun(obj,x,y,time)
    FGUI:runAction(obj, 
            FGUI:ActionRepeatForever(
                FGUI:ActionSequence(
                    FGUI:ActionMoveBy(time, x,y),
                    FGUI:ActionMoveBy(time, -x,-y)
        )))
end
function MainMission:onTransferComplete()  -- 完成转职
    local curCfg = MainMissionData.data.transfer_cur
    local nextCfg = MainMissionData.data.transfer_next
    FGUI:Open("Transfer", "TransferSucceed", { curCfg = curCfg, nextCfg = nextCfg })
    -- 发送转职完成消息
    SL:SendNetMsg(9998,12, nil, nil, nil)
    MainMissionData:SetTransferData()
    ssrMessage:sendmsgEx("Task", "onTransfer")
end

function MainMission:onAddSkill()  -- 新增技能
    print("========================","新增技能")
    ssrMessage:sendmsgEx("Task", "onStudySkill")
end
-- 等级变化
function MainMission:OnRefreshPropertyShow()
    self:RefreshUI()
end
function MainMission:OnPlayerPosChange()
    --print("位置改变")
    local curmapid =SL:GetValue("MAP_ID")
    local taskID = MainMissionData:GetTaskID()
    if taskID and FGUI:CheckOpen("A_TaskDeliver", "taskDeliver") then
        local curx,cury = SL:GetValue("X"),SL:GetValue("Z")
        local postab = Task_cfg[taskID]['task_finpos']
        local closeflag = true
        if postab then
            local mapid,x,y,range = postab[1],postab[2],postab[3],postab[4]
            if tostring(mapid) == tostring(curmapid) then  --是否在指定地图内
                if taskflag or not Task_cfg[taskID]['task_targettype'] then         --判断任务是否完成
                    local dx = x > curx and x - curx or curx - x
                    local dy = y > cury and y - cury or cury - y
                    if dx <= 3 and dy <= 3 then
                        closeflag = false
                    end
                end   
            end
        end
        if closeflag then
            --print("关闭界面")
            FGUI:Close("A_TaskDeliver", "taskDeliver")
        end
    end
    if string.find(curmapid,"2091") then
        FGUI:setVisible(self.component,false)
    else
        FGUI:setVisible(self.component,true)
    end
end

--师徒副本内容
local function fubenTimeOut()     -- 更新副本倒计时显示    
    local curtime = os.time()                                   
    local sytime = MainMissionData:GetStopTime() - curtime
    if sytime >= 0 then
        local statestr = SL:SecondToHMS(sytime, true, true)
        FGUI:GTextField_setText(self._ui.time, statestr)
        if sytime == 0 then
            SL:UnSchedule(self.dsq)
            self:EnterFuben({isEnter = false})
        end
    end
end
function MainMission:EnterFuben(data)
    local whichContro = FGUI:getController(self.component,"isTask")
    if data.isEnter then
        FGUI:Controller_setSelectedIndex(whichContro,1)
        MainMissionData:SetStopTime(tonumber(data.info.StopTime))
        self.dsq = SL:schedule(self._ui.bg, fubenTimeOut, 1) 
        self:ShowMentorShipInfo(data.info)
        FGUI:setOnClickEvent(self._ui.goout, function()
            SL:OpenCommonDialog({
                title = '温馨提示',
                str = '是否退出副本，退出后无法再次进入',
                btnDesc = {"取消","确定"},
                callback = function(tag)
                    if tag == 1 then
                        --取消
                    else
                        --确定退出
                        SL:UnSchedule(self.dsq)
                        ssrMessage:sendmsgEx("MentorShip", "goOutFuben")
                        self:EnterFuben({isEnter = false})
                    end
                end
            })
        end)
    else
        FGUI:Controller_setSelectedIndex(whichContro,0)
    end
end

function MainMission:ShowMentorShipInfo(data)
    if tonumber(data.killtype) == 1 then 
         FGUI:GTextField_setText(self._ui.killTitle,"累计击杀<font color='#00ff00'>100</font>只怪物")
    else
         FGUI:GTextField_setText(self._ui.killTitle,"击杀<font color='#00ff00'>1</font>BOSS")
    end
    FGUI:GTextField_setText(self._ui.killnum,"击杀数量：<font color='#00ff00'>"..data.killnum.."</font>")
end

function MainMission:OnPlayerPropertys()
    self:InitMissions()
end


-- 获取引导对应的item
function MainMission:GetGuideItem(id)
    local index
    for k, v in pairs(self._missionDatas) do
        if tostring(v.type) == tostring(id) then
            index = k
            break
        end
    end
    if not index then return nil end
    index = index - 1
    FGUI:GList_scrollToView(self._ui.List_mission, index, false, false)
    local cellIdx = FGUI:GList_itemIndexToChildIndex(self._ui.List_mission, index)
    local child = FGUI:GetChildAt(self._ui.List_mission, cellIdx)
    return child
end
-----------------------------------注册事件--------------------------------------
function MainMission:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_TOP, "MainMission", handler(self, self.onMissionItemTop))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_ADD, "MainMission", handler(self, self.onMissionItemAdd))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_CHANGE, "MainMission", handler(self, self.onMissionItemChange))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_REMOVE, "MainMission", handler(self, self.onMissionItemRemove))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, "MainMission", handler(self, self.onMissionShow))
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "MainMission", handler(self, self.onXunlunBegin))               -- 自动寻路开始     
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "MainMission", handler(self, self.onXunlunEnd))                   -- 自动寻路结束
    -- SL:RegisterLUAEvent(LUA_EVENT_TRANSFER_SUCCEED, "MainMission", handler(self, self.onTransferComplete))         -- 完成转职
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_ADD, "MainMission", handler(self, self.onAddSkill))                        -- 新增技能
    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainMission", handler(self, self.OnPlayerPosChange))   -- 切换地图
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_BEGIN, "MainMission", handler(self, self.OnPlayerPosChange))   -- 玩家位置改变
    SL:RegisterLUAEvent(LUA_EVENT_LEAVE_WORLD, "MainMission", handler(self, self.OnPlayerPosChange))                   -- 小退
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "MainMission", handler(self, self.OnPlayerPropertys))     -- 属性初始化
    SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "MainMission", handler(self, self.OnRefreshPropertyShow))     -- 等级变化
end

function MainMission:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_TOP, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_ADD, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_CHANGE, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_REMOVE, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "MainMission")
    -- SL:UnRegisterLUAEvent(LUA_EVENT_TRANSFER_SUCCEED, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_ADD, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_BEGIN, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_LEAVE_WORLD, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "MainMission")
end

-----------------------------------引导功能------------------------------------
-- 引导配置
local GuideConfig = {
    [1] = { -- 引导打开随身仓库
        panel = SL:GetValue("IS_PC_OPER_MODE") and "Bag_pc" or "Bag",
        panelName = SL:GetValue("IS_PC_OPER_MODE") and "PCPlayerInfoPanel" or "PlayerInfoPanel",
        panelParm= 1,
        widget = "btn_bag_warehouse",
        desc = "点击打开随身仓库",
        callback = function()
            return true -- 引导完成
        end
    },
    [2] = { -- 引导宠物激活
        panel = "Mount",
        panelName = "mountMain",
        panelParm= {type=0},
        widget = "petActiveBtn",
        desc = "点击激活宠物",
        callback = function()
            return true
        end
    },
    [3] = { -- 引导坐骑激活
        panel = "Mount",
        panelName = "mountMain",
        panelParm= {type=1},
        widget = "n60",
        desc = "点击激活坐骑",
        callback = function()
            return true
        end
    },
    [4] = { -- 随身商店引导 - 步骤1：打开商店
        panel = SL:GetValue("IS_PC_OPER_MODE") and "Bag_pc" or "Bag",
        panelName = SL:GetValue("IS_PC_OPER_MODE") and "PCPlayerInfoPanel" or "PlayerInfoPanel",
        panelParm = 1,
        widget = "btn_bag_wareShop",
        desc = "点击打开随身商店",
        callback = function()
            -- 打开随身商店            
            return false -- 不结束，继续下一步
        end,
        nextStep = 4001 -- 下一个引导步骤
    },
    [4001] = { -- 随身商店引导 - 步骤2：点击购买第一个商品
        panel = SL:GetValue("IS_PC_OPER_MODE") and "TreasureShop_pc" or "TreasureShop",
        panelName = SL:GetValue("IS_PC_OPER_MODE") and "PCBuyPanel" or "BuyPanel",
        widget = "list_buy_item_0", -- 动态获取list_buy第一个商品
        desc = "点击购买",
        callback = function()
            return true -- 结束引导
        end,
    },
    [6] = { -- 引导打开回收
        panel = SL:GetValue("IS_PC_OPER_MODE") and "Bag_pc" or "Bag",
        panelName = SL:GetValue("IS_PC_OPER_MODE") and "PCPlayerInfoPanel" or "PlayerInfoPanel",
        panelParm= 1,
        widget = "btn_bag_recycle",
        desc = "点击打开回收",
        callback = function()
            return true -- 引导完成
        end
    },
}

function MainMission:StartGuide(guideType, taskId)
    local config = GuideConfig[guideType]
    if not config then
        print("[Guide] 未找到引导配置，type = " .. tostring(guideType))
        return
    end
    
    -- 保存当前引导任务ID
    self._currentGuideTaskId = taskId
    self._currentGuideType = guideType
    
    -- 先打开目标界面
    if config.panelName then
        FGUI:Open(config.panel, config.panelName,config.panelParm)
    end
    
    -- 延迟显示引导（等待界面打开）
    SL:ScheduleOnce(handler(self, function()
        self:ShowGuideTask(config, guideType)
    end),0.5)
end

function MainMission:ShowGuideTask(config, guideType)
    -- 查找目标按钮
    local targetWidget = nil
    
    -- 尝试从不同位置获取widget
    if config.widget then
        -- 检查是否已经打开了界面（传入widget名称以支持子面板查找）
        local panelUI = self:_findOpenedPanelUI(config.panel, config.panelName, config.widget)
        
        -- 特殊处理动态列表项（如 list_buy_item_0）
        if config.widget:find("list_buy_item_") then
            if panelUI and panelUI.list_buy then
                targetWidget = FGUI:GetChildAt(panelUI.list_buy, 0)
            end
        elseif panelUI and panelUI[config.widget] then
            targetWidget = panelUI[config.widget]
        end
    end
    
    if not targetWidget then
        print("[Guide] 未找到引导目标widget: " .. tostring(config.widget))
        return
    end
    
    -- 创建引导任务
    local guideData = {
        id = self._currentGuideTaskId,
        param = guideType,
        guideWidget = targetWidget,
        guideDesc = config.desc or "请点击此按钮",
        showType = 1,
        mainIdx = 0,
        isForce = true,
        dir = 7, -- 箭头在下方
        clickCB = handler(self, function()
            if config.callback and config.callback() then
                -- 引导完成，关闭引导
                self:CompleteCurrentGuide()
            elseif config.nextStep then
                -- 多步骤引导，继续下一步
                self:ContinueToNextGuideStep(config.nextStep)
            end
        end)
    }
    
    local guideTask = GuideTask.new(guideData)
    guideTask:Enter()
    self._guideTask = guideTask
end

-- 继续下一步引导
function MainMission:ContinueToNextGuideStep(nextStep)
    -- 关闭当前引导
    if self._guideTask then
        self._guideTask:Exit()
        self._guideTask = nil
    end
    
    -- 延迟开始下一步
    SL:ScheduleOnce(handler(self, function()
        local config = GuideConfig[nextStep]
        if config then
            -- 打开新界面
            -- if config.panelName then
            --     FGUI:Open(config.panel, config.panelName, config.panelParm)
            -- end
            -- 延迟显示引导
            SL:ScheduleOnce(handler(self, function()
                self:ShowGuideTask(config, nextStep)
            end), 0.5)
        end
    end), 0.3)
end

-- 查找已打开的界面UI
function MainMission:_findOpenedPanelUI(panel, panelName, widgetName)
    -- 根据不同界面返回对应的UI
    if panel == "Bag" and panelName == "PlayerInfoPanel" then
        return FGUIFunction:GetGuideData(FGUIDefine.GuideDataKey.PlayerInfoGuide)
    elseif panel == "Bag_pc" and panelName == "PCPlayerInfoPanel" then
        return FGUIFunction:GetGuideData(FGUIDefine.GuideDataKey.PlayerInfoGuide)
    elseif panel == "Mount" and panelName == "mountMain" then
        return FGUIFunction:GetGuideData(FGUIDefine.GuideDataKey.MountGuide)
    elseif panel == "TreasureShop_pc" and panelName == "PCBuyPanel" then
        return FGUIFunction:GetGuideData(FGUIDefine.GuideDataKey.BuyGuide)      
    elseif panel == "TreasureShop" and panelName == "BuyPanel" then
        return FGUIFunction:GetGuideData(FGUIDefine.GuideDataKey.BuyGuide)
    end
    return nil
end

-- 从NPCStoreNewPanel中查找BuyPanel
function MainMission:_findBuyPanelFromNPCStore(packageName, panelName, buyPanelName)
    local npcStorePanel = FGUI:GetPanel(packageName, panelName)
    if npcStorePanel and npcStorePanel.node_root then
        -- 遍历node_root的所有子节点查找BuyPanel
        local childCount = FGUI:GetChildCount(npcStorePanel.node_root)
        local buyPanel = nil
        for i = 0, childCount - 1 do
            local child = FGUI:GetChildAt(npcStorePanel.node_root, i)
            if child and child.list_buy then
                buyPanel = child
                break
            end
        end
        return buyPanel
    end
    return nil
end

-- 完成当前引导
function MainMission:CompleteCurrentGuide()
    local taskId = self._currentGuideTaskId
    
    if self._guideTask then
        self._guideTask:Exit()
        self._guideTask = nil
    end
    
    self._currentGuideTaskId = nil
    self._currentGuideType = nil
    
    -- 通知服务端任务完成
    if taskId then
        print("[Guide] 引导完成，通知服务端任务完成，taskId=" .. tostring(taskId))
        ssrMessage:sendmsgEx("Task", "onTaskTurnComplete", {taskid = taskId})
    end
end

return MainMission