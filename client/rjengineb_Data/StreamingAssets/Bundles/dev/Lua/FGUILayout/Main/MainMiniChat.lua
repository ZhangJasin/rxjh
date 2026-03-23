local MainMiniChat = class("MainMiniChat")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local CHANNEL = SLDefine.CHAT_CHANNEL
local MSGTYPE = SLDefine.CHAT_MSG_TYPE

function MainMiniChat:Create()
	self._ui = FGUI:ui_delegate(self.component)

    self.SaveListKey = "SaveBottomChannelListKey"
	self._curChatCount = 0
	self._maxChatCount = 8
	self._channels = FGUIFunction:GetShowChannels()
    self._channelMap = {}
    self._checkAll = false
    self._selectChannel = CHANNEL.Common
    self._itemDatas = {}
    self._chatCache = {}

    self._receiveChannelList = {}
    local cacheReceiveList = self:GetReceiveList()
    local noCache = next(cacheReceiveList) == nil
    if noCache then
        for k, v in ipairs(self._channels) do
            self._channelMap[v.id] = v
            self._receiveChannelList[v.id] = true
        end
    else
        for k, v in ipairs(self._channels) do
            self._channelMap[v.id] = v
            local cacheValue = cacheReceiveList[tostring(v.id)]
            self._receiveChannelList[v.id] = cacheValue or cacheValue == nil
        end
    end

    self._noticeData = {}

    self._chatData = {}              --聊天缓存
    

    self._handlerSystemMsgEvent = handler(self, self.MsgSystemLinkEvent)
    self._handlerMsgLinkEvent = handler(self, self.MsgLinkEvent)

    self.scrollPanel = FGUI:GetScrollPane(self._ui.List_chat)

    FGUI:GList_itemRenderer(self._ui.List_chat, handler(self, self.ListViewChatItemRenderer))
    FGUI:GList_setVirtual(self._ui.List_chat)

    FGUI:setOnClickEvent(self._ui.List_chat, handler(self, self.OnChat))
    FGUI:setOnClickEvent(self._ui.Btn_chatArrow, handler(self, self.OnChatArrow))
    FGUI:setOnClickEvent(self._ui.Btn_channel, handler(self, self.BtnChannelClick))
end




function MainMiniChat:Enter()
	self:RegisterEvent()

    self:InitExNotice()
    self:UpdateChatList()
end

function MainMiniChat:Exit()
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
end

function MainMiniChat:Destroy()
    self._ui = nil
end


function MainMiniChat:OnChat()
    if self._fobOpen then self._fobOpen = false  return end
    FGUI:Open("Chat", "ChatPanel")
end
function MainMiniChat:OnChatArrow()
    local ctler = FGUI:getController(self.component, "chat")
    local idx = FGUI:Controller_getSelectedIndex(ctler)
    idx = idx == 0 and 1 or 0
    FGUI:Controller_setSelectedIndex(ctler, idx)
    FGUI:ScrollPane_scrollBottom(self.scrollPanel, false)
end


-----------------------------------MiniChat------------------------------------

function MainMiniChat:BtnChannelClick()
    FGUI:Open("Main","ChatSetting")
end

function MainMiniChat:ListViewChatItemRenderer(idx, item)
    local msgList = self._chatData
    local index =  idx + 1
    if #msgList > self._maxChatCount then
        index = #msgList -self._maxChatCount + idx + 1
    end
    local data = msgList[index]
    if not data then return end
    local itemId = FGUI:GetID(item)
    local curData = self._chatCache[itemId]
    if curData == data then return end
    self._chatCache[itemId] = data
    self:RefreshMessageItem(data, item)
end

function MainMiniChat:CheckShowMsg(chatData)
    for i = 1, #self._channels do
        local id = self._channels[i].id
        if self._receiveChannelList[id] then
            local channelData = self._channels[i]
            if channelData.id == chatData.Type then
                return true
            end
        end
    end
    return false
end
function MainMiniChat:GetFilterChatData(chatDataList)
    local res = {}
    for i = #chatDataList, 1,-1 do
        if self:CheckShowMsg(chatDataList[i]) then
            table.insert(res,1,chatDataList[i])
        end
    end
    return res
end

function MainMiniChat:UpdateChatList()
    local datas = SL:GetValue("CHAT_CACHE", self._selectChannel)
    self._chatData = self:GetFilterChatData(datas)
    FGUI:GList_setNumItems(self._ui.List_chat, math.min(self._maxChatCount, #datas))
    FGUI:ScrollPane_scrollBottom(self.scrollPanel, false)
end

function MainMiniChat:OnAddChatMsg(data)
    if not data then return end
    if not self:CheckShowMsg(data) then return end
    local msgList = self._chatData
    table.insert(msgList,data)
    if self._selectChannel == CHANNEL.Common or self._selectChannel == data.Type then
        FGUI:GList_setNumItems(self._ui.List_chat, math.min(self._maxChatCount,#msgList))
        FGUI:ScrollPane_scrollBottom(self.scrollPanel, false)
    end
end

function MainMiniChat:AddChannelToMsg(data, msg)
    local channelData = self._channelMap[data.Type]
    local channelStr = channelData and channelData.str or SL:GetValue("I18N_STRING", 40000001)
    return string.format("[color=#2DA671][%s][/color]", channelStr) .. msg
end

function MainMiniChat:CheckIsSystemChat(data)
    return (data.Type == CHANNEL.System) or (data.Type ~= CHANNEL.Private and ((not data.UserName) or data.UserName == ""))
end

function MainMiniChat:RefreshMessageItem(data, item)
    if not data then return end
    if self:CheckIsSystemChat(data) then
        self:RefreshSystemMessageItem(data, item)
    else
        self:RefreshPlayerMessageItem(data, item)
    end
end

function MainMiniChat:RefreshSystemMessageItem(data, item)
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

function MainMiniChat:MsgSystemLinkEvent(context)
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

function MainMiniChat:RefreshPlayerMessageItem(data,item)
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
        local msg
        if route == 0 then--此地图无分线
			msg = string.format("%s：[U][color=%s][url=][%s %s,%s][/url][/color][/U]", FGUIFunction:GetServerName(data.UserName), posRGB, mapName, mapX, mapY)
		else
			msg = string.format("%s：[U][color=%s][url=][%s-%s %s,%s][/url][/color][/U]", FGUIFunction:GetServerName(data.UserName), posRGB, mapName, route, mapX, mapY)
		end
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

function MainMiniChat:MsgLinkEvent(context)
    local richText = context.sender
	local richTextId = FGUI:GetID(richText)
    local data = self._itemDatas[richTextId]
    if not data then return end
    --点击链接时,禁止触发此次的打开聊天界面
    self._fobOpen = true
    if data.MT == MSGTYPE.Position then
        local mapData = data.Msg
        local mapId = mapData.mapID
        local route = mapData.route or 1
		local mapX = mapData.mapX
		local mapY = mapData.mapY
        if route == 0 then route = 1 end
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

function MainMiniChat:GetReceiveList()
    local cache = SL:GetLocalString(self.SaveListKey)
    if cache and cache ~="" then
        return SL:JsonDecode(cache)
    end
    return {}
end

-- 固定(顶部)聊天信息
function MainMiniChat:InitExNotice()
    self._noticeData = SL:GetValue("CHAT_EXNOTICE_DATA") or {}
    self:CheckChatExNotice()
end

function MainMiniChat:CheckChatExNotice(isInit)
    local listViewNotice = self._ui.List_notice

    if FGUI:GList_getNumItems(listViewNotice) >= 3 then
        return
    end
    local data = table.remove(self._noticeData, 1)
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

function MainMiniChat:OnAddExNotice(data)
    table.insert(self._noticeData, data)
    self:CheckChatExNotice()
end


function MainMiniChat:OnChatSettingUpdate(data)
    if not data then
        return 
    end

    self._receiveChannelList = data
end

-----------------------------------注册事件--------------------------------------
function MainMiniChat:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_ADD_MSG, "MainMiniChat", handler(self, self.OnAddChatMsg))
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_ADD_NOTICE, "MainMiniChat", handler(self,self.OnAddExNotice))
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_SETTING_UPDATE, "MainMiniChat", handler(self,self.OnChatSettingUpdate))
end

function MainMiniChat:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ADD_MSG, "MainMiniChat")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ADD_NOTICE, "MainMiniChat")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_SETTING_UPDATE, "MainMiniChat")
end


return MainMiniChat