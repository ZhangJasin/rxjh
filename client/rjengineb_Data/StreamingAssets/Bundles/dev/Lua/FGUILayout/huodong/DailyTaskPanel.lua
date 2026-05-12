local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local DailyTaskPanel = class("DailyTaskPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local taskDetail = require("game_config/cfgcsv/actPointDetail")
local awardDetail = require("game_config/cfgcsv/actPointAward")
local Tips_Cfg = require("game_config/cfgcsv/TipsDetail")

-- 按 sort 字段从小到大排序
table.sort(taskDetail, function(a, b)
    return (a.sort or 0) < (b.sort or 0)
end)

local dailyTaskData =SL:RequireFile("FGUILayout/huodong/DailyTaskData")
function DailyTaskPanel:Create()
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
end

-- 进入界面
function DailyTaskPanel:Enter()    
    self:Init()    
end

-- 退出界面
function DailyTaskPanel:Exit()
    if self._subscribeToken then
        dailyTaskData:Unsubscribe(self._subscribeToken)
        self._subscribeToken = nil
    end
end

function DailyTaskPanel:Destroy()
    -- 取消所有订阅
    if self._eventTokens then
        for _, token in ipairs(self._eventTokens) do
            dailyTaskData:Get():Unsubscribe(token)
        end
        self._eventTokens = nil
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
    FGUI:GTextField_setText(self.tipsbg.title, Tips_Cfg[3]['title'])
    FGUI:GRichTextField_setText(self.tipsbg.con, Tips_Cfg[3]['tips'])

    -- 点击tips
    FGUI:setOnClickEvent(self._ui.btn_tips, handler(self, self.btnTipsClicked))
    FGUI:setOnClickEvent(self.tipsbg.close_tip, handler(self, self.btnTipsClicked))

    -- 列表渲染
    FGUI:GList_itemRenderer(self._ui.taskList, handler(self, self.TaskItemRenderer))
    FGUI:GList_itemRenderer(self._ui.actList, handler(self, self.ActItemRenderer))

    --订阅数据层事件
    self._eventTokens = {}
    table.insert(self._eventTokens, dailyTaskData:Subscribe("update_data", handler(self, self.RefreshUI)))
    table.insert(self._eventTokens, dailyTaskData:Subscribe("update_award", handler(self, self.RefreshAward)))
end

function DailyTaskPanel:btnTipsClicked()
    FGUI:Controller_setSelectedIndex(self.tipsControlle, self.tipsControlle.selectedIndex == 1 and 0 or 1)
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
                    bgVisible = false,
                    OverLap = val.award[2],
                    clickCallback = false,
                    doubleClickCallback = function()
                        self:OnAwardClick(i,val.point)
                    end
                }
                ItemUtil:ItemShow_Create(itemData, awardItem, extData)
            end   
        end
    end

    dailyTaskData:ReqData()
end

-- 任务项渲染器
function DailyTaskPanel:TaskItemRenderer(index, item)    
    local taskCfg = taskDetail[index + 1]
    if taskCfg then        
        local taskData = dailyTaskData:GetTaskProgress(taskCfg.idx)
        self:UpdateTaskItem(item, taskData, taskCfg)
    end
end

-- 活动项渲染器
function DailyTaskPanel:ActItemRenderer(index, item)
    local actData = self.actList[index + 1]
    if not actData then return end
    self:UpdateActItem(item, actData, index)
end
-- 奖励点击
function DailyTaskPanel:OnAwardClick(idx,needPoint)
    local activePoint = dailyTaskData:GetActivePoint()
    local isGot = dailyTaskData:IsGotAward(idx)
    if activePoint >= needPoint  and not isGot then        
        dailyTaskData:getAward(idx)
    end
end

-- 更新任务项
function DailyTaskPanel:UpdateTaskItem(item, taskData, taskCfg)
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
        FGUI:GRichTextField_setText(text_point, str)
    end
    local btn_tj = FGUI:GetChild(item,"tj")
    if btn_tj then
        FGUI:setVisible(btn_tj, taskCfg.jian and taskCfg.jian == 1)
    end
    -- 前往/领取按钮
    local btn_go = FGUI:GetChild(item,"go")
    if btn_go then        
        local isGo = taskCfg.openUI or 0
        FGUI:setVisible(btn_go, isGo > 0)
        FGUI:setOnClickEvent(btn_go, function()
            FGUI:delayTouchEnabled(btn_go, FGUIDefine.DelayClickTime)
            if isGo == 1 then
                if SL:GetValue("GUILD_IS_JOINED") then
                    FGUIFunction:OpenGuildMainFrameUI(2)
                else
                    if SL:GetValue("IS_PC_OPER_MODE") then
                        FGUI:Open("Guild_pc", "PCGuildJoinList")
                    else
                        FGUI:Open("Guild", "GuildJoinList")
                    end
                end
            elseif isGo == 2 then
                FGUI:Open("huodong", "BossPanel")
            end
        end)
    end
end

-- 更新活动项
function DailyTaskPanel:UpdateActItem(item, actData, index)
    
end

-- 刷新活跃点进度
function DailyTaskPanel:RefreshAward()
    local activePoint = dailyTaskData:GetActivePoint()
    --奖励更新
    for i, v in ipairs(awardDetail) do
        local lock = self._ui["lock"..i]
        if lock then
            FGUI:setVisible(lock, activePoint < v.point)
        end
        local redDot = self._ui["red"..i]
        if redDot then
            FGUI:setVisible(redDot, activePoint >= v.point and not dailyTaskData:IsGotAward(i))
        end
    end    
end

-- 刷新UI（由数据层回调触发）
function DailyTaskPanel:RefreshUI()
    local taskList = dailyTaskData:GetTaskList()
    if taskList and #taskList > 0 then
        FGUI:GList_setNumItems(self._ui.taskList, #taskList)
    else
        FGUI:GList_setNumItems(self._ui.taskList, 0)
    end     
    local activePoint = dailyTaskData:GetActivePoint()
    FGUI:GTextField_setText(self._ui.point, activePoint)
    FGUI:GProgressBar_setValue(self._ui.bar, activePoint)
    self:RefreshAward() 
end
return DailyTaskPanel
