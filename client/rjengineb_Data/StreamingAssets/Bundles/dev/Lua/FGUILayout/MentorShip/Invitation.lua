local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local Invitation = class("Invitation", BaseFGUILayout)

function Invitation:Create()
    self._ui = FGUI:ui_delegate(self.component)
end

function Invitation:Enter(data)
    --师傅邀请的
    self.statusController = FGUI:getController(self.component,"status")
    self.whoController = FGUI:getController(self.component,"who")
    self.isAgreeController = FGUI:getController(self.component,"isAgree")
    self.viewType = data.type
    self.task = data.task
    self.initiator = data.initiator
    self.myUserId = tonumber(data.myUserId)
    InvitationUI.CCUI = self
    if self.viewType == "MentorShipMain" then 
        self.apprenticeList = data.apparenice
        self.selectUserId = {}
        self.waitingListData = {}
        FGUI:Controller_setSelectedIndex(self.statusController,0)
        FGUI:GList_itemRenderer(self._ui.Invitation_list, handler(self, self.RenderInvitation))
        FGUI:GList_setNumItems(self._ui.Invitation_list, #self.apprenticeList) 
    else
        --服务端发通知的
        self.waitingListData = data.dataList
        self.dsqsj = data.dsqsj
        self.agreeNum = 0
        self.agreeList = {}
        FGUI:Controller_setSelectedIndex(self.statusController,1)
        --是否师傅
        if tonumber(self.myUserId) == tonumber(self.initiator.UserID) then
            FGUI:Controller_setSelectedIndex(self.whoController,0)
        else
            FGUI:Controller_setSelectedIndex(self.isAgreeController,0)
            FGUI:Controller_setSelectedIndex(self.whoController,1)
        end
        for i=1,#self.waitingListData do
            if tonumber(self.waitingListData[i].UserID) == tonumber(self.myUserId) then
                if self.waitingListData[i].isAgreeStatus == 0 then
                    FGUI:Controller_setSelectedIndex(self.isAgreeController,0)
                else
                    FGUI:Controller_setSelectedIndex(self.isAgreeController,1)
                end
            end
        end
        FGUI:GList_itemRenderer(self._ui.wait_list_apprentice, handler(self, self.RenderWaingList))
        FGUI:GList_setNumItems(self._ui.wait_list_apprentice, #self.waitingListData)
        self:setTimeOut()
        FGUI:setOnClickEvent(self._ui.btn_agree,handler(self,self.onClickBtnAgree))
        FGUI:setOnClickEvent(self._ui.btn_chuzhan,handler(self,self.onClickBtnCZ))
    end
    self:initEvent()
end

function Invitation:resetView(data)
    if FGUI:CheckOpen("MentorShip", "Invitation") then
        self = InvitationUI.CCUI
        self.waitingListData = data
         for i=1,#self.waitingListData do
            if tonumber(self.waitingListData[i].UserID) == tonumber(self.myUserId) then
                if self.waitingListData[i].isAgreeStatus == 0 then
                    FGUI:Controller_setSelectedIndex(self.isAgreeController,0)
                else
                    FGUI:Controller_setSelectedIndex(self.isAgreeController,1)
                end
            end
        end
        FGUI:GList_setNumItems(self._ui.wait_list_apprentice, #self.waitingListData)
    end
end

function Invitation:Exit()
    print(self.agreeNum)
    --是否师傅
    if tonumber(self.myUserId) == tonumber(self.initiator.UserID) then
        --关掉所有人的
        ssrMessage:sendmsgEx("MentorShip", "closeAllInvitation",self.waitingListData)
    end
end

function Invitation:closeView(data)
    self = InvitationUI.CCUI
    self.super.Close(self)
     if self.dsq then
        SL:UnSchedule(self.dsq)
    end
    if not data.isMine then 
        SL:ShowSystemTips(data.cancelName.."取消了")
    end
end

function Invitation:timeEnd()
    self = InvitationUI.CCUI
    SL:ShowSystemTips("有玩家未同意")
    self.super.Close(self)
end

function Invitation:moveResult()
    self = InvitationUI.CCUI
    self.super.Close(self)
    FGUI:Close("MentorShip", "MentorShipPanel")
end

function Invitation:onClickBtnAgree()
    InvitationUI.CCUI = self
    --同意参加副本
    ssrMessage:sendmsgEx("MentorShip", "agreeJoin",self.waitingListData)
end
function Invitation:onClickRedBtn()
    --不同意副本
    FGUI:Close("MentorShip", "Invitation")
    if self.dsq then
        SL:UnSchedule(self.dsq)
    end
    ssrMessage:sendmsgEx("MentorShip", "notAgreeJoin",self.waitingListData)
end

function Invitation:onClickBtnCZ()
    --师傅点击了出战
    local nums = 0
    local finallyUserList = {}
    for i=1,#self.waitingListData do
        local item = self.waitingListData[i]
        if item.isAgreeStatus == 1 then
            nums = nums + 1
            table.insert(finallyUserList,item)
        elseif item.isAgreeStatus == 2 then
            nums = nums +1
        elseif item.isAgreeStatus == 0 then
        else
            table.insert(finallyUserList,item)
        end
    end
    if nums == #self.waitingListData - 1 then
        SL:UnSchedule(self.dsq)
        InvitationUI.CCUI = self
        ssrMessage:sendmsgEx("MentorShip", "mapMoveAll",{users = finallyUserList,taskType = self.task.task_target_param})
    else
        SL:ShowSystemTips("等待徒弟同意中")
    end
end

function Invitation:setView(data)
    FGUI:Open("MentorShip",'Invitation',data)
end

function Invitation:timeOutEnd()
    ssrMessage:sendmsgEx("MentorShip", "timeOutEnd",{num =self.agreeNum, users = self.waitingListData })
end

function Invitation:setTimeOut()
    self = InvitationUI.CCUI
    if self.dsq then
        SL:UnSchedule(self.dsq)
    end
    self.time = 30
    local dsjText = set
    local function invitationjs()
            local times =  SL:GetValue("SERVER_TIME")*1000 - self.dsqsj
            local min = 30 - math.floor(times/1000)
            if min > 0  then
                if min<10 then
                    min = "0"..min
                end
                FGUI:GTextField_setText(self._ui.dsjText, "00:"..min)
            else
                self:timeOutEnd()
                SL:UnSchedule(self.dsq)
                FGUI:GTextField_setText(self._ui.dsjText, "00:00")
            end
        end
     self.dsq = SL:Schedule(invitationjs,1)
end

function Invitation:initEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.close))
	FGUI:setOnClickEvent(self._ui.btn_red, handler(self, self.onClickRedBtn))
	FGUI:setOnClickEvent(self._ui.btn_yaoqing, handler(self, self.yaoqing))
    FGUI:setOnClickEvent(self._ui.btn_agree,handler(self,self.onClickBtnAgree))
    FGUI:setOnClickEvent(self._ui.btn_chuzhan,handler(self,self.onClickBtnCZ))
    -- FGUI:setOnClickEvent(self._ui.Mask,handler(self,self.close))
end
function Invitation:RenderWaingList(idx,item)
    local data = self.waitingListData[idx+1]
    local color = "#FFFADC"
    -- for w=1,#self.agreeList do
    --     if tonumber(data.UserID) == tonumber(self.agreeList[w].UserID) then
    --         color = "#FFFF00"
    --     end
    -- end
    if data.isAgreeStatus == 1 then
        color = '#FFFF00'
    end
    if data.isAgreeStatus == 2 then
        color = '#ff0000'
    end
	local vatar = FGUI:GetChild(item, "avator")
	local text_name = FGUI:GetChild(item, "text_name")
    local userName = data.UserName
    if tonumber(data.UserID) == tonumber(self.myUserId) then
        userName = "我"
    end
    FGUI:GTextField_setColor(text_name, color)
	FGUI:GTextField_setText(text_name, userName)
	if icon_job then
		FGUI:GLoader_setUrl(icon_job, FGUIFunction:GetJobUrl(data.Job))
	end
    local AVATOR_DATA = {}
	if vatar then
		if FGUIFunction.ClearCommonPlayerFrame then
			FGUIFunction:ClearCommonPlayerFrame(vatar)
		end
		AVATOR_DATA.AvatarID = data.AvatarID
		AVATOR_DATA.Job = data.Job
		AVATOR_DATA.Sex = data.Sex
		AVATOR_DATA.FrameID = data.PhotoframeID
		FGUIFunction:SetCommonPlayerFrame(vatar, AVATOR_DATA)
	end
end
function Invitation:RenderInvitation(idx,item)
    local data = self.apprenticeList[idx+1]
	local vatar = FGUI:GetChild(item, "avator")
	local text_name = FGUI:GetChild(item, "text_name")
	local text_lv = FGUI:GetChild(item, "text_level")
	local text_st = FGUI:GetChild(item, "text_state")
	local checkBox =  FGUI:GetChild(item, "checkBox")
	FGUI:GTextField_setText(text_name, data.UserName or "--")
	FGUI:GTextField_setText(text_lv, "Lv." .. tostring(data.Level or 1))
	local online = (data.IsOnline ~= nil) and data.IsOnline or data.online
	FGUI:GTextField_setText(text_st, online and "在线" or "离线")
	self.selectUserId[data.UserID] = data
    local isSelect = FGUI:getController(checkBox, "isSelect")
    FGUI:Controller_setSelectedIndex(isSelect, 0)
	if icon_job then
		FGUI:GLoader_setUrl(icon_job, FGUIFunction:GetJobUrl(data.Job))
	end
	if vatar then
		if FGUIFunction.ClearCommonPlayerFrame then
			FGUIFunction:ClearCommonPlayerFrame(vatar)
		end
        local AVATOR_DATA = {}
		AVATOR_DATA.AvatarID = data.AvatarID
		AVATOR_DATA.Job = data.Job
		AVATOR_DATA.Sex = data.Sex
		AVATOR_DATA.FrameID = data.PhotoframeID
		FGUIFunction:SetCommonPlayerFrame(vatar, AVATOR_DATA)
	end
    for _,v in pairs(self.selectUserId) do
        v.isSelect = 0
    end
	FGUI:setOnClickEvent(checkBox, function()
		local nowSelect = FGUI:Controller_getSelectedIndex(isSelect)
        local newData = data
        newData.isSelect = nowSelect == 0 and 1 or 0
		self.selectUserId[data.UserID] =  newData
		FGUI:Controller_setSelectedIndex(isSelect, nowSelect == 0 and 1 or 0)
	end)
end

function Invitation:close(idx,item)
    FGUI:Close("MentorShip", "Invitation")
    if self.dsq then
        SL:UnSchedule(self.dsq)
    end
    ssrMessage:sendmsgEx("MentorShip", "notAgreeJoin",self.waitingListData)
end
function Invitation:cloaseInvitation()
    FGUI:Close("MentorShip", "Invitation")
    if self.dsq then
        SL:UnSchedule(self.dsq)
    end
end
function Invitation:yaoqing()
    local doneList = SL:JsonDecode(SL:GetValue("T", 96))
    local doneAppr = {}
    if doneList == 0 then
    else
        --今日师徒副本进入情况
        doneAppr = doneList[tonumber(self.task.task_target_param)]
    end
    self.waitingListData = {}
    local isDone = false
    for userid,v in pairs(self.selectUserId) do
        if v.isSelect == 1 then
            for e=1,#doneAppr do 
                if tonumber(doneAppr[e]) == tonumber(userid) then
                    isDone = true
                end
            end
            --0 默认 1 同意 2不同意
            v.isAgreeStatus = 0 
            table.insert(self.waitingListData,v)
        end
    end
    if #self.waitingListData == 0 then
        SL:ShowSystemTips("至少邀请一名徒弟")
    else
        local isAllOnline = true
        for w=1,#self.waitingListData do
            if self.waitingListData[w].IsOnline then
            else
                isAllOnline = false
            end
        end
        if isAllOnline then
            self.waitingListData[#self.waitingListData + 1] = self.initiator
            local postData = {
                task=self.task,
                initiator = self.initiator,
                dataList = self.waitingListData
            }
            self.super.Close(self)
            ssrMessage:sendmsgEx("MentorShip", "toInvitation",postData)
        else
            SL:ShowSystemTips("请选择在线的玩家")
        end
    end
end

return Invitation