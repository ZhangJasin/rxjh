local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MailPanel = class("MailPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local MAX_MAIL_COUNT = 100

function MailPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	
	self:InitData()
	self:InitEvent()
end 

function MailPanel:Enter()
    self:RegisterEvent()
	SL:RequestMailList()

	SL:ComponentAttach(SLDefine.SUIComponentTable.Mail, self._ui.Node_attach)
end

function MailPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.Mail)
end

function MailPanel:OnClose()
	self._curMailID = 0
	self.super.Close(self)
end

function MailPanel:InitData()
	self._mailList = {}
    self._curMailID = 0
end

function MailPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.OnClose))
	FGUI:setOnClickEvent(self._ui.btn_takeAll, handler(self, self.OnClickTakeAll))
	FGUI:setOnClickEvent(self._ui.btn_delAll, handler(self, self.OnClickDeleteAll))

	FGUI:setOnClickEvent(self._ui.btn_take, handler(self, self.OnClickTakeOne))
	FGUI:setOnClickEvent(self._ui.btn_delete, handler(self, self.OnClickDeleteOne))
	FGUI:setOnClickEvent(self._ui.btn_help, handler(self, self.OnClickHelp))

	FGUI:GList_itemRenderer(self._ui.list_mail, handler(self, self.ItemRendererMailList))
    FGUI:GList_setOnClickItemEvent(self._ui.list_mail, handler(self, self.OnClickItemMail))

	FGUI:setOnClickEvent(self._ui.btn_sure, handler(self, self.OnClickSure))
	FGUI:setOnClickEvent(self._ui.btn_resure, handler(self, self.OnClickReSure))
end

function MailPanel:OnClickTakeAll(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	local mailList = SL:GetValue("MAIL_LIST")
	if not mailList or not next(mailList) then
		SL:ShowSystemTips(GET_STRING(50000017))
		return 
	end 

	local isEnough = self:CheckBagEnough()
	if not isEnough then 
		SL:ShowSystemTips(GET_STRING(60003001))
		return 
	end 

	SL:RequestGetAllMailReward()
	SL:RequestMailList()
end

function MailPanel:OnClickDeleteAll(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	if self:CheckAbleDeleteAllReadMail() then
		SL:RequestDelReadMail()
	else
		local mailList = SL:GetValue("MAIL_LIST")
		if mailList and next(mailList) then
			SL:ShowSystemTips(GET_STRING(50000001))
		else
			SL:ShowSystemTips(GET_STRING(50000002))
		end
	end
end

function MailPanel:OnClickTakeOne(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	local isEnough = self:CheckBagEnough(self._curMailID)
	if not isEnough then 
		SL:ShowSystemTips(GET_STRING(60003001))
		return 
	end

	if self:CheckAbleTakeRewardMailByID(self._curMailID) then 
		SL:RequestGetMailRewardByID(self._curMailID)
	else         
		SL:ShowSystemTips(GET_STRING(50000017))
	end 
end
--确定收货
function MailPanel:OnClickSure(context)
	local mail = SL:GetValue("MAIL_BY_ID", self._curMailID)	
	if not mail then 
		return
	end
	if type(mail.sItem) == "table" and #mail.sItem > 0 then
		local other = mail.sItem[1].other
		other = SL:JsonDecode(other)
		if other then
			other.emailId = self._curMailID
			SL:RequestSureTake(other)
		end
	end
end
--拒绝收货
function MailPanel:OnClickReSure(context)
	local mail = SL:GetValue("MAIL_BY_ID", self._curMailID)
	if not mail then 
		return
	end
	if type(mail.sItem) == "table" and #mail.sItem > 0 then
		local other = mail.sItem[1].other
		other = SL:JsonDecode(other)
		if other then
			other.emailId = self._curMailID
			SL:RequestRefuseTake(other)
		end
	end
end

function MailPanel:OnClickDeleteOne(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	if self._curMailID > 0 then 
		if self:CheckAbleDeleteReadMailByID(self._curMailID) then
			SL:RequestDelMail(self._curMailID)
		else 
			SL:ShowSystemTips(GET_STRING(50000001))
		end
	else        
		SL:ShowSystemTips(GET_STRING(50000002))
	end 
end

function MailPanel:OnClickHelp()
	local data = {}
	data.title = GET_STRING(50000018)
	data.str = GET_STRING(50000019)
	SL:OpenCommonHelpDialog(data)
end

-- 刷新邮件列表
function MailPanel:OnUpdateMailList()
	table.clear(self._mailList)
    self._mailList = self:GetSortMailList()
	local color = #self._mailList > 0 and "#00ff00" or "#ff0000"
	FGUI:GTextField_setText(self._ui.text_count, string.format(GET_STRING(50000020),color, #self._mailList, MAX_MAIL_COUNT))
	FGUI:setVisible(self._ui.panel_nothing, #self._mailList <= 0)

    FGUI:GList_setNumItems(self._ui.list_mail, #self._mailList)

	if #self._mailList > 0 then    
		self:SelectMail(1)
	end 

	self:RefreshMailInfo()
end

-- renderer
function MailPanel:ItemRendererMailList(idx, item)
    local index = idx + 1
    local data = self._mailList[index]
    if not data then 
        return 
    end

	local icon_state = FGUI:GetChild(item, "icon_state")
	local text_sender = FGUI:GetChild(item, "text_sender")
	local text_title = FGUI:GetChild(item, "text_title")
	local text_time = FGUI:GetChild(item, "text_time")
	local img_red = FGUI:GetChild(item, "img_redpoint")

	FGUI:GTextField_setText(text_sender, data.sSendName)
	FGUI:GTextField_setText(text_title, data.sLable)
	FGUI:GTextField_setText(text_time, data.dCreateTime)
	local path = string.format("ui://Mail/icon_mail%s", data.btReadFlag)
	FGUI:GLoader_setUrl(icon_state, path)	

	local bShow = self:CheckMailRedPoint(data.Id)
	FGUI:setVisible(img_red, bShow)
end

function MailPanel:OnClickItemMail(context)
	local selectIdx = FGUI:GList_getSelectedIndex(self._ui.list_mail) + 1
	self:SelectMail(selectIdx)
	self:RefreshMailInfo()
end

function MailPanel:SelectMail(selectIdx)
	local item = self._ui.list_mail:GetChildAt(selectIdx - 1)
	if not item then 
		return 
	end 

	local data = self._mailList[selectIdx]
	if not data then 
		return 
	end 

    if data.btReadFlag == 0 then
        SL:RequestReadMail(data.Id)
    end

	local icon_state = FGUI:GetChild(item, "icon_state")
	local path = string.format("ui://Mail/icon_mail%s", data.btReadFlag == 0 and 1 or 1)
	FGUI:GLoader_setUrl(icon_state, path)

	local img_red = FGUI:GetChild(item, "img_redpoint")
	local bShow = self:CheckMailRedPoint(data.Id)
	FGUI:setVisible(img_red, bShow)
	FGUI:GList_setSelectedIndex(self._ui.list_mail, selectIdx - 1)
	self._curMailID = data.Id
end

-- 刷新邮件内容
function MailPanel:RefreshMailInfo()
	if self._curMailID <= 0 then 
		FGUI:GTextField_setText(self._ui.text_name, "")
		FGUI:GTextField_setText(self._ui.text_sender, "")
		FGUI:GTextField_setText(self._ui.text_time, "")
		local rich_content = FGUI:GetChild(self._ui.rich_component, "rich_content")
		FGUI:GRichTextField_setText(rich_content, "")
		FGUI:setVisible(self._ui.img_got, false)
		FGUI:setVisible(self._ui.panel_items, false)

		FGUI:setVisible(self._ui.btn_sure, false)
        FGUI:setVisible(self._ui.btn_resure, false)
	else 
		local mail = SL:GetValue("MAIL_BY_ID", self._curMailID)
		if not mail then
			FGUI:setVisible(self._ui.btn_sure, false)
            FGUI:setVisible(self._ui.btn_resure, false)
			return
		end

		-- name
		FGUI:GTextField_setText(self._ui.text_name, mail.sLable)

		-- sender
		FGUI:GTextField_setText(self._ui.text_sender, mail.sSendName)

		-- tiem 
		FGUI:GTextField_setText(self._ui.text_time, mail.dCreateTime)

		-- info
		local rich_content = FGUI:GetChild(self._ui.rich_component, "rich_content")
		FGUI:GRichTextField_setText(rich_content, mail.sMemo)
		local richW, richH = FGUI:getContentSize(self._ui.rich_component)
		local textW, textH = FGUI:getContentSize(rich_content)
		if textH >= richH then 
			FGUI:setTouchEnabled(self._ui.rich_component, true)
		else 
			FGUI:setTouchEnabled(self._ui.rich_component, false)
		end 

		-- got
		FGUI:setVisible(self._ui.img_got, mail.btRecvFlag == 1 and #mail.sItem > 0)
	
		-- items
		if type(mail.sItem) == "string" and (mail.btType == 9999 or mail.btType == 9998 or mail.btType == 9997) then --交易行和摆摊的附件
			local data = SL:JsonDecode(mail.sItem)
			mail.sItem = {}
			table.insert(mail.sItem, data)
		end

		FGUI:setVisible(self._ui.panel_items, #mail.sItem > 0)

		FGUI:setVisible(self._ui.btn_sure, false)
        FGUI:setVisible(self._ui.btn_resure, false)
		if #mail.sItem > 0 then
			if mail.btRecvFlag == 0 then
				-- 附件未领取 不能删除
				if mail.btType == 9998 then
					FGUI:setVisible(self._ui.btn_sure, true)
					FGUI:setVisible(self._ui.btn_resure, true)

					FGUI:setVisible(self._ui.btn_take, false)
                    FGUI:setVisible(self._ui.btn_delete, false)
				else
					FGUI:setVisible(self._ui.btn_sure, false)
					FGUI:setVisible(self._ui.btn_resure, false)

					FGUI:setVisible(self._ui.btn_take, true)
                    FGUI:setVisible(self._ui.btn_delete, true)
				end
			end

			FGUI:GList_itemRenderer(self._ui.list_items, function (idx, item)
				FGUI:setSize(item,64,64)
				local index = idx + 1
				local data = mail.sItem[index]
				if not data then 
					return 
				end 

				local itemData = nil
				if mail.btType == 9999 or mail.btType == 9998 or mail.btType == 9997 then 
					itemData = ItemUtil:FixItemDataByServerRawData(data)
				else 
					itemData = SL:GetValue("ITEM_DATA", data.Index)
					if not itemData then 
						SL:print("error check config!")
						return 
					end
					itemData.OverLap = data.Count
				end

				if itemData then 
					itemData.isShowCount = true
					ItemUtil:RefreshItemUIByData(item, itemData)
					ItemUtil:AddItemClick(item, itemData)
				end 


			end)
			FGUI:GList_setNumItems(self._ui.list_items, #mail.sItem)
		end
	end 
end

function MailPanel:CheckAbleDeleteAllReadMail()
    local mails = SL:GetValue("MAIL_LIST")
    for k, v in pairs(mails) do
        if self:CheckAbleDeleteReadMailByID(k) then
            return true
        end
    end
    return false
end

function MailPanel:CheckAbleDeleteReadMailByID(mailID)
    local mail = SL:GetValue("MAIL_BY_ID", mailID)
    if not mail then
        return false
    end
    return mail.btReadFlag == 1 and (#mail.sItem == 0 or (#mail.sItem > 0 and mail.btRecvFlag == 1))
end

function MailPanel:CheckAbleTakeRewardMailByID(mailID)
    local mail = SL:GetValue("MAIL_BY_ID", mailID)
    if not mail then
        return false
    end
    return mail.btReadFlag == 1 and mail.btRecvFlag == 0 and #mail.sItem > 0 
end

function MailPanel:CheckMailRedPoint(mailID)
    local mail = SL:GetValue("MAIL_BY_ID", mailID)
    if not mail then
        return false
    end

	local bHaveItems = false
	if type(mail.sItem) == "string" and (mail.btType == 9999 or mail.btType == 9998 or mail.btType == 9997) then --交易行和摆摊的附件
		local info = SL:JsonDecode(mail.sItem)
		mail.sItem = {}
		table.insert(mail.sItem, info)
	end

	if #mail.sItem > 0 then
		bHaveItems = true
	end

	return mail.btRecvFlag == 0 and bHaveItems
end

function MailPanel:GetMailRewardCount(mail)
	local count = 0
	if not mail then  
		return 0
	end 

	if type(mail.sItem) == "string" and (mail.btType == 9999 or mail.btType == 9998 or mail.btType == 9997) then --交易行和摆摊的附件
		count = 1
	else 
		count = #mail.sItem
	end

	return count
end

function MailPanel:CheckBagEnough(mailID)
	local rewardCount = 0

	if mailID then 
		local mail = SL:GetValue("MAIL_BY_ID", mailID)
		if not mail then
			return false
		end

		if self:CheckAbleTakeRewardMailByID(mailID) then 
			rewardCount = self:GetMailRewardCount(mail)
		end
	else 
		local mailList = SL:GetValue("MAIL_LIST")
		if not mailList or not next(mailList) then
			return 
		end

		for id, mail in pairs(mailList) do 
			if self:CheckAbleTakeRewardMailByID(id) then 
				rewardCount = rewardCount + self:GetMailRewardCount(mail)
			end
		end 
	end 

	local itemCount = SL:GetValue("BAG_DATA_COUNT")
	local openCount = SL:GetValue("BAG_OPEN_SIZE")
	if rewardCount + itemCount > openCount then 
		return false
	end 

	return true
end 

-- 邮件列表排序
-- 邮件分为三类并排序，未读>已读未领取>已读已领取
-- 每个分类里再按时间进行排序，时间越近的排在越上方
function MailPanel:GetSortMailList()
	local mails = SL:GetValue("MAIL_LIST") or {}
	local list = SL:HashToSortArray(mails, function(a, b)
		if a.btReadFlag ~= b.btReadFlag then     
			return a.btReadFlag < b.btReadFlag
		elseif a.btRecvFlag ~= b.btRecvFlag then     
			return a.btRecvFlag < b.btRecvFlag
		else     
			return a.index < b.index
		end 
	end)

	return list
end

function MailPanel:OnDeleteAllRead()
    SL:ShowSystemTips(GET_STRING(50000003))
	self._curMailID = 0
    SL:RequestMailList()
end

function MailPanel:OnUpdateOne(mail)
	self:OnUpdateMailList()
	self:RefreshMailInfo()
end

function MailPanel:OnDeleteOne()
    SL:ShowSystemTips(GET_STRING(50000003))
	self._curMailID = 0
	self:OnUpdateMailList()
end

function MailPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_RESPONSE_LIST, "MailPanel", handler(self, self.OnUpdateMailList))
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_UPDATE_ALL, "MailPanel", handler(self, self.OnUpdateMailList))
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_DELETE_ALL_READ, "MailPanel", handler(self, self.OnDeleteAllRead))
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_UPDATE, "MailPanel", handler(self, self.OnUpdateOne))
    SL:RegisterLUAEvent(LUA_EVENT_MAIL_DELETE, "MailPanel", handler(self, self.OnDeleteOne))
end

function MailPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_MAIL_RESPONSE_LIST, "MailPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MAIL_UPDATE_ALL, "MailPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MAIL_DELETE_ALL_READ, "MailPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MAIL_UPDATE, "MailPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MAIL_DELETE, "MailPanel")
end

return MailPanel