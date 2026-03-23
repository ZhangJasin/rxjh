local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ExChangeRecordPanel = class("ExChangeRecordPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local MODE = {
    [1] = GET_STRING(30000074),
    [2] = GET_STRING(30000073),
    [3] = GET_STRING(30000070),
    [4] = GET_STRING(30000069),
    [5] = GET_STRING(30000071),
    [6] = GET_STRING(30000072),
}

--- 界面被创建时调用
function ExChangeRecordPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitData()
end

function ExChangeRecordPanel:GetAllFGuiData()
    self.list_record = self._ui.list_record
    self.noItemtip = self._ui.noItemtip
    -- 下拉过滤
    self.filter = self._ui.filter
end

function ExChangeRecordPanel:InitData()
    self.list_item = {}
    self._filter = 0
end

function ExChangeRecordPanel:InitClickEvent()
    FGUI:GList_itemRenderer(self.list_record,handler(self,self.RecordItemRender))
    FGUI:GList_setVirtual(self.list_record)
    FGUI:GComboBox_setOnChangeCallback(self.filter,handler(self,self.cbxFilterChanged))
end

function ExChangeRecordPanel:cbxFilterChanged()
    local filterSel = FGUI:GComboBox_getSelectedIndex(self.filter)
    self._filter = filterSel
    self:FilterDataAndRfView()
end

function ExChangeRecordPanel:RecordItemRender(idx,item)
    local text_time = FGUI:GetChild(item,"text_time")
    local text_goods_name = FGUI:GetChild(item,"text_goods_name")
    local text_count = FGUI:GetChild(item,"text_count")
    local text_status = FGUI:GetChild(item,"text_status")
    local item_node = FGUI:GetChild(item,"item_node")
    local icon_money = FGUI:GetChild(item,"icon_money")
    local id = FGUI:GetID(item)
    if self.list_item[id] then
        ItemUtil:ItemShow_Release(self.list_item[id])
    end

    local data = self._filter_record[idx + 1]
    if data then
        local itemData = SL:GetValue("ITEM_DATA",data.index)
        self.list_item[id] = ItemUtil:ItemShow_Create(itemData,item_node)
        FGUI:GTextField_setText(text_goods_name,itemData.Name)
        FGUI:GTextField_setText(text_status,MODE[data.type])
        FGUI:GTextField_setText(text_count,SL:GetThousandSepString(data.amount))
        FGUI:GTextField_setText(text_time,os.date("%Y-%m-%d %H:%M:%S",data.date))
        itemData = SL:GetValue("ITEM_DATA",data.currency)
        ItemUtil:RefreshItemUIByData(icon_money,itemData)
        ItemUtil:SetItemGradeVisible(icon_money,false)
        ItemUtil:SetItemCountVisible(icon_money,false)
    end
end

function ExChangeRecordPanel:CleanCache()
    for k,v in pairs(self.list_item) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end

    self.list_item = {}
end

function ExChangeRecordPanel:RefreshRecordList()
    local nums = table.nums(self._filter_record or {})
    FGUI:setVisible(self.noItemtip,nums <= 0)
    -- 最多显示30条
    if nums > 30 then
        nums = 30
    end
    FGUI:GList_setNumItems(self.list_record, nums)
end

function ExChangeRecordPanel:RefreshRecordData(data)
    self._record  = data
    self:FilterDataAndRfView()
end

function ExChangeRecordPanel:FilterDataAndRfView()
    self._filter_record = {}
    if self._filter == 0 then -- 全部记录
        self._filter_record = self._record
    elseif self._filter == 1 then -- 出售记录
        for k,v in pairs(self._record) do
            if v.type == 1 then
                table.insert(self._filter_record,v)
            end
        end
    elseif self._filter == 2 then -- 购买记录
        for k,v in pairs(self._record) do
            if v.type == 2 then
                table.insert(self._filter_record,v)
            end
        end
    end

    self:SortData()
    self:RefreshRecordList()
end

function ExChangeRecordPanel:SortData()
    table.sort(self._filter_record,function(a,b) return a.date > b.date end)
end

--- 界面打开时调用
function ExChangeRecordPanel:Enter(data)
    self:RegisterEvent()
    SL:RequestExLog()
end

--- 界面关闭时调用
function ExChangeRecordPanel:Exit()
    self:RemoveEvent()
    self:CleanCache()
end

function ExChangeRecordPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_LOG, "ExChangeRecordPanel", handler(self, self.RefreshRecordData))
end

function ExChangeRecordPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_LOG, "ExChangeRecordPanel")
end

--- 界面销毁时调用
function ExChangeRecordPanel:Destroy()
end


return ExChangeRecordPanel
