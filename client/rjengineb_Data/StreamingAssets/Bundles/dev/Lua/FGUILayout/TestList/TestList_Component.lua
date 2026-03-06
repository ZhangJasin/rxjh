local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TestList_Component = class("TestList_Component", BaseFGUILayout)

local Processer = class("Processer")
function Processer:ctor(title, owner)
    self.title = title
    self.owner = owner
    self.url = nil
    self.widget = nil
end

function Processer:Init(widget)
    self.widget = widget

end

local Switch_Processer = class("Switch_Processer", Processer)
function Switch_Processer:ctor(title, owner)
    self.super.ctor(self, title, owner)
    self.url = "ui://b8v07xpyvuky10"

    self.value = 0
    self.get = nil
    self.set = nil

    self.input = nil
end

function Switch_Processer:Init(widget, typeNames, get, set)
    Switch_Processer.super.Init(self, widget)
    self.typeNames = typeNames
    self.len = #self.typeNames
    self.get = get
    self.set = set

    widget:GetChild("title").text = self.title

    self.input = widget:GetChild("value")
    widget:GetChild("left").onClick:EventListener_Set(function()
        self:SwitchType(-1)
    end)

    widget:GetChild("right").onClick:EventListener_Set(function()
        self:SwitchType(1)
    end)
    self:Refresh()
end

function Switch_Processer:Refresh()
    local temp = self.get()
    if not temp then
        return
    end
    local t = type(self.typeNames[1])
    if type(self.typeNames[1]) == "table" then
        for i, v in ipairs(self.typeNames) do
            if v.idx == temp then
                self.input.text = tostring(temp) .. "(" .. v.name .. ")"
            end
        end
        return
    end
    self.input.text = tostring(temp) .. "(" .. self.typeNames[temp + 1] .. ")"
end

function Switch_Processer:SwitchType(offset)
    self.value = self.value + offset + self.len
    self.value = self.value % self.len
    if self.typeNames[self.value + 1].idx then
        self.set(self.typeNames[self.value + 1].idx)
    else
        self.set(self.value)
    end
    self:Refresh()
end

local Space_Processer = class("Space_Processer", Processer)
function Space_Processer:ctor(title, owner)
    self.super.ctor(self, title, owner)
    self.url = "ui://b8v07xpyvuky11"

    self.get = nil
    self.set = nil

    self.input = nil
end

function Space_Processer:Init(widget)
    Space_Processer.super.Init(self, widget)
    widget:GetChild("title").text = self.title
end

local Input_Processer = class("Input_Processer", Processer)
function Input_Processer:ctor(title, owner, btn_name)
    self.super.ctor(self, title, owner)
    self.url = "ui://b8v07xpyvuky12"
    self.btn_name = btn_name

    self.get = nil
    self.set = nil

    self.input = nil
end

function Input_Processer:Init(widget, get, set)
    Input_Processer.super.Init(self, widget)
    self.get = get
    self.set = set

    widget:GetChild("title").text = self.title

    self.input = widget:GetChild("value")
    local set = widget:GetChild("set")
    if self.btn_name then
        set.title = self.btn_name
    end

    set.onClick:EventListener_Set(function(context)
        self.set(self.input.text)
    end)

    self:Refresh()
end

function Input_Processer:Refresh()
    local temp = self.get()
    if temp then
        self.input.text = tostring(temp)
    end
end

local Doubel_Input_Processer = class("Doubel_Input_Processer", Processer)
function Doubel_Input_Processer:ctor(title, owner)
    self.super.ctor(self, title, owner)
    self.url = "ui://b8v07xpya3q113"

    self.get = nil
    self.set = nil

    self.input1 = nil
    self.input2 = nil
end

function Doubel_Input_Processer:Init(widget, get, set, prompt1, prompt2)
    Doubel_Input_Processer.super.Init(self, widget)
    self.get = get
    self.set = set

    widget:GetChild("title").text = self.title

    self.input1 = widget:GetChild("value1")
    self.input2 = widget:GetChild("value2")
    if prompt1 then
        self.input1.promptText = prompt1
    end
    if prompt2 then
        self.input2.promptText = prompt2
    end
    widget:GetChild("set").onClick:EventListener_Set(function()
        self.set(self.input1.text, self.input1.text)
    end)

    self:Refresh()
end

function Doubel_Input_Processer:Refresh()
    local value1, value2 = self.get()
    if value1 then
        self.input1.text = tostring(value1)
    end
    if value2 then
        self.input2.text = tostring(value2)
    end
end

local Button_Processer = class("Button_Processer", Processer)
function Button_Processer:ctor(title, owner)
    self.super.ctor(self, title, owner)
    self.url = "ui://b8v07xpya3q116"
    self.title = title

    self.callback = nil
end

function Button_Processer:Init(widget, callback)
    Button_Processer.super.Init(self, widget)
    self.callback = callback

    local btn = widget:GetChild("btn")
    btn.title = self.title;
    btn.onClick:EventListener_Set(function()
        if self.callback then
            self.callback()
        end
    end)
end
-- ============================================================================================================================--

function TestList_Component:Create()
    self.handle_close = handler(self, self.Close)
    self.test_list = self:GetChild("test_list")
    self.handler_list = self:GetChild("handler_list")

    FGUI:GList_setDefaultItemSize(self.test_list, 150, 150)
    FGUI:GList_itemRenderer(self.test_list, handler(self, self.TestItemRenderer))
    FGUI:GList_setNumItems(self.test_list, 200)
    FGUI:GList_AddClickItemEvent(self.test_list,handler(self, self.OnClickItem))
    FGUI:GList_AddRightClickItemEvent(self.test_list,handler(self, self.OnRightClickItem))

    self.processerList = 
    {
        Input_Processer.new("ItemNum:", self), 
        Switch_Processer.new("Layout:", self),

        Switch_Processer.new("Line Count:", self), 
        Switch_Processer.new("Column Count:", self),
        Switch_Processer.new("Line Gap:", self), 
        Switch_Processer.new("Column Gap:", self),

        Switch_Processer.new("Horizontal Align:", self),
        Switch_Processer.new("Vertical Align:", self), 
        Switch_Processer.new("AutoResizeItem:", self),
        Switch_Processer.new("DefaultItem:", self),
        Doubel_Input_Processer.new("DefaultItemSize:", self), 

        Space_Processer.new("Selection", self),
        Switch_Processer.new("SelectionMode:", self), 
        Switch_Processer.new("ItemToViewOnClick:", self),
        Input_Processer.new("CurrentSelection:", self, "Refresh"),
        Input_Processer.new("AddSelection:", self, "Add"),
        Input_Processer.new("RemoveSelection:", self, "Rm"),
        Button_Processer.new("ClearSelection", self),
        Button_Processer.new("SelectAll", self),
        Button_Processer.new("SelectReverse", self),
        -- Switch_Processer.new("EnableSelectionFocusEvents:", self)
        Switch_Processer.new("EnableArrowKeyNavigation:", self),
        Doubel_Input_Processer.new("ScrollToView:", self),
    }
    FGUI:GList_itemProvider(self.handler_list, handler(self, self.HandlerItemProvider))
    FGUI:GList_itemRenderer(self.handler_list, handler(self, self.HandlerItemRenderer))
    FGUI:GList_setNumItems(self.handler_list, #self.processerList)
    self._index = -1
    self:Init_ItemNums()
    self:Init_Layer()
    self:Init_LineCount()
    self:Init_ColumnCount()
    self:Init_LineGap()
    self:Init_ColumnGap()
    self:Init_Align()
    self:Init_VerticalAlign()
    self:Init_AutoResizeItem()
    self:Init_DefaultItem()
    self:Init_DefaultItemSize()
    self:Init_Selection()
    self:Init_SelectionMode()
    self:Init_ItemToViewOnClick()
    self:Init_PrintSelection()
    self:Init_AddSelection()
    self:Init_RemoveSelection()
    self:Init_ClearSelection()
    self:Init_SelectAll()
    self:Init_SelectReverse()
    self:Init_EnableArrowKeyNavigation()
    self:Init_ScrollToView()
    
    self:InitEvent()
end

function TestList_Component:InitEvent()
    local btn_close = self:GetChild("closeButton")
    btn_close.onClick:Add(self.handle_close)
end

function TestList_Component:HandlerItemProvider(index)
    return self.processerList[index + 1].url
end

function TestList_Component:HandlerItemRenderer(index, item)
end

function TestList_Component:TestItemRenderer(index, item)
    item.title = index % FGUI:GList_getNumItems(self.test_list)
    item.int_data = index
    local width, height = FGUI:GList_getDefaultItemSize(self.test_list)
    if width > 0 and height > 0 then
        item:SetSize(width, height)
    end
end

function TestList_Component:OnClickItem(context)
    print("鼠标左键点击了item: " .. tostring(context.data.int_data))
end

function TestList_Component:OnRightClickItem(context)
    print("鼠标右键点击了item: " .. tostring(context.data.int_data))
end

function TestList_Component:Init_ItemNums()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local get = function()
        return FGUI:GList_getNumItems(self.test_list)
    end
    local set = function(count)
        count = tonumber(count)
        FGUI:GList_setNumItems(self.test_list, count)
    end
    processer:Init(item, get, set)
end

function TestList_Component:Init_Layer()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {{
        idx = 2,
        name = "FlowHorizontal"
    }, {
        idx = 3,
        name = "FlowVertical"
    }}
    local get = function()
        return FGUI:GList_getLayout(self.test_list)
    end
    local set = function(layout)
        FGUI:GList_setLayout(self.test_list, layout)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_LineCount()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}
    local get = function()
        return FGUI:GList_getLineCount(self.test_list)
    end
    local set = function(count)
        FGUI:GList_setLineCount(self.test_list, count)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_ColumnCount()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}
    local get = function()
        return FGUI:GList_getColumnCount(self.test_list)
    end
    local set = function(count)
        FGUI:GList_setColumnCount(self.test_list, count)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_LineGap()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {
        { idx = 5, name = "5" }, 
        { idx = 10, name = "10" }, 
        { idx = 15, name = "15" }, 
        { idx = 20, name = "20" }, 
        { idx = 25, name = "25" }, 
        { idx = 30, name = "30" }, 
        { idx = 40, name = "40" }, 
        { idx = 50, name = "50" }, 
        { idx = 60, name = "60"
    }}
    local get = function()
        return FGUI:GList_getLineGap(self.test_list)
    end
    local set = function(layout)
        FGUI:GList_setLineGap(self.test_list, layout)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_ColumnGap()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = 
    {
        {idx = 5,name = "5"}, 
        {idx = 10,name = "10"}, 
        {idx = 15,name = "15"}, 
        {idx = 20,name = "20"}, 
        {idx = 25,name = "25"}, 
        {idx = 30,name = "30"}, 
        {idx = 40,name = "40"}, 
        {idx = 50,name = "50"}, 
        {idx = 60, name = "60" }
}
    local get = function()
        return FGUI:GList_getColumnGap(self.test_list)
    end
    local set = function(layout)
        FGUI:GList_setColumnGap(self.test_list, layout)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_Align()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"Left", "Center", "Right"}
    local get = function()
        return FGUI:GList_getAlign(self.test_list)
    end
    local set = function(align)
        FGUI:GList_setAlign(self.test_list, align)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_VerticalAlign()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"Top", "Middle", "Bottom"}
    local get = function()
        return FGUI:GList_getVerticalAlign(self.test_list)
    end
    local set = function(align)
        FGUI:GList_setVerticalAlign(self.test_list, align)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_AutoResizeItem()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"False", "True"}
    local get = function()
        local value = FGUI:GList_getAutoResizeItem(self.test_list)
        if value then
            return 1
        else
            return 0
        end
    end
    local set = function(value)
        FGUI:GList_setAutoResizeItem(self.test_list, value == 1)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_DefaultItem()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {
        { idx = 1, name = "ui://b8v07xpyvukyt" }, 
        { idx = 2, name = "ui://b8v07xpya3q114" }, 
        { idx = 3, name = "ui://b8v07xpya3q115" }
    }
    local get = function()
        local item = FGUI:GList_getDefaultItem(self.test_list)
        for i, v in ipairs(typeNames) do
            if v.name == item then
                return i
            end
        end
        return 1
    end
    local set = function(layout)
        local temp = typeNames[layout]
        if temp then
            FGUI:GList_setDefaultItem(self.test_list, temp.name)
        end
        local nums = FGUI:GList_getNumItems(self.test_list)
        FGUI:GList_setNumItems(self.test_list, 0)
        FGUI:GList_setNumItems(self.test_list, nums)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_DefaultItemSize()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local get = function()
        return FGUI:GList_getDefaultItemSize(self.test_list)
    end

    local set = function(width, height)
        width = tonumber(width)
        height = tonumber(height)
        FGUI:GList_setDefaultItemSize(self.test_list, width, height)
    end
    processer:Init(item, get, set)
end

function TestList_Component:Init_Selection()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    processer:Init(item)
end

function TestList_Component:Init_SelectionMode()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"Single", "Multiple", "Multiple_SingleClick", "None"}
    local get = function()
        return FGUI:GList_getSelectionMode(self.test_list)
    end
    local set = function(value)
        FGUI:GList_setSelectionMode(self.test_list, value)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_ItemToViewOnClick()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"False", "True"}
    local get = function()
        local value = FGUI:GList_getScrollItemToViewOnClick(self.test_list)
        if value then
            return 1
        else
            return 0
        end
    end
    local set = function(value)
        FGUI:GList_setScrollItemToViewOnClick(self.test_list, value == 1)
    end
    processer:Init(item, typeNames, get, set)
end


function TestList_Component:Init_PrintSelection()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local get = function()
        local selection = FGUI:GList_getSelection(self.test_list)
        return table.concat(selection,",")
    end
    local set = function(count)
        processer:Refresh()
    end
    processer:Init(item, get, set)
end

function TestList_Component:Init_AddSelection()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local get = function()
    end
    local set = function(idx)
        idx = tonumber(idx)
        FGUI:GList_addSelection(self.test_list, idx, true)
    end
    processer:Init(item, get, set)
end

function TestList_Component:Init_RemoveSelection()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local get = function()
    end
    local set = function(idx)
        idx = tonumber(idx)
        FGUI:GList_removeSelection(self.test_list, idx, true)
    end
    processer:Init(item, get, set)
end

function TestList_Component:Init_ClearSelection()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local callback = function ()
        FGUI:GList_clearSelection(self.test_list)
    end
    processer:Init(item, callback)
end

function TestList_Component:Init_SelectAll()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local callback = function ()
        FGUI:GList_selectAll(self.test_list)
    end
    processer:Init(item, callback)
end

function TestList_Component:Init_SelectReverse()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local callback = function ()
        FGUI:GList_selectReverse(self.test_list)
    end
    processer:Init(item, callback)
end

function TestList_Component:Init_EnableSelectionFocusEvents()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"False", "True"}
    local get = function()
        if self._enableSelectionFocusEvents == nil then
            self._enableSelectionFocusEvents = false
        end
        return self._enableSelectionFocusEvents and 1 or 0
    end
    local set = function(value)
        self._enableSelectionFocusEvents = value == 1
        FGUI:GList_enableSelectionFocusEvents(self.test_list, self._enableSelectionFocusEvents)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_EnableArrowKeyNavigation()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local typeNames = {"False", "True"}
    local get = function()
        if self._enableArrowKeyNavigation == nil then
            self._enableArrowKeyNavigation = false
        end
        return self._enableArrowKeyNavigation and 1 or 0
    end
    local set = function(value)
        self._enableArrowKeyNavigation = value == 1
        FGUI:GList_enableArrowKeyNavigation(self.test_list, self._enableArrowKeyNavigation)
    end
    processer:Init(item, typeNames, get, set)
end

function TestList_Component:Init_ResizeToFit()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local get = function()
    end

    local set = function(itemCount, minSize)
        itemCount = tonumber(itemCount)
        minSize = tonumber(minSize)
        FGUI:GList_resizeToFit(self.test_list, itemCount, minSize)
    end
    processer:Init(item, get, set,"[color=#666666]itemCount[/color]","[color=#666666]minSize[/color]")
end

function TestList_Component:Init_ScrollToView()
    self._index = self._index +1
    local item, processer= self:GetHandlerItem(self._index)
    local get = function()
    end

    local set = function(index, setFirst)
        index = tonumber(index)
        setFirst = setFirst == "1" or string.lower(setFirst) == "true"
        
        FGUI:GList_ScrollToView(self.test_list, index, true, setFirst)
    end
    processer:Init(item, get, set,"[color=#666666]item索引[/color]","[color=#666666]setFirst[/color]")
end

function TestList_Component:GetHandlerItem(index)
    local item_index = FGUI:GList_itemIndexToChildIndex(self.handler_list, index)
    local item = self.handler_list:GetChildAt(item_index)
    local processer = self.processerList[index + 1]
    return item, processer
end

return TestList_Component
