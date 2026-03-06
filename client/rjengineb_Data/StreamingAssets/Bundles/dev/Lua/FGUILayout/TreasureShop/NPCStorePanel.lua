local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local NPCStorePanel = class("NPCStorePanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local countPerPage = 35 -- 每页商品格子数量
local popup_shopitem_url ="ui://p8mjxubrlz03v5x"

function NPCStorePanel:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._groupId = nil
	self._shopDatas = {} 	--商品信息表
	self._itemDatas = {}	--商品Item信息表
	self._curPrice = 0 		--当前选择物品单价
	self._curShopID = 0 	--当前选择物品ID
	self._shopitem_popup = nil
	self._ui_popup = {}		--popui 同 _ui,用来查找弹出框子物体
	self._buyCount = 1		--购买数量
	self._minBuyCount = 1	--当前选中商品最小购买数量
	self._maxBuyCount = 99	--当前选中商品最大购买数量
	self._curPageIndex = 0 	--当前所在页
	self._maxPageCount = 0	--最大页数
	self._clickItem = nil


	self.handler_onShopItemRenderer = handler(self, self.OnShopItemRenderer)
	self.handler_onClickShopItem = handler(self, self.OnClickShopItem)
	-- 关闭
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	-- 上一页
	FGUI:setOnClickEvent(self._ui.BtnPre, function ()
		self:SetPage(self._curPageIndex - 1)
	end)
	-- 下一页
	FGUI:setOnClickEvent(self._ui.BtnNext, function ()
		self:SetPage(self._curPageIndex + 1)
	end)
	FGUI:GList_itemRenderer(self._ui.List_Cell, self.handler_onShopItemRenderer)
	FGUI:GList_addOnClickItemEvent(self._ui.List_Cell, self.handler_onClickShopItem)
	
end

function NPCStorePanel:Enter(groupId)
	self._groupId = groupId
    self:RegisterEvent()
	self:RefreshShopItem()
	self:InitUI()
	self:InitPopupMenu()
end

function NPCStorePanel:InitUI()
	local shopName = SL:GetValue("NPC_STORE_GROUP_NAME", self._groupId)
	FGUI:GTextField_setText(self._ui.text_title, shopName)
	self:SetPage(0)
end

function NPCStorePanel:InitPopupMenu()
	self._shopitem_popup = FGUI:PopupMenu_createMenu(popup_shopitem_url) --点击商品后的弹出PopupMenu
	self._ui_popup = {}
	setmetatable(self._ui_popup, {
		__index = function(table, key)
			local com = FGUI:PopupMenu_getChild(self._shopitem_popup, key)
			rawset(table, key, com)
			return com
		end
	})
	FGUI:setOnClickEvent(self._ui_popup.btn_count_add, function ()
		self:ModifyBuyCount(1)
	end)

	FGUI:setOnClickEvent(self._ui_popup.btn_count_sub, function ()
		self:ModifyBuyCount(-1)
	end)
	-- FGUI:setOnClickEvent(self._ui_popup.btn_input_count, handler(self, self.OnClickInputCountButton))
	-- 购买
	FGUI:setOnClickEvent(self._ui_popup.btn_buy, handler(self, self.OnClickBuyButton))
end

-- 设置页面
function NPCStorePanel:SetPage(page)
	if page < 0 then
		page = 0
	elseif page > self._maxPageCount - 1 then
		page = self._maxPageCount - 1
	end

	self._curPageIndex = page
	FGUI:GTextField_setText(self._ui.TextPage, string.format(GET_STRING(90010002), self._curPageIndex + 1))
	FGUI:GList_setNumItems(self._ui.List_Cell, countPerPage)
end

function NPCStorePanel:Exit()
	self:RemoveEvent()
	if self._shopitem_popup then
		FGUI:RemoveFromParent(self._shopitem_popup)
		self._shopitem_popup = nil
	end
	
end

function NPCStorePanel:Close()
	self.super.Close(self)
end

-- 刷新商品显示
function NPCStorePanel:RefreshShopItem()
	self._shopDatas = {}
	local data = SL:GetValue("NPC_STORE_DATA_BY_GROUP", self._groupId)
	-- npc商店无页签，道具都放一起
	if data then
		for _, pages in pairs(data) do
			if pages then
				for _, v in pairs(pages) do
					table.insert(self._shopDatas, v)
				end
			end
		end
	end

	if self._shopDatas then
		local shopCnt = #self._shopDatas
		self._maxPageCount = math.ceil(shopCnt / countPerPage)
	end
end

function NPCStorePanel:OnShopItemRenderer(idx, item)
	local index = self._curPageIndex * countPerPage + idx + 1
	local data = self._shopDatas[index]
	FGUI:SetIntData(item, idx)
	local obj = FGUI:GetChild(item, "ContentItem")
	if not data then 
		FGUI:setVisible(obj, false)
		return 		
	end
	local itemData = SL:GetValue("ITEM_DATA", data.Itemid)
	if not itemData then
		FGUI:setVisible(obj, false)
		return 		
	end	
	FGUI:setVisible(obj, true)
	self._itemDatas[index] = itemData
	ItemUtil:RefreshItemUIByData(obj,itemData)	
end

-- 点击商品事件
function NPCStorePanel:OnClickShopItem(context)
	self._clickItem = context.data
	local idx = FGUI:GetIntData(self._clickItem)
	local index = self._curPageIndex * countPerPage + idx + 1
	local itemData = self._itemDatas[index]
	local shopData = self._shopDatas[index]
	if not itemData or not shopData then return end
	--单价
	self._curPrice = shopData.Nowprice
	self._curShopID = shopData.ID
	FGUI:PopupMenu_show(self._shopitem_popup, self._clickItem)
	-- 刷新弹窗框UI
	ItemUtil:RefreshItemUIByData(self._ui_popup.icon_item,itemData)

	-- -- 名称
	 FGUI:GTextField_setText(self._ui_popup.text_name, itemData.Name)
	-- -- 描述
	if itemData.Desc then
		FGUI:GTextField_setText(self._ui_popup.text_desc, itemData.Desc)
	else
		FGUI:GTextField_setText(self._ui_popup.text_desc, "")	
	end

	-- -- 获取途径
	if itemData.GetWayInfo then
		local wayStr = string.format(GET_STRING(60006007), itemData.GetWayInfo)
		FGUI:GTextField_setText(self._ui_popup.text_way, wayStr)	
	else
		FGUI:GTextField_setText(self._ui_popup.text_way, "")	
	end

	self._minBuyCount = 1
	self._maxBuyCount = 99
	local cntArr = string.split(shopData.OnceCount, '#')
	if cntArr then
		self._minBuyCount = tonumber(cntArr[1]) or self._minBuyCount
		self._maxBuyCount = tonumber(cntArr[2]) or self._maxBuyCount
	end

	-- 初始化购买数量
	self:SetBuyCount(self._minBuyCount)
	FGUI:GTextField_setText(self._ui_popup.text_price, self._curPrice)
	--货币图标设置
	ItemUtil:SetItemIconByItemID(self._ui_popup.icon_money, shopData.Costtype)
end

function NPCStorePanel:ModifyBuyCount(value)
	self:SetBuyCount(self._buyCount + value)
end

-- 设置购买数量
function NPCStorePanel:SetBuyCount(count)
	if count > self._maxBuyCount then
		count = self._maxBuyCount
	elseif count < self._minBuyCount then
		count = self._minBuyCount
	end

	self._buyCount = count
	FGUI:GTextField_setText(self._ui_popup.text_count, count)
	FGUI:GTextField_setText(self._ui_popup.text_price, self._curPrice * self._buyCount)
end

-- 打开输入数量界面
function NPCStorePanel:OnClickInputCountButton()
	FGUI:PopupMenu_hide(self._shopitem_popup)
	local data = {}
	data.title = GET_STRING(60006008)
	data.callback_yes = function (number)
		self:SetBuyCount(number)
		FGUI:PopupMenu_show(self._shopitem_popup, self._clickItem)
	end
	data.callback_no = function ()
		FGUI:PopupMenu_show(self._shopitem_popup, self._clickItem)
	end
	FGUIFunction:OpenCommonNumberInputPanel(data)
end

-- 点击购买
function NPCStorePanel:OnClickBuyButton()
	SL:RequestStoreBuy(self._curShopID, self._buyCount, self._groupId)
	FGUI:PopupMenu_hide(self._shopitem_popup)
end

function NPCStorePanel:RegisterEvent()

end

function NPCStorePanel:RemoveEvent()
	
end

return NPCStorePanel