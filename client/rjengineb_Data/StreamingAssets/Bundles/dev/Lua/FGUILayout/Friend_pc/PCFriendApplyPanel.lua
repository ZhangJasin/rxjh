local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCFriendApplyPanel = class("PCFriendApplyPanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "添加好友", page = 1, nothing = "暂无好友"},
	[2] = {name = "好友申请", page = 2, nothing = "暂无申请"},
}

function PCFriendApplyPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:SetCloseUIWhenClickOutside(self)

	self:InitData()
	self:InitEvent()
    self:InitPage()
end 

function PCFriendApplyPanel:Close()
	self.super.Close(self)
end

function PCFriendApplyPanel:Enter(page)
    if not page then
        page = 1
    end 
    self:SelectPage(page)
    self:RegisterEvent()
end

function PCFriendApplyPanel:Exit()
	self:RemoveEvent()
end

function PCFriendApplyPanel:InitData()
    self._selPage = 1
    self._showList = {}
    self._searchData = nil
end

function PCFriendApplyPanel:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.btn_search, handler(self, self.OnClickSearchFriend))
    FGUI:setOnClickEvent(self._ui.btn_refresh, handler(self, self.OnClickRefreshBatch))

	FGUI:GList_itemRenderer(self._ui.list_friend, handler(self, self.OnRendererList))
end

function PCFriendApplyPanel:InitPage()
    FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.UpdatePageItemRenderer))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))
end

function PCFriendApplyPanel:UpdatePageItemRenderer(idx, item)
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

function PCFriendApplyPanel:OnClickPage()
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function PCFriendApplyPanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
	self._selPage = index

    FGUI:setVisible(self._ui.btn_refresh, self._selPage == 1)
    self:OnUpdateList()
end

function PCFriendApplyPanel:OnUpdateList(bSearch)
    self._showList = {}
    if bSearch then 
        if self._searchData then 
            self._showList = self._searchData
        end
    else 
        if self._selPage == 1 then 
            self._showList = SL:GetValue("FRIEND_RANDOM_LIST")
        elseif self._selPage == 2 then  
            self._showList = SL:GetValue("FRIEND_APPLYLIST")
        end
    end  

    FGUI:GList_setNumItems(self._ui.list_friend, #self._showList)
    self:SetNothingVisible()
end

function PCFriendApplyPanel:SetNothingVisible()
    local count = #self._showList
    FGUI:setVisible(self._ui.panel_nothing, count == 0)
    if count == 0 then 
        local sNothing = PAGE_DATA[self._selPage].nothing
        FGUI:GTextField_setText(self._ui.text_nothing, sNothing)
    end 
end

local AVATOR_DATA = {}
function PCFriendApplyPanel:OnRendererList(idx, item)
    if not self._showList or not next(self._showList) then  
        return 
    end 
    
    local index = idx + 1
    local data = self._showList[index]
    if not data then 
        return 
    end

    local ui_name = FGUI:GetChild(item, "text_name")
    local ui_level = FGUI:GetChild(item, "text_level")
    FGUI:GTextField_setText(ui_name, FGUIFunction:GetServerName(data.UserName))
    FGUI:GTextField_setText(ui_level, "LV："..data.Level)

    local ui_avator = FGUI:GetChild(item, "avator")
    AVATOR_DATA.AvatarID = data.AvatarID
	AVATOR_DATA.Job = data.Job
	AVATOR_DATA.Sex = data.Sex
	AVATOR_DATA.FrameID = data.PhotoframeID 
    FGUIFunction:SetCommonPlayerFrame(ui_avator, AVATOR_DATA)

    local btn_add = FGUI:GetChild(item, "btn_addFriend")
    local btn_agree = FGUI:GetChild(item, "btn_agree")
    local btn_refuse = FGUI:GetChild(item, "btn_refuse")
    FGUI:setVisible(btn_add, self._selPage == 1)
    FGUI:setVisible(btn_agree, self._selPage == 2)
    FGUI:setVisible(btn_refuse, self._selPage == 2)
    if self._selPage == 1 then 
        FGUI:GButton_setBright(btn_add, true)
        FGUI:GButton_setGrey(btn_add, false)
        FGUI:setOnClickEvent(btn_add, handler(self, self.OnClickBtnAddFriend))
        local text_btn = FGUI:GetChild(btn_add, "text")
        if SL:GetMetaValue("SOCIAL_IS_FRIEND", tonumber(data.UserID)) then 
            FGUI:GTextField_setText(text_btn, GET_STRING(40020023))
        end 
    elseif self._selPage == 2 then 
        FGUI:GButton_setBright(btn_agree, true)
        FGUI:GButton_setGrey(btn_agree, false)
        FGUI:GButton_setBright(btn_refuse, true)
        FGUI:GButton_setGrey(btn_refuse, false)
        FGUI:setOnClickEvent(btn_agree, handler(self, self.OnClickBtnAgree))
        FGUI:setOnClickEvent(btn_refuse, handler(self, self.OnClickBtnRefuse))  
    end
    FGUI:SetIntData(item, idx)
end

function PCFriendApplyPanel:OnClickBtnAddFriend(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local index = FGUI:GetIntData(eventData.sender.parent) + 1
    local data = self._showList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(eventData.sender, false)
    FGUI:GButton_setGrey(eventData.sender, true)
    SL:RequestAddFriend(data.UserID or data.UserId)
end

function PCFriendApplyPanel:OnClickBtnAgree(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local index = FGUI:GetIntData(eventData.sender.parent) + 1
    local data = self._showList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(eventData.sender, false)
    FGUI:GButton_setGrey(eventData.sender, true)
    SL:RequestAgreeFriendApply(data.UserID)
    self:OnUpdateList()
end


function PCFriendApplyPanel:OnClickBtnRefuse(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local index = FGUI:GetIntData(eventData.sender.parent) + 1
    local data = self._showList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(eventData.sender, false)
    FGUI:GButton_setGrey(eventData.sender, true)
    SL:RequestRefuseFriendApply(data.UserID)
    self:OnUpdateList()
end

function PCFriendApplyPanel:OnClickSearchFriend(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    if self._selPage == 2 then 
        return 
    end 

    local inputStr = FGUI:GTextField_getText(self._ui.input_name)
    if #inputStr <= 0 then
        SL:ShowSystemTips(GET_STRING(40000103))
        return
    end
    FGUI:GTextField_setText(self._ui.input_name, "")
    SL:RequestSearchFriend(inputStr)
end

function PCFriendApplyPanel:OnClickRefreshBatch(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    SL:RequestRandomFriend()
end

function PCFriendApplyPanel:OnUpdateApplyList(data)
    self:OnUpdateList()
end

function PCFriendApplyPanel:OnUpdateRandom(data)
    self:OnUpdateList()
end

function PCFriendApplyPanel:UpdateSearchResult(data)
    if not data then return end
    self._searchData = data
    self:OnUpdateList(true)
end

-----------------------------------注册事件--------------------------------------
function PCFriendApplyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_APPLY, "PCFriendApplyPanel", handler(self, self.OnUpdateApplyList))
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_RANDOM_UPDATE, "PCFriendApplyPanel", handler(self, self.OnUpdateRandom))
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_SEARCH_UPDATE, "PCFriendApplyPanel", handler(self, self.UpdateSearchResult))  
end

function PCFriendApplyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_FRIEND_APPLY, "PCFriendApplyPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_FRIEND_RANDOM_UPDATE, "PCFriendApplyPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_FRIEND_SEARCH_UPDATE, "PCFriendApplyPanel")
end

return PCFriendApplyPanel