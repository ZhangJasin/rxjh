--TransferPanel = {}

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TransferPanel = class("TransferPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local Task_cfg = require("game_config/cfgcsv/Task")
local Language = require("game_config/cfgcsv/Language")
local Condition = require("game_config/Condition")
local Transfer_cfg = require("game_config/Transfer")

local Cfg = {}
for _, v in pairs(Transfer_cfg) do
    Cfg[v.ClassID] = Cfg[v.ClassID] or {}
    Cfg[v.ClassID][v.Type] = Cfg[v.ClassID][v.Type] or {}
    Cfg[v.ClassID][v.Type][v.TransferLV] = v
end

function TransferPanel.getCfg()
    local jb = SL:GetValue("JOB")
    local zy = SL:GetValue("GOODEVILID") or 0
    return Cfg[jb] and Cfg[jb][zy] or {}
end

-- 创建界面并绑定所有UI事件
function TransferPanel:Create()
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
     
    -- 关闭按钮
    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("Transfer", "TransferPanel")
    end)

    -- 前往按钮
    FGUI:setOnClickEvent(self._ui.btn_go, function()
        self:GoToTask()
    end)

    -- 转职按钮
    FGUI:setOnClickEvent(self._ui.btn_comp, function()
        self:OnBtnCompClick()
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
    FGUI:GList_itemRenderer(self._ui.list_reward, handler(self, self.ListRewardShow))
    FGUI:GList_setDefaultItem(self._ui.list_reward, "ui://5rez3obxp51lv5j")

    -- 设置模型旋转
    self:SetModelRotate(self._ui.panel_Touch)
end

function TransferPanel:Enter()
    -- 注册消息回调
    SL:RegisterNetMsg(ssrNetMsgCfg.TransferInfo_RefreshTaskUI, handler(self, self.RefreshTaskUI))
    SL:RegisterNetMsg(ssrNetMsgCfg.TransferInfo_RefreshUI,handler(self, self.RefreshTransferUI))  
    
    self._curCfg = SL:GetValue("TRANSFER_MAINPLAYER_CONFIG")
    self._nextCfg = SL:GetValue("TRANSFER_MAINPLAYER_NEXT_CONFIG")
    self:RefreshUI()
end

function TransferPanel:Destroy()
end
function TransferPanel:Exit()
    -- 注销消息回调
    SL:UnRegisterNetMsg(ssrNetMsgCfg.TransferInfo_RefreshTaskUI)
    SL:UnRegisterNetMsg(ssrNetMsgCfg.TransferInfo_RefreshUI)

    self._curCfg = nil
    self._nextCfg = nil
    self:ClearModel()
end

-- 显示角色模型
function TransferPanel:ShowRoleModel()
    self:ClearModel()

    -- 绑定模型到 graph_role
    self._TransferModel = self:UIModel_Bind(self._ui.graph_role)
    FGUI:UIModel_setObjectEulerAngles(self._TransferModel, nil, 0, 0, 0)
    if not self._curCfg or not self._curCfg.ModeId then
        return
    end

    local Sex = SL:GetValue("SEX")
    local bodyId,helmetId = self._curCfg.ModeId[Sex+1][1],self._curCfg.ModeId[Sex+1][2]

    local modelData = SL:GetValue("FEATURE")
    local weaponId = nil
    local faceId = nil    
    local Job = SL:GetValue("JOB")
    if modelData then
        local extData = {}
        extData.sex = Sex
        extData.job = Job
        extData.bodyId = bodyId or modelData.clothID
        extData.helmetId = helmetId or modelData.helmetID
        extData.weaponId = modelData.weaponID == 0 and weaponId or modelData.weaponID
        extData.faceId = modelData.faceID == 0 and faceId or modelData.faceID

        self._TransferModelIndex = FGUI:UIModel_addCharacterModel(self._TransferModel, extData, nil, nil, Vector3.one * 1.3)
    end

    -- 设置模型点击回调
    FGUI:UIModel_setModelCallback(self._TransferModel, function(index)
        FGUI:UIModel_playAnimation(self._TransferModel, index, "FashionModel", nil, 0)
        self:SetModelRotate(self._ui.panel_Touch)
    end)
end

-- 清理模型
function TransferPanel:ClearModel()
    if self._TransferModel then
        self:UIModel_Unbind(self._ui.graph_role)
        self._TransferModel = nil
        self._TransferModelIndex = nil
    end
end

-- 设置模型旋转
function TransferPanel:SetModelRotate(uiTouch)
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = nil

    local beginFunc = function(eventData)
        if not self._TransferModel then
            return
        end
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = self._TransferModel:GetObjectEulerAngles(self._TransferModelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function(eventData)
        if not self._TransferModel then
            return
        end
        local distanceMax = 1000
        local distance = eventData.inputEvent.x - (beginX or 0)
        local angle = angleY - (distance * 360 / distanceMax)
        self._TransferModel:SetObjectEulerAngles(0, angle, 0, self._TransferModelIndex)
    end

    local endFunc = function(eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

-- 刷新界面数据
function TransferPanel:RefreshUI()
    if not self._ui then return end
    -- 显示角色模型
    self:ShowRoleModel()

    -- 显示当前转职名称
    if self._curCfg and self._curCfg.TransferName then
        FGUI:GRichTextField_setText(self._ui.txt_job_cur, self._curCfg.TransferName)
    else
        FGUI:GRichTextField_setText(self._ui.txt_job_cur, "初级职业")
    end
    -- 显示当前属性
    if self._curCfg and self._curCfg.TransferAS then
        FGUI:GList_setNumItems(self._ui.list_prop, #self._curCfg.TransferAS)
    else
        FGUI:GList_setNumItems(self._ui.list_prop, 4)
    end

    if self._nextCfg then
        -- 显示下一级转职名称
        if self._nextCfg.TransferName then
            FGUI:GRichTextField_setText(self._ui.txt_job_next, self._nextCfg.TransferName)
        else
            FGUI:GRichTextField_setText(self._ui.txt_job_next, "")
        end

        -- 显示下一级属性
        if self._nextCfg.TransferAS then
            FGUI:GList_setNumItems(self._ui.list_next_prop, #self._nextCfg.TransferAS)
        else
            FGUI:GList_setNumItems(self._ui.list_next_prop, 0)
        end

        -- 显示武功列表
        if self._nextCfg.WGId then
            FGUI:GList_setNumItems(self._ui.list_wg, #self._nextCfg.WGId)
            FGUI:setVisible(self._ui.wg_bg,true)
        else
            FGUI:GList_setNumItems(self._ui.list_wg, 0)
        end

        -- 显示气功列表
        if self._nextCfg.QGId then
            FGUI:GList_setNumItems(self._ui.list_qg, #self._nextCfg.QGId)
            FGUI:setVisible(self._ui.qg_bg,true)
        else
            FGUI:GList_setNumItems(self._ui.list_qg, 0)
        end

        -- 显示转职条件
        if self._nextCfg.ConditionID then
            local condition = self:GetConditionText(self._nextCfg.ConditionID)
            FGUI:GRichTextField_setText(self._ui.txt_condition, condition)
        else
            FGUI:GRichTextField_setText(self._ui.txt_condition, "")
        end    
        -- 显示奖励
        if self._nextCfg.Reward then
            FGUI:GList_setNumItems(self._ui.list_reward, #self._nextCfg.Reward)
            FGUI:setVisible(self._ui.img_reward,true)
        else
            FGUI:GList_setNumItems(self._ui.list_reward, 0)
        end    
        --请求转职任务信息
        ssrMessage:sendmsgEx("TransferInfo", "getTaskState")
    else
        FGUI:GRichTextField_setText(self._ui.txt_condition, "")
        FGUI:GRichTextField_setText(self._ui.txt_mission, "")
        FGUI:setVisible(self._ui.arrow_bg,false)
        FGUI:setVisible(self._ui.wg_bg,false)
        FGUI:setVisible(self._ui.qg_bg,false)
        FGUI:setVisible(self._ui.btn_go,false)
        FGUI:setVisible(self._ui.btn_comp,false)
        FGUI:setVisible(self._ui.img_reward,false)
        FGUI:GList_setNumItems(self._ui.list_reward, 0)
        FGUI:GList_setNumItems(self._ui.list_next_prop, 0)
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
    return string.format("转职条件：角色等级达到%d级<font color='%s'> (%d/%d)</font>", needLv, level >= needLv and "#00FF00" or "#FF0000",level, needLv)
end

function TransferPanel:RefreshTransferUI(_,newLv)
    self._curCfg = self._nextCfg
    local cfg = TransferPanel.getCfg()
    self._nextCfg = cfg and cfg[newLv+1] or nil
    self:RefreshUI() 
end

function TransferPanel:RefreshTaskUI(_,_totalNum,_compNum,_curTaskId)   
    if not self._ui then return end
    -- 保存任务状态
    self._totalNum = _totalNum
    self._compNum = _compNum
    self._curTaskId = _curTaskId

    -- 显示任务进度文本
    if self._totalNum > 0 then    
        -- 根据任务状态显示按钮
        if self._compNum >= self._totalNum then
            -- 全部任务完成，显示转职按钮
            FGUI:GRichTextField_setText(self._ui.txt_mission, "")
            self:ShowTransferButton("转 职")
        elseif self._curTaskId > 0 then
            -- 有进行中任务，显示前往按钮
            FGUI:GRichTextField_setText(self._ui.txt_mission, "转职任务：".. Language[Task_cfg[self._curTaskId]['task_targetdec']]['Dec'])
            self:ShowGoButton()
        else
            -- 没有任务，显示接取任务按钮
            FGUI:GRichTextField_setText(self._ui.txt_mission, "")
            self:ShowTransferButton("接取任务")
        end
    else
        -- 没有转职任务
       FGUI:GRichTextField_setText(self._ui.txt_mission, "转职任务：无可用任务")
        self:ShowTransferButton("转 职")
    end
end

-- 显示转职按钮
function TransferPanel:ShowTransferButton(str)
    FGUI:setVisible(self._ui.btn_comp, true)
    FGUI:setVisible(self._ui.btn_go, false)
    local title = FGUI:GetChild(self._ui.btn_comp, "title")
    if title then
        FGUI:GTextField_setText(title, str)
    end
end

-- 显示前往按钮
function TransferPanel:ShowGoButton()
    FGUI:setVisible(self._ui.btn_go, true)
    FGUI:setVisible(self._ui.btn_comp, true)

    -- 显示任务进度
    local title = FGUI:GetChild(self._ui.btn_comp, "title")
    if title then
        local compNum = self._compNum or 0
        local totalNum = self._totalNum or 0
        FGUI:GTextField_setText(title, string.format("任务%d/%d", compNum, totalNum))
    end
end

-- 按钮点击事件
function TransferPanel:OnBtnCompClick()
    local btnText = ""
    local title = FGUI:GetChild(self._ui.btn_comp, "title")
    if title then
        btnText = FGUI:GTextField_getText(title)
    end

    if btnText == "接取任务" then
        -- 接取任务
        self:AcceptTask()
    else
        -- 转职
        self:DoTransfer()
    end
end

-- 接取转职任务
function TransferPanel:AcceptTask()
    if self._nextCfg then
        ssrMessage:sendmsgEx("TransferInfo", "pickTask")
    end
end

-- 前往任务
function TransferPanel:GoToTask()
    if self._curTaskId and self._curTaskId > 0 then
        -- 发送寻路请求
        ssrMessage:sendmsgEx("Task", "xunlu", {self._curTaskId})
        FGUI:Close("Transfer", "TransferPanel")
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
    if self._nextCfg and self._nextCfg.WGId then
        local skillId = self._nextCfg.WGId[idx + 1]
        if skillId then
            local img_icon = FGUI:GetChild(item, "img_icon")
            if img_icon then
                local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", skillId)
                FGUI:GLoader_setUrl(img_icon, path, nil, true)                
            end
            local txt_name = FGUI:GetChild(item, "txt_name")
            if txt_name then
                local name = SL:GetValue("SKILL_UP_SHOWNAME_BY_ID", skillId, 1)
                FGUI:GTextField_setText(txt_name, name)            
            end            
        end
    end
end

-- 气功列表渲染
function TransferPanel:ListQGShow(idx, item)
    if self._nextCfg and self._nextCfg.QGId then
        local qgId = self._nextCfg.QGId[idx + 1]
        if qgId then
            local img_icon = FGUI:GetChild(item, "img_icon")
            if img_icon then
                local path = SL:GetValue("SKILL_QIGONG_SQUARE_ICON_BY_ID", qgId)
                FGUI:GLoader_setUrl(img_icon, path, nil, true)                
            end
            local txt_name = FGUI:GetChild(item, "txt_name")
            if txt_name then
                local name = SL:GetValue("SKILL_QIGONG_NAME_BY_ID", qgId)
                FGUI:GTextField_setText(txt_name, name)            
            end            
        end
    end
end

-- 奖励列表渲染
function TransferPanel:ListRewardShow(idx, item)   
    if FGUI:GetChildCount(item) > 0 then
        FGUI:RemoveChildAt(item, 0, true)
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
                ItemUtil:ItemShow_Create(itemData, item, extData)
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
    ssrMessage:sendmsgEx("TransferInfo", "doTransfer")
end

-- 打开界面
function TransferPanel:Open(data)
    self:RefreshUI()
end

return TransferPanel