local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ChatPanel = class("ChatPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local MSGTYPE = SLDefine.CHAT_MSG_TYPE
local CHANNEL = SLDefine.CHAT_CHANNEL

function ChatPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self.showChatExController = FGUI:getController(self.component, "ShowChatEx")

	self._myUID = SL:GetValue("USER_ID")
	self._channel = nil          -- 当前频道
	self._rollToBottom = true
	self._noticeData = {}
	self._maxCount = 50
	self._channels = FGUIFunction:GetShowChannels()
	self._channelMap = {}
	for k, v in ipairs(self._channels) do
		self._channelMap[v.id] = v
	end
	self._itemDatas = {}
	self._itemUI = {}
	self._chatData = {}
	self.shoutItemData = {}
	self.selectShoutItem = -1

	self.MsgLinkEventHandler = handler(self, self.MsgLinkEvent)
	self.MsgSystemLinkEventHandler = handler(self, self.MsgSystemLinkEvent)

	self:InitView()
	self:InitInput()
end

function ChatPanel:Enter(data)
	FGUIFunction:AdaptNotch(self.component)
	if not self.isShow then
		self:OpenAnimation()
	end
	self:RegisterEvent()
	self:InitExNotice()
	self.isShow = true

	self:JumpChannel(data)

	FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.ChatHideFunc, handler(self, self.PanelClose))
end

function ChatPanel:Exit()
	self:RemoveEvent()
	local listNum = FGUI:GList_getNumItems(self._ui.ListView_notice)
	if listNum > 0 then
		for i = listNum, 1, -1 do
			local item = FGUI:GetChildAt(self._ui.ListView_notice, i - 1)
			local title = FGUI:GetChild(item, "title")
			FGUI:stopAllActions(title)
		end
		FGUI:GList_removeChildrenToPool(self._ui.ListView_notice)
		FGUI:GList_resizeToFit(self._ui.ListView_notice)
	end
	self.isShow = false
	FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.ChatHideFunc)
end

function ChatPanel:Destroy()
	self.isShow = false
	self._ui = nil

	self:CleanItemViewCache()
end

function ChatPanel:InitView()
	if self.isShow then
		return
	end

	self.scrollPane = FGUI:GetScrollPane(self._ui.ListView_cells)
	FGUI:setOnClickEvent(self._ui.Mask, handler(self, self.PanelClose))

	FGUI:GList_itemRenderer(self._ui.ListView_receive, handler(self, self.ListViewReceiveItemRenderer))
	FGUI:GList_setOnClickItemEvent(self._ui.ListView_receive, handler(self, self.ListViewReceiveClick))

	FGUI:ScrollPane_addOnScrollEvent(self.scrollPane, handler(self, self.onChatScrollPaneScroll))
	FGUI:GList_itemRenderer(self._ui.ListView_cells, handler(self, self.ListViewCellsItemRenderer))
	FGUI:GList_itemProvider(self._ui.ListView_cells, handler(self, self.ListViewCellsItemProvider))
	FGUI:GList_setVirtual(self._ui.ListView_cells)

	FGUI:GList_setNumItems(self._ui.ListView_receive, #self._channels)
	self:InitChatEx()
end

function ChatPanel:ListViewReceiveItemRenderer(idx, item)
	local index = idx + 1
	local channel = self._channels[index]
	if not channel then return end
	FGUI:GButton_setTitle(item, channel.str)
end

function ChatPanel:ListViewReceiveClick(context)
	local item = context.data
	local childIndex = FGUI:GetChildIndex(self._ui.ListView_receive, item)
	local idx = FGUI:GList_childIndexToItemIndex(self._ui.ListView_receive, childIndex)
	local index = idx + 1
	local channel = self._channels[index]
	if not channel then return end
	self:SetChannel(channel.id)
end

function ChatPanel:ListViewCellsItemRenderer(idx, item)
	local index = idx + 1
	local data = self._chatData[index]
	if not data then return end
	self:onRefreshChatMsg(data, item)
end

function ChatPanel:ListViewCellsItemProvider(idx)
	local index = idx + 1
	local data = self._chatData[index]
	if not data then
		return "ui://Chat/ChatSysNode"
	end

	if self:CheckIsSystemChat(data) then
		return "ui://Chat/ChatSysNode"
	else
		local isSelf
		if data.Type == CHANNEL.Private then
			isSelf = self._myUID == data.SendID
		else
			isSelf = self._myUID == data.UserID
		end

		if isSelf then
			return "ui://Chat/ChatItemRight"
		else
			return "ui://Chat/ChatItemLeft"
		end
	end
end

function ChatPanel:InitInput()
	local inputStr = SL:GetValue("CHAT_INPUT_DRAFT")
	FGUI:GTextInput_setText(self._ui.TextField_input, inputStr)
	-- 发送
	FGUI:setOnClickEvent(self._ui.Button_send, function ()

		local CHANNEL = CHANNEL
		local channel = self._channel
		local cdTime =  SL:GetValue("CHAT_CDTIME", channel)
		if cdTime > 0 then
			return
		end
		if channel == CHANNEL.System then
			return
		elseif channel == CHANNEL.Common then
			channel = CHANNEL.World
		end
		local input =  FGUI:GTextInput_getText(self._ui.TextField_input)
		FGUI:GTextInput_setText(self._ui.TextField_input, "")

		-- 没有输入
		if string.len(input) <= 0 then
			SL:ShowSystemTips(SL:GetValue("I18N_STRING",40000103))
			return false
		end
		-- 存储到输入缓存
		SL:SetValue("CHAT_INPUT_CACHE", input)
		if channel == CHANNEL.Shout then
			SL:RequestSendChatMsg(input, CHANNEL.ItemShout)
		else
			SL:RequestSendChatMsg(input, channel)
		end

	end)

	FGUI:setOnClickEvent(self._ui.Button_pos, function ()
		local channel = self._channel
		local cdTime =  SL:GetValue("CHAT_CDTIME", channel)
		if cdTime > 0 then
			return
		end
		if channel == CHANNEL.System then
			return
		end
		if channel == CHANNEL.Common then
			channel = CHANNEL.World
		end
		SL:RequestSendChatPosMsg(channel)
	end)

end


function ChatPanel:SetChannel(channel)
	if self._channel == channel then return end
	self._channel = channel
	SL:SetValue("CHAT_CUR_CHANNEL", channel)
	self._rollToBottom = true
	self:UpdateReceiveChannel()
	self:UpdateChatList()
	self:UpdateCDTime(true)
end

function ChatPanel:UpdateChatList()
	local datas = SL:GetValue("CHAT_CACHE", self._channel)

	self._chatData = datas
	FGUI:GList_setNumItems(self._ui.ListView_cells, #datas)
	FGUI:GList_refreshVirtualList(self._ui.ListView_cells)
	FGUI:ScrollPane_scrollBottom(self.scrollPane, false)
	self._rollToBottom = true
end

function ChatPanel:UpdateReceiveChannel()
	local channel = self._channel
	if channel == CHANNEL.System or channel == CHANNEL.Common then
		FGUI:setVisible(self._ui.Node_forbid, true)
		FGUI:setVisible(self._ui.Layout_send, false)
	else
		FGUI:setVisible(self._ui.Node_forbid, false)
		FGUI:setVisible(self._ui.Layout_send, true)
	end
	if channel == CHANNEL.Shout then
		self:SelectShoutItem()
	end

	FGUI:setVisible(self._ui.Text_shout,  channel == CHANNEL.Shout)
end

function ChatPanel:onAddInput(str)
	local textInput = self._ui.TextField_input

	-- 是否超出上限
	local inputStr = FGUI:GTextField_getText(self._ui.TextField_input)
	local maxLen = FGUI:GTextInput_getMaxLength(self._ui.TextField_input)
	local inputStr = inputStr .. str
	if string.utf8len(inputStr) > maxLen then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 40000102))
	else
		FGUI:TextInput_setString(textInput, inputStr)
	end
end

function ChatPanel:CheckIsSystemChat(data)
	return (data.Type == CHANNEL.System) or (data.Type ~= CHANNEL.Private and ((not data.UserName) or data.UserName == ""))
end

function ChatPanel:onChatScrollPaneScroll()
    local percY = FGUI:ScrollPane_getPercY(self.scrollPane)
    local contentH = FGUI:ScrollPane_getContentHeight(self.scrollPane)
    local viewH = FGUI:ScrollPane_getViewHeight(self.scrollPane)
    local autoRollPercY = 1 - (10 / contentH)
    self._rollToBottom = contentH < viewH or percY >= autoRollPercY
end

function ChatPanel:onAddNewMsg(data)
	if not data then return end
	if self._channel == CHANNEL.Common or self._channel == data.Type then
		FGUI:GList_setNumItems(self._ui.ListView_cells, #self._chatData)
		if self._rollToBottom then
			FGUI:ScrollPane_scrollBottom(self.scrollPane, true)
		end
	end
end

function ChatPanel:onRefreshChatMsg(data,item)
	if self._channel == CHANNEL.Common or self._channel == data.Type then
		self:RefreshMessageItem(data,item)
	end
end

function ChatPanel:RefreshMessageItem(data,item)
	if not data then return end
	if self:CheckIsSystemChat(data) then
		self:RefreshSystemMessageItem(data,item)
	else
		self:RefreshPlayerMessageItem(data,item)
	end
end

function ChatPanel:RefreshSystemMessageItem(data, item)
	if not data then return end
	local channelData = self._channelMap[data.Type]
	local channelStr = channelData and channelData.str or SL:GetValue("I18N_STRING",40000001)
	local msg = string.format(SL:GetValue("I18N_STRING", 40000113), channelStr, data.Msg)
	local fColorRGB = SL:GetColorByStyleId(data.FColor)
	local itemId = FGUI:GetID(item)
	local itemUI = self._itemUI[itemId]
	if not itemUI then
		itemUI = FGUI:ui_delegate(item)
		self._itemUI[itemId] = itemUI
		FGUI:GRichTextField_setOnLinkClickEvent(itemUI.richText, self.MsgSystemLinkEventHandler)
	end
	FGUI:GRichTextField_setText(itemUI.richText, msg)
	FGUI:GRichTextField_setColor(itemUI.richText, fColorRGB)
end

function ChatPanel:MsgSystemLinkEvent(context)
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

--fgui EventContext
function ChatPanel:MsgLinkEvent(context)
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
		-- FGUIFunction:OpenItemTips({itemData = cItem,hideButtons = true })
	elseif data.MT == MSGTYPE.Trade then
		if SL:GetValue("STALL_IS_NEW_QUERY_TYPE") then
			local userId = data.Msg.userId or ""
			SL:RequestOpenShopByUserId(userId)
		else
			local shopName = ""
            if type(data.Msg) == "string" then
                shopName = data.Msg
			else
                shopName = data.Msg and data.Msg.shopName or ""
            end
            SL:RequestOpenShop(shopName)	
		end
    else
        local param = data.param
		if param and param.type == 1 then
			SL:RequestApplyJoinTeam(tonumber(param.uid))
		end
    end
end


function ChatPanel:RefreshPlayerMessageItem(data, item)
	if not data then return end
	local sendId = data.UserID
	local sendName = data.UserName	
	if data.Type == CHANNEL.Private then
		sendId = data.SendID
		sendName = data.SendName
	end
	local isSelf = self._myUID == sendId
	local itemId = FGUI:GetID(item)
	local itemUI = self._itemUI[itemId]
	if not itemUI then
		itemUI = FGUI:ui_delegate(item)
		self._itemUI[itemId] = itemUI
		FGUI:GRichTextField_setOnLinkClickEvent(itemUI.RichText, self.MsgLinkEventHandler)
	end

	data.TipsType = SL:GetValue("DOCKTYPE_NENUM").Func_Player_Head
	data.targetName = sendName
	data.targetId = sendId
	data.GuildName = SL:GetValue("ACTOR_GUILD_NAME",data.targetId) or ""
	data.FrameID = data.PhotoframeID
	-- 头像点击
	local clickCallback = function()
		-- 非本人查看
		if not isSelf then
			FGUIFunction:OpenFuncDockTips(data)
		end
	end

	FGUI:GLoader_setUrl(itemUI.Image_chatFrame, FGUIFunction:GetChatFrameUrl(data.ChatBID))
	FGUI:GTextField_setText(itemUI.Text_name, FGUIFunction:GetServerName(sendName))
	FGUI:GTextField_setText(itemUI.Text_lv, (data.Level and data.Level or ""))
	if data.SendTime then
		FGUI:GTextField_setText(itemUI.Text_time, os.date("%Y-%m-%d %H:%M:%S", data.SendTime))
	end
	FGUIFunction:SetCommonPlayerFrame(itemUI.PlayerFrame, data, clickCallback)

	local richText = itemUI.RichText
	local id = FGUI:GetID(richText)
    self._itemDatas[id] = data
	local fColorRGB = SL:GetColorByStyleId(data.FColor)
	if data.MT == MSGTYPE.Position then
		local mapData = data.Msg
        local mapName = mapData.mapName
    	local mapX = mapData.mapX
		local mapY = mapData.mapY
		local route = mapData.route or 1
		local posRGB = SL:GetColorByStyleId(218)
		local msg = string.format("[U][color=%s][url=][%s-%s %s,%s][/url][/color][/U]", posRGB, mapName, route, mapX, mapY)
		FGUI:GRichTextField_setText(richText, msg)
	elseif data.MT == MSGTYPE.Equip then
		local itemData = data.Msg
		local color = SL:GetMetaValue("ITEM_NAME_COLOR", itemData.Index)
		local name = SL:GetMetaValue("ITEM_NAME", itemData.Index)
		local msg = string.format("[U][color=%s][url=][%s][/url][/color][/U]", color, name)
		FGUI:GRichTextField_setText(richText, msg)
	elseif data.MT == MSGTYPE.Trade then
		local shopName = ""
		if type(data.Msg) == "string" then
			shopName = data.Msg
		else
			shopName = data.Msg and data.Msg.shopName or ""
		end
		local shopStr = SL:GetValue("I18N_STRING", 90010031)
		local msg = string.format(shopStr, shopName)
		FGUI:GRichTextField_setText(richText,msg)
	else
		local param = data.param
		local msg = data.Msg
		if param and param.type == 1 then--加入队伍
			msg = msg .. string.format(GET_STRING(40010028), param.count, param.max)
		end
		FGUI:GRichTextField_setText(richText, string.format("[color=%s]%s[/color]", fColorRGB, SL:ChatParser_Parse(msg)))
	end
end

function ChatPanel:UpdateCDTime(startTimer)
	if not self.isShow then
		if self.cdAction then
			SL:UnSchedule(self.cdAction)
			self.cdAction = nil
		end
		return
	end
	local channel = self._channel
	if channel == CHANNEL.Common then
		channel = CHANNEL.World
	end
	local cdTime =  SL:GetValue("CHAT_CDTIME", channel)
	local sendEnable = cdTime <= 0
	FGUI:setTouchEnabled(self._ui.Button_send, sendEnable)
	if not sendEnable then
		cdTime = math.ceil(cdTime)
		FGUI:GTextField_setText(self._ui.Button_sendText, cdTime)
		if startTimer then
			if not self.cdAction then
				self.cdAction = SL:Schedule(function()
					self:UpdateCDTime(false)
					self.cdAction = nil
				end, 1)
			end
		end
	else
		if self.cdAction then
			SL:UnSchedule(self.cdAction)
			self.cdAction = nil
		end
		FGUI:GTextField_setText(self._ui.Button_sendText, SL:GetValue("I18N_STRING",40000101))
	end
end

function ChatPanel:onChatEnterCD()
	self:UpdateCDTime(true)
end

function ChatPanel:JumpChannel(data)
	local selectChannel = SL:GetValue("CHAT_CUR_CHANNEL")
	if data and data.selectChannel then
		selectChannel = data.selectChannel
	end
	local idx = 0
	for i, v in pairs(self._channels) do
		if v.id == selectChannel then
			idx = i - 1
			break
		end
	end
	self:SetChannel(selectChannel)
	FGUI:GList_setSelectedIndex(self._ui.ListView_receive, idx)
end

-- 固定(顶部)聊天信息
function ChatPanel:InitExNotice()
    self._noticeData = SL:GetValue("CHAT_EXNOTICE_DATA") or {}
    self:CheckChatExNotice()
end

function ChatPanel:CheckChatExNotice()
    local listViewNotice = self._ui.ListView_notice
    if FGUI:GList_getNumItems(listViewNotice) >= 3 then
        return
    end
    local data = table.remove(self._noticeData, 1)
    if not data then
		return 
	end

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
        local name = showName or ""
        local str  = name .. string.format(data.Msg, remaining)
    	FGUI:GTextField_setText(item, str)
		
        if remaining < 0 then
			FGUI:stopAllActions(title)
			FGUI:GList_removeChildToPool(listViewNotice, item)
            FGUI:GList_resizeToFit(listViewNotice)
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
        self:CheckChatExNotice()
    end
end

function ChatPanel:onAddExNotice(data)
	table.insert(self._noticeData, data)
    self:CheckChatExNotice()
end

function ChatPanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_CHAT_ADD_MSG, "Chat", handler(self, self.onAddNewMsg))
	SL:RegisterLUAEvent(LUA_EVENT_CHAT_ENTER_CD, "Chat", handler(self, self.onChatEnterCD))
	SL:RegisterLUAEvent(LUA_EVENT_CHAT_PUSH_INPUT, "Chat", handler(self, self.onAddInput))
	SL:RegisterLUAEvent(LUA_EVENT_CHAT_JUMP_CHANNEL, "Chat", handler(self, self.JumpChannel))
	SL:RegisterLUAEvent(LUA_EVENT_CHAT_ADD_NOTICE, "Chat", handler(self, self.onAddExNotice))

end

function ChatPanel:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ADD_MSG, "Chat")
	SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ENTER_CD, "Chat")
	SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_PUSH_INPUT, "Chat")
	SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_JUMP_CHANNEL, "Chat")
	SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ADD_NOTICE, "Chat")
end

function ChatPanel:OpenAnimation()
	local trans = FGUI:GetTransition(self.component, ("OpenAnimation"))
	FGUI:Transition_play(trans)
end

function ChatPanel:PanelClose()
	self:HideChatEx()
	local trans = FGUI:GetTransition(self.component, ("OpenAnimation"))
	if 	FGUI:Transition_getIsPlaying(trans) then
		return
	end
	FGUI:Transition_playReverse(trans, function()
		local inputStr = FGUI:GTextInput_getText(self._ui.TextField_input)
		SL:SetValue("CHAT_INPUT_DRAFT", inputStr)
		self:Close()
	end)

	if self.cdAction then
		SL:UnSchedule(self.cdAction)
		self.cdAction = nil
	end
	self._channel = -1
end

--------------------------------------------ChatEx
---
function ChatPanel:InitChatEx()
	self.chatExTrans = FGUI:GetTransition(self.component, "OpenChatContentEx")
	self.emojiCfgs = SL:GetValue("CHAT_EMOJI")
	self.chatExItems = {}

	FGUI:setOnClickEvent(self._ui.Button_emoji, handler(self, self.ShowChatEx, 1))
	FGUI:setOnClickEvent(self._ui.Button_bag, handler(self, self.ShowChatEx, 2))
	FGUI:setOnClickEvent(self._ui.Text_shout, handler(self, self.ShowChatEx, 3))
	FGUI:setOnClickEvent(self._ui.MaskEx, handler(self, self.HideChatEx))

	FGUI:GList_addOnClickItemEvent(self._ui.ListView_chatEx, handler(self, self.ChatExItemClickEvent))
	FGUI:GList_itemRenderer(self._ui.ListView_chatEx, handler(self, self.ListViewChatExRenderer))
	FGUI:GList_setVirtual(self._ui.ListView_chatEx)


	FGUI:GList_itemRenderer(self._ui.ListView_shout, handler(self, self.ListViewShoutRenderer))
	FGUI:GList_addOnClickItemEvent(self._ui.ListView_shout, handler(self, self.ListViewShoutClick))
	self:InitShoutId()
end

function ChatPanel:SendChatItemMsg(itemData)
	local cdTime = SL:GetValue("CHAT_CDTIME", self._channel)
	if cdTime > 0 then return end
	if not itemData then return end
	SL:RequestSendChatItemMsg(self._channel, itemData.MakeIndex)
end

function ChatPanel:ChatExItemClickEvent(context)
	local idx = FGUI:GetChildIndex(self._ui.ListView_chatEx, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.ListView_chatEx,idx) + 1
	if self._showChatEx == 1 then
		local eData = self.emojiCfgs[index]
		if eData then
			FGUI:GTextInput_replaceSelection(self._ui.TextField_input, string.format("[%s]",eData.replace))
		end
	elseif self._showChatEx == 2 then
		local itemList = self:GetCurChatExData()
		local itemData = itemList[index]
		self:SendChatItemMsg(itemData)
	end
end

function ChatPanel:GetCurChatExData()
	if self._showChatEx == 1 then
		return self.emojiCfgs
	elseif self._showChatEx == 2 then
		return self.chatExItems
	end
end

function ChatPanel:FillEmojiItem(index, item)
	local data = self.emojiCfgs[index]

	if not data then
		return
	end
	local content = FGUI:GetChild(item,"Content")
	local c = FGUI:getController(item,"ChatExType")
	FGUI:Controller_setSelectedIndex(c,0)
	FGUI:GLoader_setUrl(content, "ui://public/" .. data.fxID)
end

local packageItemViewCache = {}
function ChatPanel:CleanItemViewCache()
	for k, v in pairs(packageItemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	packageItemViewCache = {}
end
function ChatPanel:FillPackageItem(index, item)

	local itemData = self.chatExItems[index]
	local content = FGUI:GetChild(item,"ContentItem")
	local  c = FGUI:getController(item,"ChatExType")
	FGUI:Controller_setSelectedIndex(c,1)

	local id = FGUI:GetID(item)
	local cacheItem = packageItemViewCache[id]

	if cacheItem then
		ItemUtil:ItemShow_Release(cacheItem)
	end
	local itemView = ItemUtil:ItemShow_Create(itemData,content)
	packageItemViewCache[id] = itemView
end


function ChatPanel:ListViewShoutRenderer(idx, item)
	local itemId = self.shoutItemData[idx + 1]
	local itemName = SL:GetValue("ITEM_NAME", tonumber(itemId))
	local itemCnt = SL:GetValue("ITEM_COUNT", tonumber(itemId))
	local str = string.format("%s(%d)",itemName or "",itemCnt)
	FGUI:GLoader_setUrl(FGUI:GetChild(item,"Icon"), "ui://Chat/shout_"..itemId)
	FGUI:GTextField_setText(FGUI:GetChild(item,"Text"), str)
end

function ChatPanel:ListViewShoutClick(context)
	local index = FGUI:GetChildIndex(self._ui.ListView_shout, context.data)
	if index == self.selectShoutItem then
		self.selectShoutItem = -1
		FGUI:GList_clearSelection(self._ui.ListView_shout)
	else
		self.selectShoutItem = index
	end
end

function ChatPanel:ListViewChatExRenderer(idx, item)
	local index = idx + 1
	if self._showChatEx == 1 then
		self:FillEmojiItem(index, item)
	elseif self._showChatEx == 2 then
		self:FillPackageItem(index, item)
	end
end

function ChatPanel:InitShoutId()
	local disPlayItem = SL:GetValue("GAME_DATA", "SpeakerType")
	local shouts = string.split(disPlayItem, "|")
	self.shoutItemData = shouts
end

function ChatPanel:SelectShoutItem()
	if self.selectShoutItem == 0 then
		FGUI:GTextField_setText(self._ui.Text_shout, GET_STRING(40001136))
	elseif self.selectShoutItem == 1 then
		FGUI:GTextField_setText(self._ui.Text_shout, GET_STRING(40001137))
	else
		FGUI:GTextField_setText(self._ui.Text_shout, GET_STRING(40001138))
	end
end


function ChatPanel:ShowChatEx(index)
	FGUI:Controller_setSelectedIndex(self.showChatExController,index == 3 and 2 or 1)
	FGUI:Transition_play(self.chatExTrans)
	self._showChatEx = index

	if index == 1 then
		FGUI:GList_setNumItems(self._ui.ListView_chatEx, #self.emojiCfgs)
	elseif index == 2 then
		self.chatExItems = SL:GetValue("CHAT_SHOW_ITEMS")
		FGUI:GList_setNumItems(self._ui.ListView_chatEx, #self.chatExItems)
	elseif index == 3 then
		FGUI:GList_setNumItems(self._ui.ListView_shout, #self.shoutItemData)
	end
end

function ChatPanel:HideChatEx()
	self._showChatEx = 0
	SL:SetValue("SELECTED_SHOUT_ITEM", self.selectShoutItem )
	self:SelectShoutItem()
	if 	FGUI:Transition_getIsPlaying(self.chatExTrans) then
		return
	end

	FGUI:Transition_playReverse(self.chatExTrans, function()
		FGUI:Controller_setSelectedIndex(self.showChatExController, 0)
	end)

end

return ChatPanel