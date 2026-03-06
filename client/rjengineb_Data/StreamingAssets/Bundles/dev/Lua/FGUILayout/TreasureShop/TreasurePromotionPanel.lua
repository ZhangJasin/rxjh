local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TreasurePromotionPanel = class("TreasurePromotionPanel", BaseFGUILayout)

function TreasurePromotionPanel:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

-- 关闭
function TreasurePromotionPanel:Close()
    self:RemoveEvent()
    FGUI:Close("TreasureShop", "TreasurePromotionPanel")
    --清理数据
    self.itemDataList=nil
    self._ui=nil
    --调用父类关闭方法
    self.super.Close(self)
end

function TreasurePromotionPanel:InitData()
    self._itemList = {}  -- 商品列表
    self._selectedItem = nil  -- 当前选中商品
    self._pageIndex = 1  -- 当前页码
end

function TreasurePromotionPanel:InitUI()
    -- 初始化商品列表
    FGUI:GList_itemRenderer(self._ui.list_items, handler(self, self.OnItemRenderer))
    FGUI:GList_setNumItems(self._ui.list_items, #self._itemList)
    
    -- 初始化分页按钮
    FGUI:GButton_addClick(self._ui.btn_prev, handler(self, self.OnClickPrev))
    FGUI:GButton_addClick(self._ui.btn_next, handler(self, self.OnClickNext))
    
    -- 初始化购买按钮
    FGUI:GButton_addClick(self._ui.btn_buy, handler(self, self.OnClickBuy))
end

function TreasurePromotionPanel:InitEvent()
    -- 注册商品选择事件
    FGUI:GList_addClick(self._ui.list_items, handler(self, self.OnSelectItem))
end

function TreasurePromotionPanel:RegisterEvent()
    -- 注册数据更新事件
    SL:RegisterLUAEvent(LUA_EVENT_TREASURE_SHOP_UPDATE, "TreasurePromotionPanel", handler(self, self.OnUpdateData))
end

function TreasurePromotionPanel:OnItemRenderer(idx, item)
    local data = self._itemList[idx + 1]
    if data then
        FGUI:GTextField_setText(FGUI:GetChild(item, "text_name"), data.name)
        FGUI:GTextField_setText(FGUI:GetChild(item, "text_price"), tostring(data.price))
        FGUI:GLoader_setURL(FGUI:GetChild(item, "icon_item"), data.icon)
    end
end

function TreasurePromotionPanel:OnSelectItem(evt)
    local idx = FGUI:GList_getSelectedIndex(self._ui.list_items)
    self._selectedItem = self._itemList[idx + 1]
    self:UpdateSelectedItem()
end

function TreasurePromotionPanel:UpdateSelectedItem()
    if self._selectedItem then
        FGUI:GTextField_setText(self._ui.text_selected_name, self._selectedItem.name)
        FGUI:GTextField_setText(self._ui.text_selected_desc, self._selectedItem.desc)
        FGUI:GLoader_setURL(self._ui.icon_selected_item, self._selectedItem.icon)
    end
end

function TreasurePromotionPanel:OnClickPrev()
    if self._pageIndex > 1 then
        self._pageIndex = self._pageIndex - 1
        self:UpdatePage()
    end
end

function TreasurePromotionPanel:OnClickNext()
    if self._pageIndex < self:GetMaxPage() then
        self._pageIndex = self._pageIndex + 1
        self:UpdatePage()
    end
end

function TreasurePromotionPanel:OnClickBuy()
    if self._selectedItem then
        SL:RequestBuyTreasureItem(self._selectedItem.id)
    end
end

function TreasurePromotionPanel:OnUpdateData(data)
    self._itemList = data.items
    self._pageIndex = data.pageIndex
    self:UpdatePage()
end

function TreasurePromotionPanel:UpdatePage()
    FGUI:GTextField_setText(self._ui.text_page, string.format("%d/%d", self._pageIndex, self:GetMaxPage()))
    FGUI:GList_setNumItems(self._ui.list_items, #self._itemList)
end

function TreasurePromotionPanel:GetMaxPage()
    return math.ceil(#self._itemList / 8)  -- 每页显示8个商品
end

function TreasurePromotionPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TREASURE_SHOP_UPDATE, "TreasurePromotionPanel")
end

function TreasurePromotionPanel:Exit()
    self:RemoveEvent()
end

return TreasurePromotionPanel