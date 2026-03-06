local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local GuildMainPanel = class("GuildMainPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local StoreData = require("game_config/Store")
local StoreGroup = require("game_config/StoreGroup")
local SysConstant  =  require("game_config/cfgcsv/SysConstant")
local guild_level_data  =  require("game_config/cfgcsv/guild_level_data")  -- 行会等级数据
local color_green = "#19D71E"
local color_white = "#DBDFE3"
local color_grey = "#8E8E8E"

local GuildMainPanelData = require("FGUILayout/Guild/GuildMainPanelData")

local rank_color = 
{
	"#EF5F54",
	"#EF5F54",
	"#F967AF",
	"#377BA6",
	"#DBDFE3"
}
local isPC = SL:GetValue("IS_PC_OPER_MODE")

local img_flag_red_url = isPC and "ui://0xwve836gl563k" or "ui://tsu6gfnoyj7kvnr"
local img_flag_blue_url = isPC and "ui://0xwve836gl563l" or "ui://tsu6gfnoyj7kvns"
local img_flag_def_big_url = isPC and "ui://0xwve836gl5638" or "ui://tsu6gfnozah9m"
local img_flag_red_big_url = isPC and "ui://0xwve836gl563m" or "ui://tsu6gfnovds7vnt"
local img_flag_blue_big_url = isPC and "ui://0xwve836gl563n" or "ui://tsu6gfnovds7vnu"

function GuildMainPanel:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self._membersData = nil
	self._guildListData = nil
	self.handler_onClickPageSwitchEvent = handler(self, self.OnClickPageSwitchItemEvent)
	self.handler_showMemberPopup = handler(self, self.ShowMemberPopup)
	self.handler_onMemberListRenderer = handler(self, self.OnMemberItemRenderer)
	self.handler_onEventListRenderer = handler(self, self.OnEventItemRenderer)
	self.handler_onGuildListRenderer = handler(self, self.OnGuildListRenderer)
	self._oldNotice = nil --行会公告编辑之前内容
	-- 成员操作弹出框
	self._cur_targetId = nil
	
	-- 关闭
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))

	--退出行会
	FGUI:setOnClickEvent(self._ui.btn_quit_guild, handler(self, self.QuitGuild))

	-- 打开申请列表
	FGUI:setOnClickEvent(self._ui.btn_apply_list, handler(self, self.OpenApplyList))

	-- 公告内容
	local str = SL:GetValue("GUILD_NOTICE") or ""
    if string.len(str) < 1 then
        str = SL:GetValue("GAME_DATA", "announce") or ""
    end

    str = string.gsub(str, "\\n", "\n")
	FGUI:GTextField_setText(self._ui("notice_scroll", "text_notice"), str)
  
	-- 编辑公告
	FGUI:setOnClickEvent(self._ui.btn_edit, handler(self, self.OnClickEditNoticeEvent))
	FGUI:setOnClickEvent(self._ui.check_owner, handler(self, self.OnChangeGuildListMode))
	FGUI:setOnClickEvent(self._ui.notice_edit_yes, handler(self, self.ConfirmNoticeEdit))
	FGUI:setOnClickEvent(self._ui.notice_edit_no, handler(self, self.CancelNoticeEdit))

	FGUI:setOnClickEvent(self._ui.btn_donate_1, function ()
		self:OnClickDonationButton(1)
	end)

	FGUI:setOnClickEvent(self._ui.btn_donate_2, function ()
		self:OnClickDonationButton(2)
	end)
	
	FGUI:setOnClickEvent(self._ui.btn_permission, function ()
		FGUI:Open("Guild", "GuildPermissionSetting")
	end)

	FGUI:GList_setVirtual(self._ui.list_member)
	FGUI:GList_setVirtual(self._ui.list_event)
	FGUI:GList_itemRenderer(self._ui.list_member, self.handler_onMemberListRenderer)
	FGUI:GList_itemRenderer(self._ui.list_event, self.handler_onEventListRenderer)
	FGUI:GList_itemRenderer(self._ui.list_guild, self.handler_onGuildListRenderer)
	FGUI:GList_addOnClickItemEvent(self._ui.list_page_switch, self.handler_onClickPageSwitchEvent)
	FGUI:GList_addOnClickItemEvent(self._ui.list_menu, handler(self, self.OnClickTopToggle))
	self:UpdateNoticeEditState(false)

	-- 订阅数据层事件
    self._subscriptions = {}
    self._subscriptions.data_UpdataPage1 = GuildMainPanelData:Subscribe("data_UpdataPage1", handler(self, self.UpdataPage1))
    self._subscriptions.data_UpdataPage2 = GuildMainPanelData:Subscribe("data_UpdataPage2", handler(self, self.UpdataPage2)) 

end

function GuildMainPanel:Enter(page)
	self.Donate_num =  SL:GetValue("U", 78) or 0       						    -- 门派每日已捐献次数
	self.ALLDonate = tonumber(SysConstant['DailyNum_SectDonate']["Value"]) or 0 -- 每日最多捐献次数
    self:RegisterEvent()
	local index = page - 1
	self:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page_switch, index)
	self:OnRefreshMainInfo()
	SL:ComponentAttach(SLDefine.SUIComponentTable.GuildMain, self._ui.Node_attach)
end

function GuildMainPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.GuildMain)
	
	self:RemoveEvent()
end

function GuildMainPanel:Destroy()
    -- 取消订阅
    if self._subscriptions then
        for _, token in pairs(self._subscriptions) do
            GuildMainPanelData:Unsubscribe(token)
        end
        self._subscriptions = nil
    end
end

function GuildMainPanel:Close()
	self.super.Close(self)
end

function GuildMainPanel:OnClickPageSwitchItemEvent()
	local selectIdx = FGUI:GList_getSelectedIndex(self._ui.list_page_switch)
	self:SelectPage(selectIdx)
end

function GuildMainPanel:SelectPage(pageIdx)
	if pageIdx == 0 then
		SL:RequestGuildInfo()
	elseif pageIdx == 1 then
		self:OnClickTopToggle()
	elseif pageIdx == 2 then
		self:OnChangeGuildListMode()
	elseif pageIdx == 3 then
		--显示商场了
		self:SetGuildShop()
	end
end

function GuildMainPanel:SetGuildShop()
	local myMoney = SL:GetValue("MONEY",20)
	FGUI:GTextField_setText(self._ui.money_text,myMoney)
	local itemDataList = {}
	for i = 1,#StoreData do
		local item = StoreData[i]
		if tonumber(item.BtLeafType) == 61 then
			table.insert(itemDataList,item)
		end
	end
	local itemDataMoney = SL:GetValue("ITEM_DATA", 20) 
	local extDataMoney = {}
	extDataMoney.hideTip = false --是否隐藏默认的Tip
	extDataMoney.itemTipData = itemDataMoney --table类型，对应ItemTips.ShowTip传入的参数
	extDataMoney.clickCallback = false --单击事件回调
	extDataMoney.doubleClickCallback = false --双击事件回调
	extDataMoney.bgVisible = false --背景隐藏
	ItemUtil:ItemShow_Create(itemDataMoney,self._ui.moneyIcon,extDataMoney)
	local selectData = {}
	FGUI:GList_itemRenderer(self._ui.showItemList, function(idx,item)
		local data = itemDataList[idx+1]
		local icon = FGUI:GetChild(item,"icon")
		local title = FGUI:GetChild(item,"title")
		local text_money = FGUI:GetChild(item,"text_money")
		local itemData = SL:GetValue("ITEM_DATA", tonumber(data.Itemid)) 
		local icon_money = FGUI:GetChild(item,"icon_money")
		local extData = {}
		extData.hideTip = false --是否隐藏默认的Tip
		extData.itemTipData = itemData --table类型，对应ItemTips.ShowTip传入的参数
		extData.clickCallback = false --单击事件回调
		extData.doubleClickCallback = false --双击事件回调
		extData.bgVisible = true --背景隐藏
		ItemUtil:ItemShow_Create(itemData,icon,extData)
		ItemUtil:ItemShow_Create(itemDataMoney,icon_money,extDataMoney)
		FGUI:GTextField_setText(title,data.Desc)
		FGUI:GTextField_setText(text_money,data.Nowprice)
		if tonumber(myMoney) >= tonumber(data.Nowprice) then
			FGUI:GTextField_setColor(text_money,"#ffffff")
		else
			FGUI:GTextField_setColor(text_money,"#ff0000")
		end
		local clickBtn = FGUI:GetChild(item,'click_node')
		FGUI:setOnClickEvent(clickBtn,function()
			selectData = data
			if tonumber(myMoney) >= tonumber(data.Nowprice) then
			else
				SL:ShowSystemTips("您的公会贡献不足")
				return 
			end
			FGUI:setVisible(self._ui.dialogToBuy,true)
			local buyCount = 1
			local max = 999
			local btn_red = FGUI:GetChild(self._ui.dialogToBuy,"btn_red") 
			local btn_green = FGUI:GetChild(self._ui.dialogToBuy,"btn_green") 
			local btn_minus = FGUI:GetChild(self._ui.dialogToBuy,"btn_minus") 
			local btn_add = FGUI:GetChild(self._ui.dialogToBuy,"btn_add") 
			local btn_max = FGUI:GetChild(self._ui.dialogToBuy,"btn_max") 
			local text_name = FGUI:GetChild(self._ui.dialogToBuy,"text_name") 
			local iconNode = FGUI:GetChild(self._ui.dialogToBuy,"iconNode") 
			local numInput = FGUI:GetChild(self._ui.dialogToBuy,"input_count") 
			local text_title = FGUI:GetChild(self._ui.dialogToBuy,"text_title") 
			FGUI:GTextField_setText(text_name,selectData.Desc)
			FGUI:GTextField_setText(text_title,"购买")
			self:setInput(numInput,buyCount)
			local iconData = SL:GetValue("ITEM_DATA", tonumber(selectData.Itemid)) 
			local iconExtData = {}
			iconExtData.hideTip = false --是否隐藏默认的Tip
			iconExtData.itemTipData = iconData --table类型，对应ItemTips.ShowTip传入的参数
			iconExtData.clickCallback = false --单击事件回调
			iconExtData.doubleClickCallback = false --双击事件回调
			iconExtData.bgVisible = true --背景隐藏
			ItemUtil:ItemShow_Create(iconData,iconNode,iconExtData)
			FGUI:setOnClickEvent(btn_minus, function ()
				buyCount = buyCount - 1 
				if buyCount < 1 then
					buyCount = 1
				end
				self:setInput(numInput,buyCount)
			end)
			FGUI:setOnClickEvent(btn_add, function ()
				buyCount = buyCount + 1 
				if buyCount > 999 then
					buyCount = 999
				end
				self:setInput(numInput,buyCount)
			end)
			FGUI:setOnClickEvent(btn_max, function ()
				buyCount = 999
				self:setInput(numInput,buyCount)
			end)
			FGUI:setOnClickEvent(btn_red, function ()
				FGUI:setVisible(self._ui.dialogToBuy,false)
			end)
			FGUI:setOnClickEvent(btn_green, function ()
				local count = FGUI:GTextInput_getText(numInput)
				ssrMessage:sendmsgEx("Guild", "buy",{count = count,price=data.Nowprice,Itemid = data.Itemid})
				FGUI:setVisible(self._ui.dialogToBuy,false)
			end)
			
        end)
	end)
	FGUI:GList_setNumItems(self._ui.showItemList, #itemDataList)
end

function GuildMainPanel:setInput(input,num)
	FGUI:GTextInput_setText(input,""..num)
end

-- 点击上边页签（成员、事件）
function GuildMainPanel:OnClickTopToggle()
	local selectIdx = FGUI:GList_getSelectedIndex(self._ui.list_menu)
	if selectIdx == 0 then
		FGUI:GList_setNumItems(self._ui.list_member, 0)
		-- 成员
		SL:RequestGuildMemberList()
	elseif selectIdx == 1 then
		-- 事件
		SL:RequestQueryGuildEventList()
	end
end
-----------------------------------主界面---------------------------------
--begin
-- 刷新主界面信息
function GuildMainPanel:OnRefreshMainInfo()
	
    if not SL:GetValue("GUILD_IS_JOINED") then
        return
    end

	local url = self:GetFlagUrlByEvild(SL:GetValue("GUILD_GODDEVILD"), true)
	FGUI:GLoader_setUrl(self._ui.icon_flag, url)

	-- 行会名
    FGUI:GTextField_setText(self._ui.text_guild_name, FGUIFunction:GetServerName(SL:GetValue("GUILD_NAME")))

    -- 会长名
    FGUI:GTextField_setText(self._ui.text_owner_name, FGUIFunction:GetServerName(SL:GetValue("GUILD_MASTER_NAME")))

	-- 等级
	local level = string.format(GET_STRING(1072), SL:GetValue("GUILD_LEVEL")) 
	FGUI:GTextField_setText(self._ui.text_guild_level, level)
	
	-- 我的贡献
	FGUI:GTextField_setText(self._ui.text_my_contribution, SL:GetValue("GUILD_EXP"))

	-- 行会资金
	local gold = SL:GetValue("GUILD_EXP_NUM")
	FGUI:GProgressBar_setValue(self._ui.progress_gdp, gold)
	local level = SL:GetValue("GUILD_LEVEL") or 1
	if level < 1 then
		level = 1
	end
	FGUI:GProgressBar_setMax(self._ui.progress_gdp, guild_level_data[level]['Exp'] or 100)

	-- 公告内容
    local str = SL:GetValue("GUILD_NOTICE") or ""
    if string.len(str) < 1 then
        str = SL:GetValue("GAME_DATA", "announce") or ""
    end	

    str = string.gsub(str, "\\n", "\n")
	FGUI:GTextField_setText(self._ui("notice_scroll", "text_notice"), str)
	-- 获取编辑公告权限
	local canEditorGuild = SL:GetValue("GUILD_CHECK_PERMISSION_SET_NOTICE")
	FGUI:setVisible(self._ui.btn_edit, canEditorGuild)

	local isChairman = SL:GetValue("GUILD_IS_CHAIRMAN")
	FGUI:setVisible(self._ui.btn_permission, isChairman)

	
	-- 更新捐献次数
	FGUI:GTextField_setText(self._ui.danateNum, "剩余捐献次数："..self.ALLDonate-self.Donate_num)
end

function GuildMainPanel:OnClickEditNoticeEvent()
	self:UpdateNoticeEditState(true)
	self._oldNotice = FGUI:GTextField_getText(self._ui("notice_scroll", "text_notice"))
end

-- 确认行会公告修改
function GuildMainPanel:ConfirmNoticeEdit()
	if not SL:GetValue("GUILD_CHECK_PERMISSION_SET_NOTICE") then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003032))
		return
	end

	local input = FGUI:GTextField_getText(self._ui("notice_scroll", "text_notice"))
	SL:RequestGuildEditNotice(input)
	self:UpdateNoticeEditState(false)
end

-- 取消行会公告修改
function GuildMainPanel:CancelNoticeEdit()
	self:UpdateNoticeEditState(false)
	FGUI:GTextField_setText(self._ui("notice_scroll", "text_notice"), self._oldNotice)
end

function GuildMainPanel:UpdateNoticeEditState(canEdit)
	FGUI:setVisible(self._ui.effect_edit, canEdit)
	FGUI:setVisible(self._ui.notice_edit_yes, canEdit)
	FGUI:setVisible(self._ui.notice_edit_no, canEdit)
	FGUI:setVisible(self._ui.btn_edit, not canEdit)
	FGUI:setTouchEnabled(self._ui("notice_scroll", "text_notice"), canEdit)
end

-- 公告编辑失败(敏感词)
function GuildMainPanel:OnEditNoticeFail()
	-- 公告内容
    local str = SL:GetValue("GUILD_NOTICE") or ""	
    str = string.gsub(str, "\\n", "\n")
	FGUI:GTextField_setText(self._ui("notice_scroll", "text_notice"), str)
end

-- 捐赠
function GuildMainPanel:OnClickDonationButton(type)
	local callBack = function(tag)
        if tag == 1 then        --- 确定
            SL:RequestDonation(type)
        end
    end
    local data = {}
    data.title = "捐献提醒"
    data.btnDesc = { "确认捐献" ,"我在想想"  }
    data.callback = callBack
    local hbid,addzj = 0,0
	if type == 1 then  --SysConstant
		hbid = SysConstant['SectDonate_Currency_Num1']["Value"][1]
		local hbname = SL:GetValue("ITEM_NAME", hbid)
		addzj = SysConstant['SectDonate_Currency_Num1']["Value"][3]
		data.str = "确定捐献"..SysConstant['SectDonate_Currency_Num1']["Value"][2]..""..hbname.."至门派资金吗？\n\n"
		data.str = data.str .. "贡献/积分+"..addzj.."     " .. "门派资金+"..addzj
	elseif type == 2 then
		hbid = SysConstant['SectDonate_Currency_Num2']["Value"][1]
		local hbname = SL:GetValue("ITEM_NAME", hbid)
		addzj = SysConstant['SectDonate_Currency_Num2']["Value"][3]
		data.str = "确定捐献"..SysConstant['SectDonate_Currency_Num2']["Value"][2]..""..hbname.."至门派资金吗？\n\n"
		data.str = data.str .. "贡献/积分+"..addzj.."     " .. "门派资金+"..addzj
	end
	SL:OpenCommonDialog(data)
end

--end
-----------------------------------主界面---------------------------------


-----------------------------------成员界面----------------------------------
--begin
-- 退出行会
function GuildMainPanel:QuitGuild()
	if SL:GetValue("GUILD_IS_CHAIRMAN") then
		if SL:GetValue("GAME_DATA", "guild_Close") == 1 then
			local data = 
			{
				str = SL:GetValue("I18N_STRING", 10003039),
				btnDesc = {SL:GetValue("I18N_STRING", 1002), SL:GetValue("I18N_STRING", 1000)}, 
				callback = function(tag)
					if tag == 1 then
						SL:RequestGuildDissolve()
					end
				end
			}
			SL:OpenCommonDialog(data)
		else
			SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003015))
		end
	else
		local data = 
		{
			str = SL:GetValue("I18N_STRING", 10003016),
			btnDesc = {SL:GetValue("I18N_STRING", 1002), SL:GetValue("I18N_STRING", 1000)}, 
			callback = function(tag)
				if tag == 1 then
					SL:RequestGuildLeave()
				end
			end
		}
		SL:OpenCommonDialog(data)
	end
end

function GuildMainPanel:OnMemberItemRenderer(idx, item)
	if not self._membersData then return end
	local data = self._membersData[idx + 1]
	if not data then 
		FGUI:setVisible(item, false)
		return
	end

	local userid = SL:GetValue("USER_ID")
	local color = color_grey
	if data.Line == 1 then
		color = tostring(userid) == data.UserID and color_green or color_white
	end

	-- 名字
	local text_name = FGUI:GetChild(item, "text_name")
	FGUI:GTextField_setText(text_name, FGUIFunction:GetServerName(data.UserName))
	FGUI:GTextField_setColor(text_name, color)
	-- 等级
	local text_level = FGUI:GetChild(item, "text_level")
	FGUI:GTextField_setText(text_level, string.format("%s"..SL:GetValue("I18N_STRING", 3), data.Level or 0))
	FGUI:GTextField_setColor(text_level, color)
	-- 职务
	local text_rank = FGUI:GetChild(item, "text_duty")
	local rankColor = data.Line == 1 and rank_color[data.Rank + 1] or color_grey
    FGUI:GTextField_setText(text_rank, SL:GetValue("GUILD_OFFICIAL_NAME_BY_RANK", data.Rank))
	FGUI:GTextField_setColor(text_rank, rankColor)

	-- 贡献值
	local text_contribution = FGUI:GetChild(item, "text_contribution")
	FGUI:GTextField_setText(text_contribution, data.MemExp or 0)
	
	-- 在线状态
	local ui_online = FGUI:GetChild(item, "text_online_state")
	FGUI:GTextField_setColor(ui_online, data.Line == 1 and color_green or color_grey)
    if data.Line == 1 then
		FGUI:GTextField_setText(ui_online, SL:GetValue("I18N_STRING", 2007))
    else
        FGUI:GTextField_setText(ui_online, SL:GetValue("I18N_STRING", 2008))
        if tonumber(data.LastTime) then     -- 离线天数
            local time = SL:SecondToDHMS(SL:GetValue("SERVER_TIME") - tonumber(data.LastTime))
            if time.d > 0 then
                FGUI:GTextField_setText(ui_online, SL:GetValue("I18N_STRING", 2008) .. time.d .. SL:GetValue("I18N_STRING", 2009))
            else
                FGUI:GTextField_setText(ui_online, SL:GetValue("I18N_STRING", 2008) .. time.h .. SL:GetValue("I18N_STRING", 2010))
            end
        end
    end

	FGUI:setOnClickEvent(item, self.handler_showMemberPopup)
	FGUI:SetIntData(item, idx)
end

-- 打开申请列表
function GuildMainPanel:OpenApplyList()
	FGUI:Open("Guild", "GuildApplyList")
end

-- 刷新事件列表
function GuildMainPanel:RefreshEventList(listData)
	self._eventsData = listData
	if not self._eventsData then
		FGUI:GList_setNumItems(self._ui.list_event, 0)
		return
	end
	self._eventsCount = #self._eventsData
	FGUI:GList_setNumItems(self._ui.list_event, self._eventsCount)
end

function GuildMainPanel:OnEventItemRenderer(idx, item)
	if not self._eventsData then return end
	-- 倒叙显示，时间大的在前
	local data = self._eventsData[idx + 1]
	if not data then 
		return
	end
	local configStr = SL:GetValue("EVENT_LIST_CONFIG_STRING", data.id)
	local time = os.date("%Y-%m-%d %H:%M:%S", data.time)
	local errorStr = nil
	if not configStr then 
		SL:release_print("EVENT_LIST_CONFIG_STRING is nil, id:".. data.id)
		errorStr = "Error EventLog ID:" .. data.id
	end

	-- 计算%s数量
	local count = 0
	for _ in string.gmatch(configStr, "%%s") do
		count = count + 1
	end

	if count > #data.params then
		SL:release_print("EVENT_LIST_CONFIG_STRING params number error, id:".. data.id)
		errorStr = "Error:" .. configStr
	end

	
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_time"), time)
	local str = errorStr or string.format(configStr, table.unpack(data.params,1,count))
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_event"), str)
end

-- 刷新成员信息
function GuildMainPanel:RefreshMemberList()
	self._membersData = SL:GetValue("GUILD_MEMBER_SORT_LIST")
	if not self._membersData then
		FGUI:GList_setNumItems(self._ui.list_member, 0)
		return
	end
	FGUI:GList_setNumItems(self._ui.list_member, #self._membersData)
	-- 刷新成员数量
	local numStr = string.format("%s/%s", SL:GetValue("GUILD_MEMBER_ONLINE_COUNT"), SL:GetValue("GUILD_MEMBER_COUNT"))
	FGUI:GTextField_setText(self._ui.text_online_member, numStr)

	if SL:GetValue("GUILD_IS_CHAIRMAN") then
		FGUI:GButton_setTitle(self._ui.btn_quit_guild, GET_STRING(10003041))
	else
		FGUI:GButton_setTitle(self._ui.btn_quit_guild, GET_STRING(10003040))
	end

	if SL:GetValue("GUILD_CHECK_PERMISSION_APPROVE_APPLY") then
		FGUI:setVisible(self._ui.btn_apply_list, true)
	else
		FGUI:setVisible(self._ui.btn_apply_list, false)
	end
end

-- 显示成员操作弹出框
function GuildMainPanel:ShowMemberPopup(context)
	if self._membersData == nil then return end
	local item = context.sender
	local idx = FGUI:GetIntData(item)
	local data = self._membersData[idx + 1]
	if data == nil then return end
	local userID = SL:GetValue("USER_ID")
	local targetUserID = tonumber(data.UserID)
	if userID == targetUserID then
		return
	end
	self._cur_targetId = targetUserID
	local dockData = {
		AvatarID = SL:GetValue("ACTOR_AVATAR", self._cur_targetId),
		Job = data.Job,
		Sex = data.Sex,
		targetName = data.UserName,
		Level = data.Level,
		GuildName = SL:GetValue("GUILD_NAME"),
		targetId = self._cur_targetId,
		TipsType = SL:GetValue("DOCKTYPE_NENUM").Func_Guild,
		FrameID = data.PhotoframeID
	}
	FGUIFunction:OpenFuncDockTips(dockData)
end
--end
-----------------------------------成员界面----------------------------------


-----------------------------------列表界面----------------------------------
--begin
function GuildMainPanel:OnRefreshGuildList(listData)
	if not listData then return end
	-- 按等级从高到低排序
	listData = HashToSortArray(listData, function (a, b)
		-- 等级排序
		if a.Level ~= b.Level then
			return a.Level > b.Level
		end

		-- 人数排序
		if a.Member ~= b.Member then
			return a.Member > b.Member
		end

		-- 经验排序
		return a.Exp > b.Exp
	end)
	self._guildListData = listData
	FGUI:GList_setNumItems(self._ui.list_guild, #self._guildListData)
end

function GuildMainPanel:OnGuildListRenderer(idx, item)
	if not self._guildListData then return end
	local data = self._guildListData[idx + 1]
	if not data then 
		FGUI:setVisible(item, false)
		return
	end

	local icon_guild = FGUI:GetChild(item, "icon_guild")
	local text_guild_name = FGUI:GetChild(item, "text_name")
	local text_level = FGUI:GetChild(item, "text_level")
	local text_member = FGUI:GetChild(item, "text_count")
	local text_owner = FGUI:GetChild(item, "text_owner")
	local text_need_level = FGUI:GetChild(item, "text_need_level")
	FGUI:GTextField_setText(text_guild_name, FGUIFunction:GetServerName(data.GuildName))
	FGUI:GTextField_setText(text_level, string.format("%s%s",data.Level, GET_STRING(3)))
	FGUI:GTextField_setText(text_member, string.format("%s/%s", data.Member, data.MemberMax))
	FGUI:GTextField_setText(text_owner, FGUIFunction:GetServerName(data.MasterName))
	FGUI:GTextField_setText(text_need_level, string.format("%s%s",data.JoinLevel, GET_STRING(3)))
	local url = self:GetFlagUrlByEvild(data.GuildGoodEvild, false)
	FGUI:GLoader_setUrl(icon_guild, url)
end

function GuildMainPanel:GetFlagUrlByEvild(evild, isBig)
	if isBig then
		if evild == SLDefine.CAMP_TYPE.EVIL then
			return img_flag_red_big_url
		elseif evild == SLDefine.CAMP_TYPE.GOOD then
			return img_flag_blue_big_url
		else
			return img_flag_def_big_url
		end
	else
		if evild == SLDefine.CAMP_TYPE.EVIL then
			return img_flag_red_url
		elseif evild == SLDefine.CAMP_TYPE.GOOD then
			return img_flag_blue_url
		end
	end

	return ""
end

function GuildMainPanel:OnChangeGuildListMode()
	local isSelected = FGUI:GButton_getSelected(self._ui.check_owner)
	local _type = isSelected and 1 or 0
	SL:RequestGuildList(_type, true)
end

--end
-----------------------------------列表界面----------------------------------



function GuildMainPanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_MAIN_INFO, "GuildMainPanel", handler(self, self.OnRefreshMainInfo))
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_NOTICE_UPDATE, "GuildMainPanel", handler(self, self.OnRefreshMainInfo))
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_MEMBER_LIST, "GuildMainPanel", handler(self, self.RefreshMemberList))
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_EDITOR_NOTICE_FAIL, "GuildMainPanel", handler(self, self.OnEditNoticeFail))
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_LIST, "GuildMainPanel", handler(self, self.OnRefreshGuildList))
	SL:RequestGameActionLogAddListener(1, LUA_EVENT_GUILD_EVENT_LIST, "GuildMainPanel", handler(self, self.RefreshEventList))
end

function GuildMainPanel:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_MAIN_INFO, "GuildMainPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_NOTICE_UPDATE, "GuildMainPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_MEMBER_LIST, "GuildMainPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_EDITOR_NOTICE_FAIL, "GuildMainPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_LIST, "GuildMainPanel")
	SL:RequestGameActionLogRemoveListener(1, LUA_EVENT_GUILD_EVENT_LIST, "GuildMainPanel")
end

function GuildMainPanel:UpdataPage1(data)
    self.Donate_num = tonumber(data.param1) or 0
    self:OnRefreshMainInfo()  
end
function GuildMainPanel:UpdataPage2(data)
    self:SetGuildShop()   
end

return GuildMainPanel