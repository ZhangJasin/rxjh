local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCGuildMainPanel = class("PCGuildMainPanel", BaseFGUILayout)

local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local Task_cfg = require("game_config/cfgcsv/Task")
local Language = require("game_config/cfgcsv/Language")
local TaskStar_cfg = require("game_config/cfgcsv/guildTaskStar")
local Act_Cfg = require("game_config/cfgcsv/guildAct")
local SysConstant = require("game_config/cfgcsv/SysConstant")

local color_green = "#19D71E"
local color_white = "#DBDFE3"
local color_grey = "#8E8E8E"

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
local img_flag_red_big_url = isPC and "ui://0xwve836s4oo3z" or "ui://tsu6gfnovds7vnt"
local img_flag_blue_big_url = isPC and "ui://0xwve836s4oo40" or "ui://tsu6gfnovds7vnu"

function PCGuildMainPanel:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	self._membersData = nil
	self._guildListData = nil
	self.handler_onClickPageSwitchEvent = handler(self, self.OnClickPageSwitchItemEvent)
	self.handler_showMemberPopup = handler(self, self.ShowMemberPopup)
	self.handler_onMemberListRenderer = handler(self, self.OnMemberItemRenderer)
	self.handler_onGuildListRenderer = handler(self, self.OnGuildListRenderer)
	
	self.handler_onActListRenderer = handler(self, self.OnActListRenderer)
	self.handler_onTaskAwardListRenderer = handler(self, self.OnTaskAwardListRenderer)
	self.handler_onTaskStarListRenderer = handler(self, self.OnTaskStarListRenderer)
	self.handler_listadditemRender = handler(self, self.ListadditemRender)

	
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
	FGUI:setOnClickEvent(self._ui.btn_event, handler(self, self.OpenGuildEventPanel))

	FGUI:setOnClickEvent(self._ui.btn_donate_1, function (eventData)
    	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
		self:OnClickDonationButton(1)
	end)

	FGUI:setOnClickEvent(self._ui.btn_donate_2, function (eventData)
    	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
		self:OnClickDonationButton(2)
	end)
	
	FGUI:setOnClickEvent(self._ui.btn_permission, function ()
		FGUI:Open("Guild_pc", "PCGuildPermissionSetting")
	end)

	
	FGUI:setOnClickEvent(self._ui.btn_refresh, function (eventData)
    	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
        self:OnBtnRefreshClicked()
	end)
	FGUI:setOnClickEvent(self._ui.btn_comp, function (eventData)
    	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
        self:OnBtnCompClicked()
	end)
	FGUI:setOnClickEvent(self._ui.btn_sub, function (eventData)
    	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
		self:OnBtnSubClicked()
	end)
	self.tipsControlle = FGUI:getController(self.component, "tips")
	self.tipsbg = FGUI:ui_delegate(self._ui.panl_tip)
     -- 点击tips
    FGUI:setOnClickEvent(self._ui.btn_tips, handler(self, self.btnTipsClicked))
    FGUI:setOnClickEvent(self.tipsbg.close_tip, handler(self, self.btnTipsClicked))

	self.additemControlle = FGUI:getController(self.component, "addItem")
	self.panl_additem = FGUI:ui_delegate(self._ui.panl_additem)
	self.addpanlobj = self.panl_additem['additemlist']
    FGUI:setOnClickEvent(self.panl_additem.bg, function()
        FGUI:Controller_setSelectedIndex(self.additemControlle,0)
    end)

	FGUI:GList_setVirtual(self._ui.list_member)
	FGUI:GList_itemRenderer(self._ui.list_member, self.handler_onMemberListRenderer)
	FGUI:GList_itemRenderer(self._ui.list_guild, self.handler_onGuildListRenderer)
	FGUI:GList_addOnClickItemEvent(self._ui.list_page_switch, self.handler_onClickPageSwitchEvent)
	
	FGUI:GList_itemRenderer(self._ui.actList, self.handler_onActListRenderer)
	FGUI:GList_itemRenderer(self._ui.awardList, self.handler_onTaskAwardListRenderer)
	FGUI:GList_itemRenderer(self._ui.starList, self.handler_onTaskStarListRenderer)
	FGUI:GList_itemRenderer(self.addpanlobj, self.handler_listadditemRender)
	FGUI:GList_addOnClickItemEvent(self.addpanlobj, function(context)
        local itemRoot = FGUI:GetChild(context.data, "itemRoot")
        local index = FGUI:GetIntData(itemRoot)
		local itemData = self._filterItems[index]
        self:OnSelectItemToSubmit(itemData)
    end)

	self:UpdateNoticeEditState(false)
end

function PCGuildMainPanel:Enter(page)
    self:RegisterEvent()
	local index = page - 1
	self:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page_switch, index)
	self:OnRefreshMainInfo()
	SL:ComponentAttach(SLDefine.SUIComponentTable.GuildMain, self._ui.Node_attach)

	FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.GuildGuide,self._ui)
end

function PCGuildMainPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.GuildMain)

	self:RemoveEvent()

	FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.GuildGuide)
end

function PCGuildMainPanel:Close()
	self.super.Close(self)
end

function PCGuildMainPanel:OnClickPageSwitchItemEvent()
	local selectIdx = FGUI:GList_getSelectedIndex(self._ui.list_page_switch)
	self:SelectPage(selectIdx)
end

function PCGuildMainPanel:SelectPage(pageIdx)
	if pageIdx == 0 then
		SL:RequestGuildInfo()
	elseif pageIdx == 1 then
		FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
		FGUI:GList_setNumItems(self._ui.actList, #Act_Cfg)
		ssrMessage:sendmsgEx("Guild", "getData")
	elseif pageIdx == 2 then
		FGUI:GList_setNumItems(self._ui.list_member, 0)
		-- 成员
		SL:RequestGuildMemberList()
	elseif pageIdx == 3 then
		self:OnChangeGuildListMode()
	end
end

-----------------------------------主界面---------------------------------
--begin
-- 刷新主界面信息
function PCGuildMainPanel:OnRefreshMainInfo()
	
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
end

function PCGuildMainPanel:OnClickEditNoticeEvent()
	self:UpdateNoticeEditState(true)
	self._oldNotice = FGUI:GTextField_getText(self._ui("notice_scroll", "text_notice"))
end

-- 确认行会公告修改
function PCGuildMainPanel:ConfirmNoticeEdit()
	if not SL:GetValue("GUILD_CHECK_PERMISSION_SET_NOTICE") then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003032))
		return
	end

	local input = FGUI:GTextField_getText(self._ui("notice_scroll", "text_notice"))
	SL:RequestGuildEditNotice(input)
	self:UpdateNoticeEditState(false)
end

-- 取消行会公告修改
function PCGuildMainPanel:CancelNoticeEdit()
	self:UpdateNoticeEditState(false)
	FGUI:GTextField_setText(self._ui("notice_scroll", "text_notice"), self._oldNotice)
end

function PCGuildMainPanel:UpdateNoticeEditState(canEdit)
	FGUI:setVisible(self._ui.effect_edit, canEdit)
	FGUI:setVisible(self._ui.notice_edit_yes, canEdit)
	FGUI:setVisible(self._ui.notice_edit_no, canEdit)
	FGUI:setVisible(self._ui.btn_edit, not canEdit)
	FGUI:setTouchEnabled(self._ui("notice_scroll", "text_notice"), canEdit)
end

-- 公告编辑失败(敏感词)
function PCGuildMainPanel:OnEditNoticeFail()
	-- 公告内容
    local str = SL:GetValue("GUILD_NOTICE") or ""	
    str = string.gsub(str, "\\n", "\n")
	FGUI:GTextField_setText(self._ui("notice_scroll", "text_notice"), str)
end

-- 捐赠
function PCGuildMainPanel:OnClickDonationButton(type)
	SL:RequestDonation(type)
end

--end
-----------------------------------主界面---------------------------------


-----------------------------------成员界面----------------------------------
--begin
-- 退出行会
function PCGuildMainPanel:QuitGuild()
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

function PCGuildMainPanel:OnMemberItemRenderer(idx, item)
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

-- 打开门派事件
function PCGuildMainPanel:OpenGuildEventPanel()
	FGUI:Open("Guild_pc", "PCGuildEventPanel")
end

-- 打开申请列表
function PCGuildMainPanel:OpenApplyList()
	FGUI:Open("Guild_pc", "PCGuildApplyList")
end

-- 刷新成员信息
function PCGuildMainPanel:RefreshMemberList()
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
function PCGuildMainPanel:ShowMemberPopup(context)
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
function PCGuildMainPanel:OnRefreshGuildList(listData)
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

function PCGuildMainPanel:OnGuildListRenderer(idx, item)
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

function PCGuildMainPanel:GetFlagUrlByEvild(evild, isBig)
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

function PCGuildMainPanel:OnChangeGuildListMode()
	local isSelected = FGUI:GButton_getSelected(self._ui.check_owner)
	local _type = isSelected and 1 or 0
	SL:RequestGuildList(_type, true)
end

--end
-----------------------------------列表界面----------------------------------

------------------------------------贡献界面----------------------------------
--begin

-- 刷新按钮点击处理
function PCGuildMainPanel:OnBtnRefreshClicked()
    if self._taskState == 0 then
        -- 未接取任务，点击刷新任务
        local maxRefreshCount = tonumber(SysConstant['Num_DailyRefresh_RewardTask']["Value"]) or 3
        local curRefreshCount = self._refreshCount or 0
        
        if curRefreshCount >= maxRefreshCount then
            -- 免费次数已用完，弹确认框使用任务刷新卷轴
            SL:OpenCommonDialog({
                title = '提示',
                str = '免费次数已用完，是否使用1个任务刷新卷刷新任务？',
                btnDesc = {"取消", "确定"},
                callback = function(tag)
                    if tag == 2 then
                        -- 确定刷新任务
                        ssrMessage:sendmsgEx("Guild", "refreshTask")
                    end
                end
            })
        else
            -- 有免费次数，直接刷新
            ssrMessage:sendmsgEx("Guild", "refreshTask")
        end
    else
        -- 已接取任务，点击快速完成
        SL:OpenCommonDialog({
            title = '提示',
            str = '是否使用1个悬赏令直接完成当前任务并获得奖励？',
            btnDesc = {"取消", "确定"},
            callback = function(tag)
                if tag == 2 then
                    -- 确定快速完成
					ssrMessage:sendmsgEx("Guild", "compTask", {1})
                end
            end
        })
    end
end

-- 确认按钮点击处理
function PCGuildMainPanel:OnBtnCompClicked()
    if self._taskState == 0 then
        -- 未接取任务，点击接取任务
        ssrMessage:sendmsgEx("Guild", "pickTask")
    else
        -- 已接取任务，点击放弃任务
        SL:OpenCommonDialog({
            title = '提示',
            str = '放弃任务将无法获得奖励，且今日可完成任务数量减1，确定要放弃吗？',
            btnDesc = {"取消", "确定"},
            callback = function(tag)
                if tag == 2 then
                    -- 确定放弃任务
                    ssrMessage:sendmsgEx("Guild", "abortTask")
                end
            end
        })
    end
end
-- 提交道具按钮点击处理
function PCGuildMainPanel:OnBtnSubClicked()
	local curTaskCfg = Task_cfg[self._taskId]
	if not curTaskCfg then
		return
	end
		
	-- 根据任务类型筛选背包物品
	local targetType = curTaskCfg.task_type or 0
	local targetParam = curTaskCfg.task_target_param
	local filterItems = self:FilterBagItemsByTaskType(targetType,targetParam)
	self._filterItems = filterItems
	
	if #filterItems == 0 then
		SL:ShowSystemTips("背包中没有符合条件的物品")
		--FGUI:Controller_setSelectedIndex(self.additemControlle, 0)
		return
	end
	-- 打开选择面板
	FGUI:Controller_setSelectedIndex(self.additemControlle, 1)
	-- 设置列表数据
	FGUI:GList_setNumItems(self.addpanlobj, #filterItems)
end

-- 根据任务类型筛选背包物品
function PCGuildMainPanel:FilterBagItemsByTaskType(targetType, targetParam)
	local result = {}
	
	if targetType ~= 9 and targetType ~= 10 then
		return result
	end
	
	-- 获取背包数据
	local bagData = SL:GetValue("BAG_DATA") or {}
	
	for _, itemData in pairs(bagData) do
		if not itemData or not itemData.Index then
			goto continue
		end
		
		local isMatch = false
		
		if targetType == 9 then
			-- 任务类型9：提交指定物品道具
			isMatch = self:CheckItemMatchTarget9(itemData, targetParam)
		elseif targetType == 10 then
			-- 任务类型10：提交指定等级范围的装备
			isMatch = self:CheckItemMatchTarget10(itemData, targetParam)
		end
		
		if isMatch then
			table.insert(result, itemData)
		end		
		::continue::
	end
	
	return result
end

-- 检查物品是否匹配任务类型9（指定物品）
function PCGuildMainPanel:CheckItemMatchTarget9(itemData, targetParam)
	if not targetParam then
		return false
	end
	
	-- 解析目标物品ID和数量
	local targetItemId = nil
	local targetCount = 1
	
	if type(targetParam) == "string" then
		local params = string.split(targetParam, "^")
		if params and #params >= 1 then
			targetItemId = tonumber(params[1])
			targetCount = tonumber(params[2]) or 1
		end
	elseif type(targetParam) == "table" then
		targetItemId = targetParam[1]
		targetCount = targetParam[2] or 1
	end
	
	if not targetItemId then
		return false
	end
	
	-- 检查物品ID是否匹配
	return itemData.Index == targetItemId
end

-- 检查物品是否匹配任务类型10（指定等级装备）
function PCGuildMainPanel:CheckItemMatchTarget10(itemData, targetParam)
	if not targetParam then
		return false
	end
	
	-- 解析装备筛选条件
	-- 格式: "装备最低等级^装备最高等级^装备品级^装备正邪"
	local stdmode,minLevel, maxLevel, grade, goodEvil = -1,0,0,0,0
	
	if type(targetParam) == "string" then
		local params = string.split(targetParam, "^")
		if params then
			stdmode= tonumber(params[1])
			minLevel = tonumber(params[2])
			maxLevel = tonumber(params[3])
			grade = tonumber(params[4])
			goodEvil = tonumber(params[5])
		end
	elseif type(targetParam) == "table" then
			stdmode= tonumber(params[1])
			minLevel = tonumber(params[2])
			maxLevel = tonumber(params[3])
			grade = tonumber(params[4])
			goodEvil = tonumber(params[5])
	end
	
	-- 获取物品配置信息
	local itemConfig = SL:GetValue("ITEM_DATA", itemData.Index)
	if not itemConfig then
		return false
	end
	
	-- 检查是否是装备
	if not ItemUtil:IsEquip(itemData) then
		return false
	end
	if stdmode > 0 and itemConfig.StdMode ~= stdmode then
		return false
	end
	-- 检查等级范围
	if minLevel and itemConfig.NeedLevel and itemConfig.NeedLevel < minLevel then
		return false
	end
	if maxLevel and itemConfig.NeedLevel and itemConfig.NeedLevel > maxLevel then
		return false
	end
	
	-- 检查品级
	if grade and itemConfig.Grade and itemConfig.Grade ~= grade then
		return false
	end
	
	-- 检查正邪阵营（0表示不限）
	if goodEvil and goodEvil ~= 0 then
		local itemGoodEvil = itemConfig.nCamp or 0
		if itemGoodEvil ~= 0 and itemGoodEvil ~= goodEvil then
			return false
		end
	end
	
	return true
end

-- 渲染可提交物品列表项
function PCGuildMainPanel:ListadditemRender(idx, item)
	-- 清除已有子节点
	local itemRoot = FGUI:GetChild(item, "itemRoot")
	FGUI:SetIntData(itemRoot, idx + 1)
	if FGUI:GetChildCount(itemRoot) > 0 then
		FGUI:RemoveChildAt(itemRoot, 0, true)
	end
	
	local filterItems = self._filterItems
	if not filterItems or not filterItems[idx + 1] then
		return
	end
	
	local itemData = filterItems[idx + 1]
	
	local name = FGUI:GetChild(item, "name")
	FGUI:GTextField_setText(name,SL:GetValue("ITEM_NAME", itemData.Index))
	-- 创建物品显示
	local extData = {
		hideTip = false,
		itemTipData = itemData,
		clickCallback = false,
		doubleClickCallback = true,
		bgVisible = true
	}
	ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
end

-- 选择物品提交
function PCGuildMainPanel:OnSelectItemToSubmit(itemData)
	if not itemData or not itemData.MakeIndex then
		return
	end
	
	-- 发送物品唯一ID给服务器
	ssrMessage:sendmsgEx("Guild", "subTask", {itemData.MakeIndex})
	
	-- 关闭选择面板
	FGUI:Controller_setSelectedIndex(self.additemControlle, 0)
end
function PCGuildMainPanel:btnTipsClicked()
    FGUI:Controller_setSelectedIndex(self.tipsControlle,self.tipsControlle.selectedIndex == 1 and 0 or 1)
end
function PCGuildMainPanel:FilterRewardsByJob(tab)
    if not tab then return {} end
    
    local myJob = SL:GetValue("JOB")
    local mySex = SL:GetValue("SEX")
    local myZy = SL:GetValue("GOODEVILID") or 0
    local filteredRewards = {}
    local index = 0
    
    for _, v in pairs(tab) do
        local needjob,needsex,needzy = v[1],v[4] or 0,v[5] or 0 
        if (needjob == myJob or needjob == 9) and (needsex == mySex or needsex == 0) and (needzy == myZy or needzy == 0) then
            index = index + 1
            filteredRewards[index] = v
        end
    end
    
    return filteredRewards
end

function PCGuildMainPanel:getTaskCon()
	local curTaskCfg = Task_cfg[self._taskId]
	if not curTaskCfg then
		return ""
	end
	local curLangCfg = Language[curTaskCfg.task_targetdec]
	if not curLangCfg then
		return ""
	end
	local jindu = curTaskCfg.task_progress or 1

	return string.format("%s(%s/%s)",curLangCfg.Dec or "",self._curJinDu > jindu and jindu or self._curJinDu,jindu)
end
function PCGuildMainPanel:OnUpdateGXUI()
	-- 检查界面是否存在
	if not self._ui then
		return
	end
	
	-- 获取每日捐献最大次数
	local maxDonateCount = tonumber(SysConstant['DailyNum_SectDonate']["Value"]) or 5
	-- 获取每日任务最大次数
	local maxTaskCount = tonumber(SysConstant['Num_Daily_RewardTask']["Value"]) or 10
	-- 获取每日免费刷新最大次数
	local maxRefreshCount = tonumber(SysConstant['Num_DailyRefresh_RewardTask']["Value"]) or 3
	
	-- 计算剩余次数
	local remainDonateCount = maxDonateCount - (self._gxCount or 0)
	local remainTaskCount = maxTaskCount - (self._taskCount or 0)
	
	-- 刷新捐献次数显示
	if self._ui.gxCount then
		FGUI:GTextField_setText(self._ui.gxCount, string.format("今日剩余捐献次数：%s", remainDonateCount))
	end
	
	-- 刷新任务次数显示
	if self._ui.taskCount then
		FGUI:GTextField_setText(self._ui.taskCount, string.format("今日可完成门派任务次数：%s", remainTaskCount))
	end

	FGUI:GList_setNumItems(self._ui.starList, TaskStar_cfg[self._taskId] and TaskStar_cfg[self._taskId].star or 0)
	
	FGUI:GRichTextField_setText(self._ui.taskCon, self:getTaskCon())

	self._taskAwards = self:FilterRewardsByJob(Task_cfg[self._taskId] and Task_cfg[self._taskId]['task_drop'])
	FGUI:GList_setNumItems(self._ui.awardList, #self._taskAwards)

	if remainTaskCount > 0  then
		-- 刷新免费刷新次数显示
		if self._ui.rCount then
			FGUI:GTextField_setText(self._ui.rCount, string.format("免费刷新次数(%s/%s)", self._refreshCount or 0, maxRefreshCount))
		end
		if self._taskState == 0 then --未接取
			FGUI:GButton_setTitle(self._ui.btn_refresh,"刷新")
			FGUI:GButton_setTitle(self._ui.btn_comp,"接取任务")
			FGUI:setVisible(self._ui.rCount, true)

			FGUI:setVisible(self._ui.btn_sub, false)
		else
			FGUI:GButton_setTitle(self._ui.btn_refresh,"快速完成")
			FGUI:GButton_setTitle(self._ui.btn_comp,"放弃任务")
			FGUI:setVisible(self._ui.rCount, false)

			local targetType = Task_cfg[self._taskId] and Task_cfg[self._taskId]['task_type'] or 0
			FGUI:setVisible(self._ui.btn_sub, targetType == 9 or targetType == 10)
		end

		
		
		FGUI:setVisible(self._ui.btn_refresh, true)
		FGUI:setTouchEnabled(self._ui.btn_comp, true)
	else
		FGUI:setVisible(self._ui.btn_sub, false)
		FGUI:setVisible(self._ui.btn_refresh, false)
		FGUI:setVisible(self._ui.rCount, false)
		FGUI:GButton_setTitle(self._ui.btn_comp,"已完成")
		FGUI:setTouchEnabled(self._ui.btn_comp, false)
	end
end
function PCGuildMainPanel:OnActListRenderer(idx, item)
	-- 根据配表索引获取配置
	local actData = Act_Cfg[idx + 1] -- idx从0开始，配表从1开始
	if not actData then
		return
	end
	
	-- 获取UI控件
	local con = FGUI:GetChild(item, "con")
	local img = FGUI:GetChild(item, "img")
	
	-- 设置描述文字
	if con then
		FGUI:GTextField_setText(con, actData.desc)
	end
	
	-- 设置图片
	if img then
		local imgUrl = string.format("ui://Guild_pc/%s", actData.img)
		FGUI:GLoader_setUrl(img, imgUrl)
	end
end
function PCGuildMainPanel:OnTaskAwardListRenderer(idx, item)
	if FGUI:GetChildCount(item) > 0 then
        FGUI:RemoveChildAt(item, 0, true)
    end

    if self._taskAwards then
        local reward = self._taskAwards[idx + 1]
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
function PCGuildMainPanel:OnTaskStarListRenderer(idx, item)
	
end

function PCGuildMainPanel:RefreshGXUI(_,gxCount,taskCount,freeCount,data)
	self._gxCount = gxCount
	self._taskCount = taskCount
	self._refreshCount = freeCount	 
	if data then
		-- 将JSON字符串转换为对象
		local dataObj = nil
		if type(data) == "string" and data ~= "" then
			dataObj = cjson.decode(data)
		elseif type(data) == "table" then
			dataObj = data
		end
		
		if dataObj then
			self._taskId = dataObj.taskid
			self._taskState = dataObj.state
			self._curJinDu = dataObj.jindu
		end
	end
	self:OnUpdateGXUI()
end
--end
-----------------------------------贡献界面----------------------------------

function PCGuildMainPanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_MAIN_INFO, "PCGuildMainPanel", handler(self, self.OnRefreshMainInfo))
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_NOTICE_UPDATE, "PCGuildMainPanel", handler(self, self.OnRefreshMainInfo))
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_MEMBER_LIST, "PCGuildMainPanel", handler(self, self.RefreshMemberList))
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_EDITOR_NOTICE_FAIL, "PCGuildMainPanel", handler(self, self.OnEditNoticeFail))
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_LIST, "PCGuildMainPanel", handler(self, self.OnRefreshGuildList))
	SL:RegisterNetMsg(ssrNetMsgCfg.Guild_RetData, handler(self, self.RefreshGXUI))
end

function PCGuildMainPanel:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_MAIN_INFO, "PCGuildMainPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_NOTICE_UPDATE, "PCGuildMainPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_MEMBER_LIST, "PCGuildMainPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_EDITOR_NOTICE_FAIL, "PCGuildMainPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_LIST, "PCGuildMainPanel")
	SL:UnRegisterNetMsg(ssrNetMsgCfg.Guild_RetData)
end


return PCGuildMainPanel