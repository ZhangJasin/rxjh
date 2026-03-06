local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local StallMain = class("StallMain", BaseFGUILayout)
-- 摆摊主界面
local countPerPage = 6 -- 每页摊位数
function StallMain:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self._my_stall_data = {}	-- 自身摊位数据
	self._shop_list = {}		-- 显示摊位数据
	self._shop_count = 0		-- 商铺数据个数
	self.handler_browse_stall = handler(self, self.OnClickBrowseStall)
	self.handler_onStallItemRender = handler(self, self.OnStallItemRenderer)
	self.handler_onClickCollectShop = handler(self, self.OnClickCollectShop)

	self._curPage = 1
	self._scrollPane = self._ui.list_stall.scrollPane
	self._timeSchedule = nil
	self._isFlipQuery = true --翻页是否向服务器查询
	self._maxPageCount = 1
	self._curBrowseIndex = 0
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_search, handler(self, self.OnSearchStall))
	FGUI:setOnClickEvent(self._ui.btn_create, handler(self, self.OpenCreateStallPanel))
	-- 上一页
	FGUI:setOnClickEvent(self._ui.btn_pre_page, function ()
		self:GotoPage(self._curPage - 1)
	end)
	-- 下一页
	FGUI:setOnClickEvent(self._ui.btn_next_page, function ()
		self:GotoPage(self._curPage + 1)
	end)	

	-- 摊位购买
	FGUI:GList_setVirtual(self._ui.list_stall)
	FGUI:GList_itemRenderer(self._ui.list_stall, self.handler_onStallItemRender)
	FGUI:setOnClickEvent(self._ui.btn_filter_collect, handler(self, self.OnClickFilterCollect))
end

function StallMain:Enter()
    self:RegisterEvent()
	-- 查询收藏店铺列表
	SL:RequestStallCollectList()
	-- 查询自身店铺信息
	SL:RequestStallSelfShop()
	self._my_stall_data = SL:GetValue("STALL_MY_DATA")
	FGUI:GList_setNumItems(self._ui.list_stall, 0)
	-- 顶部信息显示
	self._isFlipQuery = true
	self:RefreshSelfInfoDisplay()
	self:GotoPage(1)
	FGUI:GList_setSelectedIndex(self._ui.list_filter, 0)
end

function StallMain:Exit()
	self:RemoveEvent()
	if self._timeSchedule then
		SL:UnSchedule(self._timeSchedule)
		self._timeSchedule = nil
	end
	FGUI:Close("Stall", "StallProduct")
	FGUI:Close("Bag", "SimpleBagPanel")
end

function StallMain:Close()
	self.super.Close(self)
end

-- 搜索
function StallMain:OnSearchStall()
	local input = FGUI:GTextField_getText(self._ui.inputText_search)
	if input and string.len(input) > 0 then
		local filterIdx = FGUI:GList_getSelectedIndex(self._ui.list_filter)
		if filterIdx == 0 then
			-- 搜索商品名
			SL:RequestStallQueryShopByItemName(input)
		elseif filterIdx == 1 then
			-- 搜索摊位名
			SL:RequestStallQueryShopByShopName(input)
		elseif filterIdx == 2 then
			
		end	
	else
		SL:RequestStallQueryShopByPage(1)		
	end
	self._curPage = 1
	FGUI:GTextField_setText(self._ui.text_page, string.format(GET_STRING(90010001), self._curPage, self._maxPageCount))
end


-- 点击收藏按钮
function StallMain:OnClickFilterCollect()
	local isSelected = FGUI:GButton_getSelected(self._ui.btn_filter_collect)
	if isSelected then
		SL:RequestStallCollectListDetail()
	else
		SL:RequestStallQueryShopByPage(1)	
	end
end

-- 跳转到某页
function StallMain:GotoPage(page)
	self._curPage = page

	if self._curPage < 1 then
		self._curPage = 1
		SL:ShowSystemTips(GET_STRING(90010017))
		return
	end

	if self._maxPageCount and self._maxPageCount > 0 then
		if self._curPage > self._maxPageCount then
			self._curPage = self._maxPageCount
			SL:ShowSystemTips(GET_STRING(90010016))
		end
	end

	if self._isFlipQuery then
		SL:RequestStallQueryShopByPage( self._curPage)
	else
		FGUI:ScrollPane_setCurrentPageY(self._scrollPane, self._curPage - 1)
	end

	FGUI:GTextField_setText(self._ui.text_page, string.format(GET_STRING(90010001), self._curPage, self._maxPageCount))
end

-- 顶部UI显示控制
function StallMain:RefreshSelfInfoDisplay()
	if self._my_stall_data then
		FGUI:GTextField_setText(self._ui.text_tip, GET_STRING(90010005))
		FGUI:GTextField_setText(self._ui.text_time, true)

		if self._timeSchedule then
			SL:UnSchedule(self._timeSchedule)
			self._timeSchedule = nil
		end
		-- 倒计时
		local refreshTime = function ()
			if self._my_stall_data and self._my_stall_data.CloseTime then
				local remainTime = 	self._my_stall_data.CloseTime - SL:GetValue("SERVER_TIME")
				if remainTime <= 0 then	
					SL:UnSchedule(self._timeSchedule)
					self._my_stall_data = nil
					FGUI:GTextField_setText(self._ui.text_tip, GET_STRING(90010004))
					FGUI:GTextField_setText(self._ui.text_time, false)
				else
					local timeStr = string.format(GET_STRING(90010003), SL:SecondToHMS(remainTime, true))
					FGUI:GTextField_setText(self._ui.text_time, timeStr)
				end
			else
				SL:UnSchedule(self._timeSchedule)
				FGUI:GTextField_setText(self._ui.text_time, false)
			end
			
		end
		self._timeSchedule = SL:Schedule(refreshTime, 1)
		refreshTime()
	else
		FGUI:GTextField_setText(self._ui.text_tip, GET_STRING(90010004))
		FGUI:GTextField_setText(self._ui.text_time, false)
	end
end

-- 刷新自身商铺信息
function StallMain:OnRefreshSelfShop()
	self._my_stall_data = SL:GetValue("STALL_MY_DATA")
	self:RefreshSelfInfoDisplay()
end

-- 刷新摊位列表数据
function StallMain:OnRefreshShopList(data, isFlipQuery, totalPage)
	if not data then return end
	
	-- 收藏筛选
	local isCollected = FGUI:GButton_getSelected(self._ui.btn_filter_collect)
	local filterData = {}
	if isCollected then
		for k, v in pairs(data) do
			if v.IsCollected then
				table.insert(filterData, v)
			end
		end
	else
		filterData = data
	end
	
	self._shop_list = filterData
	self._isFlipQuery = isFlipQuery
	self._shop_count = #self._shop_list
	FGUI:GList_setNumItems(self._ui.list_stall, self._shop_count)
	self._maxPageCount = totalPage or 1
	FGUI:GTextField_setText(self._ui.text_page, string.format(GET_STRING(90010001), self._curPage, self._maxPageCount))
	if FGUI:CheckOpen("Stall", "StallProduct") then
		local shopData = self._shop_list[self._curBrowseIndex]
		if shopData then
			shopData.isBrowse = true
			FGUIFunction:OpenStallProductUI(shopData)
		end
	end
end

function StallMain:OnStallItemRenderer(idx, item)
	local data = self._shop_list[idx + 1]
	if not data then
		FGUI:setVisible(item, false)
		return
	end
	
	local collectBtn = FGUI:GetChild(item, "btn_collect")
	FGUI:GButton_setSelected(collectBtn, data.IsCollected)
	FGUI:setOnClickEvent(collectBtn, self.handler_onClickCollectShop)	

	FGUI:setVisible(item, true)
	FGUI:GTextField_setText(FGUI:GetChild(item, "title_stall_name"), data.Name)
	local str_user_name = string.format(SL:GetValue("I18N_STRING", 90010030), data.UserName)
	str_user_name = FGUIFunction:GetServerName(str_user_name)
	FGUI:GTextField_setText(FGUI:GetChild(item, "title_owner_name"), str_user_name)
	local browse_btn = FGUI:GetChild(item, "btn_left")
	FGUI:setOnClickEvent(browse_btn, self.handler_browse_stall)

	FGUI:SetIntData(item, idx)
end


-- 打开创建摆摊界面
function StallMain:OpenCreateStallPanel()
	local data = SL:GetValue("STALL_MY_DATA")
	if data then
		if SL:GetValue("STALL_IS_NEW_QUERY_TYPE") then
			SL:RequestOpenShopByUserId(data.Userid)
		else
			SL:RequestOpenShop(data.Name)
		end
	else
		-- 判断是否可以摆摊
		local canStall = self:IsCanStall()
		if not canStall then
			return
		end
		-- 未拥有摊位
		if self:IsOnStallArea() then
			--在摆摊区域，打开创建摆摊面板
			FGUI:Open("Stall", "StallCreatePanel")
		else
			--不在摆摊区域，移动到摆摊区域
			local dialogData = {}
			dialogData.str = GET_STRING(90010024)
			dialogData.btnDesc = {GET_STRING(1001), GET_STRING(1000)}
			dialogData.callback = function (tag)		
				if tag == 1 then
					self:MoveToStallArea()
				end
			end
			SL:OpenCommonDialog(dialogData)
		end
		self:Close()
	end
end

-- 是否在摆摊区域
function StallMain:IsOnStallArea()	
	return SL:GetValue("STALL_IS_ON_SHOP_AREA")
end

-- 当前位置是否可以摆摊
function StallMain:IsCanStall()
	-- 当前分线是否可以摆摊
	local zone = SL:GetValue("STALL_SHOP_AREA")
    if not zone then 
		SL:ShowSystemTips(GET_STRING(90010026))
		return false
	end 
	if zone.IgnoreLine and next(zone.IgnoreLine) then
		local curRouteIdx = SL:GetValue("MAP_ROUTE_IDX")
		if zone.IgnoreLine[curRouteIdx] then
			SL:ShowSystemTips(GET_STRING(90010022))
			return false
		end
	end
	return true
end

-- 前往摆摊区域
function StallMain:MoveToStallArea()	
    local zone = SL:GetValue("STALL_SHOP_AREA") or {}
    local target_x = (zone.X1 + zone.X2 + zone.X3 + zone.X4) / 4
    local target_y = (zone.Y1 + zone.Y2 + zone.Y3 + zone.Y4) / 4 
    SL:SetValue("BATTLE_AUTO_MOVE_BEGIN", zone.MapId, target_x, target_y, nil, SLDefine.AUTO_MOVE_TO_DEST_FROM.STALL)
end

-- 点击浏览摊位
function StallMain:OnClickBrowseStall(context)
	local btn = context.sender
	local idx = FGUI:GetIntData(FGUI:GetParent(btn))
	self._curBrowseIndex = idx + 1
	local shopData = self._shop_list[idx + 1]
	shopData.isBrowse = true
	FGUIFunction:OpenStallProductUI(shopData)
end

-- 点击店铺收藏按钮
function StallMain:OnClickCollectShop(context)
	local btn = context.sender
	local idx = FGUI:GetIntData(FGUI:GetParent(btn))
	local shopData = self._shop_list[idx + 1]
	local isSelected = FGUI:GButton_getSelected(btn)
	SL:RequestCollectShop(shopData.Userid, isSelected)
end

-- 切换浏览摊位
function StallMain:SwitchBrowseStall(isNext)
	local targetIndex = isNext and self._curBrowseIndex + 1 or self._curBrowseIndex - 1

	if targetIndex < 1 then	
		if self._curPage == 1 then
			SL:ShowSystemTips(SL:GetValue("I18N_STRING", 90010017))
		else
			self._curBrowseIndex = countPerPage
			self:GotoPage(self._curPage - 1)
		end	
	elseif targetIndex > countPerPage then
		self._curBrowseIndex = 1
		self:GotoPage(self._curPage + 1)
	else	
		local shopData = self._shop_list[targetIndex]
		if shopData then
			self._curBrowseIndex = targetIndex
			shopData.isBrowse = true
			FGUIFunction:OpenStallProductUI(shopData)
		else
			local str = isNext and SL:GetValue("I18N_STRING", 90010016) or SL:GetValue("I18N_STRING", 90010017)
			SL:ShowSystemTips(str)
		end
	end
end

function StallMain:OnCollectShop(userid, isCollected)
	local childCount = FGUI:GetChildCount(self._ui.list_stall)
	for idx, v in pairs(self._shop_list) do
		if v.Userid == userid then

			local index = idx - 1
			if index < childCount then
				local item = FGUI:GetChildAt(self._ui.list_stall, index)
				if item then
					local btn_collect = FGUI:GetChild(item, "btn_collect")
					FGUI:GButton_setSelected(btn_collect, isCollected)
				end
			end		
		end
	end
end

-- 刷新当前页面摊位信息
function StallMain:RefreshCurrentPage()
	self:GotoPage(self._curPage)
end


function StallMain:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_STALL_REFRESH_SHOP_LIST, "StallMain", handler(self, self.OnRefreshShopList))	--摊位列表刷新
	SL:RegisterLUAEvent(LUA_EVENT_STALL_REFRESH_SELF_SHOP, "StallMain", handler(self, self.OnRefreshSelfShop))	--刷新自身摊位数据
	SL:RegisterLUAEvent(LUA_EVENT_STALL_BROWSE_SWITCH, "StallMain", handler(self, self.SwitchBrowseStall))	--切换浏览摊位
	SL:RegisterLUAEvent(LUA_EVENT_STALL_COLLECT_SHOP, "StallMain", handler(self, self.OnCollectShop))	--收藏店铺
	SL:RegisterLUAEvent(LUA_EVENT_STALL_REFRESH_PAGE, "StallMain", handler(self, self.RefreshCurrentPage))	--刷新当前页面摊位信息
	
end

function StallMain:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_REFRESH_SHOP_LIST, "StallMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_STALL_REFRESH_SELF_SHOP, "StallMain")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_BROWSE_SWITCH, "StallMain")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_COLLECT_SHOP, "StallMain")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_REFRESH_PAGE, "StallMain")
end

return StallMain