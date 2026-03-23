local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local NoticePanel = class("NoticePanel", BaseFGUILayout)

local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort
local tclear = table.clear

local fontSize = SL:GetMetaValue("GAME_DATA","DEFAULT_FONT_SIZE_NOTICE") or 16
local NOTICE_TABLE_KEY = "Notice"

local PACKAGE_NAME = "Notice"

function NoticePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:AdaptNotch(self.component)
    local IsPC = SL:GetValue("IS_PC_OPER_MODE")
    PACKAGE_NAME = IsPC and "Notice_pc" or "Notice"

    self._rootEffect        = self._ui["Node_effect"]
    self._rootServerTips    = self._ui["Node_server_tips"]
    self._rootSystem        = self._ui["Node_system"]
    self._rootSystemXY      = self._ui["Node_system_xy"]
    self._rootTimerTipsXY   = self._ui["Node_timer_xy_tips"]
    self._listviewTimerTips = self._ui["List_timer_tips"]
    self._rootAttribute     = self._ui["Node_attribute"]
    self._rootItemTips      = self._ui["Node_item_tips"]
    self._rootDropTips      = self._ui["Node_drop_tips"]
    self._rootNormalTips    = self._ui["Node_normal_tips"]
    self._rootTopTips       = self._ui["Node_top_tips"]

    if not IsPC then
        self._graphItemEffect   = self._ui["Graph_itemEffect"]
    end

    -- 全服消息
    self._serverNotice = {}
    self._serverNoticeStatus = false
    self._serverNotice_11 = {}
    self._serverNoticeStatus_11 = false

    -- 消息 系统 跑马灯 和 顶端弹窗
    self._systemNotice = {}
    self._systemNoticeFlag = {}

    -- 系统 提示弹窗 警告
    self._systemTipsPool = Queue.new()
    self._systemTipsCells = Queue.new()
    self._systemTipsData = Queue.new()
    self._systemTipsMap = {}
    self._systemWait = false
    self._systemMoveY = SL:GetValue("IS_PC_OPER_MODE") and -25 or -50

    -- 系统 设置XY 跑马灯 
    self._systemXYCells = {}

    -- 飘字 物品拾取获得消耗
    self._itemTipsPool = Queue.new()
    self._itemTipsCells = Queue.new()
    self._itemTipsData = Queue.new()
    self._itemWait = false
    self._itemMoveY = SL:GetValue("IS_PC_OPER_MODE") and -25 or -40

    -- 飘字 属性变化
    self._attrDataPool = Queue.new()
    self._attrNodePool = Queue.new()
    self._attrTimer = nil
    self._attrEnable = false
    self._attrEnableTimer = nil     -- 进入游戏一定时间内不飘属性

    -- 掉落物品提示
    self._dropTipsCells = {}

    -- 特效
    self._screenEffects = {}

    self._topTips = {}
end

function NoticePanel:Enter()
	self:RegisterEvent()
end

function NoticePanel:Exit(isRemovedEvent)
	self:RemoveEvent()
    -- 全服消息
    tclear(self._serverNotice)
    self._serverNoticeStatus = false
    tclear(self._serverNotice_11)
    self._serverNoticeStatus_11 = false

    -- 消息 系统 跑马灯 和 顶端弹窗
    tclear(self._systemNotice)
    tclear(self._systemNoticeFlag)

    -- 系统 提示弹窗 警告
    self._systemWait = false
    self._systemTipsData:clear()
    table.clear(self._systemTipsMap)
    while not self._systemTipsCells:empty() do
        local removeNode = self._systemTipsCells:pop()
        FGUI:RemoveFromParent(removeNode, true)
    end
    while not self._systemTipsPool:empty() do
        local removeNode = self._systemTipsPool:pop()
        FGUI:RemoveFromParent(removeNode, true)
    end

    -- 系统 设置XY 跑马灯 
    self._systemXYCells = {}

    -- 飘字 物品拾取获得消耗
    self._itemWait = false
    self._itemTipsData:clear()
    while not self._itemTipsCells:empty() do
        local ui = self._itemTipsCells:pop()
        FGUI:RemoveFromParent(ui.nativeUI, true)
    end
    while not self._itemTipsPool:empty() do
        local ui = self._itemTipsPool:pop()
        FGUI:RemoveFromParent(ui.nativeUI, true)
    end

    -- 飘字 属性变化
    self:ClearAttributeTimer()
    self._attrDataPool:clear()
    while not self._attrNodePool:empty() do
        local removeNode = self._attrNodePool:pop()
        FGUI:RemoveFromParent(removeNode, true)
    end

    -- 掉落物品提示
    tclear(self._dropTipsCells)

    tclear(self._screenEffects)
    FGUI:RemoveAllChildren(self._rootEffect)

    tclear(self._topTips)
    FGUI:RemoveAllChildren(self._rootTopTips, 0, -1, false)

    if self._graphItemEffect then
        FGUI:UIModel_clear(self._graphItemEffect)
    end


    if isRemovedEvent then
        return
    end
end

function NoticePanel:Destroy()
    self._ui = nil	

    self._rootEffect        = nil
    self._rootServerTips    = nil
    self._rootSystem        = nil
    self._rootSystemXY      = nil
    self._rootTimerTipsXY   = nil
    self._listviewTimerTips = nil
    self._rootAttribute     = nil
    self._rootItemTips      = nil
    self._rootDropTips      = nil
    self._rootNormalTips    = nil
    self._rootTopTips       = nil

    self._graphItemEffect   = nil
end


--------------------------------------------------------
function NoticePanel:OnEnterWorld()
    if self._attrEnableTimer then
        SL:UnSchedule(self._attrEnableTimer)
        self._attrEnableTimer = nil
    end
    self._attrEnableTimer = SL:ScheduleOnce(function()
        self._attrEnable = true
        self._attrEnableTimer = nil

        -- 清理已存储属性
        SL:SetValue("CLEAR_CHANGED_CUR_ATTR")
        SL:SetValue("CLEAR_CHANGED_MAX_ATTR")
    end, 3)
end

function NoticePanel:OnShowServerNotice(data)
    tinsert(self._serverNotice, data)
    self:CheckServerNotice()
end

function NoticePanel:CheckServerNotice()
    if self._serverNoticeStatus then
        return
    end

    if not next(self._serverNotice) then
        return
    end

    self._serverNoticeStatus = true

    local data  = tremove(self._serverNotice, 1)
    data.FColor = data.FColor or 255
    data.BColor = data.BColor or 255
    
    local FColorRGB = SL:GetColorByStyleId(data.FColor)

    local label = FGUI:CreateObject(self._rootServerTips, PACKAGE_NAME, "Label")
    local title = FGUI:GLabel_getTextField(label)
    FGUI:GTextField_setColor(title, FColorRGB)
    if data.BColor ~= -1 then
        local BColorRGB = SL:GetColorByStyleId(data.BColor)
        FGUI:GTextField_setStroke(title, 1)
        FGUI:GTextField_setStrokeColor(title, BColorRGB)
    end
    FGUI:GTextField_setText(title, data.Msg)

    -- action
    local screenWidth = SL:GetValue("SCREEN_WIDTH")
    local textW, textH = FGUI:getSize(label)
    local actionTime  = 15 + (textW / screenWidth * 15)
    local move1 = FGUI:ActionMoveTo(0, screenWidth, 0)
    local move2 = FGUI:ActionMoveTo(actionTime, 0 - textW, 0)
    local sequence = FGUI:ActionSequence(move1, move2, FGUI:ActionCallFunc(handler(self, self.RemoveServerNotice, label, true)))
    FGUI:runAction(label, sequence)
end

function NoticePanel:RemoveServerNotice(label)
    FGUI:RemoveFromParent(label, true)
    self._serverNoticeStatus = false
    self:CheckServerNotice()
end


function NoticePanel:OnShowServerEventNotice(data)
    if data.Type == 11 then
        tinsert(self._serverNotice_11, data)
        self:ShowServerEventNotice_11(data)
    end
end

function NoticePanel:ShowServerEventNotice_11()
    if self._serverNoticeStatus_11 then
        return
    end
    if not next(self._serverNotice_11) then
        return
    end
        
    self._serverNoticeStatus_11 = true

    local item  = tremove(self._serverNotice_11, 1)
    item.FColor = item.FColor or 255
    item.BColor = item.BColor or 255

    local FColorRGB     = SL:GetColorByStyleId(item.FColor)
    local screenWidth = SL:GetValue("SCREEN_WIDTH")
    local width = screenWidth / 2
    local height = 30

    local label = FGUI:CreateObject(self._rootServerTips, PACKAGE_NAME, "LabelServerNotice")
    local title = FGUI:GLabel_getTextField(label)
    FGUI:GTextField_setColor(title, FColorRGB)
    FGUI:GTextField_setFontSize(title, fontSize)
    if item.BColor ~= -1 then
        local BColorRGB = SL:GetColorByStyleId(item.BColor)
        FGUI:GTextField_setStroke(title, 1)
        FGUI:GTextField_setStrokeColor(title, BColorRGB)
    end
    FGUI:GTextField_setText(title, item.Msg)

    FGUI:setAnchorPoint(label, 0.5, 0, true)
    FGUI:setPosition(label, width, 0)
    FGUI:setSize(label, width, height)

    FGUI:setPosition(title, width, height / 2)

    -- action
    local w, h = FGUI:getSize(title)
    local actionTime = 10 + (w / width * 10)

    local move = FGUI:ActionMoveTo(actionTime, 0 - w, height/2)
    local sequence = FGUI:ActionSequence(move, FGUI:ActionCallFunc(handler(self, self.RemoveServerEventNotice_11, label, true)))
    FGUI:runAction(title, sequence)
end

function NoticePanel:RemoveServerEventNotice_11(label)
    self._serverNoticeStatus_11 = false
    FGUI:RemoveFromParent(label, true)
    self:ShowServerEventNotice_11()
end

function NoticePanel:OnShowSystemNotice(data)
    data.Y              = data.Y or 0
    data.Count          = data.Count or 1
    data.FColor         = data.FColor or 255
    data.BColor         = data.BColor or 255
    data.Ext            = data.Ext or nil
    data.fSize          = data.fSize or fontSize
    local shout = false
    if data.Ext then
        shout = data.Ext.Shout or false
    end

    local posY = data.Y
    self._systemNotice[posY] = self._systemNotice[posY] or {}
    tinsert(self._systemNotice[posY], data)

    self:ShowSystemNotice(posY, shout)
end

function NoticePanel:ShowSystemNotice(posY, shout)
    if self._systemNoticeFlag[posY] then
        return
    end

    local items = self._systemNotice[posY]
    local item = tremove(items, 1)
    if not item then
        return
    end

    self._systemNoticeFlag[posY] = true
    local FColorRGB = SL:GetColorByStyleId(item.FColor)
    local screenWidth = SL:GetValue("SCREEN_WIDTH")
    local width = math.floor(screenWidth * 0.6)

    local comp = FGUI:CreateObject(self._rootSystem, PACKAGE_NAME, "CompSystemNotice")
    FGUI:setPosition(comp, 0, item.Y)
    FGUI:setWidth(comp, width)
    FGUI:setVisible(FGUI:GetChild(comp, "ImageHorn"), shout)

    local label = FGUI:GetChild(comp, "label")
    local title = FGUI:GLabel_getTextField(label)
    FGUI:GTextField_setColor(title, FColorRGB)
    FGUI:GTextField_setFontSize(title, item.fSize)
    if item.BColor ~= -1 then
        local BColorRGB = SL:GetColorByStyleId(item.BColor)
        FGUI:GTextField_setStroke(title, 1)
        FGUI:GTextField_setStrokeColor(title, BColorRGB)
    end
    FGUI:GTextField_setText(title, item.Msg)
    local tilteY = FGUI:getPositionY(title)

    -- action
    local titleW = FGUI:getWidth(title) 
    local actionTime    = math.ceil(10 + (titleW / width * 10))
    FGUI:setPositionX(title, width)
    local y = FGUI:getPositionY(title)
    local move1 = FGUI:ActionMoveTo(0, width, y)
    local move2 = FGUI:ActionMoveTo(actionTime, -titleW, tilteY)
    local sequence = FGUI:ActionSequence(move1, move2)
    local acRepeat = FGUI:ActionRepeat(sequence, item.Count)
    local t = table.New(NOTICE_TABLE_KEY)
    t.posY = posY
    t.comp = comp
    t.shout = shout
    local action = FGUI:ActionSequence(acRepeat, FGUI:ActionCallFunc(handler(self, self.RemoveSystemNotice, t, true)))
    FGUI:runAction(title, action)
end

function NoticePanel:RemoveSystemNotice(data)
    self._systemNoticeFlag[data.posY] = false
    FGUI:RemoveFromParent(data.comp, true)
    self:ShowSystemNotice(data.posY, data.shout)
    data.comp = nil
    data.posY = nil
    data.shout = nil
    table.recycle(NOTICE_TABLE_KEY, data)
end

function NoticePanel:OnShowSystemScaleNotice(data)
    data.Y              = data.Y or 125
    data.Count          = data.Count or 1
    data.FColor         = data.FColor or 255
    data.BColor         = data.BColor or 255
    data.ShowTime       = data.ShowTime or 1.4

    local posY = data.Y
    self._systemNotice[posY] = self._systemNotice[posY] or {}
    tinsert(self._systemNotice[posY], data)

    self:ShowSystemScaleNotice(posY)
end

function NoticePanel:ShowSystemScaleNotice(posY)
    if self._systemNoticeFlag[posY] then
        return
    end
    local items = self._systemNotice[posY]
    local item  = tremove(items, 1)
    if not item then
        return
    end

    self._systemNoticeFlag[posY] = true
    local FColorRGB     = SL:GetColorByStyleId(item.FColor)

    local label = FGUI:CreateObject(self._rootSystem, PACKAGE_NAME, "LabelSystemScaleNotice")
    local title = FGUI:GLabel_getTextField(label)
    FGUI:GTextField_setColor(title, FColorRGB)
    FGUI:GTextField_setFontSize(title, fontSize)
    if item.BColor ~= -1 then
        local BColorRGB = SL:GetColorByStyleId(item.BColor)
        FGUI:GTextField_setStroke(title, 1)
        FGUI:GTextField_setStrokeColor(title, BColorRGB)
    end
    FGUI:GTextField_setText(title, item.Msg)

    FGUI:setPosition(label, 0, item.Y)

    -- action
    local t = table.New(NOTICE_TABLE_KEY)
    t.label = label
    t.posY = posY

    local sequence = FGUI:ActionSequence(
        FGUI:ActionShow(),
        FGUI:ActionFadeIn(0.1),
        FGUI:ActionScaleTo(0, 1.5), 
        FGUI:ActionEaseBackOut(FGUI:ActionScaleTo(0.3, 1)), 
        FGUI:ActionDelayTime(item.ShowTime), 
        FGUI:ActionFadeOut(0.5),
        FGUI:ActionHide()
    )
   
    local acRepeat = FGUI:ActionRepeat(sequence, item.Count)
    local action = FGUI:ActionSequence(acRepeat, FGUI:ActionCallFunc(handler(self, self.RemoveSystemScaleNotice, t, true)))
    FGUI:runAction(label, action)
end

function NoticePanel:RemoveSystemScaleNotice(data)
    FGUI:RemoveFromParent(data.label, true)
    self._systemNoticeFlag[data.posY] = nil
    self:ShowSystemScaleNotice(data.posY)
    data.label = nil
    data.posY = nil
    table.recycle(NOTICE_TABLE_KEY, data)
end


function NoticePanel:OnShowSystemXYNotice(data)
    local X             = tonumber(data.X)
    local Y             = tonumber(data.Y)
    data.FColor         = data.FColor or 255
    data.BColor         = data.BColor or 255
    local FColorRGB     = SL:GetColorByStyleId(data.FColor)

    if not X or not Y then return end

    FGUI:setPosition(self._rootSystemXY, X, Y)

    local label = FGUI:CreateObject(self._rootSystemXY, PACKAGE_NAME, "Label")
    local title = FGUI:GLabel_getTextField(label)
    FGUI:GTextField_setColor(title, FColorRGB)
    FGUI:GTextField_setFontSize(title, fontSize)
    if data.BColor ~= -1 then
        local BColorRGB = SL:GetColorByStyleId(data.BColor)
        FGUI:GTextField_setStroke(title, 1)
        FGUI:GTextField_setStrokeColor(title, BColorRGB)
    end
    FGUI:GTextField_setText(title, data.Msg)

    tinsert(self._systemXYCells, label)

    if not self._systemXYNoticeH then
        self._systemXYNoticeH = FGUI:getHeight(label) + 10
    end
    local count = #self._systemXYCells
    for key, cell in pairs(self._systemXYCells) do
        FGUI:setPositionY(cell, -(count-key) * self._systemXYNoticeH)
    end

    local sequence = FGUI:ActionSequence(FGUI:ActionDelayTime(2.5), FGUI:ActionFadeOut(0.5), FGUI:ActionCallFunc(handler(self, self.RemoveSystemXYNotice, nil, true)), FGUI:ActionRemoveSelf())
    FGUI:runAction(label, sequence)
end

function NoticePanel:RemoveSystemXYNotice()
    tremove(self._systemXYCells, 1)
end

function NoticePanel:GetSystemTip()
    if self._systemTipsPool:empty() then
        local label = FGUI:CreateObject(self._rootNormalTips, PACKAGE_NAME, "LabelSystemTip")
        FGUI:setPositionX(label, 0)
        return label
    end
    return self._systemTipsPool:pop()
end
function NoticePanel:RecycleSystemTipsNode(node)
    FGUI:setVisible(node, false)
    FGUI:setAlpha(node, 1)
    FGUI:stopAllActions(node)
    self._systemTipsPool:push(node)
end

function NoticePanel:RemoveFirstSystemTipsNode(removeNode)
    if removeNode then
        local size = self._systemTipsCells:size()
        for idx = 1, size do
            if self._systemTipsCells:at(idx) == removeNode then
                self._systemTipsCells:remove_at(idx)
                self:RecycleSystemTipsNode(removeNode)
                break
            end
        end
    end
    self:CheckSystemTip()
end

function NoticePanel:ClearSystemTipWait()
    self._systemWait = false
    self:CheckSystemTip()
end

function NoticePanel:OnShowSystemTips(str)
    --过滤重复提示
    if self._systemTipsMap[str] then return end
    self._systemTipsData:push(str)
    self._systemTipsMap[str] = true
    self:CheckSystemTip()
end

function NoticePanel:RemoveSystemTip(str)
    self._systemTipsMap[str] = nil
end

function NoticePanel:CheckSystemTip()
    if self._systemWait then return end
    if self._systemTipsCells:size() >= 2 then return end
    local str = self._systemTipsData:pop()
    if not str then return end

    local label = self:GetSystemTip()
    FGUI:GLabel_setTitle(label, str)

    self._systemTipsCells:push(label)
    FGUI:setPositionY(label, 0)
    FGUI:setVisible(label, true)
    
    local moveTime = 0.6
    local moveSpeed = -moveTime / self._systemMoveY
    if not self._systemTipH then
        self._systemTipH = FGUI:getHeight(label)
    end
    self._systemWait = true
    -- action
    FGUI:runAction(label, FGUI:ActionSequence(
            FGUI:ActionDelayTime(0.8),--延迟后续tip出现时间,避免重叠
            FGUI:ActionCallFunc(handler(self, self.ClearSystemTipWait, nil, true)),
            FGUI:ActionDelayTime(0.3),
            FGUI:ActionCallFunc(handler(self, self.RemoveSystemTip, str, true)),
            FGUI:ActionCallFunc(handler(self, self.RemoveFirstSystemTipsNode, label, true))
        )
    )
    FGUI:runAction(label, FGUI:ActionSequence(
        FGUI:ActionDelayTime(0.7),
        FGUI:ActionFadeTo(0.4, 0)
    ))
    FGUI:runAction(label, FGUI:ActionMoveTo(moveTime, 0, self._systemMoveY), "move")
    
    -- 重排坐标
    local cellCount = self._systemTipsCells:size()
    for i = 1, cellCount - 1 do
        local node = self._systemTipsCells:at(i)
        if node then
            FGUI:stopActionByTag(node, "move")
            local curY = FGUI:getPositionY(node)
            local endY = self._systemMoveY - self._systemTipH * (cellCount - i)
            local time = math.abs((endY - curY) * moveSpeed)
            FGUI:runAction(node, FGUI:ActionMoveTo(time, 0, endY))
        end
    end
end

function NoticePanel:OnShowTimerNotice(data)
    data.Time           = data.Time or 5
    data.Label          = data.Label or ""
    data.X              = data.X or 0
    data.Y              = data.Y or 0
    data.Count          = data.Count or 1
    data.FColor         = data.FColor or 255
    data.BColor         = data.BColor or 255
    local FColorRGB     = SL:GetColorByStyleId(data.FColor)

    local label = FGUI:GList_addItemFromPool(self._listviewTimerTips)
    local title = FGUI:GLabel_getTextField(label)
    FGUI:setPosition(title, 50 + data.X, -data.Y)
    FGUI:GTextField_setColor(title, FColorRGB)
    FGUI:GTextField_setFontSize(title, fontSize)
    if data.BColor ~= -1 then
        local BColorRGB = SL:GetColorByStyleId(data.BColor)
        FGUI:GTextField_setStroke(title, 1)
        FGUI:GTextField_setStrokeColor(title, BColorRGB)
    else
        FGUI:GTextField_setStroke(title, 0)
    end

    FGUI:GList_resizeToFit(self._listviewTimerTips)

    local remaining = data.Time
    local Msg = data.Msg--Msg_formatPercent(data.Msg)
    local hasFormat = string.find(Msg, "%%") 
    local function callback()
        local str = Msg 
        local formatMsg = function()
            str = hasFormat and string.format(Msg, remaining) or Msg
        end
        if not pcall(formatMsg) then 
            SL:release_print("ERROR :TimerNotice "..Msg.." 格式错误")
            FGUI:GList_removeChildToPool(self._listviewTimerTips, label)
            FGUI:stopAllActions(label)
            FGUI:GList_resizeToFit(self._listviewTimerTips)
            return 
        end

        FGUI:GLabel_setTitle(label, str)

        if remaining < 0 then
            if data.Label and string.len(data.Label) > 0 then
                SL:SubmitAct({Act = data.Label})
            end
            FGUI:GList_removeChildToPool(self._listviewTimerTips, label)
            FGUI:stopAllActions(label)
            FGUI:GList_resizeToFit(self._listviewTimerTips)
        end
        remaining = remaining - 1
    end

    SL:schedule(label, callback, 1)
    callback()
end

function NoticePanel:OnDeleteTimerNotice()
    local num = FGUI:GList_getNumItems(self._listviewTimerTips)
    for i = 1, num do
        local item = FGUI:GetChildAt(self._listviewTimerTips, i - 1)
        if item then
            FGUI:stopAllActions(item)
        end
    end
    FGUI:GList_removeChildrenToPool(self._listviewTimerTips)
    FGUI:GList_resizeToFit(self._listviewTimerTips)
end

function NoticePanel:OnShowTimerXYNotice(data)
    data.Time           = data.Time or 5
    data.Y              = data.Y or 0
    data.X              = data.X or 0
    data.Count          = data.Count or 1
    data.FColor         = data.FColor or 255
    data.BColor         = data.BColor or 0
    local FColorRGB     = SL:GetColorByStyleId(data.FColor)

    local screenWidth = SL:GetValue("SCREEN_WIDTH")
    local screenHeight = SL:GetValue("SCREEN_HEIGHT")

    FGUI:RemoveAllChildren(self._rootTimerTipsXY)

    local x = data.X == 0 and screenWidth/2 or data.X
    local y = data.Y == 0 and screenHeight*3/5 or data.Y
    FGUI:setPosition(self._rootTimerTipsXY, x, y)

    local label = FGUI:CreateObject(self._rootTimerTipsXY, PACKAGE_NAME, "Label")
    local title = FGUI:GLabel_getTextField(label)
    FGUI:GTextField_setColor(title, FColorRGB)
    FGUI:GTextField_setFontSize(title, fontSize)
    if data.BColor ~= -1 then
        local BColorRGB = SL:GetColorByStyleId(data.BColor)
        FGUI:GTextField_setStroke(title, 1)
        FGUI:GTextField_setStrokeColor(title, BColorRGB)
    end

    if data.X == 0 then
        FGUI:setAnchorPoint(label, 0.5, 0, true)
    else
        FGUI:setAnchorPoint(label, 0, 0, true)
    end
    FGUI:setPosition(label, 0, 0)

    local remaining = data.Time - 1
    local Msg = data.Msg--Msg_formatPercent(data.Msg)
    local hasFormat = string.find(Msg, "%%")
    local function callback()
        local str = Msg 
        local formatMsg = function()
            str = hasFormat and string.format(Msg, SL:SecondToHMS(remaining, true)) or Msg
        end
        if not pcall(formatMsg) then 
            SL:release_print("ERROR :TimerNoticeXY "..Msg.." 格式错误")
            FGUI:RemoveFromParent(label, true)
            return
        end
        
        FGUI:GLabel_setTitle(label, str)
        local w,h = FGUI:getSize(label)

        if remaining < 0 then
            if data.Label and string.len(data.Label) > 0 then
                SL:SubmitAct({Act = data.Label})
            end
            FGUI:RemoveFromParent(label, true)
        end
        remaining = remaining - 1
    end
    SL:schedule(label, callback, 1)
    callback()
end

function NoticePanel:OnDeleteTimerXYNotice()
    FGUI:RemoveAllChildren(self._rootTimerTipsXY)
end

---------------------------------------------------------------------------------------
---物品/经验 获取/消耗 提示

function NoticePanel:GetItemTip()
    if self._itemTipsPool:empty() then
        local label = FGUI:CreateObject(self._rootItemTips, PACKAGE_NAME, "LabelItemTip")
        FGUI:setPositionX(label, 0)
        local ui = FGUI:ui_delegate(label)
        ui.gradeCtl = FGUI:getController(label, "grade")
        return ui
    end
    return self._itemTipsPool:pop()
end
function NoticePanel:RecycleItemTipsNode(ui)
    local label = ui.nativeUI
    FGUI:setVisible(label, false)
    FGUI:setAlpha(label, 1)
    FGUI:stopAllActions(label)
    self._itemTipsPool:push(ui)
end

function NoticePanel:RemoveFirstItemTipsNode(ui)
    if ui then
        local size = self._itemTipsCells:size()
        for idx = 1, size do
            if self._itemTipsCells:at(idx) == ui then
                self._itemTipsCells:remove_at(idx)
                self:RecycleItemTipsNode(ui)
                break
            end
        end
    end
    self:CheckItemTip()
end

function NoticePanel:ClearItemTipWait()
    self._itemWait = false
    self:CheckItemTip()
end

function NoticePanel:OnShowItemTips(str, icon, grade, lock, isGet)
    local t = table.New(NOTICE_TABLE_KEY)
    t.str = str
    t.grade = grade or 0
    t.icon = icon
    t.lock = lock or false
    t.isGet = isGet
    self._itemTipsData:push(t)
    self:CheckItemTip()
end

function NoticePanel:CheckItemTip()
    if self._itemWait then return end
    local t = self._itemTipsData:pop()
    if not t then return end

    local ui = self:GetItemTip()
    local label = ui.nativeUI
    FGUI:GLabel_setTitle(label, t.str)
    FGUI:GLabel_setTitleColor(label, t.isGet and "#FFFFFF" or "#FF0000")
    FGUI:GLoader_setUrl(ui.Loader_icon, t.icon)
    FGUI:setVisible(ui.Image_lock, t.lock)
    FGUI:Controller_setSelectedIndex(ui.gradeCtl, t.grade)

    table.Recycle(NOTICE_TABLE_KEY, t)


    self._itemTipsCells:push(ui)
    FGUI:setPositionY(label, 0)
    FGUI:setVisible(label, true)
    
    local moveTime = 0.6
    local delayTime = 0.6
    local moveSpeed = -moveTime / self._itemMoveY
    local allTime = 1.8
    self._itemWait = true

    FGUI:UIModel_clear(self._graphItemEffect)
    if t.isGet then
        FGUI:AddChild(label, self._graphItemEffect)
        FGUI:setPosition(self._graphItemEffect, 100, 15)
        FGUI:UIModel_addFx(self._graphItemEffect, 100042, 1, nil, nil, {x = 0.6, y = 0.6, z = 0.6})
    end

    -- action
    FGUI:runAction(label, FGUI:ActionSequence(
            FGUI:ActionDelayTime(delayTime),--延迟后续tip出现时间,避免重叠
            FGUI:ActionCallFunc(handler(self, self.ClearItemTipWait, nil, true)),
            FGUI:ActionDelayTime(allTime - delayTime),
            FGUI:ActionCallFunc(handler(self, self.RemoveFirstItemTipsNode, ui, true))
        )
    )
    local fadeTime = 0.5
    FGUI:runAction(label, FGUI:ActionSequence(
        FGUI:ActionDelayTime(allTime - fadeTime, 0),
        FGUI:ActionFadeTo(fadeTime, 0)
    ))
    FGUI:runAction(label, FGUI:ActionMoveTo(moveTime, 0, self._itemMoveY), "move")
    
    -- 重排坐标
    local space = delayTime / moveSpeed
    local cellCount = self._itemTipsCells:size()
    for i = 1, cellCount - 1 do
        local ui = self._itemTipsCells:at(i)
        local node = ui.nativeUI
        if node then
            FGUI:stopActionByTag(node, "move")
            local curY = FGUI:getPositionY(node)
            local endY = self._itemMoveY - space * (cellCount - i)
            local time = math.abs((endY - curY) * moveSpeed)
            FGUI:runAction(node, FGUI:ActionMoveTo(time, 0, endY))
        end
    end
end
----------------------------------------------------------------------------------------------


function NoticePanel:GetAttributeNode()
    if self._attrNodePool:empty() then 
        return FGUI:CreateObject(self._rootAttribute, PACKAGE_NAME, "CompAttributeTip")
    end 
    return self._attrNodePool:pop()
end

function NoticePanel:RecycleAttribute(node)
    FGUI:stopAllActions(node)
    self._attrNodePool:push(node)
end

local AttrKey = "AttrDataKey"
function NoticePanel:OnPropertyChange()
    -- 开关
    if not self._attrEnable then return end

    local changedCurAttr = SL:GetValue("CHANGED_CUR_ATTR")
    local changedMaxAttr = SL:GetValue("CHANGED_MAX_ATTR")

    for id, v in pairs(changedCurAttr) do
        if v > 0 then
            local cfg = SL:GetValue("ATTR_CONFIG", id)
            if cfg and cfg.Floating == 1 and cfg.Trends ~= 1 then
                local data = table.New(AttrKey)
                data.id = id 
                data.name = cfg.Name
                data.attr = v
                data.type = cfg.Type 
                self._attrDataPool:push(data)
            end
        end
    end
    for id, v in pairs(changedMaxAttr) do
        if v > 0 then
            local cfg = SL:GetValue("ATTR_CONFIG", id)
            if cfg and cfg.Floating == 1 and cfg.Trends ~= 1 then
                local data = table.New(AttrKey)
                data.id = id 
                data.name = cfg.Name
                data.attr = v
                data.type = cfg.Type 
                self._attrDataPool:push(data)
            end
        end
    end
    SL:SetValue("CLEAR_CHANGED_CUR_ATTR")
    SL:SetValue("CLEAR_CHANGED_MAX_ATTR")

    if (not self._attrTimer) and self._attrDataPool:size() > 0 then
        self._attrTimer = SL:Schedule(handler(self, self.ShowAttributes), 2)
    end
end

function NoticePanel:ClearAttributeTimer()
    if not self._attrTimer then return end
    SL:UnSchedule(self._attrTimer)
    self._attrTimer = nil
end

--属性飘字
local MAX_ATTR_COUNT = 5
function NoticePanel:ShowAttributes()
    if not SL:GetValue("SETTING_PROPERTY_TIPS_EN") then
        self._attrDataPool:clear()
        self:ClearAttributeTimer()
        return 
    end

    for index = 1, MAX_ATTR_COUNT do  
        if self._attrDataPool:size() == 0 then
            if self._attrTimer then 
                SL:UnSchedule(self._attrTimer)
                self._attrTimer = nil 
            end
            return 
        end

        local attrData = self._attrDataPool:pop()
        local node = self:GetAttributeNode()
        FGUI:setPosition(node, 0, (index - 1) * 35 + 100)
        
        local textName = FGUI:GetChild(node, "Text_name") 
        local textAttr = FGUI:GetChild(node, "Text_attr")
        local attrStr  = attrData.attr
        if attrData.type == 1 then
            attrStr = (attrData.attr / 100) .. "%"
        end
        FGUI:GTextField_setText(textName, attrData.name)
        FGUI:GTextField_setText(textAttr, " + " .. attrStr)
        
        local spawn1 = FGUI:ActionSpawn(FGUI:ActionFadeIn(0.1), FGUI:ActionMoveBy(0.1, 0, -100))
        local spawn2 = FGUI:ActionSpawn(FGUI:ActionMoveBy(0.1, 0, -60), FGUI:ActionFadeOut(0.1), FGUI:ActionScaleTo(0.1, 0.8), FGUI:ActionMoveBy(0.1, 150, -30))

        local sequence = FGUI:ActionSequence(FGUI:ActionShow(), FGUI:ActionDelayTime((index - 1) * 0.1), spawn1, FGUI:ActionDelayTime(1), spawn2, FGUI:ActionHide(), FGUI:ActionCallFunc(handler(self, self.RecycleAttribute, node, true)))
        FGUI:runAction(node, sequence)
        table.recycle(AttrKey, attrData)
    end
end

function NoticePanel:OnShowItemDropNotice(data)
    local paramList = SL:GetValue("GAME_DATA","ShowDropNotice") and string.split(SL:GetValue("GAME_DATA","ShowDropNotice"), "|")
    local setList = {}
    if paramList and paramList[1] and string.len(paramList[1]) > 0 then
        local set = paramList[1]
        setList = string.split(set, "#")
    end

    local X             = setList[1] and tonumber(setList[1]) or 0
    local Y             = setList[2] and tonumber(setList[2]) or 0 
    local interval      = setList[3] and tonumber(setList[3]) or 0
    local setFontSize   = setList[4] and tonumber(setList[4]) or fontSize
    local maxCount      = setList[5] and tonumber(setList[5]) or 4
    local delayTime     = setList[6] and tonumber(setList[6]) or 2
    local opacity       = setList[7] and tonumber(setList[7]) or 128
    data.FColor         = data.FColor or 255
    local FColorHEX     = SL:GetColorByStyleId(data.FColor)
    local BColorRGB     = data.BColor and SL:GetColorByStyleId(data.BColor)

    -- node
    local screenWidth = SL:GetValue("SCREEN_WIDTH")
    FGUI:setPosition(self._rootDropTips, screenWidth/2 + X, 50 + Y)


    local label = FGUI:CreateObject(self._rootDropTips, PACKAGE_NAME, "LabelItemDropNotice")
    local Graph_bg = FGUI:GetChild(label, "Graph_bg")

    FGUI:setVisible(Graph_bg, true)
    FGUI:setAlpha(Graph_bg, opacity / 255)
    FGUI:GGraph_setColor(Graph_bg, BColorRGB)

    FGUI:GLabel_setTitle(label, data.Msg)
    FGUI:GLabel_setTitleColor(label, FColorHEX)
    FGUI:GLabel_setTitleFontSize(label, setFontSize)


    -- action
    tinsert(self._dropTipsCells, label)
    if #self._dropTipsCells > maxCount then 
        FGUI:RemoveFromParent(self._dropTipsCells[1], true)
        tremove(self._dropTipsCells, 1)
    end 

    local sequence = FGUI:ActionSequence(FGUI:ActionDelayTime(delayTime), FGUI:ActionFadeOut(0.8), FGUI:ActionCallFunc(handler(self, self.RemoveItemDropNotice, label, true)))
    FGUI:runAction(label, sequence)

    for i = 1, #self._dropTipsCells do
        local node = self._dropTipsCells[i]
        if node then 
            local action = FGUI:ActionMoveTo(0.15, 0, -(30 + interval) * (#self._dropTipsCells - i ) - interval)
            FGUI:setPositionY(node, -(30 + interval) * (#self._dropTipsCells - i - 1) - interval)
            FGUI:runAction(node, action)
        end 
    end
end

function NoticePanel:RemoveItemDropNotice(label)
    FGUI:RemoveFromParent(label, true)
    tremove(self._dropTipsCells, 1)
end

function NoticePanel:OnPlayScreenEffect(data)
    if not data and not data.effectId then return end
    local movie = FGUI:GMovieClip_create(self._rootEffect, data.effectId)
    FGUI:GMovieClip_setPlaySettings(movie, 0, -1, data.times)
    FGUI:GMovieClip_setTimeScale(movie, data.speed)
    FGUI:GMovieClip_setOnPlayEnd(movie, function()
        self._screenEffects[data.id] = nil
        FGUI:RemoveFromParent(movie, true)
    end)
    FGUI:setPosition(movie, data.x, data.y)
    local oldMovie = self._screenEffects[data.id]
    if oldMovie then
        FGUI:RemoveFromParent(oldMovie, true)
    end
    self._screenEffects[data.id] = movie
end

function NoticePanel:OnRemoveScreenEffect(id)
    local oldMovie = self._screenEffects[id]
    if oldMovie then
        FGUI:RemoveFromParent(oldMovie, true)
        self._screenEffects[id] = nil
    end
end

function NoticePanel:OnAddTopTip(tipComponent, tipTag)
    if not tipComponent then return end
    local gid = FGUI:GetID(tipComponent)
    tipTag = tipTag or ""
    self._topTips[gid] = tipTag
    FGUI:AddChild(self._rootTopTips, tipComponent)
    local x, y = FGUI:getPosition(tipComponent)
    FGUIFunction:SetSafePosition(tipComponent, x, y)
end

function NoticePanel:OnRemoveTopTip(tipComponent, tipTag)
    if not tipComponent then return end
    local gid = FGUI:GetID(tipComponent)
    local tag = self._topTips[gid]
    if tipTag and tag ~= tipTag then return end
    self._topTips[gid] = nil
    FGUI:RemoveFromParent(tipComponent, false)
end

-----------------------------------注册事件--------------------------------------
function NoticePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ENTER_WORLD, "NoticePanel", handler(self, self.OnEnterWorld))
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, "NoticePanel", handler(self, self.OnPropertyChange))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_SERVER, "NoticePanel", handler(self, self.OnShowServerNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_SERVER_EVENT, "NoticePanel", handler(self, self.OnShowServerEventNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM, "NoticePanel", handler(self, self.OnShowSystemNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM_TIPS, "NoticePanel", handler(self, self.OnShowSystemTips))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM_SCALE, "NoticePanel", handler(self, self.OnShowSystemScaleNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM_XY, "NoticePanel", handler(self, self.OnShowSystemXYNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_TIMER, "NoticePanel", handler(self, self.OnShowTimerNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_DELETE_TIMER, "NoticePanel", handler(self, self.OnDeleteTimerNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_TIMER_XY, "NoticePanel", handler(self, self.OnShowTimerXYNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_DELETE_TIMER_XY, "NoticePanel", handler(self, self.OnDeleteTimerXYNotice))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_ITEM_TIPS, "NoticePanel", handler(self, self.OnShowItemTips))
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_DROP, "NoticePanel", handler(self, self.OnShowItemDropNotice))
    SL:RegisterLUAEvent(LUA_EVENT_SCREEN_EFFECT_PLAY, "NoticePanel", handler(self, self.OnPlayScreenEffect))
    SL:RegisterLUAEvent(LUA_EVENT_SCREEN_EFFECT_REMOVE, "NoticePanel", handler(self, self.OnRemoveScreenEffect))
    SL:RegisterLUAEvent(LUA_EVENT_TOP_TIP_ADD, "NoticePanel", handler(self, self.OnAddTopTip))
    SL:RegisterLUAEvent(LUA_EVENT_TOP_TIP_REMOVE, "NoticePanel", handler(self, self.OnRemoveTopTip))
end

function NoticePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ENTER_WORLD, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_SERVER, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_SERVER_EVENT, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM_TIPS, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM_SCALE, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM_XY, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_TIMER, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_DELETE_TIMER, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_TIMER_XY, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_DELETE_TIMER_XY, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_ITEM_TIPS, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_DROP, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_SCREEN_EFFECT_PLAY, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_SCREEN_EFFECT_REMOVE, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_TOP_TIP_ADD, "NoticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_TOP_TIP_REMOVE, "NoticePanel")
end


return NoticePanel