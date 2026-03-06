--[[
    任务交付面板UI层
    主要功能：UI渲染、事件处理、界面交互
--]]

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local taskDeliver = class("taskDeliver", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local taskDeliverData = require("FGUILayout/A_TaskDeliver/taskDeliverData")

-- 创建UI及事件绑定
function taskDeliver:Create()
    SL:SetValue("BATTLE_AFK_END")  -- 结束挂机
    self._ui = FGUI:ui_delegate(self.component)
    
    -- 订阅数据更新
    self._dataCallback = function(data)
        self:OnDataUpdate(data)
    end
    taskDeliverData:Subscribe(self._dataCallback)
    
    -- 任务奖励列表渲染
    FGUI:GList_itemRenderer(self._ui.itemlist, handler(self, self.ListShowReward))
    FGUI:GList_setDefaultItem(self._ui.itemlist, "ui://htd1mfhzoqrp4")
    FGUI:GList_setVirtual(self._ui.itemlist)

    -- 恭喜获得弹窗相关
    self.gxhdbg = FGUI:ui_delegate(self._ui.panl_gxhd)
    FGUI:setOnClickEvent(self.gxhdbg.closepanl, function()
        FGUI:Controller_setSelectedIndex(self.tanchuangControlle, 0)
        if self.dsqid then
            SL:UnSchedule(self.dsqid)
            self.dsqid = false
        end
        FGUI:Close("A_TaskDeliver", "taskDeliver")
    end)
    FGUI:setVisible(self.gxhdbg.closepanl, true)
    FGUI:setOnClickEvent(self.gxhdbg.bg, function()
        FGUI:Controller_setSelectedIndex(self.tanchuangControlle, 0)
        if self.dsqid then
            SL:UnSchedule(self.dsqid)
            self.dsqid = false
        end
        FGUI:Close("A_TaskDeliver", "taskDeliver")
    end)

    -- 恭喜获得奖励列表渲染
    FGUI:GList_itemRenderer(self.gxhdbg['n8'], handler(self, self.ListViePage2GXGet))
    FGUI:GList_setDefaultItem(self.gxhdbg['n8'], "ui://htd1mfhzoqrpe")
    FGUI:GList_setVirtual(self.gxhdbg['n8'])

    self.tanchuangControlle = FGUI:getController(self.component, "tanchuang")

    -- 领取按钮
    FGUI:setOnClickEvent(self._ui.lqbtn, function()
        local taskID = taskDeliverData:GetTaskID()
        if taskID then
            ssrMessage:sendmsgEx("Task", "getReward", {taskID})
            local rewardList = taskDeliverData:GetRewardList()
            if #rewardList > 0 then
                FGUI:Controller_setSelectedIndex(self.tanchuangControlle, 1)
                FGUI:GList_setNumItems(self.gxhdbg['n8'], #rewardList)
                FGUI:GList_refreshVirtualList(self.gxhdbg['n8'])
                self:daojishi()
            else
                FGUI:Close("A_TaskDeliver", "taskDeliver")
            end
        end
    end)

    local rewards = taskDeliverData:FilterRewardsByJob()
    taskDeliverData:SetRewardList(rewards)

    self:Updata()
    local taskID = taskDeliverData:GetTaskID()
    if taskID then
        ssrMessage:sendmsgEx("Task", "onNpc", {taskID})
    end
end

-- 界面销毁时取消订阅
function taskDeliver:Destroy()
    if self._dataCallback then
        taskDeliverData:Unsubscribe(self._dataCallback)
        self._dataCallback = nil
    end
end


-- 数据更新回调
function taskDeliver:OnDataUpdate(data)
    if not self._ui or not self.component then
        -- UI组件已销毁，取消订阅
        if self._dataCallback then
            taskDeliverData:Unsubscribe(self._dataCallback)
            self._dataCallback = nil
        end
        return
    end
    
    self:Updata()
end

-- 更新NPC、标题、内容、奖励等
function taskDeliver:Updata()
    local taskID = taskDeliverData:GetTaskID()
    -- print("任务交付面板 taskID：", taskID)
    if not taskID then return end
    
    local npcInfo = taskDeliverData:GetNpcInfo()
    if npcInfo then
        FGUI:GTextField_setText(self._ui['npcname'], npcInfo['Name'])
    end
    
    FGUI:GRichTextField_setText(self._ui['title'], taskDeliverData:GetTaskTitle())
    FGUI:GRichTextField_setText(self._ui['content'], taskDeliverData:GetTaskContent())

    -- NPC模型展示
    if self._taskModel then
        self:UIModel_Unbind(self._ui.graph_task_npc)
    end
    if npcInfo then
        self._taskModel = self:UIModel_Bind(self._ui.graph_task_npc)
        self._modelIndex = FGUI:UIModel_addLegoModel(self._taskModel, npcInfo['Appr'], nil, nil, Vector3.one * 1.4)
    end

    -- 奖励列表刷新
    local rewardList = taskDeliverData:GetRewardList()
    FGUI:GList_setNumItems(self._ui.itemlist, #rewardList)
    FGUI:GList_refreshVirtualList(self._ui.itemlist)
end

-- 任务奖励列表渲染
function taskDeliver:ListShowReward(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end
    local rewardList = taskDeliverData:GetRewardList()
    local reward = rewardList[idx + 1]
    if reward then
        local itemData = SL:GetValue("ITEM_DATA", reward[2])
        local extData = {
            hideTip = false,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = true,
            bgVisible = true,
            OverLap = reward[3]
        }
        ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
    end
end

-- 恭喜获得奖励列表渲染
function taskDeliver:ListViePage2GXGet(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end
    local rewardList = taskDeliverData:GetRewardList()
    local reward = rewardList[idx + 1]
    if reward then
        local itemData = SL:GetValue("ITEM_DATA", reward[2])
        local extData = {
            hideTip = false,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = true,
            bgVisible = true,
            OverLap = reward[3]
        }
        ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
    end
end

-- 恭喜获得弹窗倒计时自动关闭
function taskDeliver:daojishi()
    if self.dsqid then
        SL:UnSchedule(self.dsqid)
    end
    self.time = 3
    FGUI:GTextField_setText(self.gxhdbg['daojishi'], self.time .. "秒后自动关闭")
    FGUI:GTextField_setAlign(self.gxhdbg['daojishi'], 1)
    local function realivedjs()
        self.time = self.time - 1
        FGUI:GTextField_setText(self.gxhdbg['daojishi'], string.format("%s秒后自动关闭", "" .. self.time))
        FGUI:GTextField_setAlign(self.gxhdbg['daojishi'], 1)
        if self.time == 0 then
            SL:UnSchedule(self.dsqid)
            self.dsqid = false
            FGUI:Close("A_TaskDeliver", "taskDeliver")
        end
    end
    self.dsqid = SL:Schedule(realivedjs, 1)
end

-- 打开面板入口
function taskDeliver:OpenPanl(data)
    taskDeliverData:OpenPanl(data)
end



return taskDeliver