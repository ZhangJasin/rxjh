local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCAuctionRecordPanel = class("PCAuctionRecordPanel", BaseFGUILayout)

local MODE = {
    [1] = GET_STRING(30000074),
    [2] = GET_STRING(30000073),
    [3] = GET_STRING(30000070),
    [4] = GET_STRING(30000069),
    [5] = GET_STRING(30000071),
    [6] = GET_STRING(30000072),
}

function PCAuctionRecordPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitUI()
    self:InitData()
end

function PCAuctionRecordPanel:InitData()
    self._record = {}
end

function PCAuctionRecordPanel:InitUI()
    FGUI:GList_itemRenderer(self.list_record,handler(self,self.ListViewCellsItemRenderer))
	FGUI:GList_setVirtual(self.list_record)
end

function PCAuctionRecordPanel:ListViewCellsItemRenderer(idx,cell)
    local index = idx + 1
    local data = self._record[index]
    local text_time = FGUI:GetChild(cell,"text_time")
    local text_goods_name = FGUI:GetChild(cell,"text_goods_name")
    local text_count = FGUI:GetChild(cell,"text_count")
    local text_status = FGUI:GetChild(cell,"text_status")
    local text_price = FGUI:GetChild(cell,"text_price")
    local icon_money = FGUI:GetChild(cell,"icon_money")
    if data then
        FGUI:GTextField_setText(text_time,os.date("%Y-%m-%d %H:%M:%S",data.date))
        local itemData = SL:GetValue("ITEM_DATA",data.index)
        FGUI:GTextField_setText(text_goods_name,itemData.Name)
        FGUI:GTextField_setText(text_count,data.count)
        FGUI:GTextField_setText(text_status,MODE[data.type])
        FGUI:GTextField_setText(text_price,SL:GetThousandSepString(data.amount))
        itemData = SL:GetValue("ITEM_DATA",data.currency)
        ItemUtil:RefreshItemUIByData(icon_money,itemData)
        ItemUtil:SetItemGradeVisible(icon_money,false)
        ItemUtil:SetItemCountVisible(icon_money,false)
    end 
end

function PCAuctionRecordPanel:GetAllFGuiData()
    self.list_record = self._ui.list_record
    self.ctrl_isHaveRecord = FGUI:getController(self.component,"isHaveRecord")
end

function PCAuctionRecordPanel:InitClickEvent()
end

function PCAuctionRecordPanel:RefreshRecordList()
    local nums = table.nums(self._record or {})
    FGUI:Controller_setSelectedIndex(self.ctrl_isHaveRecord,nums > 0 and 1 or 0)
    FGUI:GList_setNumItems(self.list_record, nums)
end

function PCAuctionRecordPanel:RefreshRecordData(data)
    self._record = data
    self:SortData()
    self:RefreshRecordList()
end

function PCAuctionRecordPanel:SortData()
    table.sort(self._record,function(a,b) return a.date > b.date end)
end

function PCAuctionRecordPanel:Enter()
    self:RegisterEvent()
    self:RefreshRecordList()
    SL:RequestAuctionAllLog(1)
    SL:ComponentAttach(SLDefine.SUIComponentTable.AuctionRecord, self._ui.Node_attach)
end

function PCAuctionRecordPanel:Exit()
    self:RemoveEvent()
    SL:ComponentDetach(SLDefine.SUIComponentTable.AuctionRecord)
end

function PCAuctionRecordPanel:Destory()

end

function PCAuctionRecordPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_AUCTION_LOG, "PCAuctionRecordPanel", handler(self, self.RefreshRecordData))
end

function PCAuctionRecordPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_AUCTION_LOG, "PCAuctionRecordPanel")
end

return PCAuctionRecordPanel
