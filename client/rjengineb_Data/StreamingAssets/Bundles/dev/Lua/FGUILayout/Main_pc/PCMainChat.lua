local tmove = table.remove

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCMainChat = class("PCMainChat", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local SAVE_CHANNEL_KEY = "SaveBottomChannelListKey"

local DRAG_MAX_Y = -65
local DRAG_MIN_Y = -515

local CHANNEL = SLDefine.CHAT_CHANNEL
local MSGTYPE = SLDefine.CHAT_MSG_TYPE

function PCMainChat:Create()
    local chat = FGUI:GetChild(self.component, "chat")
	self._ui = FGUI:ui_delegate(chat)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.PCMainChat)

	self._maxChatCount = 200

    local minX, minY = FGUI:WorldToLocal(chat, 0, 0)
    DRAG_MIN_Y = math.max(minY, DRAG_MIN_Y)

    self._sendChannels = FGUIFunction:GetShowChannels(CHANNEL.Common, CHANNEL.System)
    self._sendChannel = nil
	self._channels = FGUIFunction:GetShowChannels()
    self._channelMap = {}
    self._receiveChannelList = {}

    local cacheReceiveList = self:GetReceiveList()

    self.CommonIndex = nil        --用于筛选列表频闭综合选项
    for k, v in ipairs(self._channels) do
        self._channelMap[v.id] = v
        if v.id == CHANNEL.Common then
            self.CommonIndex = k - 1
        end
        local idStr = tostring(v.id)
        if cacheReceiveList[idStr] == false then
            self._receiveChannelList[v.id] = false
        else
            self._receiveChannelList[v.id] = true
        end
    end

    self._noticeData = {}
    self._chatData = nil            --所有聊天记录
    self._curChatLen = 0
    self._curChatData = {}          --显示聊天记录
    self._chatCache = {}

    self._dragOffsetY = 0           --拖拽起始触摸点的偏移量
    self._dragPercY = 0             --拖拽起始聊天滑动条进度

    self._rollToBottom = true       --自动滚至底部

    self._rollTimer = nil
    self._cdTimer = nil

    self._itemDatas = {}

    self.chatScrollPane = FGUI:GetScrollPane(self._ui.List_chat)

    self._handlerUpdateCDTime = handler(self, self.UpdateCDTime)

    self._handlerSystemMsgEvent = handler(self, self.MsgSystemLinkEvent)
    self._handlerMsgLinkEvent = handler(self, self.MsgLinkEvent)

    FGUI:GList_setVirtual(self._ui.List_chat)
    FGUI:GList_itemRenderer(self._ui.List_chat, handler(self, self.OnItemRendererListChat))
    FGUI:ScrollPane_addOnScrollEvent(self.chatScrollPane, handler(self, self.OnChatScrollPaneScroll))

    FGUI:GList_itemRenderer(self._ui.List_channel, handler(self, self.OnItemRendererListChannel))
	FGUI:GList_addOnClickItemEvent(self._ui.List_channel, handler(self, self.OnClickListChannel))

    FGUI:GList_itemRenderer(self._ui.List_sendChannel, handler(self, self.OnItemRendererListSendChannel))
	FGUI:GList_addOnClickItemEvent(self._ui.List_sendChannel, handler(self, self.OnClickListSendChannel))

    FGUI:GList_itemRenderer(self._ui.List_emo, handler(self, self.OnItemRendererEmoList))
    FGUI:GList_addOnClickItemEvent(self._ui.List_emo, handler(self, self.OnClickListEmo))
    FGUI:GList_setVirtual(self._ui.List_emo)

    FGUI:GTextInput_setOnSubmit(self._ui.Input_chat, handler(self, self.OnSubmit))
    FGUI:setOnClickEvent(self._ui.Btn_send, handler(self, self.OnSend))
    FGUI:setOnClickEvent(self._ui.Btn_channel, handler(self, self.OnSwitchChannel))
    FGUI:setOnClickEvent(self._ui.Btn_sendChannel, handler(self, self.OnSwitchSendChannel))
    FGUI:setOnClickEvent(self._ui.Btn_pos, handler(self, self.OnClickPosButton))
    FGUI:setOnClickEvent(self._ui.Btn_emo, handler(self, self.OnClickEmoButton))
    FGUI:setOnClickEvent(self._ui.Mask_emo, function ()
        FGUI:setVisible(self._ui.Panel_emo, false)
    end)

    FGUI:setOnTouchEvent(self._ui.Loader_drag, handler(self, self.OnDragChatBegin), handler(self, self.OnDragChatMove), nil)
    FGUI:GSlider_setOnChanged(self._ui.Slider_chat, handler(self, self.OnSliderChatChange))

    FGUI:setOnTouchEvent(self._ui.Btn_rollTop, handler(self, self.OnRollToTopDown), nil, handler(self, self.OnRollToTopUp))
    FGUI:setOnTouchEvent(self._ui.Btn_rollBottom, handler(self, self.OnRollToBottomDown), nil, handler(self, self.OnRollToBottomUp))

    FGUI:GList_setNumItems(self._ui.List_channel, #self._channels)
    FGUI:GList_resizeToFit(self._ui.List_channel)

	FGUI:GList_setNumItems(self._ui.List_sendChannel, #self._sendChannels)
    FGUI:GList_resizeToFit(self._ui.List_sendChannel)

    FGUI:setVisible(self._ui.Group_channel, false)
    FGUI:setVisible(self._ui.Group_sendChannel, false)
end

function PCMainChat:Enter()
	self:RegisterEvent()

    self:InitAdapt()
    self:InitChat()
    self:InitExNotice()
    self:SetSendChannel(CHANNEL.Near)
end

function PCMainChat:Exit()
	self:RemoveEvent()

    local listNum = FGUI:GList_getNumItems(self._ui.List_notice)
	if listNum > 0 then
		for i = listNum, 1, -1 do
			local item = FGUI:GetChildAt(self._ui.List_notice, i - 1)
			local title = FGUI:GetChild(item, "title")
			FGUI:stopAllActions(item)
			FGUI:stopAllActions(title)
		end
		FGUI:GList_removeChildrenToPool(self._ui.List_notice)
		FGUI:GList_resizeToFit(self._ui.List_notice)
	end

    if self._rollTimer then
        SL:UnSchedule(self._rollTimer)
        self._rollTimer = nil
    end
    if self._cdTimer then
        SL:UnSchedule(self._cdTimer)
        self._cdTimer = nil
    end
end

function PCMainChat:Destroy()
    self._ui = nil
end

function PCMainChat:InitAdapt()
    local safeBottom = SL:GetValue("SCREEN_SAFE_AREA_BOTTOM")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    FGUI:setHeight(self.component, screenH - safeBottom)
    FGUI:setPositionY(self.component, 0)
    FGUI:setSize(self._ui.Mask_emo, screenW, screenH)
    local offset_y = -FGUI:getPositionY(self._ui.nativeUI)
    FGUI:setPosition(self._ui.Mask_emo, 0, offset_y)
end

----------------------------------------------------------------------------
function PCMainChat:InitChat()
    self._chatData = SL:GetValue("CHAT_CACHE", CHANNEL.Common)
    self:UpdateChatList()
    self:UpdateCDTime()
    FGUI:setVisible(self._ui.Panel_emo, false)
end

function PCMainChat:OnSend()
	local CHANNEL = CHANNEL
	local sendChannel = self._sendChannel
	local cdTime =  SL:GetValue("CHAT_CDTIME", sendChannel)
	if cdTime > 0 then return end

	if sendChannel == CHANNEL.System then
		return
	elseif sendChannel == CHANNEL.Common then
		sendChannel = CHANNEL.World
	end
	local inputStr = FGUI:GTextInput_getText(self._ui.Input_chat)
	FGUI:GTextInput_setText(self._ui.Input_chat, "")

	-- 没有输入
	if string.len(inputStr) <= 0 then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING",40000103))
		return false
	end
    SL:RequestSendChatMsg(inputStr, sendChannel)
end

function PCMainChat:OnChatScrollPaneScroll()
    local percY = FGUI:ScrollPane_getPercY(self.chatScrollPane)
    FGUI:GSlider_setValue(self._ui.Slider_chat, percY * 100)
    local contentH = FGUI:ScrollPane_getContentHeight(self.chatScrollPane)
    local viewH = FGUI:ScrollPane_getViewHeight(self.chatScrollPane)
    local autoRollPercY = 1 - (10 / contentH)
    self._rollToBottom = contentH < viewH or percY >= autoRollPercY
end

function PCMainChat:OnSliderChatChange()
    local value = FGUI:GSlider_getValue(self._ui.Slider_chat)
    FGUI:ScrollPane_setPercY(self.chatScrollPane, value/100, false)
end

function PCMainChat:OnSwitchChannel()
    local visible = FGUI:getVisible(self._ui.Group_channel)
    FGUI:setVisible(self._ui.Group_channel, not visible)
end

function PCMainChat:OnItemRendererListChannel(index, item)
    local idx = index + 1
    local channel = self._channels[idx]
    FGUI:GButton_setTitle(item, channel.str)
    if index == self.CommonIndex then
        local isSelect = true
        for k, v in pairs(self._receiveChannelList) do
            if k ~= CHANNEL.Common and v == false then
                isSelect = false
                break
            end
        end
        FGUI:GButton_setSelected(item, isSelect)
    else
        FGUI:GButton_setSelected(item, self._receiveChannelList[channel.id])
    end
end

function PCMainChat:OnClickListChannel(context)
    local item = context.data
    local idx = FGUI:GetChildIndex(self._ui.List_channel, item)
    local isSelect = FGUI:GButton_getSelected(item)
    if idx == self.CommonIndex then
        for k, v in pairs(self._receiveChannelList) do
            self._receiveChannelList[k] = isSelect
        end
        FGUI:GList_setNumItems(self._ui.List_channel, #self._channels)
    else
        local channel = self._channels[idx + 1]
        self._receiveChannelList[channel.id] = not self._receiveChannelList[channel.id]
        --刷新Common频道选中结果
        if self.CommonIndex then
            local item = FGUI:GetChildAt(self._ui.List_channel, self.CommonIndex)
            self:OnItemRendererListChannel(self.CommonIndex, item)
        end
    end
    self:SaveReceiveList()
    --接收频道变化,重置显示的聊天记录
    self:UpdateChatList()
end

function PCMainChat:OnItemRendererEmoList(index, item)
    local data = self._emojiCfgs[index + 1]

	if not data then
		return
	end

	local icon = FGUI:GetChild(item,"icon")
	FGUI:GLoader_setUrl(icon, "ui://public/" .. data.fxID)
end

function PCMainChat:OnClickListEmo(context)
    local idx = FGUI:GetChildIndex(self._ui.List_emo, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.List_emo,idx) + 1
	local eData = self._emojiCfgs[index]
    if eData then
        FGUI:GTextInput_replaceSelection(self._ui.Input_chat, string.format("[%s]",eData.replace))
    end
end

-- 点击表情按钮
function PCMainChat:OnClickEmoButton()
    self._emojiCfgs = SL:GetValue("CHAT_EMOJI") or {}
    FGUI:GList_setNumItems(self._ui.List_emo, #self._emojiCfgs)
    FGUI:setVisible(self._ui.Panel_emo, true)
end

-- 点击位置按钮
function PCMainChat:OnClickPosButton()
    local sendChannel = self._sendChannel
    local cdTime =  SL:GetValue("CHAT_CDTIME", sendChannel)
    if cdTime > 0 then
        return
    end
    if sendChannel == CHANNEL.System then
        return
    elseif sendChannel == CHANNEL.Common then
        sendChannel = CHANNEL.World
    end
    SL:RequestSendChatPosMsg(sendChannel)
end

function PCMainChat:OnSwitchSendChannel()
    local visible = FGUI:getVisible(self._ui.Group_sendChannel)
    FGUI:setVisible(self._ui.Group_sendChannel, not visible)
end

function PCMainChat:OnItemRendererListSendChannel(index, item)
    local idx = index + 1
    local channel = self._sendChannels[idx]
    FGUI:GButton_setTitle(item, channel.str)
end

function PCMainChat:OnClickListSendChannel(context)
    local item = context.data
    local idx = FGUI:GetChildIndex(self._ui.List_sendChannel, item)
    local channel = self._sendChannels[idx + 1]
    self:SetSendChannel(channel.id)
    FGUI:setVisible(self._ui.Group_sendChannel, false)
end

function PCMainChat:SetSendChannel(channel)
    self._sendChannel = channel
    local channelData = self._channelMap[channel]
    if not channelData then return end
    FGUI:GButton_setTitle(self._ui.Btn_sendChannel, channelData.str)
    SL:SetValue("CHAT_CUR_CHANNEL", channel)
    self:UpdateCDTime()
end

function PCMainChat:SaveReceiveList()
    SL:SetLocalString(SAVE_CHANNEL_KEY, SL:JsonEncode(self._receiveChannelList))
end

function PCMainChat:GetReceiveList()
    local cache = SL:GetLocalString(SAVE_CHANNEL_KEY)
    if cache and cache ~="" then
        return SL:JsonDecode(cache)
    end
    return {}
end


function PCMainChat:OnItemRendererListChat(idx, item)
    local index =  idx + 1
    local data = self._curChatData[index]
    if not data then return end
    local itemId = FGUI:GetID(item)
    local curData = self._chatCache[itemId]
    if curData == data then return end
    self._chatCache[itemId] = data
    self:RefreshMessageItem(data, item)
end

function PCMainChat:CheckShowMsg(chatData)
    local channel = chatData.Type
    if self._receiveChannelList[channel] then return true end
    return false
end
function PCMainChat:GetFilterChatData(chatDataList)
    local res = {}
    for i = #chatDataList, 1,-1 do
        if self:CheckShowMsg(chatDataList[i]) then
            table.insert(res,1,chatDataList[i])
        end
    end
    return res
end


function PCMainChat:UpdateChatList()
    table.clear(self._curChatData)
    local len = 0
    for k, v in pairs(self._chatData) do
        if self:CheckShowMsg(v) then
            len = len + 1
            self._curChatData[len] = v
        end
    end
    self._curChatLen = len
    FGUI:GList_setNumItems(self._ui.List_chat, len)
    FGUI:ScrollPane_scrollBottom(self.chatScrollPane, false)
    self._rollToBottom = true
end

function PCMainChat:OnAddChatMsg(data)
    if not data then return end
    if not self:CheckShowMsg(data) then return end
    self._curChatLen = self._curChatLen + 1
    self._curChatData[self._curChatLen] = data
    if self._curChatLen > self._maxChatCount then
        self._curChatLen = self._curChatLen - 1
        tmove(self._curChatData, 1)
    end
    FGUI:GList_setNumItems(self._ui.List_chat, #self._curChatData)
    if self._rollToBottom then
        FGUI:ScrollPane_scrollBottom(self.chatScrollPane, true)
    end
end

function PCMainChat:CheckIsSystemChat(data)
    return (data.Type == CHANNEL.System) or (data.Type ~= CHANNEL.Private and ((not data.UserName) or data.UserName == ""))
end

function PCMainChat:RefreshMessageItem(data, item)
    if not data then return end
    if self:CheckIsSystemChat(data) then
        self:RefreshSystemMessageItem(data,item)
    else
        self:RefreshPlayerMessageItem(data,item)
    end
end

function PCMainChat:RefreshSystemMessageItem(data, item)
    if not data then return end
    local channelData = self._channelMap[data.Type]
    local channelStr = channelData and channelData.str or SL:GetValue("I18N_STRING", 40000001)
    local msg = string.format(SL:GetValue("I18N_STRING", 40000113), channelStr, data.Msg)
    local fColorRGB = SL:GetColorByStyleId(data.FColor)
    local richText = FGUI:GetChild(item, "title")
    FGUI:GRichTextField_setText(richText,msg)
    FGUI:GRichTextField_setColor(richText, fColorRGB)
    FGUI:GRichTextField_setOnLinkClickEvent(richText, self._handlerSystemMsgEvent)
end

function PCMainChat:MsgSystemLinkEvent(context)
	local hrefStr = context.data
	if not hrefStr or hrefStr == "" then return end
	local strs = string.split(hrefStr, "#")
	if strs[1] == "jump" then
		local command = strs[2]
		if command == "find_point" then
			local mapID = strs[3]
			local mapX = tonumber(strs[4])
			local mapY = tonumber(strs[5])
			SL:SetValue("BATTLE_AUTO_MOVE_BEGIN",  mapID, mapX, mapY)
		elseif command == "item_tips" then
			local itemIndex = tonumber(strs[3])
			if not itemIndex then return end
			local itemData = SL:GetValue("ITEM_DATA", itemIndex)
			if not itemData then return end
			FGUIFunction:OpenItemTips({itemData = itemData})
		end
	end
end

function PCMainChat:RefreshPlayerMessageItem(data, item)
    if not data then return end
    local title = FGUI:GetChild(item, "title")
    local id = FGUI:GetID(title)
    self._itemDatas[id] = data
    local fColorRGB = SL:GetColorByStyleId(data.FColor)
    if data.MT == MSGTYPE.Position then
        local mapData = data.Msg
        local mapName = mapData.mapName
    	local mapX = mapData.mapX
		local mapY = mapData.mapY
		local route = mapData.route or 1
		local posRGB = SL:GetColorByStyleId(218)
		local msg = string.format("%s：[U][color=%s][url=][%s-%s %s,%s][/url][/color][/U]", FGUIFunction:GetServerName(data.UserName), posRGB, mapName, route, mapX, mapY)
        msg = self:AddChannelToMsg(data,msg)
        FGUI:GRichTextField_setText(title, msg)
        FGUI:GRichTextField_setOnLinkClickEvent(title, self._handlerMsgLinkEvent)
    elseif data.MT == MSGTYPE.Equip then
        local itemData = data.Msg
        local color = SL:GetMetaValue("ITEM_NAME_COLOR", itemData.Index)
	    local name = SL:GetMetaValue("ITEM_NAME", itemData.Index)
        local msg = string.format("%s：[U][color=%s][url=][%s][/url][/color][/U]", FGUIFunction:GetServerName(data.UserName), color, name)
        msg = self:AddChannelToMsg(data,msg)
        FGUI:GRichTextField_setText(title, msg)
        FGUI:GRichTextField_setOnLinkClickEvent(title, self._handlerMsgLinkEvent)
    elseif data.MT == MSGTYPE.Trade then
		local shopName = data.Msg.shopName or ""
		local shopStr = SL:GetValue("I18N_STRING", 90010031)
        local msg = string.format(shopStr, shopName)
        if data.UserName and data.UserName ~= "" then
            msg = string.format("%s：[color=%s]%s[/color]", FGUIFunction:GetServerName(data.UserName), fColorRGB, SL:ChatParser_Parse(msg))
        else
            msg = string.format("[color=%s]%s[/color]", fColorRGB, SL:ChatParser_Parse(msg))
        end
        msg = self:AddChannelToMsg(data, msg)
		FGUI:GRichTextField_setText(title,msg)
         FGUI:GRichTextField_setOnLinkClickEvent(title, self._handlerMsgLinkEvent)
    else
        local param = data.param
        local msg = data.Msg
        if param and param.type == 1 then--加入队伍
            msg = msg .. string.format(GET_STRING(40010028), param.count, param.max)
        end
        
        if data.UserName and data.UserName ~= "" then
            msg = string.format("%s：[color=%s]%s[/color]", FGUIFunction:GetServerName(data.UserName), fColorRGB, SL:ChatParser_Parse(msg))
        else
            msg = string.format("[color=%s]%s[/color]", fColorRGB, SL:ChatParser_Parse(msg))
        end
        msg = self:AddChannelToMsg(data,msg)
        FGUI:GRichTextField_setText(title, msg)
        FGUI:GRichTextField_setOnLinkClickEvent(title, self._handlerMsgLinkEvent)
    end
end

function PCMainChat:MsgLinkEvent(context)
    local richText = context.sender
	local richTextId = FGUI:GetID(richText)
    local data = self._itemDatas[richTextId]
    if not data then return end
    if data.MT == MSGTYPE.Position then
        local mapData = data.Msg
    	local mapId = mapData.mapID
    	local route = mapData.route or 1
		local mapX = mapData.mapX
		local mapY = mapData.mapY
		FGUIFunction:AutoMove(mapId, mapX, mapY, route)
    elseif data.MT == MSGTYPE.Equip then
        local itemData = data.Msg
        local isEquip = SL:GetValue("BAG_ITEM_IS_EQUIP", itemData)
        if isEquip then
            local cItem = ItemUtil:FixItemDataByServerRawData(itemData)
		    FGUIFunction:OpenItemTips({itemData = cItem, hideButtons = true})
        else
            local itemData =  SL:GetValue("ITEM_DATA", itemData.Index)
			FGUIFunction:OpenItemTips({itemData = itemData, hideButtons = true})
        end
    elseif data.MT == MSGTYPE.Trade then
		if SL:GetValue("STALL_IS_NEW_QUERY_TYPE") then
            local userId = data.Msg.userId or ""
		    SL:RequestOpenShopByUserId(userId)
        else
            local shopName = data.Msg.shopName or ""
		    SL:RequestOpenShop(shopName)
        end
    else
        local param = data.param
		if param and param.type == 1 then
			SL:RequestApplyJoinTeam(tonumber(param.uid))
		end
    end
end

function PCMainChat:AddChannelToMsg(data,msg)
    local channelData = self._channelMap[data.Type]
    local channelStr = channelData and channelData.str or SL:GetValue("I18N_STRING", 40000001)
    return string.format("[color=#2DA671][%s][/color]", channelStr) .. msg
end

function PCMainChat:OnDragChatBegin(eventData)
    local worldX, worldY = FGUI:getTouchPosition(eventData)
    local _, mouseY = FGUI:WorldToLocal(self._ui.nativeUI, worldX, worldY)
    local dragY = FGUI:getPositionY(self._ui.Loader_drag)
    self._dragOffsetY = dragY - mouseY
    self._dragPercY = FGUI:ScrollPane_getPercY(self.chatScrollPane)
    FGUI:EventContext_CaptureTouch(eventData)
end

function PCMainChat:OnDragChatMove(eventData)
    local worldX, worldY = FGUI:getTouchPosition(eventData)
    local _, mouseY = FGUI:WorldToLocal(self._ui.nativeUI, worldX, worldY)
    local dragY = math.min(DRAG_MAX_Y, math.max(DRAG_MIN_Y, mouseY + self._dragOffsetY))
    FGUI:setPositionY(self._ui.Loader_drag, dragY)
    -- 缩放复原拖拽起始进度位置
    FGUI:ScrollPane_setPercY(self.chatScrollPane, self._dragPercY)
end

function PCMainChat:OnRollToTopDown(eventData)
    FGUI:ScrollPane_scrollUp(self.chatScrollPane, 1, true)
    if self._rollTimer then return end
    self._rollTimer = SL:Schedule(handler(self, self.OnRollToTop), 0.01)
end

function PCMainChat:OnRollToTop()
    FGUI:ScrollPane_scrollUp(self.chatScrollPane, 0.1, true)
end

function PCMainChat:OnRollToTopUp(eventData)
    if not self._rollTimer then return end
    SL:UnSchedule(self._rollTimer)
    self._rollTimer = nil
end

function PCMainChat:OnRollToBottomDown(eventData)
    FGUI:ScrollPane_scrollDown(self.chatScrollPane, 1, true)
    if self._rollTimer then return end
    self._rollTimer = SL:Schedule(handler(self, self.OnRollToBottom), 0.01)
end

function PCMainChat:OnRollToBottom()
    FGUI:ScrollPane_scrollDown(self.chatScrollPane, 0.1, true)
end

function PCMainChat:OnRollToBottomUp(eventData)
    if not self._rollTimer then return end
    SL:UnSchedule(self._rollTimer)
    self._rollTimer = nil
end

function PCMainChat:UpdateCDTime()
	local channel = self._sendChannel
	local cdTime =  SL:GetValue("CHAT_CDTIME", channel)
	local sendEnable = cdTime <= 0
	FGUI:setTouchEnabled(self._ui.Btn_send, sendEnable)
	if not sendEnable then
		cdTime = math.ceil(cdTime)
        FGUI:GButton_setTitle(self._ui.Btn_send, cdTime)
		if not self._cdTimer then
			self._cdTimer = SL:Schedule(self._handlerUpdateCDTime, 1)
		end
	else
		if self._cdTimer then
			SL:UnSchedule(self._cdTimer)
			self._cdTimer = nil
		end
		FGUI:GButton_setTitle(self._ui.Btn_send, SL:GetValue("I18N_STRING", 40000101))
	end
end

function PCMainChat:OnChatEnterCD()
	self:UpdateCDTime()
end

function PCMainChat:OnAddInput(str)
	-- 是否超出上限
	local inputStr = FGUI:GTextField_getText(self._ui.Input_chat)
	local maxLen = FGUI:GTextInput_getMaxLength(self._ui.Input_chat)
	local inputStr = inputStr .. str
	if string.utf8len(inputStr) > maxLen then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 40000102))
	else
		FGUI:TextInput_setString(self._ui.Input_chat, inputStr)
	end
end


-----------------------------------顶部滚动通知--------------------------------------

-- 固定(顶部)聊天信息
function PCMainChat:InitExNotice()
    self._noticeData = SL:GetValue("CHAT_EXNOTICE_DATA") or {}
    self:CheckChatExNotice()
end

function PCMainChat:CheckChatExNotice(isInit)
    local listViewNotice = self._ui.List_notice

    if FGUI:GList_getNumItems(listViewNotice) >= 3 then
        return
    end
    local data = tmove(self._noticeData, 1)
    if not data then return end

    data.Time = data.Time or 5
    if data.Time <= 0 then
        self:CheckChatExNotice()
        return
    end

    data.Label        = data.Label or ""
    data.Y            = data.Y or 0
    data.Count        = data.Count or 1
    data.FColor       = data.FColor or 255
    data.BColor       = data.BColor or 255
    data.SendNameTemp = data.SendName or ""

    local BColorEnable  = data.BColor ~= -1
    local FColorRGB     = SL:GetColorByStyleId(data.FColor)
    local BColorRGB     = SL:GetColorByStyleId(data.BColor)

	local item = FGUI:GList_addItemFromPool(listViewNotice)
	local bg = FGUI:GetChild(item, "bg")
    local title = FGUI:GetChild(item, "title")

    if BColorEnable then
		FGUI:GGraph_setColor(bg, BColorRGB)
		FGUI:setVisible(bg, true)
	else
		FGUI:setVisible(bg, false)
    end

    FGUI:GList_resizeToFit(listViewNotice)

	local scrollW = FGUI:getWidth(listViewNotice)
    local remaining = data.Time
    local showName = data.SendName and (data.SendName .. ": ") or ""
	FGUI:GTextField_setColor(title, FColorRGB)
	if data.SendName and data.SendId then
		FGUI:setOnClickEvent(item, function()
			SL:PrivateChatWithTarget(data)
		end)
	end
    local function callback()
        remaining = math.min(remaining, data.Time)
        SL:SetValue("CHAT_EXNOTICE_SYNC", data.chatExId, remaining)
        local name = showName or ""
        local str  = name .. string.format(data.Msg, remaining)
    	FGUI:GTextField_setText(item, str)
		
        if remaining < 0 then
			FGUI:stopAllActions(item)
            FGUI:stopAllActions(title)
			FGUI:GList_removeChildToPool(listViewNotice, item)
            FGUI:GList_resizeToFit(listViewNotice)
            SL:SetValue("CHAT_EXNOTICE_REMOVE", data.chatExId)
            self:CheckChatExNotice()
        end

        remaining = remaining - 1
    end
    SL:schedule(item, callback, 1)
    callback()

	local titleW = FGUI:getWidth(title)
	local dis = titleW - scrollW

    -- 滚动
    if dis > 0 then
        local actionT = dis / 50
		FGUI:stopAllActions(title)
        FGUI:setPositionX(title, 0)
        FGUI:runAction(title, FGUI:ActionRepeatForever(
            FGUI:ActionSequence(
                FGUI:ActionMoveTo(actionT, -dis, 0),
                FGUI:ActionDelayTime(3),
                FGUI:ActionMoveTo(0, 0, 0)
            )
        ))
    end

    if #self._noticeData > 0 then
        self:CheckChatExNotice(isInit)
    end
end

function PCMainChat:OnAddExNotice(data)
    table.insert(self._noticeData, data)
    self:CheckChatExNotice()
end

function PCMainChat:OnFocus()
    FGUI:setFocus(self._ui.Input_chat)
end

function PCMainChat:OnSubmit()
    --输入不为空,发送
    local inputStr = FGUI:GTextInput_getText(self._ui.Input_chat)
    if string.len(inputStr) > 0 then
        self:OnSend()
    end
end

-----------------------------------注册事件--------------------------------------
function PCMainChat:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_ADD_MSG, "PCMainChat", handler(self, self.OnAddChatMsg))
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_ADD_NOTICE, "PCMainChat", handler(self,self.OnAddExNotice))
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_ENTER_CD, "PCMainChat", handler(self, self.OnChatEnterCD))
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_PUSH_INPUT, "PCMainChat", handler(self, self.OnAddInput))
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_FOCUS, "PCMainChat", handler(self, self.OnFocus))
end

function PCMainChat:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ADD_MSG, "PCMainChat")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ADD_NOTICE, "PCMainChat")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ENTER_CD, "PCMainChat")
	SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_PUSH_INPUT, "PCMainChat")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_FOCUS, "PCMainChat")
end


return PCMainChat