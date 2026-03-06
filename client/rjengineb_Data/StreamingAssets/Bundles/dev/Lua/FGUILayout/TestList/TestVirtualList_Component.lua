local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TestVirtualList_Component = class("TestVirtualList_Component", BaseFGUILayout)

function TestVirtualList_Component:Create()
    self.handle_close = handler(self, self.Close)
    self.test_list = self:GetChild("test_list")

    FGUI:GList_setDefaultItemSize(self.test_list, 150, 150)
    FGUI:GList_itemRenderer(self.test_list, handler(self, self.TestItemRenderer))
    FGUI:GList_AddClickItemEvent(self.test_list, handler(self, self.OnClickItem))
    FGUI:GList_AddRightClickItemEvent(self.test_list, handler(self, self.OnRightClickItem))

    -- FGUI:GList_setVirtual(self.test_list)
    self._itemNums = 200
    -- FGUI:GList_setNumItems(self.test_list, self._itemNums)

    self:InitEvent()
end

function TestVirtualList_Component:InitEvent()
    local btn_close = self:GetChild("closeButton")
    btn_close.onClick:Add(self.handle_close)

    local item_nums = self:GetChild("item_nums")
    item_nums:GetChild("title").text = "设置Item个数:"
    self._item_nums_text = item_nums:GetChild("value")
    self._item_nums_text.text = tostring(self._itemNums)
    item_nums:GetChild("set").onClick:EventListener_Set(handler(self, self.OnClickSetItemNums))

    local set = self:GetChild("set")
    local btn = set:GetChild("btn")
    btn.title = "设置为循环虚列表"
    btn.onClick:EventListener_Set( handler(self, self.OnClickSetLoopVirtualList))
end

function TestVirtualList_Component:TestItemRenderer(index, item)
    item.title = tostring(index % self._itemNums)
    item.int_data = index
end

function TestVirtualList_Component:OnClickItem(context)
    print("鼠标左键点击了item: " .. tostring(context.data.int_data))
end

function TestVirtualList_Component:OnRightClickItem(context)
    print("鼠标右键点击了item: " .. tostring(context.data.int_data))
end

function TestVirtualList_Component:OnClickSetItemNums()
    self._itemNums = tonumber(self._item_nums_text.text)
    if not FGUI:GList_getIsVirtual(self.test_list) then
        FGUI:GList_setVirtual(self.test_list)
    end
    FGUI:GList_setNumItems(self.test_list, self._itemNums)
end

function TestVirtualList_Component:OnClickSetLoopVirtualList()
    FGUI:GList_setVirtualAndLoop(self.test_list)
    FGUI:GList_setNumItems(self.test_list, self._itemNums)
end

return TestVirtualList_Component
