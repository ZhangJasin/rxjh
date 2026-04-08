--TransferPanel = {}

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TransferPanel = class("TransferPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local Language = require("game_config/cfgcsv/Language")
local Condition = require("game_config/Condition")


-- 创建界面并绑定所有UI事件
function TransferPanel:Create()
    -- 获取界面代理
    self._ui = FGUI:ui_delegate(self.component)

    -- 关闭按钮
    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("Transfer", "TransferPanel")
    end)

    -- 前往按钮
    FGUI:setOnClickEvent(self._ui.n84, function()
        -- 前往任务
    end)

    -- 转职按钮
    FGUI:setOnClickEvent(self._ui.btn_comp, function()
        self:DoTransfer()
    end)

    -- 属性列表渲染
    FGUI:GList_itemRenderer(self._ui.list_prop, handler(self, self.ListPropShow))
    FGUI:GList_setDefaultItem(self._ui.list_prop, "ui://5rez3obxp51l1h")

    -- 下一级属性列表渲染
    FGUI:GList_itemRenderer(self._ui.list_next_prop, handler(self, self.ListNextPropShow))
    FGUI:GList_setDefaultItem(self._ui.list_next_prop, "ui://5rez3obxok6ev6v")

    -- 武功列表渲染
    FGUI:GList_itemRenderer(self._ui.list_wg, handler(self, self.ListWGShow))
    FGUI:GList_setDefaultItem(self._ui.list_wg, "ui://5rez3obxp51l1g")

    -- 气功列表渲染
    FGUI:GList_itemRenderer(self._ui.list_qg, handler(self, self.ListQGShow))
    FGUI:GList_setDefaultItem(self._ui.list_qg, "ui://5rez3obxp51l1g")

    -- 奖励列表渲染
    --FGUI:GList_itemRenderer(self._ui.list_reward, handler(self, self.ListRewardShow))
    FGUI:GList_setDefaultItem(self._ui.list_reward, "ui://5rez3obxp51lv5j")

end

function TransferPanel:Enter()
    self:RefreshUI()
end

function TransferPanel:Destroy()
end
function TransferPanel:Exit()
end

-- 显示角色模型
function TransferPanel:ShowRoleModel()
    -- 获取角色模型数据并显示在 graph_role 上
    -- local roleData = SL:GetValue("ROLE_DATA")
    -- if roleData and roleData.ModelID then
    --     local modelId = roleData.ModelID
    --     -- 显示角色模型
    -- end
end

-- 刷新界面数据
function TransferPanel:RefreshUI()
    local curCfg, nextCfg = SL:GetValue("TRANSFER_MAINPLAYER_CONFIG"),SL:GetValue("TRANSFER_MAINPLAYER_NEXT_CONFIG")
    self._curCfg = curCfg
    self._nextCfg = nextCfg
    
    -- 显示角色模型
    self:ShowRoleModel()

    -- 显示当前转职名称
    if curCfg and curCfg.TransferName then
        FGUI:GRichTextField_setText(self._ui.txt_job_cur, curCfg.TransferName)
    else
        FGUI:GRichTextField_setText(self._ui.txt_job_cur, "初级职业")
    end

    -- 显示下一级转职名称
    if nextCfg and nextCfg.TransferName then
        FGUI:GRichTextField_setText(self._ui.txt_job_next, nextCfg.TransferName)
    else
        FGUI:GRichTextField_setText(self._ui.txt_job_next, "")
    end

    -- 显示当前属性
    if curCfg and curCfg.TransferAS then
        FGUI:GList_setNumItems(self._ui.list_prop, #curCfg.TransferAS)
    else
        FGUI:GList_setNumItems(self._ui.list_prop, 4)
    end

    -- 显示下一级属性
    if nextCfg and nextCfg.TransferAS then
        FGUI:GList_setNumItems(self._ui.list_next_prop, #nextCfg.TransferAS)
    else
        FGUI:GList_setNumItems(self._ui.list_next_prop, 0)
    end

    -- 显示武功列表
    if nextCfg and nextCfg.WGId then
        FGUI:GList_setNumItems(self._ui.list_wg, #nextCfg.WGId)
    else
        FGUI:GList_setNumItems(self._ui.list_wg, 0)
    end

    -- 显示气功列表
    if nextCfg and nextCfg.QGId then
        FGUI:GList_setNumItems(self._ui.list_qg, #nextCfg.QGId)
    else
        FGUI:GList_setNumItems(self._ui.list_qg, 0)
    end

    -- 显示转职条件
    if nextCfg and nextCfg.ConditionID then
        local condition = self:GetConditionText(nextCfg.ConditionID)
        FGUI:GRichTextField_setText(self._ui.txt_condition, condition)
    else
        FGUI:GRichTextField_setText(self._ui.txt_condition, "")
    end

    -- 显示当前任务
    if nextCfg and nextCfg.TaskId and #nextCfg.TaskId > 0 then
        local taskInfo = self:GetTaskInfo(nextCfg.TaskId)
        FGUI:GRichTextField_setText(self._ui.txt_mission, taskInfo)
    else
        FGUI:GRichTextField_setText(self._ui.txt_mission, "已全部完成")
    end

    -- 显示奖励
    if nextCfg and nextCfg.Reward then
        FGUI:GList_setNumItems(self._ui.list_reward, #nextCfg.Reward)
    else
        FGUI:GList_setNumItems(self._ui.list_reward, 0)
    end    
end

-- 获取条件文本
function TransferPanel:GetConditionText(conditionId)
    local curCfg = Condition[conditionId]
    local needLv = 1
    if curCfg then
        needLv= tonumber(curCfg.ConditionShow or 1)
    end
    local level = SL:GetValue("LEVEL") or 1
    return string.format("角色等级达到%d级<font color='%s'> (%d/%d)</font>", needLv, level >= level and "#00FF00" or "#FF0000",level, needLv)
end

-- 获取任务信息
function TransferPanel:GetTaskInfo(taskIds)
    -- 检查任务完成状态
    local taskProgressList = SL:GetValue("TASK_PROGRESS_LIST") or {}
    local allComplete = true
    for _, taskId in ipairs(taskIds) do
        if taskProgressList[tostring(taskId)] then
            if taskProgressList[tostring(taskId)].state ~= 2 then
                allComplete = false
                break
            end
        else
            allComplete = false
            break
        end
    end

    if allComplete then
        return "已全部完成"
    else
        return "进行中" --当前任务信息
    end
end

-- 当前属性列表渲染
function TransferPanel:ListPropShow(idx, item)
    local val = FGUI:GetChild(item, "val")
    if self._curCfg and self._curCfg.TransferAS then
        local propData = self._curCfg.TransferAS[idx + 1]
        if propData then
            FGUI:GTextField_setText(val, propData[2])
        end
    end
end

-- 下一级属性列表渲染
function TransferPanel:ListNextPropShow(idx, item)
    local val = FGUI:GetChild(item, "val")
    if self._nextCfg and self._nextCfg.TransferAS then
        local propData = self._nextCfg.TransferAS[idx + 1]
        if propData then
            FGUI:GTextField_setText(val, propData[2])
        end
    end
end

-- 武功列表渲染
function TransferPanel:ListWGShow(idx, item)
    
end

-- 气功列表渲染
function TransferPanel:ListQGShow(idx, item)
  
end

-- 奖励列表渲染
function TransferPanel:ListRewardShow(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end

    if self._nextCfg and self._nextCfg.Reward then
        local reward = self._nextCfg.Reward[idx + 1]
        if reward then
            local itemData = SL:GetValue("ITEM_DATA", reward[1])
            if itemData then
                local extData = {
                    hideTip = false,
                    itemTipData = itemData,
                    clickCallback = false,
                    doubleClickCallback = true,
                    bgVisible = true,
                    OverLap = reward[2]
                }
                ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
            end
        end
    end
end

-- 执行转职
function TransferPanel:DoTransfer()
    if not self._nextCfg then
        return
    end

    -- 发送转职请求
    SL:SendNetMsg(9998, 11, {transferId = self._nextCfg.ID}, nil, nil)
end

-- 打开界面
function TransferPanel:Open(data)
    self:RefreshUI()
end

return TransferPanel