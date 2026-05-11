local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local DailyTaskPanel = class("DailyTaskPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local taskDetail = require("game_config/cfgcsv/actPointDetail")
local awardDetail = require("game_config/cfgcsv/actPointAward")
local Tips_Cfg = require("game_config/cfgcsv/TipsDetail")
local MAX_POINT=200

-- 数据管理
DailyTaskPanel.data = {
    taskList = {},       -- 任务列表
    awardList = {},      -- 奖励列表
    activePoint = 0,     -- 当前活跃点
    subscribers = {},    -- 订阅者
}

-- 订阅数据更新
function DailyTaskPanel:Subscribe(callback)
    if callback and type(callback) == "function" then
        table.insert(self.data.subscribers, callback)
    end
end

-- 取消订阅
function DailyTaskPanel:Unsubscribe(callback)
    for i, cb in ipairs(self.data.subscribers) do
        if cb == callback then
            table.remove(self.data.subscribers, i)
            break
        end
    end
end

-- 通知订阅者
function DailyTaskPanel:NotifySubscribers()
    for i = #self.data.subscribers, 1, -1 do
        local callback = self.data.subscribers[i]
        if callback and type(callback) == "function" then
            local success, err = xpcall(function()
                callback(self.data)
            end, debug.traceback)
            if not success then
                table.remove(self.data.subscribers, i)
            end
        else
            table.remove(self.data.subscribers, i)
        end
    end
end

---@param data table {taskList = {}, awardList = {}, activePoint = number}
function DailyTaskPanel:UpdateData(data)
    if data.taskList then
        self.data.taskList = data.taskList
    end
    if data.awardList then
        self.data.awardList = data.awardList
    end
    if data.activePoint then
        self.data.activePoint = data.activePoint
    end
    self:NotifySubscribers()
end

-- 获取任务列表
function DailyTaskPanel:GetTaskList()
    return self.data.taskList
end

-- 获取奖励列表
function DailyTaskPanel:GetAwardList()
    return self.data.awardList
end

-- 获取活跃点
function DailyTaskPanel:GetActivePoint()
    return self.data.activePoint
end

function DailyTaskPanel:Create()
    -- 获取界面代理
    self._ui = FGUI:ui_delegate(self.component)

    --适配pc端UI
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    if isPC then 
        FGUI:setScale(self.component, 0.75, 0.75)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
    end       
end
function DailyTaskPanel:btnTipsClicked()
    FGUI:Controller_setSelectedIndex(self.tipsControlle,self.tipsControlle.selectedIndex == 1 and 0 or 1)
end
-- 进入界面
function DailyTaskPanel:Enter(data)
    self:RegisterEvent()
    self:Init()
    -- 请求服务端数据
    ssrMessage:sendmsgEx("DailyTask", "reqData")
end

-- 退出界面
function DailyTaskPanel:Exit()
    self:UnregisterEvent()
end

-- 注册事件
function DailyTaskPanel:RegisterEvent()
    -- 关闭按钮
    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("huodong", "DailyTaskPanel")
    end)

    self.tipsControlle = FGUI:getController(self.component, "tips")
    self.tipsbg = FGUI:ui_delegate(self._ui.panel_tips)
    FGUI:GTextField_setText(self.tipsbg.title, Tips_Cfg[3]['title']) -- 打开按钮
    FGUI:GRichTextField_setText(self.tipsbg.con, Tips_Cfg[3]['tips'])

    -- 点击tips
    FGUI:setOnClickEvent(self._ui.btn_tips, handler(self, self.btnTipsClicked))
    FGUI:setOnClickEvent(self.tipsbg.close_tip, handler(self, self.btnTipsClicked))

    -- 列表渲染
    FGUI:GList_itemRenderer(self._ui.taskList, handler(self, self.TaskItemRenderer))

    FGUI:GList_itemRenderer(self._ui.actList, handler(self, self.ActItemRenderer))
end

function DailyTaskPanel:Init()
    --奖励道具
    for i, val in ipairs(awardDetail) do
        local awardItem = self._ui["award"..i]
        if awardItem and val.award then
            if FGUI:GetChildCount(awardItem) > 0 then            
                FGUI:RemoveChildAt(awardItem, 0, true)
            end 
            local itemData = SL:GetValue("ITEM_DATA", val.award[1])
            if itemData then
                local extData = {
                    hideTip = false,
                    itemTipData = itemData,
                    clickCallback = false,
                    doubleClickCallback = true,
                    bgVisible = true,
                    OverLap = val.award[2]
                }
                ItemUtil:ItemShow_Create(itemData, awardItem, extData)
            end   
        end
    end
end

-- 任务项渲染器
function DailyTaskPanel:TaskItemRenderer(index, item)
    local taskData = self.data.taskList[index + 1]
    if not taskData then return end
    self:UpdateTaskItem(item, taskData, index)
end

-- 活动项渲染器
function DailyTaskPanel:ActItemRenderer(index, item)
    local actData = self.actList[index + 1]
    if not actData then return end
    self:UpdateActItem(item, actData, index)
end

-- 奖励项渲染器
function DailyTaskPanel:AwardItemRenderer(index, item)
    local awardData = self.data.awardList[index + 1]
    if not awardData then return end
    self:UpdateAwardItem(item, awardData, index)
end


-- 奖励点击
function DailyTaskPanel:OnAwardClick(awardData)
    if awardData.state == 1 then
        -- 已领取
        showTip("奖励已领取")
    elseif self.data.activePoint >= awardData.needPoint then
        -- 活跃点足够，发送领取请求
        SLBridge:SendLuaMsg(ssrNetMsgCfg.DailyTask, "getPointAward", {awardData.id})
    else
        -- 活跃点不足
        showTip("活跃点不足，需要" .. awardData.needPoint .. "点")
    end
end

-- 前往任务
function DailyTaskPanel:GotoTask(taskData)
    -- 根据任务类型跳转到对应界面或玩法
    if taskData.target and taskData.target ~= "" then
        
    end
end



-- 更新任务项
function DailyTaskPanel:UpdateTaskItem(item, taskData, index)
    -- 任务名称
    local text_name = item:GetChild("n1")
    if text_name then
        text_name.text = taskData.name or ""
    end
    
    -- 进度文本
    local text_progress = item:GetChild("n2")
    if text_progress then
        text_progress.text = taskData.count .. "/" .. taskData.maxCount
    end
    
    -- 活跃点
    local text_point = item:GetChild("n3")
    if text_point then
        text_point.text = "+" .. taskData.point
    end
    
    -- 前往/领取按钮
    local btn_go = item:GetChild("n4")
    if btn_go then
        if taskData.state == TASK_STATE.finish then
            btn_go.title = "领取"
        elseif taskData.state == TASK_STATE.received then
            btn_go.title = "已领取"
            btn_go.grayed = true
        else
            btn_go.title = "前往"
            btn_go.grayed = false
        end
    end
end

-- 刷新奖励列表
function DailyTaskPanel:RefreshAwardList()

end

-- 更新奖励项
function DailyTaskPanel:UpdateAwardItem(item, awardData, index)
    -- 需要活跃点
    local text_need = item:GetChild("n1")
    if text_need then
        text_need.text = awardData.needPoint
    end
    
    -- 领取状态
    local btn_get = item:GetChild("n2")
    if btn_get then
        if awardData.state == 1 then
            btn_get.title = "已领取"
            btn_get.grayed = true
        elseif self.data.activePoint >= awardData.needPoint then
            btn_get.title = "领取"
            btn_get.grayed = false
        else
            btn_get.title = awardData.needPoint .. "点"
            btn_get.grayed = true
        end
    end
    
    -- 奖励预览（如果有）
    local icon_award = item:GetChild("n3")
    if icon_award and awardData.awards and #awardData.awards > 0 then
        local itemId = awardData.awards[1][1]
        local itemCount = awardData.awards[1][2]
        -- 可以设置物品图标
    end
end

-- 更新活动项
function DailyTaskPanel:UpdateActItem(item, actData, index)
    local text_title = item:GetChild("title")
    if text_title then
        text_title.text = awardData.needPoint
    end
    
    -- 
    local btn_y = item:GetChild("yue")
    if btn_get then
        if awardData.state == 1 then
            btn_get.title = "已领取"
            btn_get.grayed = true
        elseif self.data.activePoint >= awardData.needPoint then
            btn_get.title = "领取"
            btn_get.grayed = false
        else
            btn_get.title = awardData.needPoint .. "点"
            btn_get.grayed = true
        end
    end
    
    
end

-- 刷新活跃点进度
function DailyTaskPanel:RefreshActivePoint()
    
end

return DailyTaskPanel
