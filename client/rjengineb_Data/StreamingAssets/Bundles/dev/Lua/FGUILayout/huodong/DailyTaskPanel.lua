local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local DailyTaskPanel = class("DailyTaskPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local taskDetail = require("game_config/cfgcsv/actPointDetail")
local awardDetail = require("game_config/cfgcsv/actPointAward")
local Tips_Cfg = require("game_config/cfgcsv/TipsDetail")
local MAX_POINT=200

-- 数据管理
DailyTaskPanel._data = {
    taskList = {},       -- 任务列表
    awardList = {},      -- 奖励列表
    activePoint = 0,     -- 当前活跃点
    subscribers = {},    -- 订阅者
}

-- 订阅数据更新
function DailyTaskPanel:Subscribe(callback)
    if callback and type(callback) == "function" then
        table.insert(self._data.subscribers, callback)
    end
end

-- 取消订阅
function DailyTaskPanel:Unsubscribe(callback)
    for i, cb in ipairs(self._data.subscribers) do
        if cb == callback then
            table.remove(self._data.subscribers, i)
            break
        end
    end
end

-- 通知订阅者
function DailyTaskPanel:NotifySubscribers()
    for i = #self._data.subscribers, 1, -1 do
        local callback = self._data.subscribers[i]
        if callback and type(callback) == "function" then
            local success, err = xpcall(function()
                callback(self._data)
            end, debug.traceback)
            if not success then
                table.remove(self._data.subscribers, i)
            end
        else
            table.remove(self._data.subscribers, i)
        end
    end
end

---@param data table {taskList = {}, awardList = {}, activePoint = number}
function DailyTaskPanel:UpdateData(data)
    if data.taskList then
        SL:dump(data.taskList,"===taskList==")
        self._data.taskList = data.taskList
    end
    if data.awardList then
        SL:dump(data.awardList,"===awardList==")
        self._data.awardList = data.awardList
    end
    if data.activePoint then
        print(data.activePoint,"===activePoint==")
        self._data.activePoint = data.activePoint
    end
    self:NotifySubscribers()
end

-- 获取任务列表
function DailyTaskPanel:GetTaskList()
    return self._data.taskList
end

-- 获取奖励列表
function DailyTaskPanel:GetAwardList()
    return self._data.awardList
end

-- 获取活跃点
function DailyTaskPanel:GetActivePoint()
    return self._data.activePoint
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
    self:RegisterEvent()
    self._dataCallback = function()
        self:RefreshUI()
    end
    DailyTaskPanel:Subscribe(self._dataCallback)
end

-- 进入界面
function DailyTaskPanel:Enter()    
    self:Init()
    -- 请求服务端数据
    ssrMessage:sendmsgEx("DailyTask", "reqData")
end

-- 退出界面
function DailyTaskPanel:Exit()
    if self._dataCallback then
        DailyTaskPanel:Unsubscribe(self._dataCallback)
        self._dataCallback = nil
    end
end

function DailyTaskPanel:Destroy()
    self._ui = nil
    if self._dataCallback then
        DailyTaskPanel:Unsubscribe(self._dataCallback)
        self._dataCallback = nil
    end
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
function DailyTaskPanel:btnTipsClicked()
    FGUI:Controller_setSelectedIndex(self.tipsControlle,self.tipsControlle.selectedIndex == 1 and 0 or 1)
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
    local taskData = self._data.taskList[index + 1]
    if not taskData then return end
    local taskCfg = taskDetail[index]
    if taskCfg then        
        self:UpdateTaskItem(item, taskData,taskCfg, index)
    end
end

-- 活动项渲染器
function DailyTaskPanel:ActItemRenderer(index, item)
    local actData = self.actList[index + 1]
    if not actData then return end
    self:UpdateActItem(item, actData, index)
end


-- 奖励点击
function DailyTaskPanel:OnAwardClick(awardData)
    if awardData.state == 1 then
        -- 已领取
        showTip("奖励已领取")
    elseif self._data.activePoint >= awardData.needPoint then
        -- 活跃点足够，发送领取请求
        SLBridge:SendLuaMsg(ssrNetMsgCfg.DailyTask, "getPointAward", {awardData.id})
    else
        -- 活跃点不足
        showTip("活跃点不足，需要" .. awardData.needPoint .. "点")
    end
end

-- 更新任务项
function DailyTaskPanel:UpdateTaskItem(item, taskData,taskCfg, index)
    -- 任务名称
    local text_name = FGUI:GetChild(item,"title")
    if text_name then
        FGUI:GTextField_setText(text_name, taskCfg.dec)
    end
    
    -- 进度文本
    local text_progress = FGUI:GetChild(item,"times")
    if text_progress then
        local str = string.format("<font color='#E1C330'>%s</font>/%s",taskData,taskCfg.limitTimes)
        FGUI:GRichTextField_setText(text_progress, str)
    end
    
    -- 活跃点
    local text_point = FGUI:GetChild(item,"hyCount")
    if text_point then
        local str = string.format("<font color='#E1C330'>%s</font>/%s",taskData*taskCfg.point,taskCfg.point*taskCfg.limitTimes)
        FGUI:GRichTextField_setText(text_progress, str)
    end
    local btn_tj = FGUI:GetChild(item,"tj")
    if btn_tj then
        FGUI:setVisible(btn_tj,not taskCfg.jian)
    end
    -- 前往/领取按钮
    local btn_go = FGUI:GetChild(item,"go")
    if btn_go then        
        local isGo = taskCfg.openUI or 0
        FGUI:setVisible(btn_go,isGo > 0)
        FGUI:setOnClickEvent(btn_go, function()
            FGUI:delayTouchEnabled(btn_go, FGUIDefine.DelayClickTime)
            if isGo == 1 then --门派贡献
                if SL:GetValue("GUILD_IS_JOINED") then
                    FGUIFunction:OpenGuildMainFrameUI(2)
                else
                    if SL:GetValue("IS_PC_OPER_MODE") then
                        FGUI:Open("Guild_pc", "PCGuildJoinList")
                    else
                        FGUI:Open("Guild", "GuildJoinList")
                    end
                end
            elseif isGo == 2  then --BOSS悬赏  需根据等级打开
                FGUI:Open("huodong", "BossPanel")
            end
        end)
    end
end

-- 更新活动项
function DailyTaskPanel:UpdateActItem(item, actData, index)
 
    
end

-- 刷新活跃点进度
function DailyTaskPanel:RefreshActivePoint()
     -- 活跃点
    FGUI:GTextField_setText(self._ui.point, self._data.activePoint)
    --奖励更新
    for i, v in ipairs(awardDetail) do
        local lock = FGUI:GetChild(self._ui["lock"..i])
        if lock then
            FGUI:setVisible(lock, self._data.activePoint < v.point)
        end
    end
    --进度条
    FGUI:GProgressBar_setValue(self._ui.bar, self._data.activePoint)
end

function DailyTaskPanel:RefreshUI()
    --任务刷新
    if self._data.taskList and #self._data.taskList > 0 then
        FGUI:GList_setNumItems(self._ui.taskList, #self._data.taskList)
    else
        FGUI:GList_setNumItems(self._ui.taskList, 0)
    end
    self:RefreshActivePoint()   
end

return DailyTaskPanel
