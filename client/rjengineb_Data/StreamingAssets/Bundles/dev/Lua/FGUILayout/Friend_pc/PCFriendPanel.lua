local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCFriendPanel = class("PCFriendPanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "私聊", page = 1, nothing = "暂无聊天对象"},
	[2] = {name = "好友", page = 2, nothing = "暂无好友"},
	[3] = {name = "宿敌", page = 3, nothing = "暂无宿敌"},
	[4] = {name = "黑名单", page = 4, nothing = "暂无黑名单"},
}

local AVATOR_DATA = {}

function PCFriendPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    --FGUI:SetCloseUIWhenClickOutside(self)   
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)

	self:InitData()
	self:InitEvent()
    self:InitPage()
end 

function PCFriendPanel:Enter(pageData)
    self:RegisterEvent()
    SL:RequestRandomFriend()

    local page = FGUIDefine.FriendPage.Recent
    if type(pageData) == "number" then 
        page = pageData
    else 
        page = pageData.page 
        self._privateID = pageData.UserID
        self._targetID = pageData.UserID
        self._targetData = pageData.targetData
    end 
    self:SelectPage(page)

    SL:ComponentAttach(SLDefine.SUIComponentTable.Friend, self._ui.Node_attach)
end

function PCFriendPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.Friend)

    self._targetID = nil
    self._targetData = nil
    self._initFriend = false
    self._initEnmey = false
    self._initBlack = false
	self:RemoveEvent()
    self.super.Close(self)
end

function PCFriendPanel:InitData()
    self._selPage = 1
    self._showList = nil
    self._targetID = nil
    self._targetData = nil
    self._messages = nil
    self._privateID = nil
    self.emojiCfgs = SL:GetValue("CHAT_EMOJI")

    self._initFriend = false
    self._initEnmey = false
    self._initBlack = false
end

function PCFriendPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Exit))
    FGUI:setOnClickEvent(self._ui.btn_add, handler(self, self.OpenAddFriendUI))
    FGUI:setOnClickEvent(self._ui.btn_chat, handler(self, self.OnSendMessage))
    FGUI:setOnClickEvent(self._ui.btn_pos, handler(self, self.OnSendPostion))
    
    -- list friend
	FGUI:GList_itemRenderer(self._ui.list_friend, handler(self, self.OnRendererFriend))
    FGUI:GList_addOnClickItemEvent(self._ui.list_friend, handler(self, self.OnClickItemFriend))
    FGUI:GList_setSelectedIndex(self._ui.list_friend, -1)

    -- list chat 
    FGUI:GList_itemProvider(self._ui.list_chat, handler(self, self.OnProviderChat))
	FGUI:GList_itemRenderer(self._ui.list_chat, handler(self, self.OnRendererChat))

    -- list emoj
    local listEmoj = FGUI:GetChild(self._ui.btn_emoj, "list_emoj")
    if listEmoj then 
        FGUI:GList_itemRenderer(listEmoj, handler(self, self.OnRendererEmoj))
        FGUI:GList_addOnClickItemEvent(listEmoj, handler(self, self.OnClickItemEmoj))
        FGUI:GList_setNumItems(listEmoj, #self.emojiCfgs)
    end 
end

function PCFriendPanel:InitPage()
    FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.UpdatePageItemRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
end

function PCFriendPanel:UpdatePageItemRenderer(idx, item)
    local index = idx + 1
    local data = PAGE_DATA[index]
    if not data then 
        return 
    end 

    local text_normal = FGUI:GetChild(item, "text_normal")
    local text_select = FGUI:GetChild(item, "text_select")
    FGUI:GTextField_setText(text_normal, data.name)
    FGUI:GTextField_setText(text_select, data.name)
end

function PCFriendPanel:OnClickPage(context)
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self._targetID = nil
    self._targetData = nil
    self:SelectPage(index)
end

function PCFriendPanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
    FGUI:GList_setSelectedIndex(self._ui.list_friend, -1)

	self._selPage = index
    if self._selPage == FGUIDefine.FriendPage.Recent then 
        SL:RequestRecentList()
        self:UpdateList()
    elseif self._selPage == FGUIDefine.FriendPage.Friend then 
        if not self._initFriend then 
            SL:RequestFriendList()
            self._initFriend = true
        end
        self:UpdateList()
    elseif self._selPage == FGUIDefine.FriendPage.Enemy then  
        if not self._initEnmey then 
            SL:RequestEnemyList()
            self._initEnmey = true
        end
        self:UpdateList()
    elseif self._selPage == FGUIDefine.FriendPage.Black then  
        if not self._initBlack then 
            SL:RequestBlackList()
            self._initBlack = true
        end
        self:UpdateList()
    end 

    FGUI:setVisible(self._ui.panel_chat, self._selPage == FGUIDefine.FriendPage.Friend or self._selPage == FGUIDefine.FriendPage.Recent)
    FGUI:setVisible(self._ui.panel_history, self._selPage == FGUIDefine.FriendPage.Enemy or self._selPage == FGUIDefine.FriendPage.Black)
    self:SetChatTarget(self._privateID, self._targetData)
    self._privateID = nil
end

function PCFriendPanel:UpdateList()
    local list = nil
    if self._selPage == FGUIDefine.FriendPage.Recent then  
        list = SL:GetValue("FRIEND_RECENT_LIST") 
    elseif self._selPage == FGUIDefine.FriendPage.Friend then 
        list = SL:GetValue("FRIEND_LIST")
    elseif self._selPage == FGUIDefine.FriendPage.Enemy then  
        list = SL:GetValue("FRIEND_ENEMYLIST")
    elseif self._selPage == FGUIDefine.FriendPage.Black then  
        list = SL:GetValue("FRIEND_BLACKLIST")
    end 
    self._showList = list

    self:SetNothingVisible()
    self:UpdatePlayerOnline()
    FGUI:GList_setNumItems(self._ui.list_friend, #self._showList)
end

function PCFriendPanel:SetNothingVisible()
    local count = #self._showList
    if count == 0 then 
        local sNothing = PAGE_DATA[self._selPage].nothing
        FGUI:GTextField_setText(self._ui.text_nothing, sNothing)
    else 
        FGUI:GTextField_setText(self._ui.text_nothing, "")
    end 
end

function PCFriendPanel:UpdatePlayerOnline()
    local total = #self._showList
    local online = 0
    for _, data in ipairs(self._showList) do 
        if data.Line == 1 then 
            online = online + 1
        end 
    end 

    FGUI:GTextField_setText(self._ui.text_online, string.format(GET_STRING(40020020), online, total))
end

-- list friend
function PCFriendPanel:OnRendererFriend(idx, item)
    if not self._showList or not next(self._showList) then 
        return 
    end

    local index = idx + 1
    local data = self._showList[index]
    if not data then 
        return 
    end

    local myUserId = SL:GetMetaValue("USER_ID")
    if myUserId == data.UserID then 
        return 
    end 

    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, FGUIFunction:GetServerName(data.UserName))

    local ui_level = FGUI:GetChild(item, "text_level")
    FGUI:GTextField_setText(ui_level, data.Level)

    local ui_job = FGUI:GetChild(item, "text_job")
    if data.Job and data.Job ~= 0 then
        FGUI:GTextField_setText(ui_job, GET_STRING(3000 + data.Job))
    else
        FGUI:GTextField_setText(ui_job, "")
    end

    local ui_guild = FGUI:GetChild(item, "text_guild")
    if data.GuildName and string.len(data.GuildName) > 0 then 
        FGUI:GTextField_setText(ui_guild, string.format(GET_STRING(40020021), data.GuildName))
    else 
        FGUI:GTextField_setText(ui_guild, GET_STRING(40020022))
    end
    
    local ui_state = FGUI:GetChild(item, "text_state")
    if data.Line == 1 then 
        FGUI:GTextField_setText(ui_state, GET_STRING(40010021))
        FGUI:GTextField_setColor(ui_state, "#76FF6F")
    else 
        FGUI:GTextField_setText(ui_state, GET_STRING(40010022))
        FGUI:GTextField_setColor(ui_state, "#CCCCCC")
    end 

    local ui_avator = FGUI:GetChild(item, "avator")
	AVATOR_DATA.AvatarID = data.AvatarID
	AVATOR_DATA.Job = data.Job
	AVATOR_DATA.Sex = data.Sex
	AVATOR_DATA.FrameID = data.PhotoframeID
    FGUIFunction:SetCommonPlayerFrame(ui_avator, AVATOR_DATA)

    local btnInfo = FGUI:GetChild(item, "btn_info")
    FGUI:setOnClickEvent(btnInfo, handler(self, self.OnClickPlayerInfo))

    local btn_delete = FGUI:GetChild(item, "btn_delete")
    FGUI:setVisible(btn_delete, self._selPage == FGUIDefine.FriendPage.Recent)
    FGUI:setOnClickEvent(btn_delete, handler(self, self.OnClickDeleteChat))

    if (self._targetID and self._targetID == data.UserID) or (self._privateID and self._privateID == data.UserID) then 
        FGUI:GList_setSelectedIndex(self._ui.list_friend, idx)
    end 

    FGUI:SetIntData(item, idx)
end

function PCFriendPanel:OnClickPlayerInfo(context)
    local index = FGUI:GetIntData(context.sender.parent) + 1
    local data = self._showList[index]
    if not data then  
        return
    end

    if self._selPage == 1 then 
        data.TipsType  = SL:GetValue("DOCKTYPE_NENUM").Func_Friend_Recent
    elseif self._selPage == 2 then 
        data.TipsType  = SL:GetValue("DOCKTYPE_NENUM").Func_Friend
    elseif self._selPage == 3 then 
        data.TipsType  = SL:GetValue("DOCKTYPE_NENUM").Func_Archenemy
    elseif self._selPage == 4 then 
        data.TipsType  = SL:GetValue("DOCKTYPE_NENUM").Func_Friend_BlackList
    end 

    data.targetName = data.UserName
    data.targetId = data.UserID
    data.GuildName = data.GuildName or ""
    data.FrameID = data.PhotoframeID
    FGUIFunction:OpenFuncDockTips(data)
end

function PCFriendPanel:OnClickDeleteChat(context)
    local index = FGUI:GetIntData(context.sender.parent) + 1
    local data = self._showList[index]
    if not data then  
        return
    end

    SL:PrivateChatDelete(data.UserID)
    self:UpdateList()
    self:SetChatTarget(nil)
end

local targetData = {}
function PCFriendPanel:OnClickItemFriend(context)
	local idx = FGUI:GetChildIndex(self._ui.list_friend, context.data) 
    FGUI:GList_setSelectedIndex(self._ui.list_friend, idx)

    local index = idx + 1
    local data = self._showList[index]
    if not data then  
        return
    end 

    targetData.TargetName = data.UserName
    targetData.TargetLevel = data.Level
    targetData.TargetJob = data.Job
    targetData.TargetSex = data.Sex
    self:SetChatTarget(data.UserID, targetData, data)
end

function PCFriendPanel:SetChatTarget(targetId, targetData, data)
    if targetId ~= self._targetID then 
        self._targetID = targetId
        self._targetData = targetData
    end

    if self._selPage == FGUIDefine.FriendPage.Friend or self._selPage == FGUIDefine.FriendPage.Recent then 
        self:UpdateChatView()
    else 
        self:UpdateHistoryView(data)
    end
end

-- list chat
function PCFriendPanel:UpdateChatView()
    if self._targetID then 
        local maxChatCount = FGUI:GList_getNumItems(self._ui.list_chat)
        if maxChatCount > 100 then
            FGUI:GList_removeChildToPoolAt(self._ui.list_chat, 0)
        end
        self._messages = SL:GetValue("CHAT_PRIVATE_DATA", self._targetID)  
        FGUI:GList_setNumItems(self._ui.list_chat, #self._messages)
    else 
        FGUI:GList_setNumItems(self._ui.list_chat, 0)
    end 
end

function PCFriendPanel:OnProviderChat(idx)
    if not self._messages or not next(self._messages) then 
        return 
    end

    local index = idx + 1
    local data = self._messages[index]
    if not data then 
        return 
    end

    local isSelf = SL:GetValue("USER_ID") == data.SendID
    if isSelf then
        return "ui://hxz346vpwmgrb"
    else
        return "ui://hxz346vpwmgr8"
    end
end

function PCFriendPanel:OnRendererChat(idx, item)
    if not self._messages or not next(self._messages) then 
        return 
    end

    local index = idx + 1
    local data = self._messages[index]
    if not data then 
        return 
    end

    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, FGUIFunction:GetServerName(data.SendName))

    local ui_avator = FGUI:GetChild(item, "avator")
    local job = SL:GetValue("JOB")
    local sex = SL:GetValue("SEX")
    local isSelf = SL:GetValue("USER_ID") == data.SendID 
    if not isSelf then 
        job = data.Job
        sex = data.Sex
    end 

	AVATOR_DATA.AvatarID = data.AvatarID
	AVATOR_DATA.Job = job
	AVATOR_DATA.Sex = sex
	AVATOR_DATA.FrameID = data.PhotoframeID 
    FGUIFunction:SetCommonPlayerFrame(ui_avator, AVATOR_DATA)

    local ui_frame = FGUI:GetChild(item, "Image_chatFrame")
    local frameURL = FGUIFunction:GetChatFrameUrl(data.ChatBID)
    FGUI:GLoader_setUrl(ui_frame, frameURL, nil, true)

    local rich_msg = FGUI:GetChild(item, "rich_msg")
    if data.MT == SLDefine.CHAT_MSG_TYPE.Position then
		local mapData = data.Msg
		local mapName = mapData.mapName
		local mapX = mapData.mapX
		local mapY = mapData.mapY
		local msg = string.format("<a href='%d'><u>[%s %s,%s]</u></a>",index, mapName, mapX, mapY)
		FGUI:GRichTextField_setText(rich_msg,msg)
		FGUI:GRichTextField_setOnLinkClickEvent(rich_msg, handler(self, self.OnClickPositionLink))
    else 
        FGUI:GRichTextField_setText(rich_msg, SL:ChatParser_Parse(data.Msg))
    end

    -- local richWidth = FGUI:GRichTextField_getTextWidth(rich_msg)
    -- local richHeight = FGUI:GRichTextField_getTextHeight(rich_msg)
    -- richWidth = richWidth > 364 and 364 or richWidth
    -- richHeight = richHeight > 84 and 84 or richHeight
    -- local ui_chatBg = FGUI:GetChild(item, "chat_bg")
    -- local imageW = math.max(60, richWidth + 30) 
    -- local imageH = math.max(50, richHeight + 10)
    -- FGUI:setSize(ui_chatBg, imageW, imageH)
    FGUI:GList_ScrollToView(self._ui.list_chat, idx)
    FGUI:SetIntData(item, idx)
end

function PCFriendPanel:UpdateHistoryView(data)
    if not data then 
        FGUI:GRichTextField_setText(self._ui("scroll_history", "rich_history"), "")
        return 
    end 

    if not self._targetID then 
        return 
    end 

    FGUI:GRichTextField_setText(self._ui("scroll_history", "rich_history"), data.Log)
end

function PCFriendPanel:OnClickPositionLink(context)
    if not self._targetID then 
        SL:ShowSystemTips(GET_STRING(40000110))
        return
    end

    local isBlack = SL:GetValue("SOCIAL_IS_BLACKLIST", self._targetID)
    if isBlack then 
        SL:ShowSystemTips(GET_STRING(40020003))
        return
    end 
    
    local index = FGUI:GetIntData(context.sender.parent) + 1
    local data = self._messages[index]
    if not data then 
        return 
    end
    
    local mapData = data.Msg
    local mapID = mapData.mapID
    local mapX = mapData.mapX
    local mapY = mapData.mapY
    SL:SetValue("BATTLE_AUTO_MOVE_BEGIN",  mapID, mapX, mapY)
end

-- list emoj
function PCFriendPanel:OnRendererEmoj(idx, item)
    local index = idx + 1
    local data = self.emojiCfgs[index]
    if not data then 
        return 
    end 

    local imgEmoj = FGUI:GetChild(item, "img_emoj")
    FGUI:GLoader_setUrl(imgEmoj, "ui://public_pc/"..index)
end

function PCFriendPanel:OnClickItemEmoj(context)
    local listEmoj = FGUI:GetChild(self._ui.btn_emoj, "list_emoj")
    if listEmoj then 
        local idx = FGUI:GetChildIndex(listEmoj, context.data) 
        FGUI:GList_setSelectedIndex(listEmoj, idx)
        local index = idx + 1
        local eData = self.emojiCfgs[index]
        if eData then
            FGUI:GTextInput_replaceSelection(self._ui.input_chat,string.format("[%s]",eData.replace))
        end
    end
end

-- evnet
function PCFriendPanel:OnSendMessage()
    if not self._targetID then 
        SL:ShowSystemTips(GET_STRING(40000110))
        return
    end

    local isBlack = SL:GetValue("SOCIAL_IS_BLACKLIST", self._targetID)
    if isBlack then 
        SL:ShowSystemTips(GET_STRING(40020003))
        return
    end 

    local msg = FGUI:GTextField_getText(self._ui.input_chat)
    if #msg <= 0 then
        SL:ShowSystemTips(GET_STRING(40000103))
        return
    end
    FGUI:GTextField_setText(self._ui.input_chat, "")

    SL:RequestSendChatPriavteMsg(msg, self._targetID, self._targetData)
end

function PCFriendPanel:OnSendPostion()
    SL:RequestSendChatPosMsg(SLDefine.CHAT_CHANNEL.Private, self._targetID, self._targetData)
end

function PCFriendPanel:OpenAddFriendUI()
    FGUI:Open("Friend_pc", "PCFriendApplyPanel", FGUIDefine.FriendOpreate.Add)
end

function PCFriendPanel:OnAddPrivateChatItem()
    self:UpdateChatView()
end

function PCFriendPanel:OnFriendListUpdate()
    if self._selPage ~= FGUIDefine.FriendPage.Friend then return end
    self:UpdateList()
    self:UpdateChatView()
end

function PCFriendPanel:OnRecentListUpdate()
    if self._selPage ~= FGUIDefine.FriendPage.Recent then return end
    self:UpdateList()
end

function PCFriendPanel:OnBlackListUpdate()
    if self._selPage ~= FGUIDefine.FriendPage.Black then return end
    self:UpdateList()
end

function PCFriendPanel:OnEnemyListUpdate()
    if self._selPage ~= FGUIDefine.FriendPage.Enemy then return end
    self:UpdateList()
end

-----------------------------------注册事件--------------------------------------
function PCFriendPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_ADD_PRIVATE_ITEM, "PCFriendPanel", handler(self, self.OnAddPrivateChatItem))
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_LIST_UPDATE, "PCFriendPanel", handler(self, self.OnFriendListUpdate))
    SL:RegisterLUAEvent(LUA_EVENT_RECENT_CHAT_LIST_UPDATE, "PCFriendPanel", handler(self, self.OnRecentListUpdate))
    SL:RegisterLUAEvent(LUA_EVENT_BLACK_LIST_UPDATE, "PCFriendPanel", handler(self, self.OnBlackListUpdate))
    SL:RegisterLUAEvent(LUA_EVENT_ENEMY_LIST_UPDATE, "PCFriendPanel", handler(self, self.OnEnemyListUpdate))

end

function PCFriendPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ADD_PRIVATE_ITEM, "PCFriendPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_FRIEND_LIST_UPDATE, "PCFriendPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_RECENT_CHAT_LIST_UPDATE, "PCFriendPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_BLACK_LIST_UPDATE, "PCFriendPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_ENEMY_LIST_UPDATE, "PCFriendPanel")
end

return PCFriendPanel